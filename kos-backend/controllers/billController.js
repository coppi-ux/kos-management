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

  return value.toString().split("T")[0];
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
    due_date: formatDate(bill.due_date),
    paid_date: formatDate(bill.paid_date),
  };
};

const normalizeBills = (bills) => {
  return bills.map(normalizeBill).filter((bill) => bill !== null);
};

const getTotalAddonAmountByTenantId = async (tenantId) => {
  const [rows] = await db.query(
    `
    SELECT
      COALESCE(SUM(a.price), 0) AS total
    FROM tenant_addons ta
    JOIN addons a ON ta.addon_id = a.id
    WHERE ta.tenant_id = ?
      AND ta.is_active = 1
      AND a.is_active = 1
    `,
    [tenantId]
  );

  return toNumber(rows?.[0]?.total);
};

const getBillById = async (billId) => {
  const [rows] = await db.query(
    `
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

      k.owner_id,

      t.name AS tenant_name,
      t.phone AS phone,
      t.email AS email,

      r.room_number,

      rt.name AS room_type,
      rt.base_price
    FROM bills b
    LEFT JOIN kos k ON b.kos_id = k.id
    LEFT JOIN tenants t ON b.tenant_id = t.id
    LEFT JOIN rooms r ON b.room_id = r.id
    LEFT JOIN room_types rt ON r.room_type_id = rt.id
    WHERE b.id = ?
    LIMIT 1
    `,
    [billId]
  );

  if (rows.length === 0) return null;

  return normalizeBill(rows[0]);
};

const createPaymentPaidNotification = async (bill) => {
  if (!bill) return;
  if (!bill.owner_id) return;

  const tenantName = bill.tenant_name || "Tenant";
  const billingMonth = bill.billing_month || "current month";
  const roomNumber = bill.room_number || "-";
  const totalAmount = formatRupiah(bill.total_amount);

  const title = "Payment Received";
  const message = `${tenantName} has paid the bill for ${billingMonth}. Room ${roomNumber}. Total paid: ${totalAmount}.`;

  await db.query(
    `
    INSERT INTO notifications (
      owner_id,
      type,
      title,
      message,
      is_read,
      created_at
    )
    VALUES (?, ?, ?, ?, 0, NOW())
    `,
    [
      bill.owner_id,
      "payment_paid",
      title,
      message,
    ]
  );
};

// GET BILLS BY KOS
exports.getBillsByKos = async (req, res) => {
  const { kosId } = req.params;

  console.log("GET BILLS BY KOS:", kosId);

  try {
    const [rows] = await db.query(
      `
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

        k.owner_id,

        t.name AS tenant_name,
        t.phone AS phone,
        t.email AS email,

        r.room_number,

        rt.name AS room_type,
        rt.base_price
      FROM bills b
      LEFT JOIN kos k ON b.kos_id = k.id
      LEFT JOIN tenants t ON b.tenant_id = t.id
      LEFT JOIN rooms r ON b.room_id = r.id
      LEFT JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.kos_id = ?
      ORDER BY b.due_date DESC, b.created_at DESC
      `,
      [kosId]
    );

    const bills = normalizeBills(rows);

    console.log("BILLS FOUND:", bills.length);

    return res.json({
      success: true,
      bills,
      data: bills,
    });
  } catch (error) {
    console.error("Get bills error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch bills",
    });
  }
};

// GET BILLS BY TENANT
exports.getBillsByTenant = async (req, res) => {
  const { tenantId } = req.params;

  console.log("GET BILLS BY TENANT:", tenantId);

  try {
    const [rows] = await db.query(
      `
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

        k.owner_id,

        t.name AS tenant_name,
        t.phone AS phone,
        t.email AS email,

        r.room_number,

        rt.name AS room_type,
        rt.base_price
      FROM bills b
      LEFT JOIN kos k ON b.kos_id = k.id
      LEFT JOIN tenants t ON b.tenant_id = t.id
      LEFT JOIN rooms r ON b.room_id = r.id
      LEFT JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.tenant_id = ?
      ORDER BY b.due_date DESC, b.created_at DESC
      `,
      [tenantId]
    );

    const bills = normalizeBills(rows);

    return res.json({
      success: true,
      bills,
      data: bills,
    });
  } catch (error) {
    console.error("Get tenant bills error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to get tenant bills",
    });
  }
};

