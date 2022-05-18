# Introduction
The online boutique is a cloud-native microservices demo application written by the Google cloud platform. It consists of a 10-tier microservices application. The application is a web-based e-commerce app using which users can browse items, add them to the cart, and purchase them. This set of microservices is written using Ballerina to demonstrate the language features and showcase best practices for writing microservices using Ballerina. Communication between microservices is handled using gRPC and the frontend is exposed via an HTTP service.

# Architecture
![image info](architecture-diagram.png)

# Microservices description

|Service name | Description |
|-------------|-------------|
| Frontend | Exposes an HTTP server to outside to serve data required for the React app. Acts as a frontend for all the backend microservices and abstracts the functionality.|
| Cart | Stores the product items added to the cart and retrieves them. In memory store and Redis is supported as storage options.
| ProductCatalog | Reads a list of products from a JSON file and provides the ability to search products and get then individually.
| Currency | Reads the exchange rates from a JSON and converts one currency value to another.
| Payment | Validates the card details (using the Luhn algorithm) against the supported card providers and returns a transaction ID. (Mock)
| Shipping | Gives the shipping cost estimates based on the shopping cart. Returns a tracking ID. (Mock)
| Email | Sends the user an order confirmation email with the cart details using the Gmail connector. (mock).
| Checkout | Retrieves the user cart, prepares the order, and orchestrates the payment, shipping, and email notification.
| Recommendation | Recommends other products based on the items added to the user’s cart.
| Ads | Provides text advertisements based on the context of the given words.


Te same load generator service will be used for load testing. 
The original Go frontend service serves HTML directly using the HTTP server using Go template.  In this sample, the backend is separated from the Ballerina HTTP service and React frontend.


# Running the Microservices on the Cloud

## Setting up Email Credentials
* A Gmail Account with access <br/> https://support.google.com/mail/answer/56256?hl=en

* New project with `Gmail API` enabled on the API Console.
    - Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard 
    to create a new project.

