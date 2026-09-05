import {
  NavLink,
  Outlet,
} from "react-router";

import {
  useAdminAuth,
} from "../auth/admin_auth_context";
import {
  AdminAgentDrawer,
} from "../pages/admin_agent_page";

export function AdminLayout() {
  const {
    user,
    logout,
  } = useAdminAuth();

  return (
    <div className="admin-layout">
      <aside className="admin-sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-logo">
            S
          </div>

          <div>
            <strong>Shopping</strong>
            <span>Admin Console</span>
          </div>
        </div>

        <nav className="sidebar-navigation">
          <NavLink
            to="/"
            end
            className={({ isActive }) =>
              isActive
                ? "navigation-item active"
                : "navigation-item"
            }
          >
            Dashboard
          </NavLink>

          <NavLink
            to="/products"
            className={({ isActive }) =>
              isActive
                ? "navigation-item active"
                : "navigation-item"
            }
          >
            Products
          </NavLink>

          <NavLink
            to="/categories"
            className={({ isActive }) =>
              isActive
                ? "navigation-item active"
                : "navigation-item"
            }
          >
            Categories
          </NavLink>

          <NavLink
            to="/orders"
            className={({ isActive }) =>
              isActive
                ? "navigation-item active"
                : "navigation-item"
            }
          >
            Orders
          </NavLink>

          <NavLink
            to="/inventory"
            className={({ isActive }) =>
              isActive
                ? "navigation-item active"
                : "navigation-item"
            }
          >
            Inventory
          </NavLink>
        </nav>
      </aside>

      <main className="admin-main">
        <header className="admin-toolbar">
          <div className="admin-account">
            <div>
              <strong>
                {user?.name}
              </strong>

              <span>
                {user?.email}
              </span>
            </div>

            <button
              className="secondary-button"
              type="button"
              onClick={() => {
                void logout();
              }}
            >
              Sign out
            </button>
          </div>
        </header>

        <Outlet />
      </main>

      <AdminAgentDrawer />
    </div>
  );
}
