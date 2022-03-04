import ballerina/grpc;
import ballerina/log;

listener grpc:Listener ep = new (9090);
configurable string catalogUrl = "localhost";

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "RecommendationService" on ep {
    final ProductCatalogServiceClient catalogClient;

    function init() returns error? {
        self.catalogClient = check new ("http://" + catalogUrl + ":9091");
    }

    isolated remote function ListRecommendations(ListRecommendationsRequest value) returns ListRecommendationsResponse|error {
        string[] productIds = value.product_ids;
        ListProductsResponse|grpc:Error listProducts = self.catalogClient->ListProducts({});
        if (listProducts is grpc:Error) {
            log:printError("failed to call ListProducts of catalog service", 'error = listProducts);
            return listProducts;
        }

        return {
            product_ids: from Product product in listProducts.products
                where productIds.indexOf(product.id) is ()
                select product.id
        };
    }
}
