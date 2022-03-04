import ballerina/test;

@test:Config {}
function shippingTest() returns error? {
    ShippingServiceClient ep = check new ("http://localhost:9095");
    GetQuoteRequest req1 = {
        address: {
            street_address: "Muffin Man",
            city: "London",
            state: "",
            country: "England"
        },
        items: [
            {
                product_id: "23",
                quantity: 1
            },
            {
                product_id: "46",
                quantity: 3
            }
        ]
    };
    GetQuoteResponse getQuoteResponse = check ep->GetQuote(req1);
    int units = getQuoteResponse.cost_usd.units;
    int nanos = getQuoteResponse.cost_usd.nanos;
    test:assertEquals(units, 8);
    test:assertEquals(nanos, 10000000);

    ShipOrderRequest req = {};
    ShipOrderResponse getSupportedCurrenciesResponse = check ep->ShipOrder(req);
    test:assertEquals(getSupportedCurrenciesResponse.tracking_id.length(), 18);
}
