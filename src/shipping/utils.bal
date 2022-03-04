import ballerina/random;
import ballerina/lang.'string as str;

isolated function generateRandomLetter() returns string {
    //Note - We only use checkpanic as we have valid inputs if the inputs are invalid application will be crashed.
    int randomLetterCodePoint = checkpanic random:createIntInRange(65, 91);
    return checkpanic str:fromCodePointInt(randomLetterCodePoint);
}

isolated function generateRandomNumber(int digit) returns string {
    string out = "";
    foreach int item in 0 ... digit {
        //Note - We only use checkpanic as we have valid inputs if the inputs are invalid application will be crashed.
        int randomInt = checkpanic random:createIntInRange(0, 10);
        out += randomInt.toString();
    }
    return out;
}

isolated function generateTrackingId(string baseAddress) returns string {
    return generateRandomLetter() + generateRandomLetter() + "-" + baseAddress.length().toString() + generateRandomNumber(3) + "-" + (baseAddress.length() / 2).toString() + generateRandomNumber(7);
}
