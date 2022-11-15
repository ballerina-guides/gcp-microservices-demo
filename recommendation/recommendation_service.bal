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

import ballerina/grpc;
import ballerina/log;
import ballerinax/jaeger as _;

configurable string catalogHost = "localhost";
configurable decimal catalogTimeout = 3;

# Recommends other products based on the items added to the user’s cart.
@display {
    label: "Recommendation",
    id: "recommendation"
}
@grpc:Descriptor {value: DEMO_DESC}
service "RecommendationService" on new grpc:Listener(9090) {
    @display {
        label: "Catalog",
        id: "catalog"
    }
    private final ProductCatalogServiceClient catalogClient;

    function init() returns error? {
        self.catalogClient = check new (string `http://${catalogHost}:9091`, timeout = catalogTimeout);
    }

    # Provides a product list according to the request.
    #
    # + request - `ListRecommendationsRequest` containing product ids
    # + return - `ListRecommendationsResponse` containing the recommended product ids
    remote function ListRecommendations(ListRecommendationsRequest request)
    returns ListRecommendationsResponse|error {
        ListProductsResponse|grpc:Error listProducts = self.catalogClient->ListProducts({});
        if listProducts is grpc:Error {
            log:printError("failed to call ListProducts of catalog service", 'error = listProducts);
            return error grpc:InternalError("failed to get list of products from catalog service", listProducts);
        }

        return {
            product_ids: from Product product in listProducts.products
                where request.product_ids.indexOf(product.id) is ()
                limit 5
                select product.id
        };
    }
}
