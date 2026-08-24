import {
  NavLink,
  Outlet,
} from "react-router";

import {
  useAdminAuth,
} from "../auth/admin_auth_context";

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
            <span>管理后台</span>
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
            仪表盘
          </NavLink>

          <NavLink
            to="/products"
            className={({ isActive }) =>
              isActive
                ? "navigation-item active"
                : "navigation-item"
            }
          >
            商品管理
          </NavLink>

          <NavLink
            to="/categories"
            className={({ isActive }) =>
                isActive
                ? "navigation-item active"
                : "navigation-item"
            }
          >
            分类管理
        </NavLink>

          <NavLink
            to="/orders"
            className={({ isActive }) =>
              isActive
                ? "navigation-item active"
                : "navigation-item"
            }
          >
            订单管理
          </NavLink>

          <NavLink
            to="/inventory"
            className={({ isActive }) =>
              isActive
                ? "navigation-item active"
                : "navigation-item"
            }
          >
            库存管理
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
              退出登录
            </button>
          </div>
        </header>

        <Outlet />
      </main>
    </div>
  );
}