import ballerina/test;
@test:Config {}
function listProductsTest() returns error? {
    AdServiceClient adClient = check new ("http://localhost:9099");
    AdRequest request = {
        context_keys: []
    };

    AdResponse response = check adClient->GetAds(request);
    Ad[] expectedAds = [{
        redirect_url: "/product/1YMWWN1N4O",
        text: "Watch for sale. Buy one, get second kit for free"
    }];
    Ad[] receivedAds = [];
    response.ads.forEach(function (Ad ad) {
        receivedAds.push(ad);
    });
    test:assertEquals(receivedAds, expectedAds);
}
