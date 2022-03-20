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

import { Fragment, useEffect, useRef, useState } from 'react';
import Header from '../components/products/Header';
import Footer from '../components/products/Footer';
import CartItem from "../components/products/CartItem";
import ExpireOptionPicker from "../components/products/ExpireOptionPicker";
import LoadingSpinner from '../components/UI/LoadingSpinner';
import useHttp from '../hooks/use-http';
import { getCartPage, checkout } from '../lib/api';
import Recommendations from '../components/products/Recommendations';
import Order from '../components/products/Order';

const CartPage = () => {
    const [isSubmitted, setSubmitted] = useState({});
    const emailRef = useRef();
    const addressRef = useRef();
    const zipRef = useRef();
    const cityRef = useRef();
    const stateRef = useRef();
    const countryRef = useRef();
    const cardNumberRef = useRef(); 
    const expireMonthRef = useRef();
    const expireYearRef = useRef();
    const cvvRef = useRef();

    async function submitFormHandler(event) {
        event.preventDefault();

        const email = emailRef.current.value;
        const address = addressRef.current.value;
        const zip = zipRef.current.value;
        const city = cityRef.current.value;
        const state = stateRef.current.value;
        const country = countryRef.current.value;
        const cardNumber = cardNumberRef.current.value;
        const expireMonth = expireMonthRef.current.value;
        const expireYear = expireYearRef.current.value;
        const cvv = cvvRef.current.value;

        let data = {
            email: email,
            street_address : address,
            zip_code: parseInt(zip),
            city : city,
            state : state,
            country : country,
            credit_card_number : cardNumber,
            credit_card_expiration_month : parseInt(expireMonth),
            credit_card_expiration_year : parseInt(expireYear),
            credit_card_cvv : parseInt(cvv)
        }
        let data1 = await checkout(data);
        setSubmitted(data1);
    }

    const { sendRequest, status, data: cartData, error } = useHttp(
        getCartPage,
        true
    );

      useEffect(() => {
        sendRequest();
      }, [sendRequest]);

      if (status === 'pending') {
        return (
          <div className='centered'>
            <LoadingSpinner />
          </div>
        );
      }

      if (error) {
        return <p className='centered focused'>{error}</p>;
      }

      let data = cartData;
    // let data = {
    //     session_id: "user 1",
    //     request_id: "req 1",
    //     user_currency: "usd",
    //     show_currency: true,
    //     currencies: ["USD", "EUR", "YEN"],
    //     cart_size: 5,
    //     banner_color: "red",
    //     platform_css: "local",
    //     platform_name: "local",
    //     is_cymbal_brand: false,
    //     recommendations: [{
    //         "id": "L9ECAV7KIM",
    //         "name": "Loafers",
    //         "description": "A neat addition to your summer wardrobe.",
    //         "picture": "/static/img/products/loafers.jpg",
    //     }, {
    //         "id": "2ZYFJ3GM2N",
    //         "name": "Hairdryer",
    //         "description": "This lightweight hairdryer has 3 heat and speed settings. It's perfect for travel.",
    //         "picture": "/static/img/products/hairdryer.jpg",
    //     }],
    //     items: [{
    //         product: {
    //             id: "OLJCESPC7Z",
    //             name: "Sunglasses",
    //             description: "Add a modern touch to your outfits with these sleek aviator sunglasses.",
    //             picture: "/static/img/products/sunglasses.jpg"
    //         },
    //         price: "15.99$",
    //         quantity: 2
    //     }, {
    //         product: {
    //             id: "66VCHSJNUP",
    //             name: "Tank Top",
    //             description: "Perfectly cropped cotton tank, with a scooped neckline.",
    //             picture: "/static/img/products/tank-top.jpg",
    //         },
    //         price: "10.00$",
    //         quantity: 2
    //     }],
    //     shipping_cost: "$9.99",
    //     total_cost: "$35.99",
    //     expiration_years: [2022, 2023, 2024, 2025]
    // }

    let cart = data.items;

    let recommendations = data.recommendations

    let shippingCost = data.shipping_cost
    let totalCost = data.total_cost

    const cartItemsList = []
    for (const [index, val] of cart.entries()) {
        let value = val.product
        cartItemsList.push(<CartItem key={index} id={value.id} picture={value.picture} name={value.name} price={val.price} quantity={val.quantity} />)
    }


    let expireOptionList = []
    for (const [index, value] of data.expiration_years.entries()) {
        expireOptionList.push(<ExpireOptionPicker key={index} year={value} />)
    }

    let cartBlock = <section class="empty-cart-section">
        <h3>Your shopping cart is empty!</h3>
        <p>Items you add to your shopping cart will appear here.</p>
        <a class="cymbal-button-primary" href="/" role="button">Continue Shopping</a>
    </section>;

    if (cart.length > 0) {
        cartBlock = <section class="container">
            <div class="row">

                <div class="col-lg-6 col-xl-5 offset-xl-1 cart-summary-section">

                    <div class="row mb-3 py-2">
                        <div class="col-4 pl-md-0">
                            <h3>Cart ({cart.length})</h3>
                        </div>
                        <div class="col-8 pr-md-0 text-right">
                            <form method="POST" action="/cart/empty">
                                <button class="cymbal-button-secondary cart-summary-empty-cart-button" type="submit">
                                    Empty Cart
                                </button>
                                <a class="cymbal-button-primary" href="/" role="button">
                                    Continue Shopping
                                </a>
                            </form>
                        </div>
                    </div>
                    {cartItemsList}
                    <div class="row cart-summary-shipping-row">
                        <div class="col pl-md-0">Shipping</div>
                        <div class="col pr-md-0 text-right">{shippingCost}</div>
                    </div>

                    <div class="row cart-summary-total-row">
                        <div class="col pl-md-0">Total</div>
                        <div class="col pr-md-0 text-right">{totalCost}</div>
                    </div>

                </div>

                <div class="col-lg-5 offset-lg-1 col-xl-4">

                    <form class="cart-checkout-form" onSubmit={submitFormHandler}>

                        <div class="row">
                            <div class="col">
                                <h3>Shipping Address</h3>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="col cymbal-form-field">
                                <label for="email">E-mail Address</label>
                                <input type="email" id="email"
                                    name="email" value="someone@example.com" required ref={emailRef}/>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="col cymbal-form-field">
                                <label for="street_address">Street Address</label>
                                <input type="text" name="street_address"
                                    id="street_address" value="1600 Amphitheatre Parkway" required ref={addressRef}/>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="col cymbal-form-field">
                                <label for="zip_code">Zip Code</label>
                                <input type="text"
                                    name="zip_code" id="zip_code" value="94043" required pattern="\d{4,5}" ref={zipRef}/>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="col cymbal-form-field">
                                <label for="city">City</label>
                                <input type="text" name="city" id="city"
                                    value="Mountain View" required ref={cityRef}/>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="col-md-5 cymbal-form-field">
                                <label for="state">State</label>
                                <input type="text" name="state" id="state"
                                    value="CA" required ref={stateRef}/>
                            </div>
                            <div class="col-md-7 cymbal-form-field">
                                <label for="country">Country</label>
                                <input type="text" id="country"
                                    placeholder="Country Name"
                                    name="country" value="United States" required ref={countryRef}/>
                            </div>
                        </div>

                        <div class="row">
                            <div class="col">
                                <h3 class="payment-method-heading">Payment Method</h3>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="col cymbal-form-field">
                                <label for="credit_card_number">Credit Card Number</label>
                                <input type="text" id="credit_card_number"
                                    name="credit_card_number"
                                    placeholder="0000-0000-0000-0000"
                                    value="4432-8015-6152-0454"
                                    required pattern="\d{4}-\d{4}-\d{4}-\d{4}" ref={cardNumberRef}/>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="col-md-5 cymbal-form-field">
                                <label for="credit_card_expiration_month">Month</label>
                                <select name="credit_card_expiration_month" id="credit_card_expiration_month" ref={expireMonthRef}>
                                    <option value="1">January</option>
                                    <option value="2">February</option>
                                    <option value="3">March</option>
                                    <option value="4">April</option>
                                    <option value="5">May</option>
                                    <option value="6">June</option>
                                    <option value="7">July</option>
                                    <option value="8">August</option>
                                    <option value="9">September</option>
                                    <option value="10">October</option>
                                    <option value="11">November</option>
                                    <option value="12" selected>December</option>
                                </select>
                                <img src={process.env.PUBLIC_URL + "/static/icons/Hipster_DownArrow.svg"} alt="" class="cymbal-dropdown-chevron" />
                            </div>
                            <div class="col-md-4 cymbal-form-field">
                                <label for="credit_card_expiration_year">Year</label>
                                <select name="credit_card_expiration_year" id="credit_card_expiration_year" ref={expireYearRef}>
                                    {expireOptionList}
                                </select>
                                <img src={process.env.PUBLIC_URL + "/static/icons/Hipster_DownArrow.svg"} alt="" class="cymbal-dropdown-chevron" />
                            </div>
                            <div class="col-md-3 cymbal-form-field">
                                <label for="credit_card_cvv">CVV</label>
                                <input type="password" id="credit_card_cvv"
                                    name="credit_card_cvv" value="672" required pattern="\d{3}" ref={cvvRef}/>
                            </div>
                        </div>

                        <div class="form-row justify-content-center">
                            <div class="col text-center">
                                <button class="cymbal-button-primary" type="submit">
                                    Place Order
                                </button>
                            </div>
                        </div>

                    </form>

                </div>

            </div>
        </section>
    }
    let contents = <main role="main" class="cart-sections">
    {cartBlock}
</main>;

    if (Object.keys(isSubmitted).length !== 0) {
        contents = <Order orderId={isSubmitted.order.order_id} shippingTrackingId={isSubmitted.order.shipping_tracking_id} totalPaid={isSubmitted.total_paid}></Order>;
    }

    return <Fragment>
        <Header/>
        <div class="local">
            <span class="platform-flag">
                local
            </span>
        </div>
        {contents}
        <div>
            {recommendations.length > 0 &&
                <Recommendations values={recommendations} ></Recommendations>
            }
        </div>

        <Footer></Footer>
    </Fragment>
};

export default CartPage;
