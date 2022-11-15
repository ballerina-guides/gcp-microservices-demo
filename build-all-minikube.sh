#!/usr/bin/env bash
# Copyright 2022 WSO2 LLC. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

eval $(minikube docker-env)
( cd gcp.client.stub ; bal pack ; bal push --repository local)
( cd cart ; bal build --cloud=k8s)
( cd currency ; bal build --cloud=k8s)
( cd email ; bal build --cloud=k8s)
( cd payment ; bal build --cloud=k8s)
( cd productcatalog ; bal build --cloud=k8s)
( cd recommendation ; bal build --cloud=k8s)
( cd shipping ; bal build --cloud=k8s)
( cd ads ; bal build --cloud=k8s)
( cd checkout ; bal build --cloud=k8s)
( cd frontend ; bal build --cloud=k8s)
