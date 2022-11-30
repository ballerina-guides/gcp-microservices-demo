## Frontend Service

The HTTP service uses cookies to identify the user details. Since this sample does not have a register capability, if the cookie is not found in the request it will always regenerate a new cookie with return the cookie with the response. Please note that this is not a secure way to do this but for demo purposes only. Anyhow, to implement the feature, since we need to intercept each request, without repeating the code we have implemented an AuthInterceptor and registered into the service.


```bal
service class AuthInterceptor {
    *http:RequestInterceptor;
    resource function 'default [string... path](http:RequestContext ctx, http:Request req)
                returns http:NextService|error? {
        http:Cookie[] usernameCookie = req.getCookies().filter(function
                                (http:Cookie cookie) returns boolean {
            return cookie.name == USER_COOKIE_NAME;
        });
        if usernameCookie.length() == 0 {
            http:Cookie cookie = new (USER_COOKIE_NAME, uuid:createType1AsString(),
                                                path = "/");

            req.addCookies([cookie]);
        }
        return ctx.next();
    }
}

AuthInterceptor authInterceptor = new;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true
    },
    interceptors: [authInterceptor]
}
service / on new http:Listener (9098) {

}
```

In ballerina, an HTTP resource is represented by a resource function. The function definition has all the information about the resource. The following resource function has the resource path of /cart and gets invoked for POST requests. The resource expects a payload with the `AddToCartRequest` record format and the cookie header. It could return responses with different HTTP error codes depending on various reasons. You can find more information about writing a REST service from the [learn page.](https://ballerina.io/learn/write-a-restful-api-with-ballerina/).

```bal
resource function post cart(@http:Payload AddToCartRequest req, @http:Header {name: "Cookie"} string cookieHeader)
            returns http:Ok|http:Unauthorized|http:BadRequest|error {
    http:Cookie|http:Unauthorized cookie = getUserIdFromCookie(cookieHeader);
    if cookie is http:Unauthorized {
        return cookie;
    }
    string userId = cookie.value;
    Product|error product = getProduct(req.productId);
    if product is error {
        return <http:BadRequest> {
            body: "invalid request" + product.message()
        };
    }

    check insertCart(userId, req.productId, req.quantity);

    return <http:Ok> {
        headers: {
            "Set-Cookie": cookie.toStringValue()
        },
        body: "item added the cart"
    };
}
```
