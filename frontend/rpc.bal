// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

import ballerina/grpc;
import ballerina/log;
import ballerina/random;

const string LOCALHOST = "localhost";

configurable string currencyHost = LOCALHOST;
@display {
    label: "Currency",
    id: "currency"
}
final CurrencyServiceClient currencyClient = check new (string `http://${currencyHost}:9093`);

configurable string catalogHost = LOCALHOST;
@display {
    label: "Catalog",
    id: "catalog"
}
final ProductCatalogServiceClient catalogClient = check new (string `http://${catalogHost}:9091`);

configurable string cartHost = LOCALHOST;
@display {
    label: "Cart",
    id: "cart"
}
final CartServiceClient cartClient = check new (string `http://${cartHost}:9092`);

configurable string shippingHost = LOCALHOST;
@display {
    label: "Shipping",
    id: "shipping"
}
final ShippingServiceClient shippingClient = check new (string `http://${shippingHost}:9095`);

configurable string recommendHost = LOCALHOST;
@display {
    label: "Recommendation",
    id: "recommendation"
}
final RecommendationServiceClient recommendClient = check new (string `http://${recommendHost}:9090`);

configurable string adHost = LOCALHOST;
@display {
    label: "Ads",
    id: "ads"
}
final AdServiceClient adClient = check new (string `http://${adHost}:9099`);

configurable string checkoutHost = LOCALHOST;
@display {
    label: "Checkout",
    id: "checkout"
}
final CheckoutServiceClient checkoutClient = check new (string `http://${checkoutHost}:9094`);

isolated function getSupportedCurrencies() returns string[]|grpc:Error {
    GetSupportedCurrenciesResponse|grpc:Error supportedCurrencies = currencyClient->GetSupportedCurrencies({});
    if supportedCurrencies is grpc:Error {
        log:printError("failed to call getSupportedCurrencies from currency service", 'error = supportedCurrencies);
        return supportedCurrencies;
    }
    return supportedCurrencies.currency_codes;
}

isolated function getProducts() returns Product[]|grpc:Error {
    ListProductsResponse|grpc:Error productsResponse = catalogClient->ListProducts({});

    if productsResponse is grpc:Error {
        log:printError("failed to call listProducts from catalog service", 'error = productsResponse);
        return productsResponse;
    }
    return productsResponse.products;
}

isolated function getProduct(string prodId) returns Product|grpc:Error {
    GetProductRequest request = {
        id: prodId
    };
    Product|grpc:Error product = catalogClient->GetProduct(request);

    if product is grpc:Error {
        log:printError("failed to call getProduct from catalog service", 'error = product);
    }
    return product;
}

isolated function getCart(string userId) returns Cart|grpc:Error {
    GetCartRequest request = {
        user_id: userId
    };
    Cart|grpc:Error cart = cartClient->GetCart(request);

    if cart is grpc:Error {
        log:printError("failed to call getCart from cart service", 'error = cart);
    }
    return cart;
}

isolated function emptyCart(string userId) returns grpc:Error? {
    EmptyCartRequest request = {
        user_id: userId
    };
    Empty|grpc:Error cart = cartClient->EmptyCart(request);

    if cart is grpc:Error {
        log:printError("failed to call emptyCart from cart service", 'error = cart);
        return cart;
    }
}

isolated function insertCart(string userId, string productId, int quantity) returns grpc:Error? {
    AddItemRequest request = {
        user_id: userId,
        item: {
            product_id: productId,
            quantity
        }
    };
    Empty|grpc:Error response = cartClient->AddItem(request);

    if response is grpc:Error {
        log:printError("failed to call addItem from cart service", 'error = response);
        return response;
    }
}

isolated function convertCurrency(Money usd, string userCurrency) returns Money|grpc:Error {
    CurrencyConversionRequest request = {
        'from: usd,
        to_code: userCurrency
    };
    Money|grpc:Error convertedCurrency = currencyClient->Convert(request);
    if convertedCurrency is grpc:Error {
        log:printError("failed to call convert from currency service", 'error = convertedCurrency);
    }
    return convertedCurrency;
}

isolated function getShippingQuote(CartItem[] items, string currency) returns Money|grpc:Error {
    GetQuoteRequest request = {
        items
    };
    GetQuoteResponse|grpc:Error quote = shippingClient->GetQuote(request);
    if quote is grpc:Error {
        log:printError("failed to call getQuote from shipping service", 'error = quote);
        return quote;
    }
    return convertCurrency(quote.cost_usd, currency);
}

isolated function getRecommendations(string userId, string[] productIds = []) returns Product[]|grpc:Error {
    ListRecommendationsRequest request = {
        user_id: userId,
        product_ids: ["2ZYFJ3GM2N", "LS4PSXUNUM"]
    };
    ListRecommendationsResponse|grpc:Error recommendations = recommendClient->ListRecommendations(request);
    if recommendations is grpc:Error {
        log:printError("failed to call listRecommnadation from recommandation service", 'error = recommendations);
        return recommendations;
    }

    return from string productId in recommendations.product_ids
        limit 4
        select check getProduct(productId);
}

isolated function getAd(string[] ctxKeys) returns Ad[]|grpc:Error {
    AdRequest request = {
        context_keys: ctxKeys
    };
    AdResponse|grpc:Error adResponse = adClient->GetAds(request);
    if adResponse is grpc:Error {
        log:printError("failed to call getAds from ads service", 'error = adResponse);
        return adResponse;
    }
    return adResponse.ads;
}

isolated function chooseAd(string[] ctxKeys = []) returns Ad|error {
    Ad[] ads = check getAd(ctxKeys);
    return ads[check random:createIntInRange(0, ads.length())];
}

isolated function checkoutCart(PlaceOrderRequest request) returns OrderResult|grpc:Error {
    PlaceOrderResponse|grpc:Error placeOrderResponse = checkoutClient->PlaceOrder(request);
    if placeOrderResponse is grpc:Error {
        log:printError("failed to call placeOrder from checkout service", 'error = placeOrderResponse);
        return placeOrderResponse;
    }
    return placeOrderResponse.'order;
}
