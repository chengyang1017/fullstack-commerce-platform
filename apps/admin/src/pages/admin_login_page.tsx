import axios from "axios";
import {
  type FormEvent,
  useState,
} from "react";

import {
  useAdminAuth,
} from "../auth/admin_auth_context";

interface ErrorResponse {
  message?: string;
}

export function AdminLoginPage() {
  const { login } = useAdminAuth();

  const [email, setEmail] = useState("");
  const [password, setPassword] =
    useState("");

  const [isSubmitting, setIsSubmitting] =
    useState(false);

  const [errorMessage, setErrorMessage] =
    useState<string | null>(null);

  async function handleSubmit(
    event: FormEvent<HTMLFormElement>,
  ): Promise<void> {
    event.preventDefault();

    if (isSubmitting) {
      return;
    }

    const normalizedEmail =
      email.trim().toLowerCase();

    if (
      normalizedEmail.length === 0 ||
      password.length === 0
    ) {
      setErrorMessage("请输入邮箱和密码");
      return;
    }

    setIsSubmitting(true);
    setErrorMessage(null);

    try {
      await login(
        normalizedEmail,
        password,
      );
    } catch (error) {
      if (
        axios.isAxiosError<ErrorResponse>(
          error,
        )
      ) {
        setErrorMessage(
          error.response?.data.message ??
            "登录失败，请检查账号和密码",
        );
      } else {
        setErrorMessage(
          "登录失败，请稍后重试",
        );
      }
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="login-page">
      <section className="login-panel">
        <div className="login-brand">
          <div className="login-logo">
            S
          </div>

          <div>
            <p className="login-eyebrow">
              SHOPPING MANAGEMENT
            </p>

            <h1>管理员后台</h1>

            <p className="login-description">
              管理商品、库存、订单和客户资料
            </p>
          </div>
        </div>

        <form
          className="login-form"
          onSubmit={handleSubmit}
        >
          <label className="form-field">
            <span>管理员邮箱</span>

            <input
              type="email"
              value={email}
              onChange={(event) => {
                setEmail(event.target.value);
              }}
              autoComplete="username"
              placeholder="admin@shopping.com"
              disabled={isSubmitting}
            />
          </label>

          <label className="form-field">
            <span>密码</span>

            <input
              type="password"
              value={password}
              onChange={(event) => {
                setPassword(
                  event.target.value,
                );
              }}
              autoComplete="current-password"
              placeholder="请输入密码"
              disabled={isSubmitting}
            />
          </label>

          {errorMessage && (
            <div
              className="login-error"
              role="alert"
            >
              {errorMessage}
            </div>
          )}

          <button
            className="primary-button"
            type="submit"
            disabled={isSubmitting}
          >
            {isSubmitting
              ? "正在登录..."
              : "登录后台"}
          </button>
        </form>
      </section>
    </main>
  );
}