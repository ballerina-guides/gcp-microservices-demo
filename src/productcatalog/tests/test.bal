import ballerina/test;

@test:Config {}
function catalogTest() returns error? {
    ProductCatalogServiceClient ep = check new ("http://localhost:9091");
    Empty req = {};
    ListProductsResponse listProducts = check ep->ListProducts(req);
    test:assertEquals(listProducts.products.length(), 9);
}
