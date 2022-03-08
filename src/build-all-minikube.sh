#!/usr/bin/env bash
# Copyright 2022 WSO2 Inc. (http://wso2.org)
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

( cd cart ; eval $(minikube docker-env) ; bal build)
( cd currency ; eval $(minikube docker-env) ; bal build)
( cd email ; eval $(minikube docker-env) ; bal build)
( cd payment ; eval $(minikube docker-env) ; bal build)
( cd productcatalog ; eval $(minikube docker-env) ; bal build)
( cd recommendation ;eval $(minikube docker-env);  bal build)
( cd shipping ; eval $(minikube docker-env); bal build)
( cd ads ; eval $(minikube docker-env) ; bal build)
( cd checkout ; eval $(minikube docker-env) ; bal build)
( cd frontend ; eval $(minikube docker-env) ; bal build)
