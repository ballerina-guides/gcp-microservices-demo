const Recommendation = (props) => {
    return (
        <div class="col-md-3">
        <div>
          <a href={`/product/${props.id}`}>
            <img alt="" src={process.env.PUBLIC_URL + props.picture}/>
          </a>
          <div>
            <h5>
              {props.name}
            </h5>
          </div>
        </div>
      </div>
    );
  };
  
  export default Recommendation;
  