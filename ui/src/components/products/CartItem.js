/*
 *  Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

const CartItem = (props) => {
    return (
        <div class="row cart-summary-item-row">
        <div class="col-md-4 pl-md-0">
            <a href={`/product/${props.id}`}>
                <img class="img-fluid" alt="" src={process.env.PUBLIC_URL + props.picture} />
            </a>
        </div>
        <div class="col-md-8 pr-md-0">
            <div class="row">
                <div class="col">
                    <h4>{props.name}</h4>
                </div>
            </div>
            <div class="row cart-summary-item-row-item-id-row">
                <div class="col">
                    SKU #{props.id}
                </div>
            </div>
            <div class="row">
                <div class="col">
                    Quantity: {props.quantity}
                </div>
                <div class="col pr-md-0 text-right">
                    <strong>
                        {props.price}
                    </strong>
                </div>
            </div>
        </div>
    </div>
    );
  };
  
  export default CartItem;
  