* OAuth Credentials 
    - Go to **Credentials -> OAuth Consent Screen**, enter a product name to be shown to users, and click **Save**.
    - On the **Credentials** tab, click **Create Credentials** and select **OAuth Client ID**.
    - Select the **Web application** application type, enter a name for the application, and specify a redirect URI 
    (enter https://developers.google.com/oauthplayground if you want to use [OAuth 2.0 Playground](https://developers.google.com/oauthplayground) 
    to receive the Authorization Code and obtain the Access Token and Refresh Token).
    - Click **Create**. Your Client ID and Client Secret will appear.
    - In a separate browser window or tab, visit [OAuth 2.0 Playground](https://developers.google.com/oauthplayground). 
    Click on the `OAuth 2.0 Configuration` icon in the top right corner and click on `Use your own OAuth credentials` and 
    provide your `OAuth Client ID` and `OAuth Client Secret`.
    - Select the required Gmail API scopes from the list of APIs.
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

Then execute the `build-all-docker.sh` to build the ballerina packages and Docker images, and then execute the Docker-compose up to run the containers.
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

Kustomize is used for combining all the YAML files that have generated into one. You can execute the following command to build the final YAML file.
```
kustomize build . > final.yaml
```
If you are using Minikube, you can execute the following `build-all-minikube.sh` script to build the containers into minikube cluster so you won't have to push the containers manually.
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

# Ballerina Highlights
## gRPC Support
The online boutique store application uses gRPC as the communication method between the microservices. Each language has its own way of providing the gRPC capabilities for the language. As many other languages, Ballerina supports generating server and client codes using the `.proto` file using the `bal grpc` command. You can view the `.proto` file here. Ballerina has services and clients as first class constructs and gRPC builds upon that foundation. You can compare the original Go lang code and Ballerina code below.
Go - 

```go
type checkoutService struct {
   cartSvcAddr           string
}
 
func main() {
   port := listenPort
   if os.Getenv("PORT") != "" {
       port = os.Getenv("PORT")
   }
 
   svc := new(checkoutService)
   mustMapEnv(&svc.cartSvcAddr, "CART_SERVICE_ADDR")
 
   log.Infof("service config: %+v", svc)
 
   lis, err := net.Listen("tcp", fmt.Sprintf(":%s", port))
   if err != nil {
       log.Fatal(err)
   }
 
   var srv *grpc.Server
   srv = grpc.NewServer()
   pb.RegisterCheckoutServiceServer(srv, svc)
   log.Infof("starting to listen on tcp: %q", lis.Addr().String())
   err = srv.Serve(lis)
   log.Fatal(err)
}

 
func (cs *checkoutService) PlaceOrder(ctx context.Context, req *pb.PlaceOrderRequest) (*pb.PlaceOrderResponse, error) {
   ...
}
```

Ballerina - 
```ballerina
configurable string cartUrl = "http://localhost:9092";

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "CheckoutService" on ep {
    
    function init() returns error? {
        self.cartClient = check new (cartUrl);
        …
    }

    remote function PlaceOrder(PlaceOrderRequest value) returns PlaceOrderResponse|error {
           …  
    }
}
```

## DataStore repository- Cart Service
The usecase is to store the user’s shopping cart details. The type of the store will be decided by the configurables loaded into the application by the factory. In memory and Redis store is supported in the sample. You can find the code sample below.
C# -
```c#
public interface ICartStore
{
    Task AddItemAsync(string userId, string productId, int quantity);
    Task EmptyCartAsync(string userId);

    Task<Hipstershop.Cart> GetCartAsync(string userId);
}


internal class LocalCartStore : ICartStore
{
    // Maps between user and their cart
    private ConcurrentDictionary<string, Hipstershop.Cart> userCartItems = new ConcurrentDictionary<string, Hipstershop.Cart>();    

    public Task AddItemAsync(string userId, string productId, int quantity)
    {
    }
}
```

Ballerina -
```ballerina
public type DataStore object {
    isolated function add(string userId, string productId, int quantity);

    isolated function emptyCart(string userId);

    isolated function getCart(string userId) returns Cart;
};

public isolated class InMemoryStore {
    *DataStore;
    private map<Cart> store = {};

    isolated function add(string userId, string productId, int quantity) {
    }
}

public isolated class RedisStore {
    *DataStore;

    isolated function add(string userId, string productId, int quantity) {
    }
}
```

## Search products using query expressions - catalog service
The product catalog service contains all the details of the available products. The requirement is to get the products similar to the search query. You can find the original implementation below.

```go
func (p *productCatalog) SearchProducts(ctx context.Context, req *pb.SearchProductsRequest) (*pb.SearchProductsResponse, error) {
	time.Sleep(extraLatency)
	// Interpret the query as a substring match with the name or description.
	var ps []*pb.Product
	for _, p := range parseCatalog() {
		if strings.Contains(strings.ToLower(p.Name), strings.ToLower(req.Query)) ||
			strings.Contains(strings.ToLower(p.Description), strings.ToLower(req.Query)) {
			ps = append(ps, p)
		}
	}
	return &pb.SearchProductsResponse{Results: ps}, nil
}
```

Even though you can implement the same using the Ballerina foreach statement, the Ballerina query expression is used to implement the search function. Query expressions contain a set of clauses similar to SQL to process the data.
```ballerina
remote function SearchProducts(SearchProductsRequest value) returns SearchProductsResponse|error {
    return {
        results: from Product product in self.products
            where isProductRelated(product, value.query)
            select product
    };
}

isolated function isProductRelated(Product product, string query) returns boolean {
    string queryLowercase = query.toLowerAscii();
    return product.name.toLowerAscii().includes(queryLowercase) || product.description.toLowerAscii().includes(queryLowercase);
}
```

You can read more about query expressions in this [blog](https://dzone.com/articles/language-integrated-queries-in-ballerina). You can have much more complicated queries using the `limit` and `let` keywords, ordering, joins and so on. You can use query expressions not only for arrays but for streams, and tables as well.


## Concurrency safety - Ad service
Ballerina is designed for network-based applications. The concept of isolation in Ballerina simplifies development by ensuring the safety of shared resources during concurrent execution. Ballerina Compiler warns if the application is not concurrent safe and helps to make it concurrent safe and performant at the same time. The following code shows how a class is marked as readonly so that by default, the compiler makes concurrent calls to its objects.
```ballerina
readonly class AdStore {

    final map<Ad[]> & readonly ads;
    private final int MAX_ADS_TO_SERVE = 2;

    isolated function init() {
        self.ads =  getAds().cloneReadOnly();
    }

    public isolated function getRandomAds() returns Ad[]|error {
    }
}
```
You can read this [blog](https://dzone.com/articles/concurrency-safe-execution-ballerina-isolation) for more information about isolation concepts.

## Coordinating with multiple services and configurables - checkout service
Microservices often requires to communicate with other services to get a specific task done. Checkout service coordinates with the cart service, catalog service, currency service, shipping service, payment service, and email service to perform the checkout. 

```ballerina
configurable string cartUrl = "http://localhost:9092";

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "CheckoutService" on ep {
    final CartServiceClient cartClient;
    …
    
    function init() returns error? {
        self.cartClient = check new (cartUrl);
        …
    }

    remote function PlaceOrder(PlaceOrderRequest value) returns PlaceOrderResponse|error {
        string orderId = uuid:createType1AsString();
        CartItem[] userCartItems = check self.getUserCart(value.user_id, value.user_currency);

           …  
    }
}

  function getUserCart(string userId, string userCurrency) returns CartItem[]|error {
        GetCartRequest req = {user_id: userId};
        Cart|grpc:Error cart = self.cartClient->GetCart(req);
        if (cart is grpc:Error) {
            log:printError("failed to call getCart of cart service", 'error = cart);
            return cart;
        }
        return cart.items;
    }
```
As shown in the above code, Ballerina makes it very easy to invoke other microservices, log, and handle errors. The configurable feature helps to configure the value of the variable by overriding it in the runtime. This will be explained in depth in the testing and deployment sections of this article.

## HTML generation with XML - email service
The email service is responsible for generating a confirmation email with the order and tracking details. Ballerina’s built-in XML feature is used for generating HTML code required for the email. You can see the code below to see how the if blocks, loops, concat, variables are used in the XML to create the HTML page.

```
isolated function getConfirmationHtml(OrderResult res) returns xml {
    string fontUrl = "https://fonts.googleapis.com/css2?family=DM+Sans:ital,wght@0,400;0,700;1,400;1,700&display=swap";

    xml items = xml `<tr>
        <th>Item No.</th>
        <th>Quantity</th> 
        <th>Price</th>
    </tr>`;

    foreach OrderItem item in res.items {
        xml content = xml `<tr>
        <td>#${item.item.product_id}</td>
        <td>${item.item.quantity}</td> 
        <td>${item.cost.units}.${item.cost.nanos / 10000000} ${item.cost.currency_code}</td>
        </tr>`;
        items = items + content;
    }

    xml body = xml `<body>
    <h2>Your Order Confirmation</h2>
    <p>Thanks for shopping with us!</p>
    <h3>Order ID</h3>
    <p>#${res.order_id}</p>
    <h3>Shipping</h3>
    <p>#${res.shipping_tracking_id}</p>
    <p>${res.shipping_cost.units}.${res.shipping_cost.nanos / 10000000} ${res.shipping_cost.currency_code}</p>
    <p>${res.shipping_address.street_address}, ${res.shipping_address.city}, ${res.shipping_address.country} ${res.shipping_address.zip_code}</p>
    <h3>Items</h3>
    <table style="width:100%">
        ${items}
    </table>
    </body>
    `;

    xml page = xml `
    <html>
    <head>
        <title>Your Order Confirmation</title>
        <link href="${fontUrl}" rel="stylesheet"></link>
    </head>
    <style>
        body{
        font-family: 'DM Sans', sans-serif;
        }
    </style>
        ${body}
    </html>`;

    return page;
}
```

## Testing microservices - the recommendation service
Microservices are loosely coupled, Independently deployable units. These units should be tested before we integrate them with other microservices. Ballerina’s test framework allows you to test your microservices effortlessly.
First, we need to make sure that the catalog URL is marked as a configurable. 

```ballerina
import ballerina/grpc;
import ballerina/log;

listener grpc:Listener ep = new (9090);
configurable string catalogUrl = "http://localhost:9091";

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "RecommendationService" on ep {
final ProductCatalogServiceClient catalogClient;

    function init() returns error? {
        self.catalogClient = check new (catalogUrl);
    }

    isolated remote function ListRecommendations(ListRecommendationsRequest value) returns ListRecommendationsResponse|error {
        ….
    }
}
```

In the `tests` directory, you need to create a `Config.toml` file and override that variable with the mock URL. This allows you to point to another service in the testing phase. 
```toml
catalogUrl="http://localhost:8989"
```

You can define a mock service to represent the catalog service in the test file, and execute the test based on that.

```ballerina
import ballerina/test;
import ballerina/grpc;

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "ProductCatalogService" on new grpc:Listener(8989) {
    remote function ListProducts(Empty value) returns ListProductsResponse {
        return {products: [{
            id: "test id",
            categories: ["watch", "clothes"],
            description: "Test description",
            name: "test name",
            picture: "",
            price_usd: {
                currency_code: "USD",
                nanos: 900000000,
                units: 5
            }
        }]};
    }

    remote function GetProduct(GetProductRequest value) returns Product|error {
        return error("method not implemented");
    }

    remote function SearchProducts(SearchProductsRequest value) returns SearchProductsResponse|error {
        return error("method not implemented");
    }
}

@test:Config {}
function recommandTest() returns error?{
    RecommendationServiceClient ep = check new ("http://localhost:9090");
    ListRecommendationsRequest req = {
        user_id: "1",
        product_ids: ["2ZYFJ3GM2N", "LS4PSXUNUM"]
    };
    ListRecommendationsResponse listProducts = check ep->ListRecommendations(req);
    test:assertEquals(listProducts.product_ids.length(), 1);
}
```

Ballerina has object mocking features that allows you to do this without even running a service. For in-depth information on object mocking, see[]().
