import ballerina/grpc;
import ballerina/io;

listener grpc:Listener ep = new (9091);
configurable string productJsonPath = "./resources/products.json";

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "ProductCatalogService" on ep {
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
