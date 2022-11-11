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
const string SESSION_ID_KEY = "sessionId";
const string USER_CURRENCY = "USD";
const ENABLE_SINGLE_SHARED_SESSION = "ENABLE_SINGLE_SHARED_SESSION";
final boolean is_cymbal_brand = os:getEnv("CYMBAL_BRANDING") == "true";

service class AuthInterceptor {
    *http:RequestInterceptor;
    resource function 'default [string... path](http:RequestContext ctx, http:Request request) returns http:NextService|error? {
        http:Cookie[] usernameCookie = request.getCookies().filter(cookie => cookie.name == SESSION_ID_COOKIE);
        string sessionId;
        if usernameCookie.length() == 0 {
            if os:getEnv(ENABLE_SINGLE_SHARED_SESSION) == "true" {
                // Hard coded user id, shared across sessions
                sessionId = "12345678-1234-1234-1234-123456789123";
            } else {
                sessionId = uuid:createType1AsString();
            }
            http:Cookie cookie = new (SESSION_ID_COOKIE, sessionId, path = "/");
            request.addCookies([cookie]);
        } else {
            sessionId = usernameCookie[0].value;
        }
        ctx.set(SESSION_ID_KEY, sessionId);
        return ctx.next();
    }
}

# This service serves the data required by the UI by communicating with internal gRCP services
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

    # Description
    #
    # + cookieHeader - Parameter Description
    # + return - Return Value Description
    resource function get metadata(@http:Header {name: "Cookie"} string cookieHeader)
                returns MetadataResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }

        string[] supportedCurrencies = check getSupportedCurrencies();
        Cart cart = check getCart(cookie.value);
        MetadataResponse metadataResponse = {
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                user_currency: USER_CURRENCY, //Todo to cookies
                currencies: supportedCurrencies,
                cart_size: cart.items.length(),
                is_cymbal_brand: is_cymbal_brand
            }
        };
        return metadataResponse;
    }

    # Description
    #
    # + cookieHeader - Parameter Description
    # + return - Return Value Description
    resource function get .(@http:Header {name: "Cookie"} string cookieHeader)
                returns HomeResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        Product[] products = check getProducts();

        ProductLocalized[] productsLocalized = [];
        foreach Product product in products {
            Money converedMoney = check convertCurrency(product.price_usd, USER_CURRENCY);
            productsLocalized.push(toProductLocalized(product, renderMoney(converedMoney)));
        }

        HomeResponse homeResponse = {
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                products: productsLocalized,
                ad: check chooseAd()
            }
        };
        return homeResponse;
    }

    # Description
    #
    # + id - Parameter Description  
    # + cookieHeader - Parameter Description
    # + return - Return Value Description
    resource function get product/[string id](@http:Header {name: "Cookie"} string cookieHeader)
                returns ProductResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        Product product = check getProduct(id);
        Money convertedMoney = check convertCurrency(product.price_usd, USER_CURRENCY);
        ProductLocalized productLocal = toProductLocalized(product, renderMoney(convertedMoney));
        Product[] recommendations = check getRecommendations(userId, [id]);

        ProductResponse productResponse = {
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                product: productLocal,
                recommendations: recommendations,
                ad: check chooseAd(product.categories)
            }
        };
        return productResponse;
    }

    # Description
    # + return - Return Value Description
    resource function post setCurrency() returns json {
        return {};
    }

    # Description
    #
    # + cookieHeader - Parameter Description
    # + return - Return Value Description
    resource function get cart(@http:Header {name: "Cookie"} string cookieHeader)
                returns CartResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        Cart cart = check getCart(userId);
        Product[] recommandations = check getRecommendations(userId, self.getProductIdFromCart(cart));
        Money shippingCost = check getShippingQuote(cart.items, USER_CURRENCY);
        Money totalPrice = {
            currency_code: USER_CURRENCY,
            nanos: 0,
            units: 0
        };
        CartItemView[] cartItems = [];
        foreach CartItem item in cart.items {
            Product product = check getProduct(item.product_id);

            Money converedPrice = check convertCurrency(product.price_usd, USER_CURRENCY);

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

        CartResponse cartResponse = {
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
        return cartResponse;
    }

    # Description
    #
    # + request - Parameter Description  
    # + cookieHeader - Parameter Description
    # + return - Return Value Description
    resource function post cart(@http:Payload AddToCartRequest request, @http:Header {name: "Cookie"} string cookieHeader)
                returns http:Created|http:Unauthorized|http:BadRequest|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        Product|error product = getProduct(request.productId);
        if product is error {
            http:BadRequest badRequest = {
                body: string `invalid request ${product.message()}`
            };
            return badRequest;
        }

        check insertCart(userId, request.productId, request.quantity);

        http:Created response = {
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: "item added the cart"
        };
        return response;
    }

    # Description
    #
    # + cookieHeader - Parameter Description
    # + return - Return Value Description
    resource function post cart/empty(@http:Header {name: "Cookie"} string cookieHeader)
                returns http:Created|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
        }
        string userId = cookie.value;
        check emptyCart(userId);
        http:Created response = {
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: "cart emptied"
        };
        return response;
    }

    # Description
    #
    # + request - Parameter Description  
    # + cookieHeader - Parameter Description
    # + return - Return Value Description
    resource function post cart/checkout(@http:Payload CheckoutRequest request, @http:Header {name: "Cookie"} string cookieHeader)
                returns CheckoutResponse|http:Unauthorized|error {
        http:Cookie|http:Unauthorized cookie = getSessionIdFromCookieHeader(cookieHeader);
        if cookie is http:Unauthorized {
            return cookie;
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
            user_currency: USER_CURRENCY,
            credit_card: {
                credit_card_cvv: request.credit_card_cvv,
                credit_card_expiration_month: request.credit_card_expiration_month,
                credit_card_expiration_year: request.credit_card_expiration_year,
                credit_card_number: request.credit_card_number
            }
        });

        Product[] recommendations = check getRecommendations(userId);
        Money totalCost = orderResult.shipping_cost;
        foreach OrderItem item in orderResult.items {
            Money multiplyRes = multiplySlow(item.cost, item.item.quantity);
            totalCost = sum(totalCost, multiplyRes);
        }

        CheckoutResponse checkoutResponse = {
            headers: {
                "Set-Cookie": cookie.toStringValue()
            },
            body: {
                'order: orderResult,
                total_paid: renderMoney(totalCost),
                recommendations: recommendations
            }
        };

        return checkoutResponse;
    }

    function getProductIdFromCart(Cart cart) returns string[] {
        return from CartItem item in cart.items
            select item.product_id;
    }
}
