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
  