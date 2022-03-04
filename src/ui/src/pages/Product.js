import { Fragment, useEffect, useRef } from 'react';
import Header from '../components/new/Header';
import Footer from '../components/new/Footer';
import LoadingSpinner from '../components/UI/LoadingSpinner';
import useHttp from '../hooks/use-http';
import { getSingleProduct, addProductToCart } from '../lib/api';
import Recommendations from '../components/new/Recommendations';
import Ad from '../components/new/Ad';
import { useParams, useNavigate } from 'react-router-dom';

const Product = () => {
    
    const params = useParams();
    const quantityRef = useRef();
    const navigate = useNavigate();

    const { productId } = params;

    function submitFormHandler(event) {
        event.preventDefault();

        const quantity = quantityRef.current.value;

        addProductToCart({ quantity: parseInt(quantity), productId: productId }).finally(()=>{
            navigate("/cart");
        })
    }

    const { sendRequest, status, data: loadedProduct, error } = useHttp(
        getSingleProduct,
        true
    );

    useEffect(() => {
        sendRequest(productId);
    }, [sendRequest, productId]);

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



    let data = loadedProduct

    let product = data.product;
    let recommendations = data.recommendations;

    return <Fragment>
        <Header/>
        <div class="local">
            <span class="platform-flag">
                local
            </span>
        </div>
        <main role="main">
            <div class="h-product container">
                <div class="row">
                    <div class="col-md-6">
                        <img class="product-image" alt="" src={`${process.env.PUBLIC_URL + product.picture}`} />
                    </div>
                    <div class="product-info col-md-5">
                        <div class="product-wrapper">

                            <h2>{product.id}</h2>
                            <p class="product-price">{product.price}</p>
                            <p>{product.description}</p>

                            <form onSubmit={submitFormHandler}>
                                <input type="hidden" name="product_id" value={product.id} />
                                <div class="product-quantity-dropdown">
                                    <select name="quantity" id="quantity" ref={quantityRef}>
                                        <option>1</option>
                                        <option>2</option>
                                        <option>3</option>
                                        <option>4</option>
                                        <option>5</option>
                                        <option>10</option>
                                    </select>
                                    <img src={process.env.PUBLIC_URL + "/static/icons/Hipster_DownArrow.svg"} alt="" />
                                </div>
                                <button type="submit" class="cymbal-button-primary">Add To Cart</button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
            <div>
                {recommendations.length > 0 &&
                    <Recommendations values={recommendations} ></Recommendations>
                }
            </div>
            <div class="ad">
                <Ad redirect_url={data.ad.redirect_url} text={data.ad.text}></Ad>
            </div>
        </main>

        <Footer></Footer>
    </Fragment>
};

export default Product;