// GET OVERDUE BILLS
exports.getOverdueBills = async (req, res) => {
  const { kosId } = req.params;

  console.log("GET OVERDUE BILLS BY KOS:", kosId);

  try {
    const [rows] = await db.query(
      `
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

        k.owner_id,

        t.name AS tenant_name,
        t.phone AS phone,
        t.email AS email,

        r.room_number,

        rt.name AS room_type,
        rt.base_price
      FROM bills b
      LEFT JOIN kos k ON b.kos_id = k.id
      LEFT JOIN tenants t ON b.tenant_id = t.id
      LEFT JOIN rooms r ON b.room_id = r.id
      LEFT JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.kos_id = ?
        AND b.status = 'unpaid'
        AND b.due_date < CURDATE()
      ORDER BY b.due_date DESC, b.created_at DESC
      `,
      [kosId]
    );

    const overdueBills = normalizeBills(rows);

    return res.json({
      success: true,
      overdue_bills: overdueBills,
      bills: overdueBills,
      data: overdueBills,
    });
  } catch (error) {
    console.error("Get overdue bills error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch overdue bills",
    });
  }
};

// MARK BILL AS PAID
exports.markPaid = async (req, res) => {
  const { id } = req.params;

  console.log("MARK BILL AS PAID:", id);

  try {
    const existingBill = await getBillById(id);

    if (!existingBill) {
      return res.status(404).json({
        success: false,
        message: "Bill not found",
      });
    }

    if (existingBill.status === "paid") {
      return res.status(400).json({
        success: false,
        message: "Bill already paid",
        bill: existingBill,
        data: existingBill,
      });
    }

    const totalAmount =
      toNumber(existingBill.total_amount) > 0
        ? toNumber(existingBill.total_amount)
        : toNumber(existingBill.base_amount) +
          toNumber(existingBill.addon_amount) +
          toNumber(existingBill.penalty_amount);

    const [result] = await db.query(
      `
      UPDATE bills
      SET
        status = 'paid',
        paid_date = CURDATE(),
        total_amount = ?
      WHERE id = ?
        AND status = 'unpaid'
      `,
      [totalAmount, id]
    );

    const updatedBill = await getBillById(id);

    if (result.affectedRows > 0 && updatedBill) {
      try {
        await createPaymentPaidNotification(updatedBill);
      } catch (notificationError) {
        console.error("Create payment notification error:", notificationError);
      }
    }

    return res.json({
      success: true,
      message: "Bill marked as paid",
      affectedRows: result.affectedRows,
      bill: updatedBill,
      data: updatedBill,
    });
  } catch (error) {
    console.error("Mark paid error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to mark bill as paid",
    });
  }
};

// GENERATE BILLS
exports.manualGenerate = async (req, res) => {
  const { kosId } = req.params;

  console.log("GENERATE BILLS FOR KOS:", kosId);

  try {
    const [tenants] = await db.query(
      `
      SELECT
        t.id AS tenant_id,
        t.name AS tenant_name,
        t.phone AS phone,
        t.email AS email,

        r.id AS room_id,
        r.kos_id AS kos_id,
        r.room_number,

        rt.name AS room_type,
        rt.base_price AS base_price
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE r.kos_id = ?
        AND t.is_active = 1
      ORDER BY t.id ASC
      `,
      [kosId]
    );

    console.log("ACTIVE TENANTS FOUND:", tenants.length);

    if (tenants.length === 0) {
      return res.json({
        success: false,
        message: "No active tenants found for this kos",
        generated_count: 0,
      });
    }

    let generatedCount = 0;
    const generatedBills = [];
    const skippedBills = [];

    const billingMonth = new Date().toISOString().slice(0, 7);

    for (const tenant of tenants) {
      const [existing] = await db.query(
        `
        SELECT id
        FROM bills
        WHERE tenant_id = ?
          AND billing_month = ?
        LIMIT 1
        `,
        [tenant.tenant_id, billingMonth]
      );

      if (existing.length > 0) {
        skippedBills.push({
          tenant_id: tenant.tenant_id,
          tenant_name: tenant.tenant_name,
          reason: "Bill already exists for this month",
        });

        continue;
      }

      const addonAmount = await getTotalAddonAmountByTenantId(
        tenant.tenant_id
      );

      const baseAmount = toNumber(tenant.base_price);
      const penaltyAmount = 0;
      const totalAmount = baseAmount + addonAmount + penaltyAmount;

      const [insertResult] = await db.query(
        `
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
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, DATE_ADD(CURDATE(), INTERVAL 1 MONTH), 'unpaid')
        `,
        [
          tenant.tenant_id,
          tenant.room_id,
          tenant.kos_id,
          billingMonth,
          baseAmount,
          addonAmount,
          penaltyAmount,
          totalAmount,
        ]
      );

      const generatedBill = await getBillById(insertResult.insertId);

      if (generatedBill) {
        generatedBills.push(generatedBill);
      }

      generatedCount++;
    }

    console.log("GENERATED COUNT:", generatedCount);

    return res.json({
      success: true,
      message:
        generatedCount > 0
          ? "Bills generated successfully"
          : "No new bills to generate today",
      generated_count: generatedCount,
      skipped_count: skippedBills.length,
      bills: generatedBills,
      generated_bills: generatedBills,
      skipped_bills: skippedBills,
    });
  } catch (error) {
    console.error("Generate bills error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to generate bills",
    });
  }
};