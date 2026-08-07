import {
  type ReactNode,
  useEffect,
  useState,
} from "react";

import {
  loginAdmin,
  logoutAdmin,
  restoreAdminSession,
  type AdminUser,
} from "./admin_auth_api";

import {
  AdminAuthContext,
  type AdminAuthContextValue,
  type AuthStatus,
} from "./admin_auth_context";

interface AdminAuthProviderProps {
  children: ReactNode;
}

export function AdminAuthProvider({
  children,
}: AdminAuthProviderProps) {
  const [status, setStatus] =
    useState<AuthStatus>("loading");

  const [user, setUser] =
    useState<AdminUser | null>(null);

  useEffect(() => {
    let isMounted = true;

    async function restoreSession():
        Promise<void> {
      const restoredUser =
        await restoreAdminSession();

      if (!isMounted) {
        return;
      }

      if (restoredUser) {
        setUser(restoredUser);
        setStatus("authenticated");
      } else {
        setUser(null);
        setStatus("unauthenticated");
      }
    }

    void restoreSession();

    function handleAuthExpired(): void {
      setUser(null);
      setStatus("unauthenticated");
    }

    window.addEventListener(
      "admin-auth-expired",
      handleAuthExpired,
    );

    return () => {
      isMounted = false;

      window.removeEventListener(
        "admin-auth-expired",
        handleAuthExpired,
      );
    };
  }, []);

  async function login(
    email: string,
    password: string,
  ): Promise<void> {
    const loggedInUser =
      await loginAdmin(
        email,
        password,
      );

    setUser(loggedInUser);
    setStatus("authenticated");
  }

  async function logout(): Promise<void> {
    await logoutAdmin();

    setUser(null);
    setStatus("unauthenticated");
  }

  const value: AdminAuthContextValue = {
    status,
    user,
    login,
    logout,
  };

  return (
    <AdminAuthContext.Provider value={value}>
      {children}
    </AdminAuthContext.Provider>
  );
}