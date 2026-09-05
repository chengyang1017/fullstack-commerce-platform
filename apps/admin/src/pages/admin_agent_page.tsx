import {
  useMemo,
  useState,
  type FormEvent,
  type KeyboardEvent,
} from "react";
import { Link } from "react-router";

import { httpClient } from "../api/http_client";

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
  "给我后台总览",
  "检查库存风险",
  "查看待处理订单",
  "检查付款异常",
  "看看热销商品",
];

export function AdminAgentPage() {
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: "welcome",
      role: "agent",
      text:
        "我是商城后台运营 Agent。你可以直接问我订单、库存、付款和热销商品。当前版本只读取业务数据，不会自动修改订单或库存。",
    },
  ]);

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
            "Agent 暂时无法读取后台数据，请稍后再试。",
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
    <section className="agent-page">
      <header className="page-header agent-page-header">
        <div>
          <p className="page-eyebrow">OPERATIONS AGENT</p>
          <h1>后台运营 Agent</h1>
          <p className="page-description">
            用自然语言检查订单、库存、付款与销售数据。
          </p>
        </div>

        <div className="agent-status-badge">
          <span className="agent-status-dot" />
          Read-only
        </div>
      </header>

      <div className="agent-shell">
        <aside className="agent-sidebar-panel">
          <div>
            <span className="agent-panel-label">快速任务</span>
            <h2>让 Agent 帮你看后台</h2>
            <p>
              它会直接读取当前数据库，不需要你逐页查商品、订单和库存。
            </p>
          </div>

          <div className="agent-quick-list">
            {initialSuggestions.map((suggestion) => (
              <button
                key={suggestion}
                type="button"
                className="agent-quick-button"
                disabled={loading}
                onClick={() => {
                  void sendMessage(suggestion);
                }}
              >
                <span>✦</span>
                {suggestion}
              </button>
            ))}
          </div>

          <div className="agent-safety-note">
            <strong>安全模式</strong>
            <span>
              目前 Agent 只分析数据，不会自动改库存、订单状态或商品资料。
            </span>
          </div>
        </aside>

        <div className="agent-chat-panel">
          <div className="agent-chat-history">
            {messages.map((message) => (
              <div
                key={message.id}
                className={`agent-message-row ${message.role}`}
              >
                <div className="agent-message-avatar">
                  {message.role === "agent" ? "A" : "你"}
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
              placeholder="例如：哪些商品快没库存了？"
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
              {loading ? "分析中..." : "发送"}
            </button>
          </form>
        </div>
      </div>
    </section>
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
        数据时间：{formatGeneratedAt(result.generatedAt)}
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

  return date.toLocaleString("zh-CN", {
    timeZone: "Asia/Kuala_Lumpur",
    hour12: false,
  });
}
