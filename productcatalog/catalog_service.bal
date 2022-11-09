// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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
import ballerina/io;

configurable string productJsonPath = "./resources/products.json";

@display {
    label: "",
    id: "catalog"
}
@grpc:Descriptor {value: DEMO_DESC}
service "ProductCatalogService" on new grpc:Listener(9091) {
    final Product[] & readonly products;

    function init() returns error? {
        json productsJson = check io:fileReadJson(productJsonPath);
        Product[] products = check parseProductJson(productsJson);
        self.products = products.cloneReadOnly();
    }

    remote function ListProducts(Empty request) returns ListProductsResponse {
        return {products: self.products};
    }

    remote function GetProduct(GetProductRequest request) returns Product|error {
        foreach Product product in self.products {
            if product.id == request.id {
                return product;
            }
        }
        return error grpc:NotFoundError(string `no product with ID ${request.id}`);
    }

    remote function SearchProducts(SearchProductsRequest request) returns SearchProductsResponse|error {
        return {
            results: from Product product in self.products
                where isProductRelated(product, request.query)
                select product
        };
    }
}
