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

import ballerina/regex;
import ballerina/time;

type CardValidationError distinct error;

type CardCompany record {|
    string name;
    string pattern;
|};

# Class used to validate the card details.
class CardValidator {
    private final CardCompany[] companies = [
        {
            name: "VISA",
            pattern: "^4[0-9]{12}(?:[0-9]{3})?$"
        },
        {
            name: "MASTERCARD",
            pattern: "^5[1-5][0-9]{14}$"

        }
    ];
    private final string cardNumber;
    private final int expireYear;
    private final int expireMonth;

    isolated function init(string cardNumber, int expireYear, int expireMonth) {
        self.cardNumber = regex:replaceAll(cardNumber, "[^0-9]+", "");
        self.expireYear = expireYear;
        self.expireMonth = expireMonth;
    }

    # Validates the card with.
    # + return - `CardCompany` containing details
    isolated function isValid() returns CardCompany|error {
        if (self.cardNumber.length() < 13) || (self.cardNumber.length() > 19) {
            return error CardValidationError("Credit card info is invalid: failed length check");
        }
        if !check self.isLuhnValid() {
            return error CardValidationError("Credit card info is invalid: failed luhn check");
        }
        CardCompany? gleanCompany = self.getCompany();
        if gleanCompany is () {
            return error CardValidationError("Sorry, we cannot process the credit card. " +
                "Only VISA or MasterCard is accepted.");
        }
        if self.isExpired() {
            return error CardValidationError(
                string `Your credit card (ending ${self.cardNumber.substring(self.cardNumber.length() -4)})
                    expired on ${self.expireMonth}/${self.expireYear}`);
        }
        return gleanCompany;
    }

    private isolated function isLuhnValid() returns boolean|error {
        int digits = self.cardNumber.length();
        int oddOrEven = digits & 1;
        int sum = 0;

        foreach int count in 0 ..< digits {
            int digit = 0;
            digit = check int:fromString(self.cardNumber[count]);

            if ((count & 1) ^ oddOrEven) == 0 {
                digit *= 2;
                if digit > 9 {
                    digit -= 9;
                }
            }
            sum += digit;
        }
        return sum != 0 && (sum % 10 == 0);
    }

    private isolated function getCompany() returns CardCompany? {
        foreach CardCompany company in self.companies {
            if regex:matches(self.cardNumber, company.pattern) {
                return company;
            }
        }
        return;
    }

    private isolated function isExpired() returns boolean {
        int expireYear = self.expireYear;
        int expireMonth = self.expireMonth;

        time:Civil currentTime = time:utcToCivil(time:utcNow());
        int month = currentTime.month;
        int year = currentTime.year;

        if year > expireYear {
            return true;
        }
        return year == expireYear && month > expireMonth;
    }
}
