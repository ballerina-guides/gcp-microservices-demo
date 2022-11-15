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

( cd cart ; bal build --cloud=docker)
( cd currency ; bal build --cloud=docker)
( cd email ; bal build --cloud=docker)
( cd payment ; bal build --cloud=docker)
( cd productcatalog ; bal build --cloud=docker)
( cd recommendation ; bal build --cloud=docker)
( cd shipping ; bal build --cloud=docker)
( cd ads ; bal build --cloud=docker)
( cd checkout ; bal build --cloud=docker)
( cd frontend ; bal build --cloud=docker)
