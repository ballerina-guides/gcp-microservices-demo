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
import ballerina/log;

configurable string datastore = "";
configurable string redisHost = "";
configurable string redisPassword = "";

# Stores the product items added to the cart and retrieves them.
@display {
    label: "Cart",
    id: "cart"
}
@grpc:Descriptor {value: DEMO_DESC}
service "CartService" on new grpc:Listener(9092) {
    private final DataStore store;

    function init() returns error? {
        if datastore == "redis" {
            log:printInfo("Redis datastore is selected");
            self.store = check new RedisStore();
        } else {
            log:printInfo("In memory datastore used as redis config is not given");
            self.store = new InMemoryStore();
        }
    }

    # Adds an item to the cart
    #
    # + request - `AddItemRequest` containing the user id and the `CartItem`
    # + return - an `Empty` value or an error
    remote function AddItem(AddItemRequest request) returns Empty|error {
        lock {
            check self.store.add(request.user_id, request.item.product_id, request.item.quantity);
        }
        return {};
    }

    # Provides the cart with items.
    #
    # + request - `GetCartRequest` containing the user id
    # + return - `Cart` containing the items or an error
    remote function GetCart(GetCartRequest request) returns Cart|error {
        lock {
            Cart cart = check self.store.getCart(request.user_id);
            return cart.cloneReadOnly();
        }
    }

    # Clears the cart.
    #
    # + request - `EmptyCartRequest` containing the user id
    # + return - `Empty` value or an error
    remote function EmptyCart(EmptyCartRequest request) returns Empty|error {
        lock {
            check self.store.emptyCart(request.user_id);
        }
        return {};
    }
}

