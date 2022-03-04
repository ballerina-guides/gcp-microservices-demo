import ballerina/test;

@test:Config {}
function paymentTest() returns error? {
    PaymentServiceClient ep = check new ("http://localhost:9096");
    ChargeRequest req = {
        amount: {
            currency_code: "USD",
            units: 5,
            nanos: 990000000
        },
        credit_card: {
            credit_card_number: "4432-8015-6152-0454",
            credit_card_cvv: 123,
            credit_card_expiration_year: 2023,
            credit_card_expiration_month: 10
        }
    };
    ChargeResponse chargeResponse = check ep->Charge(req);
    test:assertTrue(chargeResponse.transaction_id.length() > 1);
}
