import {
  Navigate,
  Outlet,
  Route,
  Routes,
} from "react-router";

import "./App.css";

import {
  useAdminAuth,
} from "./auth/admin_auth_context";
import {
  AdminLayout,
} from "./layouts/admin_layout";
import {
  AdminAgentPage,
} from "./pages/admin_agent_page";
import {
  AdminCategoriesPage,
} from "./pages/admin_categories_page";
import {
  AdminDashboardPage,
} from "./pages/admin_dashboard_page";
import {
  AdminInventoryPage,
} from "./pages/admin_inventory_page";
import {
  AdminLoginPage,
} from "./pages/admin_login_page";
import {
  AdminOrdersPage,
} from "./pages/admin_orders_page";
import {
  AdminProductsPage,
} from "./pages/admin_products_page";

function RequireAdmin() {
  const { status } = useAdminAuth();

  if (status === "loading") {
    return (
      <main className="loading-page">
        <div className="loading-spinner" />
        <p>正在恢复管理员会话...</p>
      </main>
    );
  }

  if (status === "unauthenticated") {
    return (
      <Navigate
        to="/login"
        replace
      />
    );
  }

  return <Outlet />;
}

function GuestOnly() {
  const { status } = useAdminAuth();

  if (status === "loading") {
    return (
      <main className="loading-page">
        <div className="loading-spinner" />
        <p>正在恢复管理员会话...</p>
      </main>
    );
  }

  if (status === "authenticated") {
    return (
      <Navigate
        to="/"
        replace
      />
    );
  }

  return <Outlet />;
}

function App() {
  return (
    <Routes>
      <Route element={<GuestOnly />}>
        <Route
          path="/login"
          element={<AdminLoginPage />}
        />
      </Route>

      <Route element={<RequireAdmin />}>
        <Route element={<AdminLayout />}>
          <Route
            index
            element={<AdminDashboardPage />}
          />

          <Route
            path="agent"
            element={<AdminAgentPage />}
          />

          <Route
            path="products"
            element={<AdminProductsPage />}
          />

          <Route
            path="categories"
            element={<AdminCategoriesPage />}
          />

          <Route
            path="orders"
            element={<AdminOrdersPage />}
          />

          <Route
            path="inventory"
            element={<AdminInventoryPage />}
          />
        </Route>
      </Route>

      <Route
        path="*"
        element={
          <Navigate
            to="/"
            replace
          />
        }
      />
    </Routes>
  );
}

export default App;
