import ballerina/http;

//Request Records
type AddToCartRequest record {|
    string productId;
    int quantity;
|};

type CheckoutRequest record {|
    string email;
    string street_address;
    int zip_code;
    string city;
    string state;
    string country;
    string credit_card_number;
    int credit_card_expiration_month;
    int credit_card_expiration_year;
    int credit_card_cvv;
|};

//Response Records

type CartItemView record {
    Product product;
    int quantity;
    string price;
};

type MetadataResponse record {|
    *http:Ok;
    MetadataBody body;
|};

type MetadataBody record {|
    string user_currency;
    string[] currencies;
    int cart_size;
    boolean is_cymbal_brand;
|};

type ProductLocalized record {|
    *Product;
    string price;
|};

type HomeResponse record {|
    *http:Ok;
    HomeBody body;
|};

type HomeBody record {|
    ProductLocalized[] products;
    Ad ad;
|};

type ProductResponse record {|
    *http:Ok;
    ProductBody body;
|};

type ProductBody record {|
    ProductLocalized product;
    Product[] recommendations;
    Ad ad;
|};

type CartResponse record {|
    *http:Ok;
    CartBody body;
|};

type CartBody record {|
    Product[] recommendations;
    string shipping_cost;
    string total_cost;
    CartItemView[] items;
    int[] expiration_years;
|};

type CheckoutResponse record {|
    *http:Ok;
    CheckoutBody body;
|};

type CheckoutBody record {|
    OrderResult 'order;
    string total_paid;
    Product[] recommendations;
|};
