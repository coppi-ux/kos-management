const db = require("../config/db");

const toNumber = (value) => {
  const number = Number(value || 0);
  return Number.isNaN(number) ? 0 : number;
};

const formatDate = (value) => {
  if (!value) return null;

  if (value instanceof Date) {
    return value.toISOString().split("T")[0];
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return null;
  }

  return date.toISOString().split("T")[0];
};

const formatRupiah = (value) => {
  const amount = toNumber(value);
  return `Rp ${amount.toLocaleString("id-ID")}`;
};

const normalizeBill = (bill) => {
  if (!bill) return null;

  const baseAmount = toNumber(bill.base_amount);
  const addonAmount = toNumber(bill.addon_amount);
  const penaltyAmount = toNumber(bill.penalty_amount);

  const calculatedTotal = baseAmount + addonAmount + penaltyAmount;

  const totalAmount =
    toNumber(bill.total_amount) > 0
      ? toNumber(bill.total_amount)
      : calculatedTotal;

  return {
    ...bill,
    base_amount: baseAmount,
    addon_amount: addonAmount,
    penalty_amount: penaltyAmount,
    total_amount: totalAmount,
    base_price: toNumber(bill.base_price),
    due_date: formatDate(bill.due_date),
    paid_date: formatDate(bill.paid_date),
    created_at: bill.created_at,
    updated_at: bill.updated_at,
    status: bill.status || "unpaid",
  };
};

const getActiveAddonsByTenantId = async (tenantId) => {
  const [addons] = await db.query(
    `
    SELECT
      ta.id AS tenant_addon_id,
      ta.tenant_id,
      ta.addon_id,
      ta.start_date,
      ta.end_date,
      ta.is_active,
      a.name AS addon_name,
      a.price AS addon_price
    FROM tenant_addons ta
    JOIN addons a ON ta.addon_id = a.id
    WHERE ta.tenant_id = ?
      AND ta.is_active = 1
      AND a.is_active = 1
    ORDER BY a.name ASC
    `,
    [tenantId]
  );

  return addons.map((addon) => ({
    ...addon,
    start_date: formatDate(addon.start_date),
    end_date: formatDate(addon.end_date),
    addon_price: toNumber(addon.addon_price),
  }));
};

const getTenantBillSummary = async (tenantId) => {
  const [summaryRows] = await db.query(
    `
    SELECT
      COUNT(*) AS total_bills,
      SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) AS paid_bills,
      SUM(CASE WHEN status = 'unpaid' THEN 1 ELSE 0 END) AS unpaid_bills,
      COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) AS total_paid_amount,
      COALESCE(SUM(CASE WHEN status = 'unpaid' THEN total_amount ELSE 0 END), 0) AS total_unpaid_amount
    FROM bills
    WHERE tenant_id = ?
    `,
    [tenantId]
  );

  const summary = summaryRows[0] || {};

  return {
    total_bills: toNumber(summary.total_bills),
    paid_bills: toNumber(summary.paid_bills),
    unpaid_bills: toNumber(summary.unpaid_bills),
    total_paid_amount: toNumber(summary.total_paid_amount),
    total_unpaid_amount: toNumber(summary.total_unpaid_amount),
  };
};

const createPaymentRequestNotification = async ({
  connection,
  bill,
  paymentMethod,
}) => {
  if (!connection) return;
  if (!bill) return;
  if (!bill.owner_id) return;
  if (!bill.id) return;

  const tenantName = bill.tenant_name || "Tenant";
  const billingMonth = bill.billing_month || "current month";
  const roomNumber = bill.room_number || "-";
  const totalAmount = formatRupiah(bill.total_amount);
  const method = paymentMethod || "cash";

  const title = "Payment Confirmation Needed";
  const message = `${tenantName} has submitted a ${method} payment request for ${billingMonth}. Room ${roomNumber}. Total: ${totalAmount}. Please confirm the payment.`;

  await connection.query(
    `
    INSERT INTO notifications (
      owner_id,
      bill_id,
      type,
      title,
      message,
      is_read,
      created_at
    )
    VALUES (?, ?, ?, ?, ?, 0, NOW())
    ON DUPLICATE KEY UPDATE
      title = VALUES(title),
      message = VALUES(message),
      is_read = 0,
      updated_at = CURRENT_TIMESTAMP
    `,
    [
      bill.owner_id,
      bill.id,
      "payment_requested",
      title,
      message,
    ]
  );
};

