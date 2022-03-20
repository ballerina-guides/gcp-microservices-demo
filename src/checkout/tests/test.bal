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

import ballerina/test;

@test:Config {}
function intAddTest() returns error? {
    CheckoutServiceClient ep = check new ("http://localhost:9094");
    //Populate cart first.
    CartServiceClient ep1 = check new ("http://localhost:9092");
    //Add Cart
    AddItemRequest item1 = {user_id: "3", item: {product_id: "OLJCESPC7Z", quantity: 1}};
    _ = check ep1->AddItem(item1);

    PlaceOrderRequest req = {
        user_id: "3",
        address: {
            country: "Sri lanka",
            city: "Colombo",
            state: "Western",
            street_address: "56,Palm Grove",
            zip_code: 10300
        },
        credit_card: {
            credit_card_number: "4444444444444448",
            credit_card_cvv: 123,
            credit_card_expiration_year: 2023,
            credit_card_expiration_month: 10

        },
        email: "anjanasupun05@gmail.com",
        user_currency: "USD"
    };
    PlaceOrderResponse placeOrderResponse = check ep->PlaceOrder(req);
    test:assertTrue(placeOrderResponse.'order.length() > 1);
}
