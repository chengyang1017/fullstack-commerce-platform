import {
  useEffect,
  useMemo,
  useState,
  type FormEvent,
  type KeyboardEvent,
} from "react";
import { Link } from "react-router";

import { httpClient } from "../api/http_client";
import "./admin_agent_page.css";

interface AgentCard {
  label: string;
  value: string;
  description: string;
  tone?: "default" | "success" | "warning" | "danger";
}

interface AgentItem {
  title: string;
  subtitle: string;
  meta?: string;
  href?: string;
}

interface AgentResponse {
  success: boolean;
  intent:
    | "overview"
    | "low_stock"
    | "pending_orders"
    | "top_products"
    | "payment_risk"
    | "help";
  reply: string;
  cards: AgentCard[];
  items: AgentItem[];
  suggestions: string[];
  generatedAt: string;
}

interface ChatMessage {
  id: string;
  role: "user" | "agent";
  text: string;
  result?: AgentResponse;
}

const initialSuggestions = [
  "Give me an overview",
  "Check low-stock products",
  "Show pending orders",
  "Check payment issues",
  "Show top-selling products",
];

export function AdminAgentDrawer() {
  const [open, setOpen] = useState(false);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: "welcome",
      role: "agent",
      text:
        "I’m your commerce operations agent. Ask me about orders, inventory, payments, or product performance. This version is read-only and will not change business data.",
    },
  ]);

  useEffect(() => {
    function handleEscape(event: globalThis.KeyboardEvent) {
      if (event.key === "Escape") {
        setOpen(false);
      }
    }

    window.addEventListener("keydown", handleEscape);
    return () => window.removeEventListener("keydown", handleEscape);
  }, []);

  const latestSuggestions = useMemo(() => {
    const latestAgentMessage = [...messages]
      .reverse()
      .find((message) => message.role === "agent");

    return latestAgentMessage?.result?.suggestions ?? initialSuggestions;
  }, [messages]);

  async function sendMessage(prompt?: string) {
    const message = (prompt ?? input).trim();

    if (!message || loading) {
      return;
    }

    setOpen(true);
    setInput("");
    setLoading(true);

    setMessages((current) => [
      ...current,
      {
        id: createMessageId(),
        role: "user",
        text: message,
      },
    ]);

    try {
      const response = await httpClient.post<AgentResponse>(
        "/api/admin/agent",
        { message },
      );

      setMessages((current) => [
        ...current,
        {
          id: createMessageId(),
          role: "agent",
          text: response.data.reply,
          result: response.data,
        },
      ]);
    } catch (error) {
      console.error("Admin Agent request failed", error);

      setMessages((current) => [
        ...current,
        {
          id: createMessageId(),
          role: "agent",
          text:
            "I couldn’t read the admin data right now. Please try again in a moment.",
        },
      ]);
    } finally {
      setLoading(false);
    }
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    void sendMessage();
  }

  function handleKeyDown(
    event: KeyboardEvent<HTMLTextAreaElement>,
  ) {
    if (
      event.key === "Enter" &&
      !event.shiftKey &&
      !event.nativeEvent.isComposing
    ) {
      event.preventDefault();
      void sendMessage();
    }
  }

  return (
    <>
      {open && (
        <button
          className="agent-drawer-backdrop"
          type="button"
          aria-label="Close operations agent"
          onClick={() => setOpen(false)}
        />
      )}

      <aside
        className={`agent-drawer ${open ? "open" : ""}`}
        aria-hidden={!open}
      >
        <header className="agent-drawer-header">
          <div className="agent-drawer-title-row">
            <div className="agent-drawer-mark">✦</div>
            <div>
              <strong>Operations Agent</strong>
              <span>Live commerce insights</span>
            </div>
          </div>

          <button
            className="agent-drawer-close"
            type="button"
            aria-label="Close operations agent"
            onClick={() => setOpen(false)}
          >
            ×
          </button>
        </header>

        <div className="agent-drawer-status">
          <span className="agent-status-dot" />
          Read-only mode · connected to live admin data
        </div>

        <div className="agent-chat-history">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`agent-message-row ${message.role}`}
            >
              <div className="agent-message-avatar">
                {message.role === "agent" ? "A" : "You"}
              </div>

              <div className="agent-message-content">
                <div className="agent-message-bubble">
                  {message.text}
                </div>

                {message.result && (
                  <AgentResult result={message.result} />
                )}
              </div>
            </div>
          ))}

          {loading && (
            <div className="agent-message-row agent">
              <div className="agent-message-avatar">A</div>
              <div className="agent-message-content">
                <div className="agent-message-bubble agent-thinking">
                  <span />
                  <span />
                  <span />
                </div>
              </div>
            </div>
          )}
        </div>

        <div className="agent-suggestion-row">
          {latestSuggestions.slice(0, 4).map((suggestion) => (
            <button
              key={suggestion}
              type="button"
              className="agent-suggestion-chip"
              disabled={loading}
              onClick={() => {
                void sendMessage(suggestion);
              }}
            >
              {suggestion}
            </button>
          ))}
        </div>

        <form
          className="agent-composer"
          onSubmit={handleSubmit}
        >
          <textarea
            value={input}
            maxLength={500}
            rows={2}
            placeholder="Ask about orders, stock, payments..."
            disabled={loading}
            onChange={(event) => {
              setInput(event.target.value);
            }}
            onKeyDown={handleKeyDown}
          />

          <button
            className="primary-button agent-send-button"
            type="submit"
            disabled={loading || input.trim().length === 0}
          >
            {loading ? "Analyzing..." : "Send"}
          </button>
        </form>
      </aside>

      <button
        className={`agent-floating-button ${open ? "hidden" : ""}`}
        type="button"
        aria-label="Open operations agent"
        onClick={() => setOpen(true)}
      >
        <span className="agent-floating-icon">✦</span>
        <span>Agent</span>
      </button>
    </>
  );
}

function AgentResult({
  result,
}: {
  result: AgentResponse;
}) {
  return (
    <div className="agent-result">
      {result.cards.length > 0 && (
        <div className="agent-card-grid">
          {result.cards.map((card) => (
            <article
              key={`${card.label}-${card.value}`}
              className={`agent-metric-card ${card.tone ?? "default"}`}
            >
              <span>{card.label}</span>
              <strong>{card.value}</strong>
              <small>{card.description}</small>
            </article>
          ))}
        </div>
      )}

      {result.items.length > 0 && (
        <div className="agent-result-list">
          {result.items.map((item, index) => {
            const content = (
              <>
                <div>
                  <strong>{item.title}</strong>
                  <span>{item.subtitle}</span>
                </div>
                {item.meta && <small>{item.meta}</small>}
              </>
            );

            if (item.href) {
              return (
                <Link
                  key={`${item.title}-${index}`}
                  to={item.href}
                  className="agent-result-item"
                >
                  {content}
                </Link>
              );
            }

            return (
              <div
                key={`${item.title}-${index}`}
                className="agent-result-item"
              >
                {content}
              </div>
            );
          })}
        </div>
      )}

      <div className="agent-result-time">
        Data time: {formatGeneratedAt(result.generatedAt)}
      </div>
    </div>
  );
}

function createMessageId(): string {
  if (typeof crypto !== "undefined" && crypto.randomUUID) {
    return crypto.randomUUID();
  }

  return `${Date.now()}-${Math.random()}`;
}

function formatGeneratedAt(value: string): string {
  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toLocaleString("en-MY", {
    timeZone: "Asia/Kuala_Lumpur",
    hour12: false,
  });
}
