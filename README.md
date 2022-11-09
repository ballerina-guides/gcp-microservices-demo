# Introduction
The online boutique is a cloud-native microservices demo application written by the Google cloud platform. It consists of a 10-tier microservices application. The application is a web-based e-commerce app using which users can browse items, add them to the cart, and purchase them. This set of microservices is written using Ballerina to demonstrate the language features and showcase best practices for writing microservices using Ballerina. Communication between microservices is handled using gRPC and the frontend is exposed via an HTTP service.

# Architecture
![image info](architecture-diagram.png)

# Microservices description

|Service name | Description |
|-------------|-------------|
| Frontend | Exposes an HTTP server to outside to serve data required for the React app. Acts as a frontend for all the backend microservices and abstracts the functionality.|
| Cart | Stores the product items added to the cart and retrieves them. In memory store and Redis is supported as storage option.
| ProductCatalog | Reads a list of products from a JSON file and provides the ability to search products and get them individually.
| Currency | Reads the exchange rates from a JSON and converts one currency value to another.
| Payment | Validates the card details (using the Luhn algorithm) against the supported card providers and returns a transaction ID. (Mock)
| Shipping | Gives the shipping cost estimates based on the shopping cart. Returns a tracking ID. (Mock)
| Email | Sends the user an order confirmation email with the cart details using the Gmail connector. (mock).
| Checkout | Retrieves the user cart, prepares the order, and orchestrates the payment, shipping, and email notification.
| Recommendation | Recommends other products based on the items added to the user’s cart.
| Ads | Provides text advertisements based on the context of the given words.


The same load generator service will be used for load testing. 
The original Go frontend service serves HTML directly using the HTTP server using Go template.  In this sample, the backend is separated from the Ballerina HTTP service and React frontend.

# Service Implementation
First, we will be covering general implementation-related stuff thats common to all the services and then we will be diving into specific implementations of each microservices.

As shown in the diagram, `Frontend Service` is the only service that is being exposed to the internet. All the microservices except the `Frontend Service` uses gRPC for service-to-service communication. You can see the following example from the `Ad Service`.
```bal
import ballerina/grpc;

@grpc:Descriptor {value: DEMO_DESC}
service "AdService" on new grpc:Listener(9099) {

    remote function GetAds(AdRequest request) returns AdResponse|error {
    }
}
```

Ballerina provides the capability to generate docker, and Kubernetes artifacts to deploy the code on the cloud with minimal configuration. To enable this you need to add the `cloud="k8s"` under build options into the `Ballerina.toml` file of the project.

```toml
[package]
org = "wso2"
name = "recommendation"
version = "0.1.0"

[build-options]
observabilityIncluded = true
cloud = "k8s"
```

Additionally, you could make a `Cloud.toml` file in the project directory and configure various things in the container and the deployment. For every microservice in this sample, we would be modifying the container org, name, and tag of the created kubernetes yaml. Additionally, we add the cloud.deployment.internal_domain_name property to define a name for the generated service name. This allows us to easily specify host name values for services that depend on this service. This will be explained in depth in the next section. You can find a sample from the recommendation service below. Service-specific features of the `Cloud.toml` will be covered in their own sections.

```toml
[container.image]
name="recommendation-service"
repository="wso2inc"
tag="v0.1.0"

[cloud.deployment]
internal_domain_name="recommendation-service"
```

