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
import wso2/client_stubs as stub;

const LOCALHOST = "localhost";

configurable decimal currencyTimeout = 3;
configurable decimal catalogTimeout = 3;
configurable decimal cartTimeout = 3;
configurable decimal shippingTimeout = 3;
configurable decimal recommendationTimeout = 3;
configurable decimal adTimeout = 3;
configurable decimal checkoutTimeout = 3;

configurable string currencyHost = LOCALHOST;
@display {
    label: "Currency",
    id: "currency"
}
final stub:CurrencyServiceClient currencyClient = check new (string `http://${currencyHost}:9093`,
                                                timeout = currencyTimeout);

configurable string catalogHost = LOCALHOST;
@display {
    label: "Catalog",
    id: "catalog"
}
final stub:ProductCatalogServiceClient catalogClient = check new (string `http://${catalogHost}:9091`,
                                                    timeout = catalogTimeout);

configurable string cartHost = LOCALHOST;
@display {
    label: "Cart",
    id: "cart"
}
final stub:CartServiceClient cartClient = check new (string `http://${cartHost}:9092`, timeout = cartTimeout);

configurable string shippingHost = LOCALHOST;
@display {
    label: "Shipping",
    id: "shipping"
}
final stub:ShippingServiceClient shippingClient = check new (string `http://${shippingHost}:9095`,
                                                timeout = shippingTimeout);

configurable string recommendHost = LOCALHOST;
@display {
    label: "Recommendation",
    id: "recommendation"
}
final stub:RecommendationServiceClient recommendClient = check new (string `http://${recommendHost}:9090`,
                                                        timeout = recommendationTimeout);

configurable string adHost = LOCALHOST;
@display {
    label: "Ads",
    id: "ads"
}
final stub:AdServiceClient adClient = check new (string `http://${adHost}:9099`, timeout = adTimeout);

configurable string checkoutHost = LOCALHOST;
@display {
    label: "Checkout",
    id: "checkout"
}
final stub:CheckoutServiceClient checkoutClient = check new (string `http://${checkoutHost}:9094`,
                                                timeout = checkoutTimeout);

isolated function getSupportedCurrencies() returns string[]|grpc:Error {
    stub:GetSupportedCurrenciesResponse|grpc:Error supportedCurrencies = currencyClient->GetSupportedCurrencies({});
    if supportedCurrencies is grpc:Error {
        log:printError("failed to get supported currencies from currency service", supportedCurrencies);
        return supportedCurrencies;
    }
    return supportedCurrencies.currency_codes;
}

isolated function getProducts() returns stub:Product[]|grpc:Error {
    stub:ListProductsResponse|grpc:Error productsResponse = catalogClient->ListProducts({});
    if productsResponse is grpc:Error {
        log:printError("failed to list products from catalog service", productsResponse);
        return productsResponse;
    }
    return productsResponse.products;
}

isolated function getProduct(string id) returns stub:Product|grpc:Error {
    stub:Product|grpc:Error product = catalogClient->GetProduct({id});
    if product is grpc:Error {
        log:printError("failed to get product from catalog service", product);
    }
    return product;
}

isolated function getCart(string userId) returns stub:Cart|grpc:Error {
    stub:Cart|grpc:Error cart = cartClient->GetCart({
        user_id: userId
    });
    if cart is grpc:Error {
        log:printError("failed to get cart from cart service", cart);
    }
    return cart;
}

isolated function emptyCart(string userId) returns grpc:Error? {
    stub:Empty|grpc:Error cart = cartClient->EmptyCart({
        user_id: userId
    });
    if cart is grpc:Error {
        log:printError("failed to empty cart", cart);
        return cart;
    }
}

isolated function insertItemToCart(string userId, string productId, int quantity) returns grpc:Error? {
    stub:Empty|grpc:Error response = cartClient->AddItem({
        user_id: userId,
        item: {
            product_id: productId,
            quantity
        }
    });
    if response is grpc:Error {
        log:printError("failed to add item from cart service", response);
        return response;
    }
}

isolated function convertCurrency(stub:Money usd, string userCurrency) returns stub:Money|grpc:Error {
    stub:Money|grpc:Error convertedCurrency = currencyClient->Convert({
        'from: usd,
        to_code: userCurrency
    });
    if convertedCurrency is grpc:Error {
        log:printError("failed to convert currency", convertedCurrency);
    }
    return convertedCurrency;
}

isolated function getShippingQuote(stub:CartItem[] items, string currency) returns stub:Money|grpc:Error {
    stub:GetQuoteResponse|grpc:Error quote = shippingClient->GetQuote({
        items
    });
    if quote is grpc:Error {
        log:printError("failed to get quote from shipping service", quote);
        return quote;
    }
    return convertCurrency(quote.cost_usd, currency);
}

isolated function getRecommendations(string userId, string[] productIds = []) returns stub:Product[]|grpc:Error {
    stub:ListRecommendationsResponse|grpc:Error recommendations = recommendClient->ListRecommendations({
        user_id: userId,
        product_ids: ["2ZYFJ3GM2N", "LS4PSXUNUM"]
    });
    if recommendations is grpc:Error {
        log:printError("failed to list recommendations from recommendation service", recommendations);
        return recommendations;
    }

    return from string productId in recommendations.product_ids
        limit 4
        select check getProduct(productId);
}

isolated function getAds(string[] context_keys) returns stub:Ad[]|grpc:Error {
    stub:AdResponse|grpc:Error adResponse = adClient->GetAds({context_keys});
    if adResponse is grpc:Error {
        log:printError("failed to get ads from ads service", adResponse);
        return adResponse;
    }
    return adResponse.ads;
}

isolated function chooseAd(string[] ctxKeys = []) returns stub:Ad|error {
    stub:Ad[] ads = check getAds(ctxKeys);
    return ads[check random:createIntInRange(0, ads.length())];
}

isolated function checkoutCart(stub:PlaceOrderRequest request) returns stub:OrderResult|grpc:Error {
    stub:PlaceOrderResponse|grpc:Error placeOrderResponse = checkoutClient->PlaceOrder(request);
    if placeOrderResponse is grpc:Error {
        log:printError("failed to place order from checkout service", placeOrderResponse);
        return placeOrderResponse;
    }
    return placeOrderResponse.'order;
}
