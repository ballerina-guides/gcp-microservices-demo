import ballerina/test;

@test:Config {}
function emailSendTest() returns error? {
    EmailServiceClient ep = check new ("http://localhost:9097");
    Money cost = {
        currency_code: "USD",
        nanos: 900000000,
        units: 5
    };

    Address address = {
        street_address: "56, Palm grove",
        city: "Colombo",
        country: "Sri Lanka",
        state: "Western",
        zip_code: 10300
    };

    OrderItem item1 = {
        item: {
            product_id: "1",
            quantity: 2
        },
        cost: cost
    };

    OrderItem item2 = {
        item: {
            product_id: "2",
            quantity: 1
        },
        cost: cost
    };

    SendOrderConfirmationRequest req = {
        email: "anjanasupun05@gmail.com",
        'order: {
            order_id: "1",
            shipping_tracking_id: "2323",
            shipping_cost: cost,
            shipping_address: address,
            items: [item1, item2]
        }
    };
    _ = check ep->SendOrderConfirmation(req);

}
