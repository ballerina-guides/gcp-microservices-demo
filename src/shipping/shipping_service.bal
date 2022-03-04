import ballerina/grpc;

listener grpc:Listener ep = new (9095);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "ShippingService" on ep {
    final float SHIPPING_COST = 8.99;

    isolated remote function GetQuote(GetQuoteRequest value) returns GetQuoteResponse|error {
        CartItem[] items = value.items;
        int count = 0;
        float cost = 0.0;
        foreach CartItem item in items {
            count += item.quantity;
        }

        if (count != 0) {
            cost = self.SHIPPING_COST;
        }
        float cents = cost % 1;
        int dollars = <int>(cost - cents);

        Money money = {currency_code: "USD", nanos: <int>cents * 10000000, units: dollars};

        return {
            cost_usd: money
        };
    }
    isolated remote function ShipOrder(ShipOrderRequest value) returns ShipOrderResponse|error {
        Address ress = value.address;
        string baseAddress = ress.street_address + ", " + ress.city + ", " + ress.state;
        string trackingId = generateTrackingId(baseAddress);
        return {tracking_id: trackingId};
    }
}

