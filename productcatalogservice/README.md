# Product Catalog Service

The Catalog Service maintains a list of products available in the store. The product list will be read from JSON and converted to a readonly array of `Product` when the service is initialized. The `Catalog Service` has the Search Product capability. This feature is implemented using ballerina query expressions. It allows you to write SQL like queries to filter data from the array. You can find more details about query expressions in this [blog](https://dzone.com/articles/language-integrated-queries-in-ballerina).

```bal
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
