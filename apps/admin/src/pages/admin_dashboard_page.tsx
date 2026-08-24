export function AdminDashboardPage() {
  return (
    <>
      <header className="page-header">
        <p className="page-eyebrow">
          DASHBOARD
        </p>

        <h1>后台总览</h1>
      </header>

      <section className="dashboard-grid">
        <article className="dashboard-card">
          <span>商品总数</span>
          <strong>—</strong>
          <p>下一步接入商品 API</p>
        </article>

        <article className="dashboard-card">
          <span>待处理订单</span>
          <strong>—</strong>
          <p>订单模块尚未接入</p>
        </article>

        <article className="dashboard-card">
          <span>库存预警</span>
          <strong>—</strong>
          <p>库存模块尚未接入</p>
        </article>
      </section>
    </>
  );
}