import './App.css';
import { BrowserRouter, Routes, Route, Outlet } from 'react-router-dom';
import HomePage from './pages/home/HomePage.tsx';
import Nav from './components/navbar/navbar.tsx';

function Layout() {
  return (
    <>
      <Nav />
      <Outlet />
    </>
  );
}

function App() {
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