const createPaymentPaidNotification = async ({
  connection,
  bill,
}) => {
  if (!connection) return;
  if (!bill) return;
  if (!bill.owner_id) return;
  if (!bill.id) return;

  const tenantName = bill.tenant_name || "Tenant";
  const billingMonth = bill.billing_month || "current month";
  const roomNumber = bill.room_number || "-";
  const totalAmount = formatRupiah(bill.total_amount);

  const title = "Payment Received";
  const message = `${tenantName} has paid the bill for ${billingMonth}. Room ${roomNumber}. Total paid: ${totalAmount}.`;

  await connection.query(
    `
    INSERT INTO notifications (
      owner_id,
      bill_id,
      type,
      title,
      message,
      is_read,
      created_at
    )
    VALUES (?, ?, ?, ?, ?, 0, NOW())
    ON DUPLICATE KEY UPDATE
      title = VALUES(title),
      message = VALUES(message),
      is_read = 0,
      updated_at = CURRENT_TIMESTAMP
    `,
    [
      bill.owner_id,
      bill.id,
      "payment_paid",
      title,
      message,
    ]
  );
};

exports.getMyBills = async (req, res) => {
  try {
    const tenantId = req.user.id;

    const [bills] = await db.query(
      `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        k.owner_id,
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
      JOIN kos k ON b.kos_id = k.id
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.tenant_id = ?
      ORDER BY b.billing_month DESC, b.created_at DESC
      `,
      [tenantId]
    );

    const normalizedBills = bills
      .map(normalizeBill)
      .filter((bill) => bill !== null);

    const paidBills = normalizedBills.filter(
      (bill) => bill.status === "paid"
    );

    const unpaidBills = normalizedBills.filter(
      (bill) => bill.status === "unpaid"
    );

    const currentBill = unpaidBills.length > 0 ? unpaidBills[0] : null;

    const activeAddons = await getActiveAddonsByTenantId(tenantId);
    const summary = await getTenantBillSummary(tenantId);

    return res.status(200).json({
      success: true,
      bills: normalizedBills,
      data: normalizedBills,
      paid_bills: paidBills,
      unpaid_bills: unpaidBills,
      current_bill: currentBill,
      bill: currentBill,
      active_addons: activeAddons,
      addons: activeAddons,
      summary,
    });
  } catch (error) {
    console.error("[TenantBill] Get my bills error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch bills",
    });
  }
};

exports.getCurrentBill = async (req, res) => {
  try {
    const tenantId = req.user.id;

    const [rows] = await db.query(
      `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        k.owner_id,
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
      JOIN kos k ON b.kos_id = k.id
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.tenant_id = ?
        AND b.status = 'unpaid'
      ORDER BY b.billing_month DESC, b.created_at DESC
      LIMIT 1
      `,
      [tenantId]
    );

    const activeAddons = await getActiveAddonsByTenantId(tenantId);

    if (rows.length === 0) {
      return res.status(200).json({
        success: true,
        message: "No current unpaid bill",
        bill: null,
        current_bill: null,
        data: null,
        active_addons: activeAddons,
        addons: activeAddons,
      });
    }

    const normalizedBill = normalizeBill(rows[0]);

    return res.status(200).json({
      success: true,
      bill: normalizedBill,
      current_bill: normalizedBill,
      data: normalizedBill,
      active_addons: activeAddons,
      addons: activeAddons,
    });
  } catch (error) {
    console.error("[TenantBill] Get current bill error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch current bill",
    });
  }
};

