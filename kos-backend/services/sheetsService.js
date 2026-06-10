const { google } = require("googleapis");
const db = require("../config/db");

const getPrivateKey = () => {
  const key = process.env.GOOGLE_PRIVATE_KEY;

  if (!key) {
    throw new Error("GOOGLE_PRIVATE_KEY is missing");
  }

  return key.replace(/\\n/g, "\n");
};

const getAuth = () => {
  if (!process.env.GOOGLE_CLIENT_EMAIL) {
    throw new Error("GOOGLE_CLIENT_EMAIL is missing");
  }

  if (!process.env.GOOGLE_SHEET_ID) {
    throw new Error("GOOGLE_SHEET_ID is missing");
  }

  return new google.auth.JWT({
    email: process.env.GOOGLE_CLIENT_EMAIL,
    key: getPrivateKey(),
    scopes: ["https://www.googleapis.com/auth/spreadsheets"],
  });
};

const getSheets = () => {
  const auth = getAuth();

  return google.sheets({
    version: "v4",
    auth,
  });
};

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

const getBillsData = async (kosId) => {
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

  return rows;
};

const getTenantsData = async (kosId) => {
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
      CASE
        WHEN t.is_active = 1 THEN 'Active'
        ELSE 'Inactive'
      END AS status
    FROM tenants t
    JOIN rooms r ON t.room_id = r.id
    JOIN room_types rt ON r.room_type_id = rt.id
    WHERE r.kos_id = ?
    ORDER BY t.name ASC
    `,
    [kosId]
  );

  return rows;
};

const ensureSheet = async (sheets, spreadsheetId, sheetTitle) => {
  const meta = await sheets.spreadsheets.get({
    spreadsheetId,
  });

  const sheetExists = meta.data.sheets?.some((sheet) => {
    return sheet.properties?.title === sheetTitle;
  });

  if (sheetExists) return;

  await sheets.spreadsheets.batchUpdate({
    spreadsheetId,
    requestBody: {
      requests: [
        {
          addSheet: {
            properties: {
              title: sheetTitle,
            },
          },
        },
      ],
    },
  });
};

const writeSheet = async (sheets, spreadsheetId, sheetTitle, rows) => {
  await ensureSheet(sheets, spreadsheetId, sheetTitle);

  await sheets.spreadsheets.values.clear({
    spreadsheetId,
    range: `${sheetTitle}!A:Z`,
  });

  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: `${sheetTitle}!A1`,
    valueInputOption: "RAW",
    requestBody: {
      values: rows,
    },
  });
};

const buildBillRows = (bills) => {
  return [
    [
      "ID",
      "Tenant",
      "Room",
      "Type",
      "Month",
      "Base (Rp)",
      "Addons (Rp)",
      "Penalty (Rp)",
      "Total (Rp)",
      "Due Date",
      "Paid Date",
      "Status",
      "Created At",
    ],
    ...bills.map((bill) => [
      bill.id,
      bill.tenant_name || "",
      bill.room_number || "",
      bill.room_type || "",
      bill.billing_month || "",
      Number(bill.base_amount || 0),
      Number(bill.addon_amount || 0),
      Number(bill.penalty_amount || 0),
      Number(bill.total_amount || 0),
      formatDate(bill.due_date),
      formatDate(bill.paid_date),
      bill.status || "",
      formatDateTime(bill.created_at),
    ]),
  ];
};

const buildTenantRows = (tenants) => {
  return [
    [
      "ID",
      "Name",
      "Email",
      "Phone",
      "Room",
      "Type",
      "Base Price (Rp)",
      "Start Date",
      "Status",
    ],
    ...tenants.map((tenant) => [
      tenant.id,
      tenant.name || "",
      tenant.email || "",
      tenant.phone || "",
      tenant.room_number || "",
      tenant.room_type || "",
      Number(tenant.base_price || 0),
      formatDate(tenant.start_date),
      tenant.status || "",
    ]),
  ];
};

const syncToSheets = async (kosId) => {
  const parsedKosId = Number(kosId);

  if (Number.isNaN(parsedKosId) || parsedKosId <= 0) {
    throw new Error("Invalid kosId");
  }

  const spreadsheetId = process.env.GOOGLE_SHEET_ID;

  if (!spreadsheetId) {
    throw new Error("GOOGLE_SHEET_ID is missing");
  }

  const sheets = getSheets();

  const [bills, tenants] = await Promise.all([
    getBillsData(parsedKosId),
    getTenantsData(parsedKosId),
  ]);

  const billRows = buildBillRows(bills);
  const tenantRows = buildTenantRows(tenants);

  await writeSheet(sheets, spreadsheetId, "Bills", billRows);
  await writeSheet(sheets, spreadsheetId, "Tenants", tenantRows);

  return {
    bills_synced: bills.length,
    tenants_synced: tenants.length,
  };
};

module.exports = {
  syncToSheets,
};