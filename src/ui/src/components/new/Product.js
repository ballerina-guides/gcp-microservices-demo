const Product = (props) => {
    return (
    <div class="col-md-4 hot-product-card">
        <a href={`/product/${props.id}`}>
          <img alt="" src={`${process.env.PUBLIC_URL + props.picture}`}></img>
          <div class="hot-product-card-img-overlay"></div>
        </a>
        <div>
          <div class="hot-product-card-name">{props.name}</div>
          <div class="hot-product-card-price">{props.price}</div>
        </div>
      </div>
    );
  };
  
  export default Product;
  