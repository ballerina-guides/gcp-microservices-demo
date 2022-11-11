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

# Gives the shipping cost estimates based on the shopping cart.
@display {
    label: "Shipping",
    id: "shipping"
}
@grpc:Descriptor {value: DEMO_DESC}
service "ShippingService" on new grpc:Listener(9095) {

    # Provides a quote with shipping cost.
    #
    # + request - `GetQuoteRequest` contaning the user's selected items
    # + return - `GetQuoteResponse` containing the shipping cost 
    remote function GetQuote(GetQuoteRequest request) returns GetQuoteResponse|error {
        CartItem[] items = request.items;
        int count = 0;
        float cost = 0.0;
        foreach CartItem item in items {
            count += item.quantity;
        }

        if count != 0 {
            cost = 8.99;
        }
        float cents = cost % 1;
        int dollars = <int>(cost - cents);

        Money usdCost = {currency_code: "USD", nanos: <int>cents * 10000000, units: dollars};

        return {
            cost_usd: usdCost
        };
    }

    # Ships the order and provide a tracking id.
    #
    # + request - `ShipOrderRequest` containing the address and the user's order items
    # + return - `ShipOrderResponse` containing the tracking id or an error
    remote function ShipOrder(ShipOrderRequest request) returns ShipOrderResponse|error {
        Address address = request.address;
        return {
            tracking_id: generateTrackingId(string `${address.street_address}, ${address.city}, ${address.state}`)
        };
    }
}

