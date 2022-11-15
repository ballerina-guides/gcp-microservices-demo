// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/grpc;
import wso2/'client.stub;

@grpc:Descriptor {value: stub:DEMO_DESC}
service "ProductCatalogService" on new grpc:Listener(9091) {
    remote function ListProducts(stub:Empty value) returns stub:ListProductsResponse {
        return {
            products: [
                {
                    id: "test id",
                    categories: ["watch", "clothes"],
                    description: "Test description",
                    name: "test name",
                    picture: "",
                    price_usd: {
                        currency_code: "USD",
                        nanos: 900000000,
                        units: 5
                    }
                }
            ]
        };
    }

    remote function GetProduct(stub:GetProductRequest value) returns stub:Product|error {
        return error("method not implemented");
    }

    remote function SearchProducts(stub:SearchProductsRequest value) returns stub:SearchProductsResponse|error {
        return error("method not implemented");
    }
}

@test:Config {}
function recommendTest() returns error? {
    stub:RecommendationServiceClient ep = check new ("http://localhost:9090");
    stub:ListRecommendationsRequest req = {
        user_id: "1",
        product_ids: ["2ZYFJ3GM2N", "LS4PSXUNUM"]
    };
    stub:ListRecommendationsResponse listProducts = check ep->ListRecommendations(req);
    test:assertEquals(listProducts.product_ids.length(), 1);
}
