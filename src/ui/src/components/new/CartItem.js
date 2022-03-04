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
  