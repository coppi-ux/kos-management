const db = require("../config/db");

const Bill = {
  create: (data, callback) => {
    const sql = `
      INSERT INTO bills (
        tenant_id,
        room_id,
        kos_id,
        billing_month,
        base_amount,
        addon_amount,
        penalty_amount,
        total_amount,
        due_date,
        status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'unpaid')
    `;

    const baseAmount = Number(data.base_amount || 0);
    const addonAmount = Number(data.addon_amount || 0);
    const penaltyAmount = Number(data.penalty_amount || 0);
    const totalAmount = Number(
      data.total_amount || baseAmount + addonAmount + penaltyAmount
    );

    db.query(
      sql,
      [
        data.tenant_id,
        data.room_id,
        data.kos_id,
        data.billing_month,
        baseAmount,
        addonAmount,
        penaltyAmount,
        totalAmount,
        data.due_date,
      ],
      callback
    );
  },

  findExisting: (tenantId, billingMonth, callback) => {
    const sql = `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        b.billing_month,
        b.base_amount,
        b.addon_amount,
        b.penalty_amount,
        b.total_amount,
        b.due_date,
        b.paid_date,
        b.status,
        b.created_at,
        b.updated_at,

        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type,
        rt.base_price
      FROM bills b
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.tenant_id = ?
        AND b.billing_month = ?
      LIMIT 1
    `;

    db.query(sql, [tenantId, billingMonth], callback);
  },

  findByKosId: (kosId, callback) => {
    const sql = `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        b.billing_month,
        b.base_amount,
        b.addon_amount,
        b.penalty_amount,
        b.total_amount,
        b.due_date,
        b.paid_date,
        b.status,
        b.created_at,
        b.updated_at,

        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type,
        rt.base_price
      FROM bills b
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.kos_id = ?
      ORDER BY b.billing_month DESC, b.created_at DESC
    `;

    db.query(sql, [kosId], callback);
  },

  findByTenantId: (tenantId, callback) => {
    const sql = `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        b.billing_month,
        b.base_amount,
        b.addon_amount,
        b.penalty_amount,
        b.total_amount,
        b.due_date,
        b.paid_date,
        b.status,
        b.created_at,
        b.updated_at,

        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type,
        rt.base_price
      FROM bills b
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.tenant_id = ?
      ORDER BY b.billing_month DESC, b.created_at DESC
    `;

    db.query(sql, [tenantId], callback);
  },

  findCurrentByTenantId: (tenantId, callback) => {
    const sql = `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        b.billing_month,
        b.base_amount,
        b.addon_amount,
        b.penalty_amount,
        b.total_amount,
        b.due_date,
        b.paid_date,
        b.status,
        b.created_at,
        b.updated_at,

        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type,
        rt.base_price
      FROM bills b
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.tenant_id = ?
        AND b.status = 'unpaid'
      ORDER BY b.billing_month DESC, b.created_at DESC
      LIMIT 1
    `;

    db.query(sql, [tenantId], callback);
  },

  findPaidByTenantId: (tenantId, callback) => {
    const sql = `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        b.billing_month,
        b.base_amount,
        b.addon_amount,
        b.penalty_amount,
        b.total_amount,
        b.due_date,
        b.paid_date,
        b.status,
        b.created_at,
        b.updated_at,

        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type,
        rt.base_price
      FROM bills b
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.tenant_id = ?
        AND b.status = 'paid'
      ORDER BY b.billing_month DESC, b.paid_date DESC, b.created_at DESC
    `;

    db.query(sql, [tenantId], callback);
  },

  markPaid: (id, callback) => {
    const sql = `
      UPDATE bills
      SET
        status = 'paid',
        paid_date = CURDATE()
      WHERE id = ?
        AND status = 'unpaid'
    `;

    db.query(sql, [id], callback);
  },

  markPaidByTenant: (id, tenantId, callback) => {
    const sql = `
      UPDATE bills
      SET
        status = 'paid',
        paid_date = CURDATE()
      WHERE id = ?
        AND tenant_id = ?
        AND status = 'unpaid'
    `;

    db.query(sql, [id, tenantId], callback);
  },

  findOverdue: (callback) => {
    const sql = `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        b.billing_month,
        b.base_amount,
        b.addon_amount,
        b.penalty_amount,
        b.total_amount,
        b.due_date,
        b.paid_date,
        b.status,
        b.created_at,
        b.updated_at,

        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type,
        rt.base_price
      FROM bills b
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.status = 'unpaid'
        AND b.due_date < CURDATE()
      ORDER BY b.due_date ASC
    `;

    db.query(sql, callback);
  },

  updatePenalty: (id, penaltyAmount, totalAmount, callback) => {
    const sql = `
      UPDATE bills
      SET
        penalty_amount = ?,
        total_amount = ?
      WHERE id = ?
        AND status = 'unpaid'
    `;

    db.query(sql, [penaltyAmount, totalAmount, id], callback);
  },

  refreshTotalAmount: (id, callback) => {
    const sql = `
      UPDATE bills
      SET total_amount = base_amount + addon_amount + penalty_amount
      WHERE id = ?
    `;

    db.query(sql, [id], callback);
  },

  deleteById: (id, callback) => {
    const sql = `
      DELETE FROM bills
      WHERE id = ?
    `;

    db.query(sql, [id], callback);
  },
};

module.exports = Bill;