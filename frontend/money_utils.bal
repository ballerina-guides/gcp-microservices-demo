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
import wso2/client_stubs as stub;

const map<string> logos = {
    "USD": "$",
    "CAD": "$",
    "JPY": "¥",
    "EUR": "€",
    "TRY": "₺",
    "GBP": "£"
};

# Checks if specified value has a valid units/nanos signs and ranges.
#
# + money - object to be validated
# + return - Validity
isolated function isValid(stub:Money money) returns boolean {
    return signMatches(money) && validNanos(money.nanos);
}

# Checks if the sign matches
#
# + money - object to be validated
# + return - validity status
isolated function signMatches(stub:Money money) returns boolean {
    return money.nanos == 0 || money.units == 0 || (money.nanos < 0) == (money.units < 0);
}

# Checks if nanos are valid
#
# + nanos - nano input
# + return - validity status
isolated function validNanos(int nanos) returns boolean {
    return -999999999 <= nanos && nanos <= +999999999;
}

# Checks if the money is zero
#
# + money - object to be validated
# + return - zero status
isolated function isZero(stub:Money money) returns boolean {
    return money.units == 0 && money.nanos == 0;
}

# Returns true if the specified money value is valid and is positive.
#
# + money - object to the validated
# + return - positive status
isolated function isPositive(stub:Money money) returns boolean {
    return isValid(money) && money.units > 0 || (money.units == 0 && money.nanos > 0);
}

# Returns true if the specified money value is valid and is negative.
#
# + money - object to the validated
# + return - negative status
isolated function isNegative(stub:Money money) returns boolean {
    return isValid(money) && money.units < 0 || (money.units == 0 && money.nanos < 0);
}

# Returns true if values firstValue and r have a currency code and they are the same values.
#
# + firstValue - first money object
# + secondValue - second money object
# + return - currency type equal status
isolated function areSameCurrency(stub:Money firstValue, stub:Money secondValue) returns boolean {
    return firstValue.currency_code != "" && firstValue.currency_code == secondValue.currency_code;
}

# Returns true if values firstValue and secondValue are the equal, including the currency.
#
# + firstValue - first money object
# + secondValue - second money object
# + return - currency equal status
isolated function areEqual(stub:Money firstValue, stub:Money secondValue) returns boolean {
    return firstValue.currency_code == secondValue.currency_code && 
                firstValue.units == secondValue.units && firstValue.nanos == secondValue.nanos;
}

# Negate returns the same amount with the sign negated.
#
# + money - object to be negated
# + return - negated money object
isolated function negate(stub:Money money) returns stub:Money {
    return {
        units: -money.units,
        nanos: -money.nanos,
        currency_code: money.currency_code
    };
}

# Adds two `Money` values.
#
# + firstValue - first money object
# + secondValue - second money object
# + return - sum money object
isolated function sum(stub:Money firstValue, stub:Money secondValue) returns stub:Money {

    int nanosMod = 1000000000;

    int units = firstValue.units + secondValue.units;
    int nanos = firstValue.nanos + secondValue.nanos;

    if (units == 0 && nanos == 0) || (units > 0 && nanos >= 0) || (units < 0 && nanos <= 0) {
        // same sign <units, nanos>
        units += nanos / nanosMod;
        nanos = nanos % nanosMod;
    } else {
        // different sign. nanos guaranteed to not to go over the limit
        if units > 0 {
            units = units - 1;
            nanos += nanosMod;
        } else {
            units = units + 1;
            nanos -= nanosMod;
        }
    }

    return {
        units: units,
        nanos: nanos,
        currency_code: firstValue.currency_code
    };
}

# Slow multiplication operation done through adding the value to itself n-1 times.
#
# + money - money object to be multiplied
# + n - multiply factor
# + return - multiplied money object
isolated function multiplySlow(stub:Money money, int n) returns stub:Money {
    int t = n;
    stub:Money out = money;
    while t > 1 {
        out = sum(out, money);
        t = t - 1;
    }
    return out;
}

isolated function renderMoney(stub:Money money) returns string {
    return string `${currencyLogo(money.currency_code)}
                ${money.units.toString()}.${(money.nanos / 10000000).toString()}`;
}

isolated function currencyLogo(string code) returns string {
    return logos.get(code);
}
