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

import ballerina/http;
import ballerina/log;
import ballerina/regex;

isolated function getSessionIdFromCookieHeader(string cookieStr) returns http:Cookie|http:Unauthorized {
    http:Cookie[] cookies = parseCookieHeader(cookieStr);
    http:Cookie[] usernameCookie = cookies.filter(cookie => cookie.name == SESSION_ID_COOKIE);
    if usernameCookie.length() == 1 {
        return usernameCookie[0];
    }
    return {
        body: string `${SESSION_ID_COOKIE} cookie is not available.`
    };
}

isolated function getCurrencyFromCookieHeader(string cookieStr) returns http:Cookie|http:Unauthorized {
    http:Cookie[] cookies = parseCookieHeader(cookieStr);
    http:Cookie[] currencyCookie = cookies.filter(cookie => cookie.name == CURRENCY_COOKIE);
    if currencyCookie.length() == 1 {
        return currencyCookie[0];
    }
    return {
        body: CURRENCY_COOKIE + " cookie is not available."
    };
}

isolated function parseCookieHeader(string cookieStringValue) returns http:Cookie[] {
    http:Cookie[] cookiesInRequest = [];
    string cookieValue = cookieStringValue;
    string[] nameValuePairs = regex:split(cookieValue, "; ");
    foreach string pair in nameValuePairs {
        if regex:matches(pair, "^([^=]+)=.*$") {
            string[] nameValue = regex:split(pair, "=");
            http:Cookie cookie;
            cookie = new (nameValue[0], nameValue.length() > 1 ? nameValue[1] : "", path = "/");
            cookiesInRequest.push(cookie);
        } else {
            log:printError(string `Invalid cookie: ${pair}, which must be in the format as [{name}=].`);
        }
    }
    return cookiesInRequest;
}

isolated function getCartSize(Cart cart) returns int|error {
    int cartsize = 0;
    check from CartItem item in cart.items
        do {
            cartsize += item.quantity;
        };
    return cartsize;
}

isolated function toProductLocalized(Product product, string price) returns ProductLocalized {
    return {
        ...product,
        price
    };
}
