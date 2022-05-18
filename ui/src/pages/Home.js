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

import { Fragment, useEffect } from 'react';
import Header from '../components/products/Header';
import Footer from '../components/products/Footer';
import Product from '../components/products/Product';
import LoadingSpinner from '../components/UI/LoadingSpinner';
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
    let data = homeData;

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
