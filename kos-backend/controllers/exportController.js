const db = require("../config/db");

const formatDate = (value) => {
  if (!value) return "";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value.toString();
  }

  return date.toISOString().slice(0, 10);
};

const formatDateTime = (value) => {
  if (!value) return "";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value.toString();
  }

  return date.toISOString().replace("T", " ").slice(0, 19);
};

const escapeCsvValue = (value) => {
  if (value === null || value === undefined) return "";

  const stringValue = value.toString();
  const escapedValue = stringValue.replace(/"/g, '""');

  return `"${escapedValue}"`;
};

const buildCsv = (headers, rows) => {
  const csvRows = [
    headers.map(escapeCsvValue).join(","),
    ...rows.map((row) => row.map(escapeCsvValue).join(",")),
  ];

  return `\uFEFF${csvRows.join("\n")}`;
};

exports.exportBills = async (req, res) => {
  try {
    const { kosId } = req.params;

    const [rows] = await db.query(
      `
      SELECT
        b.id,
        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type,
        b.billing_month,
        b.base_amount,
        b.addon_amount,
        b.penalty_amount,
        b.total_amount,
        b.due_date,
        b.paid_date,
        b.status,
        b.created_at
      FROM bills b
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.kos_id = ?
      ORDER BY b.billing_month DESC, t.name ASC
      `,
      [kosId]
    );

    const headers = [
      "ID",
      "Tenant Name",
      "Room Number",
      "Room Type",
      "Billing Month",
      "Base Amount",
      "Addon Amount",
      "Penalty Amount",
      "Total Amount",
      "Due Date",
      "Paid Date",
      "Status",
      "Created At",
    ];

    const dataRows = rows.map((row) => [
      row.id,
      row.tenant_name,
      row.room_number,
      row.room_type,
      row.billing_month,
      row.base_amount,
      row.addon_amount,
      row.penalty_amount,
      row.total_amount,
      formatDate(row.due_date),
      formatDate(row.paid_date),
      row.status,
      formatDateTime(row.created_at),
    ]);

    const today = new Date().toISOString().slice(0, 10);
    const csv = buildCsv(headers, dataRows);

    res.setHeader("Content-Type", "text/csv; charset=utf-8");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="bills_kos_${kosId}_${today}.csv"`
    );

    return res.status(200).send(csv);
  } catch (error) {
    console.error("[Export] Bills export error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to export bills",
    });
  }
};

exports.exportTenants = async (req, res) => {
  try {
    const { kosId } = req.params;

    const [rows] = await db.query(
      `
      SELECT
        t.id,
        t.name,
        t.email,
        t.phone,
        r.room_number,
        rt.name AS room_type,
        rt.base_price,
        t.start_date,
        t.is_active,
        t.created_at
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE r.kos_id = ?
      ORDER BY t.name ASC
      `,
      [kosId]
    );

    const headers = [
      "ID",
      "Name",
      "Email",
      "Phone",
      "Room Number",
      "Room Type",
      "Base Price",
      "Start Date",
      "Active",
      "Registered At",
    ];

    const dataRows = rows.map((row) => [
      row.id,
      row.name,
      row.email,
      row.phone || "",
      row.room_number,
      row.room_type,
      row.base_price,
      formatDate(row.start_date),
      Number(row.is_active) === 1 ? "Yes" : "No",
      formatDateTime(row.created_at),
    ]);

    const today = new Date().toISOString().slice(0, 10);
    const csv = buildCsv(headers, dataRows);

    res.setHeader("Content-Type", "text/csv; charset=utf-8");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="tenants_kos_${kosId}_${today}.csv"`
    );

    return res.status(200).send(csv);
  } catch (error) {
    console.error("[Export] Tenants export error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to export tenants",
    });
  }
};