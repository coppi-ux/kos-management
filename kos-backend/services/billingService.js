const Bill = require("../models/bill");
const Addon = require("../models/addon");
const db = require("../config/db");

const {
  onBillGenerated,
  onDueSoon,
  onOverdue,
} = require("./notificationService");

const PENALTY_PER_DAY = 10000;

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

const getBillingMonth = (date) => {
  const d = new Date(date);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, "0");

  return `${year}-${month}`;
};

const getDueDate = (startDate, referenceDate) => {
  const start = new Date(startDate);
  const ref = new Date(referenceDate);

  const due = new Date(ref);
  due.setMonth(due.getMonth() + 1);
  due.setDate(start.getDate());

  return formatDate(due);
};

const getActiveTenants = (callback) => {
  const sql = `
    SELECT
      t.id AS tenant_id,
      t.name AS tenant_name,
      t.email,
      t.phone,
      t.start_date,
      t.room_id,

      r.kos_id,
      r.room_number,

      rt.id AS room_type_id,
      rt.name AS room_type,
      rt.base_price
    FROM tenants t
    JOIN rooms r ON t.room_id = r.id
    JOIN room_types rt ON r.room_type_id = rt.id
    WHERE t.is_active = 1
    ORDER BY t.id ASC
  `;

  db.query(sql, callback);
};

const getOwnerByKosId = (kosId, callback) => {
  const sql = `
    SELECT
      o.id,
      o.email
    FROM kos k
    JOIN owners o ON k.owner_id = o.id
    WHERE k.id = ?
    LIMIT 1
  `;

  db.query(sql, [kosId], callback);
};

const getTotalAddonAmount = (tenantId, callback) => {
  if (Addon && typeof Addon.getTotalAddonPrice === "function") {
    Addon.getTotalAddonPrice(tenantId, (err, addonResult) => {
      if (err) {
        callback(err);
        return;
      }

      const total = toNumber(addonResult?.[0]?.total);
      callback(null, total);
    });

    return;
  }

  const sql = `
    SELECT
      COALESCE(SUM(a.price), 0) AS total
    FROM tenant_addons ta
    JOIN addons a ON ta.addon_id = a.id
    WHERE ta.tenant_id = ?
      AND ta.is_active = 1
      AND a.is_active = 1
  `;

  db.query(sql, [tenantId], (err, rows) => {
    if (err) {
      callback(err);
      return;
    }

    callback(null, toNumber(rows?.[0]?.total));
  });
};

const buildBillData = (tenant, billingMonth, dueDate, addonAmount) => {
  const baseAmount = toNumber(tenant.base_price);
  const normalizedAddonAmount = toNumber(addonAmount);
  const penaltyAmount = 0;
  const totalAmount = baseAmount + normalizedAddonAmount + penaltyAmount;

  return {
    tenant_id: tenant.tenant_id,
    room_id: tenant.room_id,
    kos_id: tenant.kos_id,
    billing_month: billingMonth,
    base_amount: baseAmount,
    addon_amount: normalizedAddonAmount,
    penalty_amount: penaltyAmount,
    total_amount: totalAmount,
    due_date: dueDate,
  };
};

const createBillForTenant = (tenant, referenceDate, options = {}) => {
  const billingMonth = getBillingMonth(referenceDate);
  const dueDate = getDueDate(tenant.start_date, referenceDate);

  Bill.findExisting(tenant.tenant_id, billingMonth, (err, existing) => {
    if (err) {
      console.error(
        `[Billing] Failed checking existing bill for ${tenant.tenant_name}:`,
        err
      );
      return;
    }

    if (existing && existing.length > 0) {
      console.log(
        `[Billing] Already exists for ${tenant.tenant_name} - ${billingMonth}`
      );
      return;
    }

    getTotalAddonAmount(tenant.tenant_id, (err, addonAmount) => {
      if (err) {
        console.error(
          `[Billing] Failed getting add-ons for ${tenant.tenant_name}:`,
          err
        );
        return;
      }

      const billData = buildBillData(
        tenant,
        billingMonth,
        dueDate,
        addonAmount
      );

      Bill.create(billData, (err, result) => {
        if (err) {
          console.error(`[Billing] Failed for ${tenant.tenant_name}:`, err);
          return;
        }

        const createdBill = {
          id: result?.insertId,
          ...billData,
          tenant_name: tenant.tenant_name,
          room_number: tenant.room_number,
          room_type: tenant.room_type,
          status: "unpaid",
        };

        console.log(
          `[Billing] ✅ Bill created for ${tenant.tenant_name} - Base: Rp${billData.base_amount} + Addons: Rp${billData.addon_amount} = Rp${billData.total_amount}`
        );

        if (options.notify !== false) {
          onBillGenerated(tenant, createdBill);
        }
      });
    });
  });
};

