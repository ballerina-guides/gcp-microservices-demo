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

import CurrencyOption from './CurrencyOption';
import {  useState, useEffect } from 'react';
import { getMetadata } from '../../lib/api';

const Header = () => {
    const [myData, setMyData] =  useState({
        cart_size : 0,
        currencies : ["USD","EUR"],
        is_cymbal_brand : false,
        user_currency : "USD",
      });
    
      useEffect(() => {
        getMetadata().then((data)=> {
          setMyData(data)
        })
      }, []);

    let image = <img src={process.env.PUBLIC_URL + "/static/icons/Hipster_NavLogo.svg"} alt="" className="top-left-logo" />;
    if (myData.is_cymbal_brand) {
        image = <img src={process.env.PUBLIC_URL + "/static/icons/Cymbal_NavLogo.svg"} alt="" className="top-left-logo-cymbal" />;
    }

    const items = []
    for (const value of myData.currencies.values()) {
        items.push(<CurrencyOption user_currency={value} />)
    }

    let currencyInfo = <div className="h-controls">
            <div className="h-control">
                <span className="icon currency-icon"> {myData.user_currency}</span>
                <form method="POST" className="controls-form" action="/setCurrency" id="currency_form" >
                    <select name="currency_code" onchange="document.getElementById('currency_form').submit();">
                        {items}
                    </select>
                </form>
                <img src={process.env.PUBLIC_URL + "/static/icons/Hipster_DownArrow.svg"} alt="" className="icon arrow" />
            </div>
        </div>;
    let cartSize;
    if (myData.cart_size) {
        cartSize = <span className="cart-size-circle">{myData.cart_size}</span>
    }
    return (
        <header>
            <div className="navbar">
                <div className="container d-flex justify-content-center">
                    <div className="h-free-shipping">Free shipping with $75 purchase!</div>
                </div>
            </div>
            <div className="navbar sub-navbar">
                <div className="container d-flex justify-content-between">
                    <a href="/" className="navbar-brand d-flex align-items-center">
                        {image}
                    </a>
                    <div className="controls">
                        {currencyInfo}
                        <a href="/cart" className="cart-link">
                            <img src={process.env.PUBLIC_URL + "/static/icons/Hipster_CartIcon.svg"} alt="Cart icon" className="logo" title="Cart" />
                            {cartSize}
                        </a>
                    </div>
                </div>
            </div>
        </header>
    );
};

export default Header;
