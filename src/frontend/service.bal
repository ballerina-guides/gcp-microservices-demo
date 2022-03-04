import ballerina/http;
import ballerina/os;
import ballerina/time;
import ballerina/uuid;

const string USER_COOKIE_NAME = "userId";
const string userCurrency = "USD";
final boolean is_cymbal_brand = os:getEnv("CYMBAL_BRANDING") == "true";

listener http:Listener ep = new (9098);

service class AuthInterceptor {
    *http:RequestInterceptor;
    resource function 'default [string... path](http:RequestContext ctx, http:Request req)
                returns http:NextService|error? {
        http:Cookie[] usernameCookie = req.getCookies().filter(function
                                (http:Cookie cookie) returns boolean {
            return cookie.name == USER_COOKIE_NAME;
        });
        if (usernameCookie.length() == 0) {
            http:Cookie cookie = new (USER_COOKIE_NAME, uuid:createType1AsString(),
                                                path = "/");

            req.addCookies([cookie]);
        }
        return ctx.next();
    }
}

AuthInterceptor authInterceptor = new;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true
    },
    interceptors: [authInterceptor]
}
service / on ep {

    resource function get metadata(@http:Header {name: "Cookie"} string cookieHeader)
                returns MetadataResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getUserIdFromCookie(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }

        string[] supportedCurrencies = check getSupportedCurrencies();
        Cart cart = check getCart(cookie.value);
        return <MetadataResponse>{
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                user_currency: userCurrency, //Todo to cookies
                currencies: supportedCurrencies,
                cart_size: cart.items.length(),
                is_cymbal_brand: is_cymbal_brand
            }
        };
    }

    resource function get .(@http:Header {name: "Cookie"} string cookieHeader)
                returns HomeResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getUserIdFromCookie(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        Product[] products = check getProducts();

        ProductLocalized[] productsLocalized = [];
        foreach Product product in products {
            Money converedMoney = check convertCurrency(product.price_usd, userCurrency);
            productsLocalized.push(toProductLocalized(product, renderMoney(converedMoney)));
        }

        return <HomeResponse>{
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                products: productsLocalized,
                ad: check chooseAd([])
            }
        };
    }

    resource function get product/[string id](@http:Header {name: "Cookie"} string cookieHeader)
                returns ProductResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getUserIdFromCookie(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        Product product = check getProduct(id);
        Money converedMoney = check convertCurrency(product.price_usd, userCurrency);
        ProductLocalized productLocal = toProductLocalized(product, renderMoney(converedMoney));
        Product[] recommendations = check getRecommendations(userId, [id]);

        return <ProductResponse>{
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                product: productLocal,
                recommendations: recommendations,
                ad: check chooseAd(product.categories)
            }
        };
    }

    resource function post setCurrency() returns json {
        return {};
    }

    resource function get logout() returns json {
        return {};
    }

    resource function get cart(@http:Header {name: "Cookie"} string cookieHeader)
                returns CartResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getUserIdFromCookie(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        Cart cart = check getCart(userId);
        Product[] recommandations = check getRecommendations(userId, self.getProductIdFromCart(cart));
        Money shippingCost = check getShippingQuote(cart.items, userCurrency);
        Money totalPrice = {
            currency_code: userCurrency,
            nanos: 0,
            units: 0
        };
        CartItemView[] cartItems = [];
        foreach CartItem item in cart.items {
            Product product = check getProduct(item.product_id);

            Money converedPrice = check convertCurrency(product.price_usd, userCurrency);

            Money price = multiplySlow(converedPrice, item.quantity);
            string renderedPrice = renderMoney(price);
            cartItems.push({
                product,
                price: renderedPrice,
                quantity: item.quantity
            });
            totalPrice = sum(totalPrice, price);
        }
        totalPrice = sum(totalPrice, shippingCost);
        int year = time:utcToCivil(time:utcNow()).year;
        int[] years = [year, year + 1, year + 2, year + 3, year + 4];

        return <CartResponse>{
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                recommendations: recommandations,
                shipping_cost: renderMoney(shippingCost),
                total_cost: renderMoney(totalPrice),
                items: cartItems,
                expiration_years: years
            }
        };
    }

    function getProductIdFromCart(Cart cart) returns string[] {
        return from CartItem item in cart.items
            select item.product_id;
    }

    resource function post cart(@http:Payload AddToCartRequest req, @http:Header {name: "Cookie"} string cookieHeader)
                returns http:Ok|http:Unauthorized|http:BadRequest|error {
        http:Cookie|http:Unauthorized cookie = getUserIdFromCookie(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        Product|error product = getProduct(req.productId);
        if product is error {
            http:BadRequest resp = {
                body: "invalid request" + product.message()
            };
            return resp;
        }

        check insertCart(userId, req.productId, req.quantity);

        http:Ok resp = {
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: "item added the cart"
        };
        return resp;
    }

    resource function post cart/empty(@http:Header {name: "Cookie"} string cookieHeader)
                returns http:Ok|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getUserIdFromCookie(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        check emptyCart(userId);
        http:Ok resp = {
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: "cart emptied"
        };
        return resp;
    }

    resource function post cart/checkout(@http:Payload CheckoutRequest req, @http:Header {name: "Cookie"} string cookieHeader)
                returns CheckoutResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getUserIdFromCookie(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;

        OrderResult orderResult = check checkoutCart({
            email: req.email,
            address: {
                city: req.city,
                country: req.country,
                state: req.state,
                street_address: req.street_address,
                zip_code: req.zip_code
            },
            user_id: userId,
            user_currency: userCurrency,
            credit_card: {
                credit_card_cvv: req.credit_card_cvv,
                credit_card_expiration_month: req.credit_card_expiration_month,
                credit_card_expiration_year: req.credit_card_expiration_year,
                credit_card_number: req.credit_card_number
            }
        });

        Product[] recommendations = check getRecommendations(userId, []);
        Money totalCost = orderResult.shipping_cost;
        foreach OrderItem item in orderResult.items {
            Money multiplyRes = multiplySlow(item.cost, item.item.quantity);
            totalCost = sum(totalCost, multiplyRes);
        }

        return <CheckoutResponse>{
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                'order: orderResult,
                total_paid: renderMoney(totalCost),
                recommendations: recommendations
            }
        };
    }
}
