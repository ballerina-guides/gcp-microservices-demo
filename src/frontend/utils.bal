import ballerina/http;
import ballerina/log;
import ballerina/regex;

isolated function getUserIdFromCookie(string cookieStr) returns http:Cookie|http:Unauthorized {
    http:Cookie[] cookies = parseCookieHeader(cookieStr);
    http:Cookie[] usernameCookie = cookies.filter(isolated function
                            (http:Cookie cookie) returns boolean {
        return cookie.name == USER_COOKIE_NAME;
    });
    if usernameCookie.length() == 1 {
        return usernameCookie[0];
    }
    return {
        body: USER_COOKIE_NAME + " cookie is not available."
    };
}

isolated function parseCookieHeader(string cookieStringValue) returns http:Cookie[] {
    http:Cookie[] cookiesInRequest = [];
    string cookieValue = cookieStringValue;
    string[] nameValuePairs = regex:split(cookieValue, "; ");
    foreach var item in nameValuePairs {
        if regex:matches(item, "^([^=]+)=.*$") {
            string[] nameValue = regex:split(item, "=");
            http:Cookie cookie;
            if nameValue.length() > 1 {
                cookie = new (nameValue[0], nameValue[1], path = "/");
            } else {
                cookie = new (nameValue[0], "", path = "/");
            }
            cookiesInRequest.push(cookie);
        } else {
            log:printError("Invalid cookie: " + item + ", which must be in the format as [{name}=].");
        }
    }
    return cookiesInRequest;
}

isolated function toProductLocalized(Product product, string price) returns ProductLocalized {
    return {
        id: product.id,
        categories: product.categories,
        description: product.description,
        name: product.name,
        picture: product.picture,
        price_usd: product.price_usd,
        price: price
    };
}
