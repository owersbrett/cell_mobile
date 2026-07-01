import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import { Home } from './components/Home';
import { ModuleView } from './components/ModuleView';

const router = createBrowserRouter([
  { path: '/', element: <Home /> },
  { path: '/lesson/:id', element: <ModuleView /> },
]);

export default function App() {
  return <RouterProvider router={router} />;
}
