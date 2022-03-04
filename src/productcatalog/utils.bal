
isolated function parseProductJson(json jsonContents) returns Product[]|error {
    json productsJson = check jsonContents.products;
    if (productsJson !is json[]) {
        return error("product array is not found");
    }
    Product[] products = from json productJson in productsJson
        let Product product = {
            id: check productJson.id,
            name: check productJson.name,
            description: check productJson.description,
            picture: check productJson.picture,
            price_usd: check parseMoneyJson(check productJson.priceUsd),
            categories: check (check productJson.categories).cloneWithType()
        }
        select product;
    return products;
}

isolated function parseMoneyJson(json moenyJson) returns Money|error {
    return {
        currency_code: check moenyJson.currencyCode,
        units: check moenyJson.units,
        nanos: check moenyJson.nanos
    };
}

isolated function isProductRelated(Product product, string query) returns boolean {
    string queryLowercase = query.toLowerAscii();
    return product.name.toLowerAscii().includes(queryLowercase) || product.description.toLowerAscii().includes(queryLowercase);
}