exports.payBill = async (req, res) => {
  const connection = await db.getConnection();

  try {
    console.log("========== TENANT PAY BILL HIT ==========");
    console.log("PARAMS:", req.params);
    console.log("BODY:", req.body);
    console.log("USER:", req.user);

    const { id } = req.params;
    const { payment_method } = req.body;
    const tenantId = req.user.id;

    if (!id) {
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Bill id is required",
      });
    }

    if (!payment_method) {
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Payment method required",
      });
    }

    await connection.beginTransaction();

    const [rows] = await connection.query(
      `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        k.owner_id,
        b.billing_month,
        b.status,
        b.base_amount,
        b.addon_amount,
        b.penalty_amount,
        b.total_amount,
        b.due_date,
        b.paid_date,
        b.created_at,
        b.updated_at,
        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type,
        rt.base_price
      FROM bills b
      JOIN kos k ON b.kos_id = k.id
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.id = ?
        AND b.tenant_id = ?
      LIMIT 1
      `,
      [id, tenantId]
    );

    if (rows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Bill not found",
      });
    }

    const bill = normalizeBill(rows[0]);

    if (bill.status === "paid") {
      await connection.rollback();
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Bill already paid",
      });
    }

    await createPaymentRequestNotification({
      connection,
      bill,
      paymentMethod: payment_method,
    });

    await connection.commit();
    connection.release();

    return res.status(200).json({
      success: true,
      message: "Payment request sent. Waiting for owner confirmation.",
      payment_method,
      bill_id: Number(id),
      bill,
      data: bill,
    });
  } catch (error) {
    await connection.rollback();
    connection.release();

    console.error("[TenantBill] Pay bill request error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to send payment request",
    });
  }
};

exports.confirmBillPaid = async (req, res) => {
  const connection = await db.getConnection();

  try {
    console.log("========== OWNER CONFIRM BILL PAID HIT ==========");
    console.log("PARAMS:", req.params);
    console.log("USER:", req.user);

    const { id } = req.params;

    if (!id) {
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Bill id is required",
      });
    }

    await connection.beginTransaction();

    const [rows] = await connection.query(
      `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        k.owner_id,
        b.billing_month,
        b.status,
        b.base_amount,
        b.addon_amount,
        b.penalty_amount,
        b.total_amount,
        b.due_date,
        b.paid_date,
        b.created_at,
        b.updated_at,
        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type,
        rt.base_price
      FROM bills b
      JOIN kos k ON b.kos_id = k.id
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.id = ?
      LIMIT 1
      `,
      [id]
    );

    if (rows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Bill not found",
      });
    }

    const bill = normalizeBill(rows[0]);

    if (bill.status === "paid") {
      await connection.rollback();
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Bill already paid",
      });
    }

    const [updateResult] = await connection.query(
      `
      UPDATE bills
      SET
        status = 'paid',
        paid_date = CURDATE(),
        total_amount = ?
      WHERE id = ?
        AND status = 'unpaid'
      `,
      [bill.total_amount, id]
    );

    if (updateResult.affectedRows === 0) {
      await connection.rollback();
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Failed to confirm payment",
      });
    }

    const [updatedRows] = await connection.query(
      `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        k.owner_id,
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
      JOIN kos k ON b.kos_id = k.id
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.id = ?
      LIMIT 1
      `,
      [id]
    );

    const paidBill =
      updatedRows.length > 0 ? normalizeBill(updatedRows[0]) : null;

    if (paidBill) {
      await createPaymentPaidNotification({
        connection,
        bill: paidBill,
      });

      await connection.query(
        `
        UPDATE notifications
        SET
          is_read = 1,
          updated_at = CURRENT_TIMESTAMP
        WHERE bill_id = ?
          AND type = 'payment_requested'
        `,
        [id]
      );
    }

    await connection.commit();
    connection.release();

    return res.status(200).json({
      success: true,
      message: "Payment confirmed successfully",
      bill_id: Number(id),
      paid_date: formatDate(new Date()),
      bill: paidBill,
      data: paidBill,
    });
  } catch (error) {
    await connection.rollback();
    connection.release();

    console.error("[TenantBill] Confirm bill paid error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to confirm payment",
    });
  }
};

exports.getMyActiveAddons = async (req, res) => {
  try {
    const tenantId = req.user.id;

    const addons = await getActiveAddonsByTenantId(tenantId);

    const totalAddonAmount = addons.reduce((total, addon) => {
      return total + Number(addon.addon_price || 0);
    }, 0);

    return res.status(200).json({
      success: true,
      addons,
      data: addons,
      total_addon_amount: totalAddonAmount,
    });
  } catch (error) {
    console.error("[TenantBill] Get active addons error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch additional bills",
    });
  }
};