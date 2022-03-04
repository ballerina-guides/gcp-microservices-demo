import ballerina/test;
import ballerina/grpc;

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "ProductCatalogService" on new grpc:Listener(8989) {
    remote function ListProducts(Empty value) returns ListProductsResponse {
        return {
            products: [
                {
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
                }
            ]
        };
    }

    remote function GetProduct(GetProductRequest value) returns Product|error {
        return error("method not implemented");
    }

    remote function SearchProducts(SearchProductsRequest value) returns SearchProductsResponse|error {
        return error("method not implemented");
    }
}

@test:Config {}
function recommandTest() returns error? {
    RecommendationServiceClient ep = check new ("http://localhost:9090");
    ListRecommendationsRequest req = {
        user_id: "1",
        product_ids: ["2ZYFJ3GM2N", "LS4PSXUNUM"]
    };
    ListRecommendationsResponse listProducts = check ep->ListRecommendations(req);
    test:assertEquals(listProducts.product_ids.length(), 1);
}
