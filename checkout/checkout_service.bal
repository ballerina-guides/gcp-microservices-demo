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
import ballerina/uuid;
import ballerina/log;
import ballerina/observe;
import ballerinax/jaeger as _;
import wso2/gcp.'client.stub as stub;

const string LOCALHOST = "localhost";

configurable string cartHost = LOCALHOST;
configurable string catalogHost = LOCALHOST;
configurable string currencyHost = LOCALHOST;
configurable string shippingHost = LOCALHOST;
configurable string paymentHost = LOCALHOST;
configurable string emailHost = LOCALHOST;

configurable decimal cartTimeout = 3;
configurable decimal catalogTimeout = 3;
configurable decimal currencyTimeout = 3;
configurable decimal shippingTimeout = 3;
configurable decimal paymentTimeout = 3;
configurable decimal emailTimeout = 3;

# The service retrieves the user cart, prepares the order, and orchestrates the payment, shipping, and email notification.
@display {
    label: "Checkout",
    id: "checkout"
}
@grpc:Descriptor {value: stub:DEMO_DESC}
service "CheckoutService" on new grpc:Listener(9094) {
    @display {
        label: "Cart",
        id: "cart"
    }
    private final stub:CartServiceClient cartClient;

    @display {
        label: "Catalog",
        id: "catalog"
    }
    private final stub:ProductCatalogServiceClient catalogClient;

    @display {
        label: "Currency",
        id: "currency"
    }
    private final stub:CurrencyServiceClient currencyClient;

    @display {
        label: "Shipping",
        id: "shipping"
    }
    private final stub:ShippingServiceClient shippingClient;
    @display {
        label: "Payment",
        id: "payment"
    }
    private final stub:PaymentServiceClient paymentClient;

    @display {
        label: "Email",
        id: "email"
    }
    private final stub:EmailServiceClient emailClient;

    function init() returns error? {
        self.cartClient = check new (string `http://${cartHost}:9092`, timeout = cartTimeout);
        self.catalogClient = check new (string `http://${catalogHost}:9091`, timeout = catalogTimeout);
        self.currencyClient = check new (string `http://${currencyHost}:9093`, timeout = currencyTimeout);
        self.shippingClient = check new (string `http://${shippingHost}:9095`, timeout = shippingTimeout);
        self.paymentClient = check new (string `http://${paymentHost}:9096`, timeout = paymentTimeout);
        self.emailClient = check new (string `http://${emailHost}:9097`, timeout = emailTimeout);
    }

    # Places the order and process payment, shipping and email notification.
    #
    # + request - `PlaceOrderRequest` containing user details
    # + return - returns `PlaceOrderResponse` containing order details
    remote function PlaceOrder(stub:PlaceOrderRequest request) returns stub:PlaceOrderResponse|grpc:Error|error {
        int rootParentSpanId = observe:startRootSpan("PlaceOrderSpan");
        int childSpanId = check observe:startSpan("PlaceOrderFromClientSpan", parentSpanId = rootParentSpanId);

        string orderId = uuid:createType1AsString();
        stub:CartItem[] userCartItems = check self.getUserCartItems(request.user_id, request.user_currency);
        stub:OrderItem[] orderItems = check self.prepOrderItems(userCartItems, request.user_currency);
        stub:Money shippingPrice = check self.convertCurrency(check self.quoteShipping(request.address, userCartItems),
            request.user_currency);

        stub:Money totalCost = {
            currency_code: request.user_currency,
            units: 0,
            nanos: 0
        };
        totalCost = sum(totalCost, shippingPrice);
        foreach stub:OrderItem item in orderItems {
            stub:Money itemCost = multiplySlow(item.cost, item.item.quantity);
            totalCost = sum(totalCost, itemCost);
        }

        string transactionId = check self.chargeCard(totalCost, request.credit_card);
        log:printInfo(string `payment went through ${transactionId}`);
        string shippingTrackingId = check self.shipOrder(request.address, userCartItems);
        check self.emptyUserCart(request.user_id);

        stub:OrderResult 'order = {
            order_id: orderId,
            shipping_tracking_id: shippingTrackingId,
            shipping_cost: shippingPrice,
            shipping_address: request.address,
            items: orderItems
        };

        stub:Empty|grpc:Error result = self.sendConfirmationMail(request.email, 'order);
        if result is grpc:Error {
            log:printWarn(string `failed to send order confirmation to ${request.email}`, 'error = result);
        } else {
            log:printInfo(string `order confirmation email sent to ${request.email}`);
        }

        check observe:finishSpan(childSpanId);
        check observe:finishSpan(rootParentSpanId);

        return {'order};
    }

    function getUserCartItems(string userId, string userCurrency) returns stub:CartItem[]|grpc:Error {
        stub:GetCartRequest getCartRequest = {user_id: userId};
        stub:Cart|grpc:Error cartResponse = self.cartClient->GetCart(getCartRequest);
        if cartResponse is grpc:Error {
            log:printError("failed to call getCart of cart service", 'error = cartResponse);
            return cartResponse;
        }
        return cartResponse.items;
    }

    function prepOrderItems(stub:CartItem[] cartItems, string userCurrency) returns stub:OrderItem[]|grpc:Error {
        stub:OrderItem[] orderItems = [];
        foreach stub:CartItem item in cartItems {
            stub:GetProductRequest productRequest = {id: item.product_id};
            stub:Product|grpc:Error productResponse = self.catalogClient->GetProduct(productRequest);
            if productResponse is grpc:Error {
                log:printError("failed to call getProduct from catalog service", 'error = productResponse);
                return error grpc:InternalError(
                                    string `failed to get product ${item.product_id}`, productResponse);
            }

            stub:CurrencyConversionRequest conversionRequest = {
                'from: productResponse.price_usd,
                to_code: userCurrency
            };

            stub:Money|grpc:Error conversionResponse = self.currencyClient->Convert(conversionRequest);
            if conversionResponse is grpc:Error {
                log:printError("failed to call convert from currency service", 'error = conversionResponse);
                return error grpc:InternalError(string `failed to convert price of ${item.product_id} to
                    ${userCurrency}`, conversionResponse);
            }
            orderItems.push({
                item,
                cost: conversionResponse
            });
        }
        return orderItems;
    }

    function quoteShipping(stub:Address address, stub:CartItem[] items) returns stub:Money|grpc:InternalError {
        stub:GetQuoteRequest quoteRequest = {
            address,
            items
        };
        stub:GetQuoteResponse|grpc:Error getQuoteResponse = self.shippingClient->GetQuote(quoteRequest);
        if getQuoteResponse is grpc:Error {
            log:printError("failed to call getQuote from shipping service", 'error = getQuoteResponse);
            return error grpc:InternalError(
                string `failed to get shipping quote: ${getQuoteResponse.message()}`, getQuoteResponse);
        }
        return getQuoteResponse.cost_usd;
    }

    function convertCurrency(stub:Money usd, string userCurrency) returns stub:Money|grpc:InternalError {
        stub:CurrencyConversionRequest conversionRequest = {
            'from: usd,
            to_code: userCurrency
        };
        stub:Money|grpc:Error convertionResponse = self.currencyClient->Convert(conversionRequest);
        if convertionResponse is grpc:Error {
            log:printError("failed to call convert from currency service", 'error = convertionResponse);
            return error grpc:InternalError(
                string `failed to convert currency: ${convertionResponse.message()}`, convertionResponse);
        }
        return convertionResponse;
    }

    function chargeCard(stub:Money total, stub:CreditCardInfo card) returns string|grpc:InternalError {
        stub:ChargeRequest chargeRequest = {
            amount: total,
            credit_card: card
        };
        stub:ChargeResponse|grpc:Error chargeResponse = self.paymentClient->Charge(chargeRequest);
        if chargeResponse is grpc:Error {
            log:printError("failed to call charge from payment service", 'error = chargeResponse);
            return error grpc:InternalError(
                string `could not charge the card: ${chargeResponse.message()}`, chargeResponse);
        }
        return chargeResponse.transaction_id;
    }

    function shipOrder(stub:Address address, stub:CartItem[] items) returns string|grpc:UnavailableError {
        stub:ShipOrderRequest orderRequest = {};
        stub:ShipOrderResponse|grpc:Error shipOrderResponse = self.shippingClient->ShipOrder(orderRequest);
        if shipOrderResponse is grpc:Error {
            log:printError("failed to call shipOrder from shipping service", 'error = shipOrderResponse);
            return error grpc:UnavailableError(
                string `shipment failed: ${shipOrderResponse.message()}`, shipOrderResponse);
        }
        return shipOrderResponse.tracking_id;
    }

    function emptyUserCart(string userId) returns grpc:InternalError? {
        stub:EmptyCartRequest request = {
            user_id: userId
        };
        stub:Empty|grpc:Error emptyCart = self.cartClient->EmptyCart(request);
        if emptyCart is grpc:Error {
            log:printError("failed to call emptyCart from cart service", 'error = emptyCart);
            return error grpc:InternalError(
                string `failed to empty user cart during checkout: ${emptyCart.message()}`, emptyCart);
        }
    }

    function sendConfirmationMail(string email, stub:OrderResult orderResult) returns stub:Empty|grpc:Error {
        return self.emailClient->SendOrderConfirmation({
            email,
            'order: orderResult
        });
    }
}
