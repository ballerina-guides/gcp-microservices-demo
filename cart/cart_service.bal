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

    remote function AddItem(AddItemRequest value) returns Empty|error {
        lock {
            check self.store.addItem(value.user_id, value.item.product_id, value.item.quantity);
        }
        return {};
    }

    remote function GetCart(GetCartRequest value) returns Cart|error {
        lock {
            Cart cart = check self.store.getCart(value.user_id);
            return cart.cloneReadOnly();
        }
    }

    remote function EmptyCart(EmptyCartRequest value) returns Empty|error {
        lock {
            check self.store.emptyCart(value.user_id);
        }
        return {};
    }
}

