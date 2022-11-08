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

@display {
    label: "",
    id: "shipping"
}
@grpc:Descriptor {value: DEMO_DESC}
service "ShippingService" on new grpc:Listener(9095) {
    final float SHIPPING_COST = 8.99;

    isolated remote function GetQuote(GetQuoteRequest value) returns GetQuoteResponse|error {
        CartItem[] items = value.items;
        int count = 0;
        float cost = 0.0;
        foreach CartItem item in items {
            count += item.quantity;
        }

        if count != 0 {
            cost = self.SHIPPING_COST;
        }
        float cents = cost % 1;
        int dollars = <int>(cost - cents);

        Money money = {currency_code: "USD", nanos: <int>cents * 10000000, units: dollars};

        return {
            cost_usd: money
        };
    }

    isolated remote function ShipOrder(ShipOrderRequest value) returns ShipOrderResponse|error {
        Address address = value.address;
        string trackingId = generateTrackingId(string`${address.street_address}, ${address.city}, ${address.state}`);
        return {tracking_id: trackingId};
    }
}

