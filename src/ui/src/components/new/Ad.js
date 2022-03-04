const Ad = (props) => {
    return (
    <div class="container py-3 px-lg-5 py-lg-5">
        <div role="alert">
            <strong>Ad</strong>
            <a href={props.redirect_url} rel="nofollow" target="_blank">
                {props.text}
            </a>
        </div>
    </div>
    );
  };
  
  export default Ad;
  