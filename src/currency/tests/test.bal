import ballerina/test;

@test:Config {}
function currencyExchangeTest() returns error? {
    CurrencyServiceClient ep = check new ("http://localhost:9093");
    Empty req = {};
    GetSupportedCurrenciesResponse getSupportedCurrenciesResponse = check ep->GetSupportedCurrencies(req);
    test:assertEquals(getSupportedCurrenciesResponse.currency_codes.length(), 33);

    CurrencyConversionRequest reqq = {
        'from: {
            currency_code: "USD",
            units: 18,
            nanos: 990000000
        },
        to_code: "EUR"
    };
    Money money = check ep->Convert(reqq);
    test:assertEquals(money.currency_code, "EUR");
    test:assertEquals(money.nanos, 797877045);
    test:assertEquals(money.units, 16);
}
