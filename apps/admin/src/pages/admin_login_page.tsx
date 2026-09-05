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
      setErrorMessage("Enter your email and password.");
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
          "Sign-in failed. Check your admin credentials.",
        );
      } else {
        setErrorMessage(
          "Sign-in failed. Please try again shortly.",
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

            <h1>Admin Console</h1>

            <p className="login-description">
              Manage products, inventory, orders, and customer operations.
            </p>
          </div>
        </div>

        <form
          className="login-form"
          onSubmit={handleSubmit}
        >
          <label className="form-field">
            <span>Admin email</span>

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
            <span>Password</span>

            <input
              type="password"
              value={password}
              onChange={(event) => {
                setPassword(
                  event.target.value,
                );
              }}
              autoComplete="current-password"
              placeholder="Enter your password"
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
              ? "Signing in..."
              : "Sign in"}
          </button>
        </form>
      </section>
    </main>
  );
}
