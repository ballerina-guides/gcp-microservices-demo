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
import ballerinax/jaeger as _;
import wso2/client_stubs as stub;

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

        stub:CreditCardInfo creditCard = request.credit_card;
        CardCompany|error cardCompany = getCardCompany(creditCard.credit_card_number, creditCard.credit_card_expiration_year,
            creditCard.credit_card_expiration_month);
        if cardCompany is CardValidationError {
            log:printError("Credit card is not valid", 'error = cardCompany);
            return cardCompany;
        } else if cardCompany is error {
            log:printError("Error occured while validating the credit card", 'error = cardCompany);
            return cardCompany;
        }
        log:printInfo(string `Transaction processed: the card ending
            ${creditCard.credit_card_number.substring(creditCard.credit_card_number.length() - 4)},
                Amount: ${request.amount.currency_code}${request.amount.units}.${request.amount.nanos}`);

        return {
            transaction_id: uuid:createType1AsString()
        };
    }
}

