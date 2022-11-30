# Ads Service

The Ads service loads a set of ads based on the category when the service is initialized and then serves ads based on the products in the cart.
The Ad Store represents a read only class as these ads are not updated after the service is initialized. This allows us to access the ad store without lock statements allowing the concurrent calls to the service.

```bal
readonly class AdStore {

    final map<Ad[]> & readonly ads;

    isolated function init() {
        self.ads =  getAds().cloneReadOnly();
    }

    public isolated function getRandomAds() returns Ad[]|error {
        ...
    }

    public isolated function getAdsByCategory(string category) returns Ad[] {
        ...
    }
}

isolated function getAds() returns map<Ad[]> {
    return {
        "clothing": [tankTop],
        "accessories": [watch],
        "footwear": [loafers],
        "hair": [hairdryer],
        "decor": [candleHolder],
        "kitchen":[bambooGlassJar, mug]
    };
}
```
