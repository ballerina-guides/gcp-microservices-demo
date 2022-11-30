# Recommendation Service

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