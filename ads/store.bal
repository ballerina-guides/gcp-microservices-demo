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

import ballerina/random;
import wso2/gcp.'client.stub as stub;

# Class used to provide ads by category or by random.
readonly class AdStore {

    private final map<stub:Ad[]> & readonly ads;
    private final int MAX_ADS_TO_SERVE = 2;

    isolated function init() {
        self.ads = getAds().cloneReadOnly();
    }

    # Returns a set of random ads
    # + return - an `Ad[]` or an error
    public isolated function getRandomAds() returns stub:Ad[]|error {
       stub:Ad[] allAds = [];
        foreach stub:Ad[] ads in self.ads {
            allAds.push(...ads);
        }
        stub:Ad[] randomAds = [];
        foreach int i in 0 ..< self.MAX_ADS_TO_SERVE {
            randomAds.push(allAds[check random:createIntInRange(0, allAds.length())]);
        }
        return randomAds;
    }

    # Returns a set of ads related to a category
    #
    # + category - related ad category
    # + return - returns an `Ad[]`
    public isolated function getAdsByCategory(string category) returns stub:Ad[] {
        if !self.ads.hasKey(category) {
            return [];
        }
        return self.ads.get(category);
    }
}

isolated function getAds() returns map<stub:Ad[]> {
    stub:Ad hairdryer = {
        redirect_url: "/product/2ZYFJ3GM2N",
        text: "Hairdryer for sale. 50% off."
    };
    stub:Ad tankTop = {
        redirect_url: "/product/66VCHSJNUP",
        text: "Tank top for sale. 20% off."
    };
    stub:Ad candleHolder = {
        redirect_url: "/product/0PUK6V6EV0",
        text: "Candle holder for sale. 30% off."
    };
    stub:Ad bambooGlassJar = {
        redirect_url: "/product/9SIQT8TOJO",
        text: "Bamboo glass jar for sale. 10% off."
    };
    stub:Ad watch = {
        redirect_url: "/product/1YMWWN1N4O",
        text: "Watch for sale. Buy one, get second kit for free"
    };
    stub:Ad mug = {
        redirect_url: "/product/6E92ZMYYFZ",
        text: "Mug for sale. Buy two, get third one for free"
    };
    stub:Ad loafers = {
        redirect_url: "/product/L9ECAV7KIM",
        text: "Loafers for sale. Buy one, get second one for free"
    };
    return {
        "clothing": [tankTop],
        "accessories": [watch],
        "footwear": [loafers],
        "hair": [hairdryer],
        "decor": [candleHolder],
        "kitchen": [bambooGlassJar, mug]
    };
}
