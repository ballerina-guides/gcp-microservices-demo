import Recommendation from './Recommendation';
const Recommendations = (props) => {
    let values = [props.values];
    const items = []

    for (let index = 0; index < values[0].length; ++index) {
        const value = values[0][index];
        items.push(<Recommendation key={index} id={value.id} picture={value.picture} name={value.name}> </Recommendation>)
    }
    
    return (
    <section class="recommendations">
        <div class="container">
          <div class="row">
            <div class="col-xl-10 offset-xl-1">
              <h2>You May Also Like</h2>
              <div class="row">
                  {items}
              </div>
            </div>
          </div>
        </div>
    </section>
    );
  };
  
  export default Recommendations;
  