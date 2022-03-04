import { Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import Product from './pages/Product';
import Cart from './pages/Cart';
import NotFound from './pages/NotFound';
function App() {

  return (
      <Routes>
        <Route path='/' element={<Home />}>
        </Route>
        <Route path='/product/:productId' element={<Product />}>
        </Route>
        <Route path='/cart' element={<Cart />}>
        </Route>
        <Route path='*' element= {<NotFound />}>
        </Route>
      </Routes>
  );
}

export default App;
