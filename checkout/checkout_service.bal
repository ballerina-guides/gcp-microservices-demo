// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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
import ballerina/uuid;
import ballerina/log;

configurable string cartHost = "localhost";
configurable string catalogHost = "localhost";
configurable string currencyHost = "localhost";
configurable string shippingHost = "localhost";
configurable string paymentHost = "localhost";
configurable string emailHost = "localhost";

@display {
    label: "",
    id: "checkout"
}
@grpc:Descriptor {value: DEMO_DESC}
service "CheckoutService" on new grpc:Listener(9094) {
    @display {
        label: "",
        id: "cart"
    }
    final CartServiceClient cartClient;

    @display {
        label: "",
        id: "catalog"
    }
    final ProductCatalogServiceClient catalogClient;

    @display {
        label: "",
        id: "currency"
    }
    final CurrencyServiceClient currencyClient;

    @display {
        label: "",
        id: "shipping"
    }
    final ShippingServiceClient shippingClient;
    @display {
        label: "",
        id: "payment"
    }
    final PaymentServiceClient paymentClient;

    @display {
        label: "",
        id: "email"
    }
    final EmailServiceClient emailClient;

    function init() returns error? {
        self.cartClient = check new (string `http://${cartHost}:9092`, timeout = 3);
        self.catalogClient = check new (string `http://${catalogHost}:9091`, timeout = 3);
        self.currencyClient = check new (string `http://${currencyHost}:9093`, timeout = 3);
        self.shippingClient = check new (string `http://${shippingHost}:9095`, timeout = 3);
        self.paymentClient = check new (string `http://${paymentHost}:9096`, timeout = 3);
        self.emailClient = check new (string `http://${emailHost}:9097`, timeout = 3);
    }

    remote function PlaceOrder(PlaceOrderRequest request) returns PlaceOrderResponse|error {
        string orderId = uuid:createType1AsString();
        CartItem[] userCartItems = check self.getUserCart(request.user_id, request.user_currency);
        OrderItem[] orderItems = check self.prepOrderItems(userCartItems, request.user_currency);
        Money shippingPrice = check self.convertCurrency(check self.quoteShipping(request.address, userCartItems), request.user_currency);

        Money totalCost = {
            currency_code: request.user_currency,
            units: 0,
            nanos: 0
        };
        totalCost = sum(totalCost, shippingPrice);
        foreach OrderItem item in orderItems {
            Money multPrice = multiplySlow(item.cost, item.item.quantity);
            totalCost = sum(totalCost, multPrice);
        }

        string transactionId = check self.chargeCard(totalCost, request.credit_card);
        log:printInfo("payment went through " + transactionId);
        string shippingTrackingId = check self.shipOrder(request.address, userCartItems);
        check self.emptyUserCart(request.user_id);

        OrderResult 'order = {
            order_id: orderId,
            shipping_tracking_id: shippingTrackingId,
            shipping_cost: shippingPrice,
            shipping_address: request.address,
            items: orderItems
        };

        check self.sendConfirmationMail(request.email, 'order);

        return {'order};
    }

    function getUserCart(string userId, string userCurrency) returns CartItem[]|error {
        GetCartRequest req = {user_id: userId};
        Cart|grpc:Error cart = self.cartClient->GetCart(req);
        if cart is grpc:Error {
            log:printError("failed to call getCart of cart service", 'error = cart);
            return cart;
        }
        return cart.items;
    }

    function prepOrderItems(CartItem[] items, string userCurrency) returns OrderItem[]|error {
        OrderItem[] orderItems = [];
        foreach CartItem item in items {
            GetProductRequest req = {id: item.product_id};
            Product|grpc:Error product = self.catalogClient->GetProduct(req);
            if product is grpc:Error {
                log:printError("failed to call getProduct from catalog service", 'error = product);
                return product;
            }

            CurrencyConversionRequest conversionRequest = {
                'from: product.price_usd,
                to_code: userCurrency
            };

            Money|grpc:Error money = self.currencyClient->Convert(conversionRequest);
            if money is grpc:Error {
                log:printError("failed to call convert from currency service", 'error = money);
                return money;
            }
            orderItems.push({
                item,
                cost: money
            });
        }
        return orderItems;
    }

    function quoteShipping(Address address, CartItem[] items) returns Money|error {
        GetQuoteRequest req = {
            address: address,
            items
        };
        GetQuoteResponse|grpc:Error getQuoteResponse = self.shippingClient->GetQuote(req);
        if getQuoteResponse is grpc:Error {
            log:printError("failed to call getQuote from shipping service", 'error = getQuoteResponse);
            return getQuoteResponse;
        }
        return getQuoteResponse.cost_usd;
    }

    function convertCurrency(Money usd, string userCurrency) returns Money|error {
        CurrencyConversionRequest conversionRequest = {
            'from: usd,
            to_code: userCurrency
        };
        Money|grpc:Error convert = self.currencyClient->Convert(conversionRequest);
        if convert is grpc:Error {
            log:printError("failed to call convert from currency service", 'error = convert);
            return convert;
        }
        return self.currencyClient->Convert(conversionRequest);
    }

    function chargeCard(Money total, CreditCardInfo card) returns string|error {
        ChargeRequest chargeRequest = {
            amount: total,
            credit_card: card
        };
        ChargeResponse|grpc:Error chargeResponse = self.paymentClient->Charge(chargeRequest);
        if chargeResponse is grpc:Error {
            log:printError("failed to call charge from payment service", 'error = chargeResponse);
            return chargeResponse;
        }
        return chargeResponse.transaction_id;
    }

    function shipOrder(Address address, CartItem[] items) returns string|error {
        ShipOrderRequest orderRequest = {};
        ShipOrderResponse|grpc:Error getSupportedCurrenciesResponse = self.shippingClient->ShipOrder(orderRequest);
        if getSupportedCurrenciesResponse is grpc:Error {
            log:printError("failed to call shipOrder from shipping service", 'error = getSupportedCurrenciesResponse);
            return getSupportedCurrenciesResponse;
        }
        return getSupportedCurrenciesResponse.tracking_id;
    }

    function emptyUserCart(string userId) returns error? {
        EmptyCartRequest request = {
            user_id: userId
        };
        Empty|grpc:Error emptyCart = self.cartClient->EmptyCart(request);
        if emptyCart is grpc:Error {
            log:printError("failed to call emptyCart from cart service", 'error = emptyCart);
            return emptyCart;
        }
    }

    function sendConfirmationMail(string email, OrderResult orderRes) returns error? {
        SendOrderConfirmationRequest orderConfirmRequest = {
            email,
            'order: orderRes
        };
        Empty|grpc:Error sendOrderConfirmation = self.emailClient->SendOrderConfirmation(orderConfirmRequest);
        if sendOrderConfirmation is grpc:Error {
            log:printError("failed to call sendOrderConfirmation from email service", 'error = sendOrderConfirmation);
            return sendOrderConfirmation;
        }
    }
}
