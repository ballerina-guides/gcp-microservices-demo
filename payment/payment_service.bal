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
import ballerina/uuid;
import ballerina/observe;
import ballerinax/jaeger as _;
import wso2/gcp.'client.stub as stub;

# This service validates the card details (using the Luhn algorithm) against the supported card providers and charges the card.
@display {
    label: "Payment",
    id: "payment"
}
@grpc:Descriptor {value: stub:DEMO_DESC}
service "PaymentService" on new grpc:Listener(9096) {

    function init() {
        log:printInfo(string `Payment service gRPC server started.`);
    }

    # Validate and charge the amount from the card.
    #
    # + request - `ChargeRequest` containing the card details and the amount to charge
    # + return - `ChargeResponse` with the transaction id or an error
    remote function Charge(stub:ChargeRequest request) returns stub:ChargeResponse|error {
        log:printInfo(string `PaymentService#Charge invoked with request ${request.toString()}`);
        int rootParentSpanId = observe:startRootSpan("PaymentSpan");
        int childSpanId = check observe:startSpan("PaymentFromClientSpan", parentSpanId = rootParentSpanId);

        var {credit_card_number: cardNumber, credit_card_expiration_year: expirationYear,
                credit_card_expiration_month: expirationMonth} = request.credit_card;
        CardType|error cardType = getCardDetails(cardNumber, expirationYear, expirationMonth);
        if cardType is CardValidationError {
            log:printError("Credit card is not valid", 'error = cardType);
            return cardType;
        } else if cardType is error {
            log:printError("Error occured while validating the credit card", 'error = cardType);
            return cardType;
        } else {
            string lastFourDigits = cardNumber.substring(cardNumber.length() - 4);
            string amount = let var {currency_code, units, nanos} = request.amount in
                    string `${currency_code}${units}.${nanos}`;
            log:printInfo(string `Transaction processed: ${cardType} ending ${lastFourDigits}, Amount: ${amount}`);
        }

        check observe:finishSpan(childSpanId);
        check observe:finishSpan(rootParentSpanId);
        return {
            transaction_id: uuid:createType1AsString()
        };
    }
}

