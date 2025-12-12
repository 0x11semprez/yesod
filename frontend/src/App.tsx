import './App.css';
import { BrowserRouter, Routes, Route, Outlet } from 'react-router-dom';

import HomePage from './pages/home/HomePage.tsx';
import NavBar from './components/navbar/NavBar.tsx';

const Layout = () => {
  return (
    <>
      <NavBar />
      <Outlet />
    </>
  );
}

const App = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<HomePage />} />
          <Route path="*" element={<div>404 (route not found)</div>} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}


export default App;