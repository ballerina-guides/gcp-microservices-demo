// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/os;
import ballerina/time;
import ballerina/uuid;

const string SESSION_ID_COOKIE = "sessionIdCookie";
const string CURRENCY_COOKIE = "currencyCookie";
const string SESSION_ID = "sessionId";
const ENABLE_SINGLE_SHARED_SESSION = "ENABLE_SINGLE_SHARED_SESSION";
final boolean is_cymbal_brand = os:getEnv("CYMBAL_BRANDING") == "true";

service class AuthInterceptor {
    *http:RequestInterceptor;
    resource function 'default [string... path](http:RequestContext ctx, http:Request request)
        returns http:NextService|error? {
        http:Cookie[] usernameCookie = request.getCookies().filter(cookie => cookie.name == SESSION_ID_COOKIE);
        http:Cookie[] currencyCookie = request.getCookies().filter(cookie => cookie.name == CURRENCY_COOKIE);
        string sessionId;
        if usernameCookie.length() == 0 {
            if os:getEnv(ENABLE_SINGLE_SHARED_SESSION) == "true" {
                // Hard coded user id, shared across sessions
                sessionId = "12345678-1234-1234-1234-123456789123";
            } else {
                sessionId = uuid:createType1AsString();
            }
            http:Cookie sessionIdCookie = new (SESSION_ID_COOKIE, sessionId, path = "/");
            http:Cookie[] cookies = request.getCookies();
            cookies.push(sessionIdCookie);
            request.addCookies(cookies);
        } else {
            sessionId = usernameCookie[0].value;
        }
        if currencyCookie.length() == 0 {
            http:Cookie currency = new (CURRENCY_COOKIE, "USD", path = "/");
            http:Cookie[] cookies = request.getCookies();
            cookies.push(currency);
            request.addCookies(cookies);
        }
        ctx.set(SESSION_ID, sessionId);
        return ctx.next();
    }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true
    },
    interceptors: [new AuthInterceptor()]
}
@display {
    label: "Frontend",
    id: "frontend"
}
service / on new http:Listener(9098) {

    resource function get metadata(@http:Header {name: "Cookie"} string cookieHeader)
                returns MetadataResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }

        http:Cookie|http:Unauthorized currencyCookie = getCurrencyFromCookieHeader(cookieHeader);
        if currencyCookie is http:Unauthorized {
            return currencyCookie;
        }

        string[] supportedCurrencies = check getSupportedCurrencies();
        Cart cart = check getCart(cookie.value);
        return <MetadataResponse>{
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                user_currency: [currencyCookie.value, currencyLogo(currencyCookie.value)], //Todo to cookies
                currencies: supportedCurrencies,
                cart_size: cart.items.length(),
                is_cymbal_brand: is_cymbal_brand
            }
        };
    }

    resource function get .(@http:Header {name: "Cookie"} string cookieHeader)
                returns HomeResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        http:Cookie|http:Unauthorized currencyCookie = getCurrencyFromCookieHeader(cookieHeader);
        if currencyCookie is http:Unauthorized {
            return currencyCookie;
        }
        Product[] products = check getProducts();

        ProductLocalized[] productsLocalized = [];
        foreach Product product in products {
            Money converedMoney = check convertCurrency(product.price_usd, currencyCookie.value);
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
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        http:Cookie|http:Unauthorized currencycookie = getCurrencyFromCookieHeader(cookieHeader);
        if currencycookie is http:Unauthorized {
            return currencycookie;
        }
        string userId = cookie.value;
        Product product = check getProduct(id);
        Money convertedMoney = check convertCurrency(product.price_usd, currencycookie.value);
        ProductLocalized productLocal = toProductLocalized(product, renderMoney(convertedMoney));
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

    resource function post setCurrency(@http:Payload record {|string currency;|} request, @http:Header {name: "Cookie"} string cookieHeader)
                returns http:Response|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string[] supportedCurrencies = check getSupportedCurrencies();
        Cart cart = check getCart(cookie.value);
        http:Response response = new;
        http:Cookie currencyCookie = new (CURRENCY_COOKIE, request.currency, path = "/");
        response.addCookie(currencyCookie);
        response.setJsonPayload({
            user_currency: [request.currency, currencyLogo(request.currency)],
            currencies: supportedCurrencies,
            cart_size: cart.items.length(),
            is_cymbal_brand: is_cymbal_brand
        });
        return response;
    }

    resource function get cart(@http:Header {name: "Cookie"} string cookieHeader)
                returns CartResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        http:Cookie|http:Unauthorized currencyCookie = getCurrencyFromCookieHeader(cookieHeader);
        if currencyCookie is http:Unauthorized {
            return currencyCookie;
        }
        string userId = cookie.value;
        Cart cart = check getCart(userId);
        Product[] recommandations = check getRecommendations(userId, self.getProductIdFromCart(cart));
        Money shippingCost = check getShippingQuote(cart.items, currencyCookie.value);
        Money totalPrice = {
            currency_code: currencyCookie.value,
            nanos: 0,
            units: 0
        };
        CartItemView[] cartItems = [];
        foreach CartItem item in cart.items {
            Product product = check getProduct(item.product_id);

            Money converedPrice = check convertCurrency(product.price_usd, currencyCookie.value);

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

    resource function post cart(@http:Payload AddToCartRequest request, @http:Header {name: "Cookie"} string cookieHeader)
                returns http:Created|http:Unauthorized|http:BadRequest|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        Product|error product = getProduct(request.productId);
        if product is error {
            return <http:BadRequest>{
                body: "invalid request" + product.message()
            };
        }

        check insertCart(userId, request.productId, request.quantity);

        return <http:Created>{
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: "item added the cart"
        };
    }

    resource function post cart/empty(@http:Header {name: "Cookie"} string cookieHeader)
                returns http:Created|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        check emptyCart(userId);
        return <http:Created>{
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: "cart emptied"
        };
    }

    resource function post cart/checkout(@http:Payload CheckoutRequest request, @http:Header {name: "Cookie"} string cookieHeader)
                returns CheckoutResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        http:Cookie|http:Unauthorized currencyCookie = getCurrencyFromCookieHeader(cookieHeader);
        if currencyCookie is http:Unauthorized {
            return currencyCookie;
        }
        string userId = cookie.value;

        OrderResult orderResult = check checkoutCart({
            email: request.email,
            address: {
                city: request.city,
                country: request.country,
                state: request.state,
                street_address: request.street_address,
                zip_code: request.zip_code
            },
            user_id: userId,
            user_currency: currencyCookie.value,
            credit_card: {
                credit_card_cvv: request.credit_card_cvv,
                credit_card_expiration_month: request.credit_card_expiration_month,
                credit_card_expiration_year: request.credit_card_expiration_year,
                credit_card_number: request.credit_card_number
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
