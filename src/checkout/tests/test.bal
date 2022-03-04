import ballerina/test;
import ballerina/io;
@test:Config {}
function intAddTest() returns error? {
    CheckoutServiceClient ep = check new ("http://localhost:9094");
    //Populate cart first.
    CartServiceClient ep1 = check new ("http://localhost:9092");
    //Add Cart
    AddItemRequest item1 = {user_id: "3", item: {product_id: "OLJCESPC7Z", quantity: 1}};
    _ = check ep1->AddItem(item1);

    PlaceOrderRequest req = {
        user_id: "3",
        address: {
            country: "Sri lanka",
            city: "Colombo",
            state: "Western",
            street_address: "56,Palm Grove",
            zip_code: 10300
        },
        credit_card: {
            credit_card_number: "4444444444444448",
            credit_card_cvv: 123,
            credit_card_expiration_year: 2023,
            credit_card_expiration_month: 10

        },
        email: "anjanasupun05@gmail.com",
        user_currency: "USD"
    };
    PlaceOrderResponse placeOrderResponse = check ep->PlaceOrder(req);
    io:println (placeOrderResponse.'order);
    test:assertTrue(placeOrderResponse.'order.length()>1);
}
