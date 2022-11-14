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
import ballerina/lang.'string as str;

isolated function generateRandomLetter() returns string {
    //Note - We only use checkpanic as we have valid inputs if the inputs are invalid application will be crashed.
    int randomLetterCodePoint = checkpanic random:createIntInRange(65, 91);
    return checkpanic str:fromCodePointInt(randomLetterCodePoint);
}

isolated function generateRandomNumber(int digit) returns string {
    string randomNumber = "";
    foreach int item in 0 ... digit {
        //Note - We only use checkpanic as we have valid inputs if the inputs are invalid application will be crashed.
        int randomInt = checkpanic random:createIntInRange(0, 10);
        randomNumber += randomInt.toString();
    }
    return randomNumber;
}

isolated function generateTrackingId(string baseAddress) returns string {
    return string `${generateRandomLetter()}${generateRandomLetter()}-${baseAddress.length().toString()}${generateRandomNumber(3)}-${(baseAddress.length() / 2).toString()}${generateRandomNumber(7)}`;
}
