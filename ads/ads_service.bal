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
    id: "ads"
}
@grpc:Descriptor {value: DEMO_DESC}
service "AdService" on new grpc:Listener(9099) {
    final AdStore store;

    function init() {
        self.store = new AdStore();
    }

    remote function GetAds(AdRequest request) returns AdResponse|error {
        Ad[] ads = [];
        foreach string category in request.context_keys {
            Ad[] availableAds = self.store.getAdsByCategory(category);
            ads.push(...availableAds);
        }

        if ads.length() == 0 {
            ads = check self.store.getRandomAds();
        }

        return {
            ads: ads
        };
    }
}
