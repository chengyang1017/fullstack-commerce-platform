import {
  createContext,
  useContext,
} from "react";

import type {
  AdminUser,
} from "./admin_auth_api";

export type AuthStatus =
  | "loading"
  | "authenticated"
  | "unauthenticated";

export interface AdminAuthContextValue {
  status: AuthStatus;
  user: AdminUser | null;

  login(
    email: string,
    password: string,
  ): Promise<void>;

  logout(): Promise<void>;
}

export const AdminAuthContext =
  createContext<AdminAuthContextValue | null>(
    null,
  );

export function useAdminAuth():
    AdminAuthContextValue {
  const context = useContext(
    AdminAuthContext,
  );

  if (!context) {
    throw new Error(
      "useAdminAuth 必须在 AdminAuthProvider 内使用",
    );
  }

  return context;
}