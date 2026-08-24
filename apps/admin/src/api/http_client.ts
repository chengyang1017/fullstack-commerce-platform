import axios, {
  AxiosError,
  type InternalAxiosRequestConfig,
} from "axios";

import {
  clearAccessToken,
  getAccessToken,
  setAccessToken,
} from "../auth/access_token_store";

const baseURL = import.meta.env.VITE_API_BASE_URL;

if (!baseURL) {
  throw new Error(
    "缺少 VITE_API_BASE_URL",
  );
}

export const httpClient = axios.create({
  baseURL,
  withCredentials: true,
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
  },
});

const refreshClient = axios.create({
  baseURL,
  withCredentials: true,
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
  },
});

interface RetryableRequestConfig
  extends InternalAxiosRequestConfig {
  _retry?: boolean;
}

interface RefreshResponse {
  success: boolean;
  accessToken: string;
  expiresInSeconds: number;
}

httpClient.interceptors.request.use(
  (config) => {
    const accessToken = getAccessToken();

    if (accessToken) {
      config.headers.Authorization =
        `Bearer ${accessToken}`;
    }

    return config;
  },
);

httpClient.interceptors.response.use(
  (response) => response,

  async (error: AxiosError) => {
    const originalRequest =
      error.config as
        | RetryableRequestConfig
        | undefined;

    const statusCode =
      error.response?.status;

    if (
      statusCode !== 401 ||
      !originalRequest ||
      originalRequest._retry
    ) {
      return Promise.reject(error);
    }

    const url = originalRequest.url ?? "";

    if (
      url.includes("/api/auth/admin/login") ||
      url.includes("/api/auth/admin/refresh")
    ) {
      return Promise.reject(error);
    }

    originalRequest._retry = true;

    try {
      const response =
          await refreshClient.post<RefreshResponse>(
        "/api/auth/admin/refresh",
      );

      setAccessToken(
        response.data.accessToken,
      );

      return httpClient(originalRequest);
    } catch (refreshError) {
      clearAccessToken();

      window.dispatchEvent(
        new Event("admin-auth-expired"),
      );

      return Promise.reject(refreshError);
    }
  },
);