Ballerina Language provides an in-built functionality to configure values at runtime through configurable module-level variables. This feature will be used in almost all the microservices we write in this sample. When we deploy the services in different platforms(local, docker-compose, k8s) the hostname of the service changes. Consider the following sample from the recommendation service. The recommendation service depends on the catalog service, therefore it needs to resolve the hostname of the catalog service. The value "localhost" is assigned as the default value but it will be changed depending on the value passed on to it in runtime. You can find more details about this on the [configurable learn page](https://ballerina.io/learn/configure-ballerina-programs/configure-a-sample-ballerina-service/).

```bal
listener grpc:Listener ep = new (9090);
configurable string catalogHost = "localhost";

@grpc:Descriptor {value: DEMO_DESC}
service "RecommendationService" on ep {
    final ProductCatalogServiceClient catalogClient;

    function init() returns error? {
        self.catalogClient = check new ("http://" + catalogHost + ":9091");
    }

    isolated remote function ListRecommendations(ListRecommendationsRequest value) returns ListRecommendationsResponse|error {
        ...
    }
}
```

You can override the value using `Config.toml`. Note that this "catalog-service" is the same value as `cloud.deployment.internal_domain_name` in the `Cloud.toml` of the `Catalog Service`. 
```toml
catalogHost="catalog-service"
```

Then you could mount this `Config.toml` into Kubernetes using config maps by having the following entry in the `Cloud.toml`
```toml
[[cloud.config.files]]
file="./k8s/Config.toml"
```

## Cart Service

The cart service manages all the details about the shopping card of the user. It implements the Repository pattern to have multiple implementations of DataStore. We have an in-memory data store and redis based data store in the application.

In the original c# implementation, the repository is defined using an interface. You can find the ballerina representation below. As you notice, the function body is not implemented. This forces the implementer to implement the body of the function. 
```bal
public type DataStore object {
    isolated function add(string userId, string productId, int quantity);

    isolated function emptyCart(string userId);

    isolated function getCart(string userId) returns Cart;
};
```

Then we implement the DataStore using the concrete class `InMemoryStore` and `RedisStore` to provide the actual implementation of the Datastore.

```bal
public isolated class InMemoryStore {
    *DataStore;
    private map<Cart> store = {};

    isolated function add(string userId, string productId, int quantity) {
    }

    isolated function emptyCart(string userId) {
    }

    isolated function getCart(string userId) returns Cart {
    }
}
```

You could also observe that we use lock statements to ensure the concurrent safety.
```bal
isolated function getCart(string userId) returns Cart {
    lock {
        if self.store.hasKey(userId) {
            return self.store.get(userId).cloneReadOnly();
        }
        Cart newItem = {
            user_id: userId,
            items: []
        };
        self.store[userId] = newItem;
        return newItem.cloneReadOnly();
    }
}
```
And finally, we use the appropriate data store based on the config given by the user in the application initialization. 

```bal
configurable string datastore = "";

service "CartService" on new grpc:Listener(9092) {
    private final DataStore store;

    function init() {
        if datastore == "redis" {
            log:printInfo("Redis datastore is selected");
            self.store = new RedisStore();
        } else {
            log:printInfo("In memory datastore is selected");
            self.store = new InMemoryStore();
        }
    }
}
```

## Ads Service

The Ads service loads a set of ads based on the category when the service is initialized and then serves ads based on the products in the cart.
The Ad Store represents a read only class as these ads are not updated after the service is initialized. This allows us to access the ad store without lock statements allowing the concurrent calls to the service.

```bal
readonly class AdStore {

    final map<Ad[]> & readonly ads;

    isolated function init() {
        self.ads =  getAds().cloneReadOnly();
    }

    public isolated function getRandomAds() returns Ad[]|error {
        ...
    }

    public isolated function getAdsByCategory(string category) returns Ad[] {
        ...
    }
}

isolated function getAds() returns map<Ad[]> {
    return {
        "clothing": [tankTop],
        "accessories": [watch],
        "footwear": [loafers],
        "hair": [hairdryer],
        "decor": [candleHolder],
        "kitchen":[bambooGlassJar, mug]
    };
}
```

## Checkout Service

The checkout service gets called when the user confirms the checkout request. This service represents an intermediate coordination service between several services. 
The `PlaceOrder` remote function will be called upon the checkout request. It will call the `Cart Service` to get the products of the cart in the user's account. Then it will match those products with `Catalog Service` and call the `Currency Service` to convert the prices to the user's preferred currency. Then it calls `Shipping Service` to get the shipping quote and it converts the shipping cost to the user's preferred currency using the `Currency Service`. Then the service calculates the total cost and calls the `Payment Service` so it would be charged from the card and it returns a transaction id. Then we ship the order using the `Shipping Service` then clear the cart of the user using the `Cart Service`. Finally, we send an email with all the details to the user's email using `Email Service` and return the order summary to the caller.

```bal
configurable string cartHost = "localhost";

service "CheckoutService" on new grpc:Listener(9094) {
    final CartServiceClient cartClient;
    ...

    function init() returns error? {
        self.cartClient = check new ("http://" + cartHost + ":9092");
        ...
    }

    remote function PlaceOrder(PlaceOrderRequest value) returns PlaceOrderResponse|error {
        ...
    }
}
```

## Currency Service

The Currency service is responsible for converting a given currency object to another currency. The service contains a JSON file with the conversion rates. When the service is initialized it will read this JSON and store it in a read-only map as it's not getting modified afterward. When the `Convert` remote function is invoked, it will read the rate from the map, convert the value and return the converted currency value to the caller.

```bal
configurable string currencyJsonPath = "./data/currency_conversion.json";

service "CurrencyService" on new grpc:Listener(9093) {
    final map<decimal> & readonly currencyMap;

    function init() returns error? {
        json currencyJson = check io:fileReadJson(currencyJsonPath);
        self.currencyMap = check parseCurrencyJson(currencyJson).cloneReadOnly();
    }

    remote function GetSupportedCurrencies(Empty value) returns GetSupportedCurrenciesResponse|error {
        return {currency_codes: self.currencyMap.keys()};

    }
    remote function Convert(CurrencyConversionRequest value) returns Money|error {
        ...
    }
}
```

Additionally, since we are reading the Currency rates from the JSON file, therefore we need to copy the JSON into the container. This can be done using having the following codeblock in the `Cloud.toml`.
```toml
[[container.copy.files]]
sourceFile="./data/currency_conversion.json"
target="/home/ballerina/data/currency_conversion.json"
```

## Email Service

The service is responsible for sending an email with the order confirmation after checkout completion. The HTML generation required for the Email formatting is done using ballerina's built-in XML feature. The email-sending part is handled by the Gmail connector. 

```bal
service "EmailService" on new grpc:Listener(9097) {

    isolated remote function SendOrderConfirmation(SendOrderConfirmationRequest value) returns Empty|error {
        string htmlBody = self.getConfirmationHtml(request.'order).toString();
        gmail:MessageRequest messageRequest = {
            recipient: request.email,
            subject: "Order Confirmation",
            messageBody: htmlBody,
            contentType: gmail:TEXT_HTML
        };

        gmail:Message|error sendMessageResponse = gmailClient->sendMessage(messageRequest);
        ...
        return {};
    }

    isolated function getConfirmationHtml(OrderResult res) returns xml {
        ...

        xml items = xml `<tr>
          <th>Item No.</th>
          <th>Quantity</th> 
          <th>Price</th>
        </tr>`;

        foreach OrderItem item in res.items {
            xml content = xml `<tr>
            <td>#${item.item.product_id}</td>
            ...
            </tr>`;
            items = items + content;
        }

        xml page = ...

        return page;
    }
}
```

This service requires sensitive Gmail credentials, to use in the Gmail connector. This also is done with the help of Ballerina's configurable feature. The sample code and the `Config.toml` file can be found below.

```bal
type GmailConfig record {|
    string refreshToken;
    string clientId;
    string clientSecret;
|};

configurable GmailConfig gmail = ?;
```

```toml
[gmail]
refreshToken = ""
clientId = ""
clientSecret =  ""
```

However, as this `Config.toml` contains sensitive information we need to load this as a secret to the kubernetes cluster. You can do that by adding the following entry to the `Cloud.toml`.
```toml
[[cloud.secret.files]]
file="./Config.toml"
```

### Frontend Service

The HTTP service uses cookies to identify the user details. Since this sample does not have a register capability, if the cookie is not found in the request it will always regenerate a new cookie with return the cookie with the response. Please note that this is not a secure way to do this but for demo purposes only. Anyhow, to implement the feature, since we need to intercept each request, without repeating the code we have implemented an AuthInterceptor and registered into the service.


```bal
listener http:Listener ep = new (9098);

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
service / on ep {

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
## Payment Service

Payment Service is responsible for validating the card details and sending a mock payment id. The validation is done by checking length, performing Luhn algorithm validation, validating the card company, and checking the expiry date. This microservice shows some usage of low-level operations to implement the validation algorithm.


```bal
isolated function isLuhnValid() returns boolean|error {
    int digits = self.card.length();
    int oddOrEven = digits & 1;
    int sum = 0;

    foreach int count in 0 ..< digits {
        int digit = 0;
        digit = check int:fromString(self.card[count]);

        if (((count & 1) ^ oddOrEven) == 0) {
            digit *= 2;
            if digit > 9 {
                digit -= 9;
            }
        }
        sum += digit;
    }
    return sum != 0 && (sum % 10 == 0);
}
```

## Product Catalog Service

The Catalog Service maintains a list of products available in the store. The product list will be read from JSON and converted to a readonly array of `Product` when the service is initialized. The `Catalog Service` has the Search Product capability. This feature is implemented using ballerina query expressions. It allows you to write SQL like queries to filter data from the array. You can find more details about query expressions in this [blog](https://dzone.com/articles/language-integrated-queries-in-ballerina).

```
configurable string productJsonPath = "./resources/products.json";

@grpc:Descriptor {value: DEMO_DESC}
service "ProductCatalogService" on new grpc:Listener(9091) {
    final Product[] & readonly products;

    function init() returns error? {
        json productsJson = check io:fileReadJson(productJsonPath);
        Product[] products = check parseProductJson(productsJson);
        self.products = products.cloneReadOnly();
    }

    remote function ListProducts(Empty value) returns ListProductsResponse {
        return {products: self.products};
    }

    remote function GetProduct(GetProductRequest value) returns Product|error {
        foreach Product product in self.products {
            if product.id == value.id {
                return product;
            }
        }
        return error("product not found");
    }

    remote function SearchProducts(SearchProductsRequest value) returns SearchProductsResponse|error {
        return {
            results: from Product product in self.products
                where isProductRelated(product, value.query)
                select product
        };
    }
}
```

## Recommendation Service

`Recommendation Service` simply calls the `Catalog Service` and returns a set of product which is not included in the user's cart. For this filtration also we make use of query expressions.

```bal
isolated remote function ListRecommendations(ListRecommendationsRequest value) returns ListRecommendationsResponse|error {
    string[] productIds = value.product_ids;
    ListProductsResponse|grpc:Error listProducts = self.catalogClient->ListProducts({});
    if listProducts is grpc:Error {
        log:printError("failed to call ListProducts of catalog service", 'error = listProducts);
        return listProducts;
    }

    return {
        product_ids: from Product product in listProducts.products
            where productIds.indexOf(product.id) is ()
            select product.id
    };
}
```

## Shipping Service

The `Shipping Service` is a mock service where it returns a constant shipping cost if the cart is not empty. It also has the capability to generate a mock tracking number for the shipment. 

## Kustomize

[Kustomize](https://kustomize.io/) is a tool where you can add, remove or update Kubernetes yamls without modifying the original yaml. This tool can be used to apply more modifications to the generated yaml from code to cloud. In the `kustomization.yaml` in the root directory, you can find a sample kustomize definition. This simply takes all the generated yamls from each project and combines them into one. Then we need to add an environment variable to specify where the Config.toml is located for the email service. This is done by using kustomize patches. You can see the sample code below.

kustomization.yaml
```yaml
resources:
  - ads/target/kubernetes/ads/ads.yaml
  - cart/target/kubernetes/cart/cart.yaml
  - checkout/target/kubernetes/checkout/checkout.yaml
  - currency/target/kubernetes/currency/currency.yaml
  - email/target/kubernetes/email/email.yaml
  - frontend/target/kubernetes/frontend/frontend.yaml
  - payment/target/kubernetes/payment/payment.yaml
  - productcatalog/target/kubernetes/productcatalog/productcatalog.yaml
  - recommendation/target/kubernetes/recommendation/recommendation.yaml
  - shipping/target/kubernetes/shipping/shipping.yaml

patchesStrategicMerge:
- secret-env-patch.yaml
```

secret-env-patch.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: email-deployment
spec:
  template:
    spec:
      containers:
        - name: email-deployment
          env:
            - name: BAL_CONFIG_FILES
              value: "/home/ballerina/conf/Config.toml:"

```


# Running the Microservices on the Cloud

## Setting up Email Credentials
* A Gmail Account with access <br/> https://support.google.com/mail/answer/56256?hl=en

* New project with `Gmail API` enabled on the API Console.
    - Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard 
    to create a new project.

* OAuth Credentials 
    - Go to **OAuth Consent Screen**, select `User Type` as `Internal` and click **Create**. Add an `App name`, `User support email` and `Developer email address` click **Save**.
    - On the **Credentials** tab, click **Create Credentials** and select **OAuth Client ID**.
    - Select the **Web application** application type, enter a name for the application, and specify a redirect URI 
    (enter https://developers.google.com/oauthplayground if you want to use [OAuth 2.0 Playground](https://developers.google.com/oauthplayground) 
    to receive the Authorization Code and obtain the Access Token and Refresh Token).
    - Click **Create**. Your Client ID and Client Secret will appear.
    - In a separate browser window or tab, visit [OAuth 2.0 Playground](https://developers.google.com/oauthplayground). 
    Click on the `OAuth 2.0 Configuration` icon in the top right corner and click on `Use your own OAuth credentials` and 
    provide your `OAuth Client ID` and `OAuth Client Secret`.
    - Select the required Gmail API scopes from the list of APIs (`auth.gmail.send`).
    - Then click **Authorize APIs**.
    - When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the refresh 
    token and access token.

* Create the `Config.toml` file in `email/` and paste the following code after replacing the values.
    ```toml
    [gmail]
    refreshToken = "<your-refresh-token>"
    clientId = "<your-client-id>"
    clientSecret =  "<your-client-secret>"
    ```

## Docker-Compose

Then execute the `build-all-docker.sh` to build the Ballerina packages and Docker images, and then execute `docker-compose up` to run the containers.
```bash
./build-all-docker.sh
docker-compose up
```

You can start the React application by executing following commands from the `ui/` directory.
```bash
npm install
npm start
```
## Kubernetes

Kustomize is used for combining all the YAML files that have been generated into one. You can execute the following command to build the final YAML file.
```
kubectl kustomize ./ > final.yaml
```
If you are using Minikube, you can execute the following `build-all-minikube.sh` script to build the containers into the minikube cluster so you won't have to push the containers manually.
```
build-all-minikube.sh
```

If you are not using Minikube, you have to push the artifacts to your Docker registry manually.

You can deploy the artifacts into Kubernetes using the following command.
```
kubectl apply -f final.yaml
```
You can expose the frontend service via node port to access the backend services from the react app.
```
kubectl expose deployment frontend-deployment --type=NodePort --name=frontend-svc-local
```

Execute `kubectl get svc` and get the port of the `frontend-svc-local` service.

Execute `minikube ip` to get the ip of the minikube cluster.

Change the value of the `FRONTEND_SVC_URL` variable in `ui/src/lib/api.js` to the frontend service (Example Value - http://192.168.49.2:32437')
