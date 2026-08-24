import { httpClient } from "../api/http_client";
import {
  clearAccessToken,
  setAccessToken,
} from "./access_token_store";

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  role: "ADMIN";
}

interface AuthResponse {
  success: boolean;
  accessToken: string;
  expiresInSeconds: number;
  user: AdminUser;
}

export async function loginAdmin(
  email: string,
  password: string,
): Promise<AdminUser> {
  const response =
      await httpClient.post<AuthResponse>(
    "/api/auth/admin/login",
    {
      email,
      password,
    },
  );

  setAccessToken(
    response.data.accessToken,
  );

  return response.data.user;
}

export async function restoreAdminSession():
    Promise<AdminUser | null> {
  try {
    const response =
        await httpClient.post<AuthResponse>(
      "/api/auth/admin/refresh",
    );

    setAccessToken(
      response.data.accessToken,
    );

    return response.data.user;
  } catch {
    clearAccessToken();
    return null;
  }
}

export async function logoutAdmin():
    Promise<void> {
  try {
    await httpClient.post(
      "/api/auth/admin/logout",
    );
  } finally {
    clearAccessToken();
  }
}