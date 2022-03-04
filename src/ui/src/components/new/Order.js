import { Fragment } from 'react';

const Order = (props) => {
    let orderId = props.orderId;
    let shippingTrackingId = props.shippingTrackingId;
    let totalPaid = props.totalPaid;

    return <Fragment>
        <main role="main" class="order">

<section class="container order-complete-section">
    <div class="row">
        <div class="col-12 text-center">
            <h3>
                Your order is complete!
            </h3>
        </div>
        <div class="col-12 text-center">
            <p>We've sent you a confirmation email.</p>
        </div>
    </div>
    <div class="row border-bottom-solid padding-y-24">
        <div class="col-6 pl-md-0">
            Confirmation #
        </div>
        <div class="col-6 pr-md-0 text-right">
            {orderId}
        </div>
    </div>
    <div class="row border-bottom-solid padding-y-24">
        <div class="col-6 pl-md-0">
            Tracking #
        </div>
        <div class="col-6 pr-md-0 text-right">
            {shippingTrackingId}
        </div>
    </div>
    <div class="row padding-y-24">
        <div class="col-6 pl-md-0">
            Total Paid
        </div>
        <div class="col-6 pr-md-0 text-right">
            {totalPaid}
        </div>
    </div>
    <div class="row">
        <div class="col-12 text-center">
            <a class="cymbal-button-primary" href="/" role="button">
                Continue Shopping
            </a>
        </div>
    </div>
</section>

</main>

    </Fragment>
};

export default Order;