const generateDueBills = () => {
  const today = new Date();
  const todayDay = today.getDate();

  console.log(`[Billing] Running billing check for day ${todayDay}...`);

  getActiveTenants((err, tenants) => {
    if (err) {
      console.error("[Billing] Error fetching tenants:", err);
      return;
    }

    if (!tenants || tenants.length === 0) {
      console.log("[Billing] No active tenants found.");
      return;
    }

    tenants.forEach((tenant) => {
      const startDate = new Date(tenant.start_date);
      const startDay = startDate.getDate();

      if (todayDay !== startDay) return;

      createBillForTenant(tenant, today, {
        notify: true,
      });
    });
  });
};

const forceGenerateAllBills = () => {
  const today = new Date();

  console.log("[Billing] Force generating bills for all tenants...");

  getActiveTenants((err, tenants) => {
    if (err) {
      console.error("[Billing] Error fetching tenants:", err);
      return;
    }

    if (!tenants || tenants.length === 0) {
      console.log("[Billing] No active tenants found.");
      return;
    }

    tenants.forEach((tenant) => {
      createBillForTenant(tenant, today, {
        notify: true,
      });
    });
  });
};

const checkDueSoon = () => {
  const today = new Date();
  const threeDaysLater = new Date(today);

  threeDaysLater.setDate(today.getDate() + 3);

  const targetDate = formatDate(threeDaysLater);

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

      t.name AS tenant_name,
      t.email,
      t.phone,

      r.room_number
    FROM bills b
    JOIN tenants t ON b.tenant_id = t.id
    JOIN rooms r ON b.room_id = r.id
    WHERE b.status = 'unpaid'
      AND DATE(b.due_date) = ?
  `;

  db.query(sql, [targetDate], (err, bills) => {
    if (err) {
      console.error("[DueSoon] Error fetching due soon bills:", err);
      return;
    }

    if (!bills || bills.length === 0) {
      console.log(`[DueSoon] No bills due soon for ${targetDate}.`);
      return;
    }

    bills.forEach((bill) => {
      console.log(`[DueSoon] Notifying ${bill.tenant_name}`);

      onDueSoon(
        {
          tenant_id: bill.tenant_id,
          tenant_name: bill.tenant_name,
          email: bill.email,
          phone: bill.phone,
        },
        {
          ...bill,
          due_date: formatDate(bill.due_date),
          paid_date: formatDate(bill.paid_date),
          base_amount: toNumber(bill.base_amount),
          addon_amount: toNumber(bill.addon_amount),
          penalty_amount: toNumber(bill.penalty_amount),
          total_amount: toNumber(bill.total_amount),
        }
      );
    });
  });
};

const updatePenalties = () => {
  const today = new Date();

  Bill.findOverdue((err, overdueBills) => {
    if (err) {
      console.error("[Penalty] Error fetching overdue bills:", err);
      return;
    }

    if (!overdueBills || overdueBills.length === 0) {
      console.log("[Penalty] No overdue bills found.");
      return;
    }

    overdueBills.forEach((bill) => {
      const dueDate = new Date(bill.due_date);

      if (Number.isNaN(dueDate.getTime())) {
        console.error(`[Penalty] Invalid due date for bill ${bill.id}`);
        return;
      }

      const daysLate = Math.floor(
        (today - dueDate) / (1000 * 60 * 60 * 24)
      );

      if (daysLate <= 0) return;

      const baseAmount = toNumber(bill.base_amount);
      const addonAmount = toNumber(bill.addon_amount);
      const penaltyAmount = daysLate * PENALTY_PER_DAY;
      const totalAmount = baseAmount + addonAmount + penaltyAmount;

      Bill.updatePenalty(bill.id, penaltyAmount, totalAmount, (err) => {
        if (err) {
          console.error(
            `[Penalty] Failed updating penalty for bill ${bill.id}:`,
            err
          );
          return;
        }

        console.log(
          `[Penalty] ${bill.tenant_name} - ${daysLate} days late - Rp${penaltyAmount}`
        );

        getOwnerByKosId(bill.kos_id, (err, owners) => {
          if (err) {
            console.error(
              `[Penalty] Failed fetching owner for kos ${bill.kos_id}:`,
              err
            );
            return;
          }

          if (!owners || owners.length === 0) {
            console.log(`[Penalty] Owner not found for kos ${bill.kos_id}`);
            return;
          }

          const owner = owners[0];

          onOverdue(
            {
              tenant_id: bill.tenant_id,
              tenant_name: bill.tenant_name,
              email: bill.email,
              phone: bill.phone,
            },
            {
              ...bill,
              days_late: daysLate,
              due_date: formatDate(bill.due_date),
              paid_date: formatDate(bill.paid_date),
              base_amount: baseAmount,
              addon_amount: addonAmount,
              penalty_amount: penaltyAmount,
              total_amount: totalAmount,
            },
            owner
          );
        });
      });
    });
  });
};

module.exports = {
  generateDueBills,
  updatePenalties,
  forceGenerateAllBills,
  checkDueSoon,

  // Optional export, berguna kalau nanti mau dipakai di test/debug.
  createBillForTenant,
  getBillingMonth,
  getDueDate,
};