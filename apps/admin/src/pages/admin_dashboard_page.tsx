export function AdminDashboardPage() {
  return (
    <>
      <header className="page-header">
        <p className="page-eyebrow">
          DASHBOARD
        </p>

        <h1>Admin overview</h1>
        <p className="page-description">
          Manage your commerce operations from one place. Use the floating Agent button for live operational insights.
        </p>
      </header>

      <section className="dashboard-grid">
        <article className="dashboard-card">
          <span>Products</span>
          <strong>Manage</strong>
          <p>Review product listings, pricing, availability, and status.</p>
        </article>

        <article className="dashboard-card">
          <span>Orders</span>
          <strong>Review</strong>
          <p>Inspect customer orders, payments, and fulfilment details.</p>
        </article>

        <article className="dashboard-card">
          <span>Inventory</span>
          <strong>Monitor</strong>
          <p>Track stock movements and identify low-stock products.</p>
        </article>
      </section>
    </>
  );
}
