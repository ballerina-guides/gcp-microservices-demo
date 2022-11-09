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

@display {
    label: "",
    id: "payment"
}
@grpc:Descriptor {value: DEMO_DESC}
service "PaymentService" on new grpc:Listener(9096) {

    isolated remote function Charge(ChargeRequest value) returns ChargeResponse|error {
        CreditCardInfo creditCard = value.credit_card;
        CardValidator cardValidator = new (creditCard.credit_card_number, creditCard.credit_card_expiration_year, creditCard.credit_card_expiration_month);
        CardCompany|error cardValid = cardValidator.isValid();
        if cardValid is error {
            log:printError("Credit card is not valid", 'error = cardValid);
            return cardValid;
        }
        log:printInfo(string `Transaction processed: the card ending ${creditCard.credit_card_number.substring(creditCard.credit_card_number.length() - 4)}, 
        Amount: ${value.amount.currency_code}${value.amount.units}.${value.amount.nanos}`);
        return {
            transaction_id: uuid:createType1AsString()
        };
    }
}

