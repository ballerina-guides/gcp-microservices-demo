import { Fragment, useEffect } from 'react';
import Header from '../components/new/Header';
import Footer from '../components/new/Footer';
import Product from '../components/new/Product';
import LoadingSpinner from '../components/UI/LoadingSpinner';
import NoQuotesFound from '../components/quotes/NoQuotesFound';
import useHttp from '../hooks/use-http';
import { getHomePage } from '../lib/api';

const HomePage = () => {
    const { sendRequest, status, data: homeData, error } = useHttp(
        getHomePage,
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

    //   if (status === 'completed' && (!loadedQuotes || loadedQuotes.length === 0)) {
    //     return <NoQuotesFound />;
    //   }

    //   return <QuoteList quotes={loadedQuotes} />;
    let data = homeData;
    // let data = {
    //     session_id :"user 1",
    //     request_id : "req 1",
    //     user_currency : "usd",
    //     show_currency : true,
    //     currencies :["USD", "EUR", "YEN"],
    //     cart_size: 5,
    //     banner_color : "red",
    //     platform_css : "local",
    //     platform_name : "local",
    //     is_cymbal_brand : false,
    //     products :[{
    //         product: {
    //             "id": "OLJCESPC7Z",
    //             "name": "Sunglasses",
    //             "description": "Add a modern touch to your outfits with these sleek aviator sunglasses.",
    //             "picture": "/static/img/products/sunglasses.jpg"
    //         },
    //         price: "$10.99"
    //     }, {
    //         product: {
    //             "id": "66VCHSJNUP",
    //             "name": "Tank Top",
    //             "description": "Perfectly cropped cotton tank, with a scooped neckline.",
    //             "picture": "/static/img/products/tank-top.jpg",
    //         },
    //         price: "$15.99"
    //     }, {
    //         product: {
    //             "id": "1YMWWN1N4O",
    //             "name": "Watch",
    //             "description": "This gold-tone stainless steel watch will work with most of your outfits.",
    //             "picture": "/static/img/products/watch.jpg",
    //         },
    //         price: "$20.99"
    //     }],
    //     ad : {
    //         redirect_url: "/product/66VCHSJNUP",
    //         text: "Buy this thingg"
    //     },
    // }

    const items = []
    for (const [index, value] of data.products.entries()) {
        items.push(<Product key={index} id={value.id} picture={value.picture} name={value.name} price={value.price} />)
    }


    return <Fragment>
        <Header/>
        <div class="local">
            <span class="platform-flag">
                local
            </span>
        </div>
        <main role="main" class="home">

            <div class="home-mobile-hero-banner d-lg-none"></div>

            <div class="container-fluid">
                <div class="row">
                    <div class="col-4 d-none d-lg-block home-desktop-left-image"></div>

                    <div class="col-12 col-lg-8">

                        <div class="row hot-products-row px-xl-6">

                            <div class="col-12">
                                <h3>Hot Products</h3>
                            </div>
                            {items}
                        </div>

                        <div class="row d-none d-lg-block home-desktop-footer-row">
                            <div class="col-12 p-0">
                                <Footer></Footer>
                            </div>
                        </div>

                    </div>

                </div>
            </div>

        </main>

        <div class="d-lg-none">
            <Footer></Footer>
        </div>

    </Fragment>
};

export default HomePage;
