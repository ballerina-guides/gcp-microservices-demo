import CurrencyOption from './CurrencyOption';
import {  useState, useEffect } from 'react';
import { getMetadata } from './../../lib/api';

const CommentItem = () => {
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
    for (const [index, value] of myData.currencies.entries()) {
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

export default CommentItem;
