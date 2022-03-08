# Introduction
Online Boutique is a cloud-native microservices demo application written by the Google cloud platform. Online Boutique consists of a 10-tier microservices application. The application is a web-based e-commerce app where users can browse items, add them to the cart, and purchase them. We have written this set of microservices using ballerina to demonstrate the language features and showcase best practices for writing microservices using Ballerina. Microservice communication is handled using gRPC and the frontend exposes HTTP service.
Architecture


# Microservices Description

|Service Name | Description |
|-------------|-------------|
| Frontend | Exposes HTTP server to outside to serve data required for the React App. Acts as a frontend for all the backend microservices and abstracts the functionality.|
| Cart | Stores the product items added to the cart and retrieves them. In memory store and Redis is supported as storage options.
| ProductCatalog | Reads a list of products from a JSON file and provides the ability to search products and get individual products.
| Currency | Reads exchange rates from a JSON and converts one money amount to another currency.
| Payment | Validates the card details using Luhn algorithm and against supported card providers and returns a transaction ID. (Mock)
| Shipping | Gives shipping cost estimates based on the shopping cart. Returns a tracking ID. (Mock)
| Email | Sends user an order confirmation email with the cart details using the Gmail connector. (mock).
| Checkout | Retrieves user cart, prepares the order, and orchestrates the payment, shipping, and email notification.
| Recommendation | Recommends other products based on the user’s cart items
| Ads | Provides text ads based on given context words.


We will be using the same load generator service for load testing. 
In the original frontend go service, It serves HTML directly using the HTTP server using go templates, In our sample, we have separated the backend and the frontend using Ballerina HTTP service and React frontend.


# Running the sample
## Docker-Compose
Create `Config.toml` in `src/email/` and paste the following code after replacing the values. You can generate credentials using following these steps https://github.com/ballerina-platform/module-ballerinax-googleapis.gmail/tree/v0.99.11#prerequisites
```toml
[gmail]
refreshToken = "<your-refresh-token>"
clientId = "<your-client-id>"
clientSecret =  "<your-client-secret>"
```
Change directory into src directory of the repository root and build the docker images and then execute docker-compose up.
```bash
./build-all-docker.sh
docker-compose up
```

We can start the react application by executing following commands in `src/ui/` directory.
```bash
npm install
npm start
```
## Kubernetes

We use kustomize for combining all the YAML that have generated into one. You can execute the following command to build the final yaml.
```
kustomize build kubernetes > final.yaml
```
If you are using minikube, you can execute the following bash script to build inside the minikube cluster.
```
build-all-minikube.sh
```

If you are not using minikube, you have to manually push to your docker registry. You need to make sure to make the Config.toml in `src/email/` a secret before pushing to public docker registries.

Finally you can deploy the artifacts into Kubernetes using the following command.
```
kubectl apply -f final.yaml
```

# Ballerina Highlights
## gRPC Support
The online boutique store application uses gRPC as the communication method between each microservices. Each language has its own way of providing gRPC capabilities for the language. As many other languages, ballerina supports generating server and client codes using the proto file using `bal grpc` command. You can view the proto file here. Ballerina has services and clients as a first class construct and gRPC builds upon that foundation. You can compare the original golang code and ballerina code below.
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
The usecase is to store user’s shopping cart details. The type of the store will be decided by the configurables loaded into the application by the factory. In memory and redis store is supported in the sample. You can find the code sample below.
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

## Search products using query expressions - Catalog Service
Product catalog service contains all the details of avaiable products. The requirement is to get the products similar to the search query. You can find the original implementation below.

```go
func (p *productCatalog) SearchProducts(ctx context.Context, req *pb.SearchProductsRequest) (*pb.SearchProductsResponse, error) {
	time.Sleep(extraLatency)
	// Intepret query as a substring match in name or description.
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

Even tough we can implement the same using ballerina using foreach statement, we have used ballerina query expression to implement the search function. Query expressions contain a set of clauses similar to SQL to process the data.
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

You can read more about Query expressions in this blog. You can have much more complicated queries using limit,let keywords, ordering, joins and so on. You can use query expressions not only for arrays but for streams, and tables as well.


## Concurrency safety - Ad Service
Ballerina is designed for network based applications. The concept of isolation in Ballerina simplifies development by ensuring the safety of shared resources during concurrent execution. Ballerina Compiler warns if the application is not concurrent safe and helps to make it concurrent safe and performant at the same time. The following code shows how a class is marked as readonly so by default compiler makes enables concurrent calls to its objects.
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
You can read this blog for more information about isolation concepts.

## Coordinating with multiple services and Configurables - Checkout Service
Microservices often requires to communicate with other services to get a specific task done. Checkout service coordinates with cart service, catalog service, currency service, shipping service payment service and email service to perform the checkout. 

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
As you shown in above code, ballerina make it very easy to invoke other microservices, log and handle errors. Configurable feature helps to configure the value of the variable by overriding in the runtime. This will be explained in depth in the testing and deployment sections of this article.

## HTML generation with XML - Email Service
Email service is responsible for generating a confirmation email with order details, tracking details. Ballerina’s built in XML feature is used for generating HTML code required for the email. You can see the below code to see how the if blocks, loops, concat, variables used in xml to create the html page.

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

## Testing Microservices - Recommendation Service
Microservices are Loosely coupled, Independently deployable units. These units should be tested before we integrate them with other microservices. Ballerina’s test framework allows you to test your microservices effortlessly.
First we need to make sure the catalogUrl is marked as configurable. 

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

In the tests directory you need to create a Config.toml and override that variable with mock url. This allows you to point to another service in the testing phase. 
```toml
catalogUrl="http://localhost:8989"
```

You can define a mock service to represent the catalog service in the test file and execute the test based on that.

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

Ballerina has object mocking features that allows you to do this without even running a service. You can read in depth about object mocking here
