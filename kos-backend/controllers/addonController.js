const db = require("../config/db");

const toNumber = (value) => {
  const number = Number(value || 0);
  return Number.isNaN(number) ? 0 : number;
};

const toPositiveInt = (value) => {
  const number = Number(value || 0);
  if (Number.isNaN(number) || number <= 0) return 0;
  return Math.floor(number);
};

const formatDate = (value) => {
  if (!value) return null;

  if (value instanceof Date) {
    return value.toISOString().split("T")[0];
  }

  return value.toString().split("T")[0];
};

const getCurrentBillingMonth = async (connection) => {
  const [rows] = await connection.query(
    `
    SELECT DATE_FORMAT(CURDATE(), '%Y-%m') AS billing_month
    `
  );

  return rows[0].billing_month;
};

const getTenantAddonTotal = async (connection, tenantId) => {
  const [rows] = await connection.query(
    `
    SELECT
      COALESCE(SUM(a.price), 0) AS total_addon_amount
    FROM tenant_addons ta
    JOIN addons a ON ta.addon_id = a.id
    WHERE ta.tenant_id = ?
      AND ta.is_active = 1
      AND a.is_active = 1
    `,
    [tenantId]
  );

  return toNumber(rows[0]?.total_addon_amount);
};

const refreshCurrentUnpaidBill = async (connection, tenantId, kosId) => {
  const [tenantRows] = await connection.query(
    `
    SELECT
      t.id AS tenant_id,
      t.name AS tenant_name,
      r.id AS room_id,
      r.kos_id,
      rt.base_price
    FROM tenants t
    JOIN rooms r ON t.room_id = r.id
    JOIN room_types rt ON r.room_type_id = rt.id
    WHERE t.id = ?
      AND r.kos_id = ?
      AND t.is_active = 1
    LIMIT 1
    `,
    [tenantId, kosId]
  );

  if (tenantRows.length === 0) {
    throw new Error("Active tenant not found for this kos");
  }

  const tenant = tenantRows[0];
  const billingMonth = await getCurrentBillingMonth(connection);
  const addonTotal = await getTenantAddonTotal(connection, tenantId);
  const baseAmount = toNumber(tenant.base_price);

  const [billRows] = await connection.query(
    `
    SELECT
      id,
      base_amount,
      addon_amount,
      penalty_amount,
      total_amount,
      status
    FROM bills
    WHERE tenant_id = ?
      AND billing_month = ?
    LIMIT 1
    `,
    [tenantId, billingMonth]
  );

  if (billRows.length === 0) {
    const penaltyAmount = 0;
    const totalAmount = baseAmount + addonTotal + penaltyAmount;

    const [insertResult] = await connection.query(
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
        addonTotal,
        penaltyAmount,
        totalAmount,
      ]
    );

    return {
      bill_id: insertResult.insertId,
      tenant_name: tenant.tenant_name,
      billing_month: billingMonth,
      base_amount: baseAmount,
      addon_amount: addonTotal,
      penalty_amount: penaltyAmount,
      total_amount: totalAmount,
      status: "unpaid",
      skipped_update: false,
    };
  }

  const bill = billRows[0];
  const penaltyAmount = toNumber(bill.penalty_amount);
  const totalAmount = baseAmount + addonTotal + penaltyAmount;

  if (bill.status === "paid") {
    return {
      bill_id: bill.id,
      tenant_name: tenant.tenant_name,
      billing_month: billingMonth,
      base_amount: toNumber(bill.base_amount),
      addon_amount: addonTotal,
      penalty_amount: penaltyAmount,
      total_amount: totalAmount,
      status: "paid",
      skipped_update: true,
    };
  }

  await connection.query(
    `
    UPDATE bills
    SET
      base_amount = ?,
      addon_amount = ?,
      penalty_amount = ?,
      total_amount = ?
    WHERE id = ?
      AND status = 'unpaid'
    `,
    [
      baseAmount,
      addonTotal,
      penaltyAmount,
      totalAmount,
      bill.id,
    ]
  );

  return {
    bill_id: bill.id,
    tenant_name: tenant.tenant_name,
    billing_month: billingMonth,
    base_amount: baseAmount,
    addon_amount: addonTotal,
    penalty_amount: penaltyAmount,
    total_amount: totalAmount,
    status: "unpaid",
    skipped_update: false,
  };
};

exports.createAddon = async (req, res) => {
  try {
    const kosId = toPositiveInt(req.body.kos_id);
    const { name, price } = req.body;

    if (!kosId || !name || price === undefined || price === null) {
      return res.status(400).json({
        success: false,
        message: "kos_id, name, and price are required",
      });
    }

    const priceNumber = Number(price);

    if (Number.isNaN(priceNumber) || priceNumber <= 0) {
      return res.status(400).json({
        success: false,
        message: "Price must be a positive number",
      });
    }

    const cleanName = name.toString().trim();

    if (!cleanName) {
      return res.status(400).json({
        success: false,
        message: "Add-on name is required",
      });
    }

    const [kosRows] = await db.query(
      `
      SELECT id
      FROM kos
      WHERE id = ?
      LIMIT 1
      `,
      [kosId]
    );

    if (kosRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Kos not found",
      });
    }

    const [existingRows] = await db.query(
      `
      SELECT id, is_active
      FROM addons
      WHERE kos_id = ?
        AND name = ?
      LIMIT 1
      `,
      [kosId, cleanName]
    );

    if (existingRows.length > 0) {
      const existingAddon = existingRows[0];

      if (Number(existingAddon.is_active) === 1) {
        return res.status(400).json({
          success: false,
          message: "Add-on already exists",
        });
      }

      await db.query(
        `
        UPDATE addons
        SET
          price = ?,
          is_active = 1
        WHERE id = ?
        `,
        [priceNumber, existingAddon.id]
      );

      const addon = {
        id: existingAddon.id,
        kos_id: kosId,
        name: cleanName,
        price: priceNumber,
        is_active: 1,
      };

      return res.status(200).json({
        success: true,
        message: "Add-on reactivated successfully",
        addon_id: existingAddon.id,
        addon,
        data: addon,
      });
    }

    const [result] = await db.query(
      `
      INSERT INTO addons (
        kos_id,
        name,
        price,
        is_active
      )
      VALUES (?, ?, ?, 1)
      `,
      [kosId, cleanName, priceNumber]
    );

    const addon = {
      id: result.insertId,
      kos_id: kosId,
      name: cleanName,
      price: priceNumber,
      is_active: 1,
    };

    return res.status(201).json({
      success: true,
      message: "Add-on created successfully",
      addon_id: result.insertId,
      addon,
      data: addon,
    });
  } catch (error) {
    console.error("Create addon error:", error);

    if (error.code === "ER_DUP_ENTRY") {
      return res.status(400).json({
        success: false,
        message: "Add-on already exists",
      });
    }

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to create addon",
    });
  }
};

exports.getAddonsByKos = async (req, res) => {
  try {
    const kosId = toPositiveInt(req.params.kosId || req.params.id);

    if (!kosId) {
      return res.status(400).json({
        success: false,
        message: "Invalid kos selected",
      });
    }

    const [rows] = await db.query(
      `
      SELECT
        id,
        kos_id,
        name,
        price,
        is_active,
        created_at,
        updated_at
      FROM addons
      WHERE kos_id = ?
        AND is_active = 1
      ORDER BY created_at DESC
      `,
      [kosId]
    );

    const addons = rows.map((addon) => ({
      ...addon,
      price: toNumber(addon.price),
      created_at: formatDate(addon.created_at),
      updated_at: formatDate(addon.updated_at),
    }));

    return res.json({
      success: true,
      addons,
      kos_addons: addons,
      data: addons,
    });
  } catch (error) {
    console.error("Get addons error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Database error",
    });
  }
};

exports.getTenantsByKosForAddon = async (req, res) => {
  try {
    const kosId = toPositiveInt(req.params.kosId || req.params.id);

    if (!kosId) {
      return res.status(400).json({
        success: false,
        message: "Invalid kos selected",
      });
    }

    const [rows] = await db.query(
      `
      SELECT
        t.id,
        t.name,
        t.email,
        t.phone,
        t.room_id,
        t.start_date,
        t.is_active,
        r.room_number,
        r.kos_id
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      WHERE r.kos_id = ?
        AND t.is_active = 1
      ORDER BY t.name ASC
      `,
      [kosId]
    );

    const tenants = rows.map((tenant) => ({
      ...tenant,
      start_date: formatDate(tenant.start_date),
    }));

    return res.json({
      success: true,
      tenants,
      data: tenants,
    });
  } catch (error) {
    console.error("Get tenants for addon error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch tenants",
    });
  }
};

exports.deleteAddon = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const addonId = toPositiveInt(req.params.id || req.params.addonId);

    if (!addonId) {
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Invalid add-on selected",
      });
    }

    await connection.beginTransaction();

    const [addonRows] = await connection.query(
      `
      SELECT id, kos_id
      FROM addons
      WHERE id = ?
      LIMIT 1
      `,
      [addonId]
    );

    if (addonRows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Add-on not found",
      });
    }

    const addon = addonRows[0];

    const [tenantRows] = await connection.query(
      `
      SELECT DISTINCT tenant_id
      FROM tenant_addons
      WHERE addon_id = ?
        AND is_active = 1
      `,
      [addonId]
    );

    await connection.query(
      `
      UPDATE addons
      SET is_active = 0
      WHERE id = ?
      `,
      [addonId]
    );

    await connection.query(
      `
      UPDATE tenant_addons
      SET
        is_active = 0,
        end_date = CURDATE()
      WHERE addon_id = ?
        AND is_active = 1
      `,
      [addonId]
    );

    for (const tenant of tenantRows) {
      await refreshCurrentUnpaidBill(
        connection,
        tenant.tenant_id,
        addon.kos_id
      );
    }

    await connection.commit();
    connection.release();

    return res.json({
      success: true,
      message: "Addon deleted",
    });
  } catch (error) {
    await connection.rollback();
    connection.release();

    console.error("Delete addon error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to delete addon",
    });
  }
};

exports.clearKosAddons = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const kosId = toPositiveInt(req.params.kosId || req.params.id);

    if (!kosId) {
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Invalid kos selected",
      });
    }

    await connection.beginTransaction();

    const [addonRows] = await connection.query(
      `
      SELECT id
      FROM addons
      WHERE kos_id = ?
        AND is_active = 1
      `,
      [kosId]
    );

    if (addonRows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "No active add-ons found",
      });
    }

    const addonIds = addonRows.map((addon) => addon.id);
    const placeholders = addonIds.map(() => "?").join(",");

    const [tenantRows] = await connection.query(
      `
      SELECT DISTINCT tenant_id
      FROM tenant_addons
      WHERE addon_id IN (${placeholders})
        AND is_active = 1
      `,
      addonIds
    );

    await connection.query(
      `
      UPDATE addons
      SET is_active = 0
      WHERE kos_id = ?
        AND is_active = 1
      `,
      [kosId]
    );

    await connection.query(
      `
      UPDATE tenant_addons
      SET
        is_active = 0,
        end_date = CURDATE()
      WHERE addon_id IN (${placeholders})
        AND is_active = 1
      `,
      addonIds
    );

    for (const tenant of tenantRows) {
      await refreshCurrentUnpaidBill(
        connection,
        tenant.tenant_id,
        kosId
      );
    }

    await connection.commit();
    connection.release();

    return res.json({
      success: true,
      message: "All add-ons cleared successfully",
      cleared_count: addonIds.length,
    });
  } catch (error) {
    await connection.rollback();
    connection.release();

    console.error("Clear kos add-ons error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to clear add-ons",
    });
  }
};

exports.addAddonsToBill = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const kosId = toPositiveInt(req.body.kos_id);
    const tenantId = toPositiveInt(req.body.tenant_id);
    const addonIds = req.body.addon_ids;

    if (!kosId || !tenantId) {
      connection.release();

      return res.status(400).json({
        success: false,
        message: "kos_id and tenant_id are required",
      });
    }

    await connection.beginTransaction();

    const [tenantRows] = await connection.query(
      `
      SELECT
        t.id AS tenant_id,
        t.name AS tenant_name,
        r.id AS room_id,
        r.kos_id,
        rt.base_price
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE t.id = ?
        AND r.kos_id = ?
        AND t.is_active = 1
      LIMIT 1
      `,
      [tenantId, kosId]
    );

    if (tenantRows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Active tenant not found for this kos",
      });
    }

    let addonRows = [];

    if (Array.isArray(addonIds) && addonIds.length > 0) {
      const validAddonIds = addonIds
        .map((id) => Number(id))
        .filter((id) => id > 0);

      if (validAddonIds.length === 0) {
        await connection.rollback();
        connection.release();

        return res.status(400).json({
          success: false,
          message: "No valid add-ons found",
        });
      }

      const uniqueAddonIds = [...new Set(validAddonIds)];
      const placeholders = uniqueAddonIds.map(() => "?").join(",");

      const [rows] = await connection.query(
        `
        SELECT
          id,
          kos_id,
          name,
          price
        FROM addons
        WHERE kos_id = ?
          AND is_active = 1
          AND id IN (${placeholders})
        `,
        [kosId, ...uniqueAddonIds]
      );

      addonRows = rows;
    } else {
      const [rows] = await connection.query(
        `
        SELECT
          id,
          kos_id,
          name,
          price
        FROM addons
        WHERE kos_id = ?
          AND is_active = 1
        `,
        [kosId]
      );

      addonRows = rows;
    }

    if (addonRows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(400).json({
        success: false,
        message: "No active add-ons found",
      });
    }

    for (const addon of addonRows) {
      const [existingRows] = await connection.query(
        `
        SELECT
          id,
          is_active
        FROM tenant_addons
        WHERE tenant_id = ?
          AND addon_id = ?
        LIMIT 1
        `,
        [tenantId, addon.id]
      );

      if (existingRows.length > 0) {
        const existing = existingRows[0];

        if (Number(existing.is_active) === 0) {
          await connection.query(
            `
            UPDATE tenant_addons
            SET
              is_active = 1,
              start_date = CURDATE(),
              end_date = NULL
            WHERE id = ?
            `,
            [existing.id]
          );
        }
      } else {
        await connection.query(
          `
          INSERT INTO tenant_addons (
            tenant_id,
            addon_id,
            start_date,
            is_active
          )
          VALUES (?, ?, CURDATE(), 1)
          `,
          [tenantId, addon.id]
        );
      }
    }

    const refreshedBill = await refreshCurrentUnpaidBill(
      connection,
      tenantId,
      kosId
    );

    const assignedAddons = addonRows.map((addon) => ({
      id: addon.id,
      addon_id: addon.id,
      kos_id: addon.kos_id,
      tenant_id: tenantId,
      name: addon.name,
      addon_name: addon.name,
      price: toNumber(addon.price),
      addon_price: toNumber(addon.price),
      is_active: 1,
    }));

    await connection.commit();
    connection.release();

    return res.status(200).json({
      success: true,
      message: "Add-ons added to bill successfully",
      tenant_name: refreshedBill.tenant_name,
      addons: assignedAddons,
      tenant_addons: assignedAddons,
      addon_total: refreshedBill.addon_amount,
      base_amount: refreshedBill.base_amount,
      penalty_amount: refreshedBill.penalty_amount,
      total_amount: refreshedBill.total_amount,
      billing_month: refreshedBill.billing_month,
      bill_id: refreshedBill.bill_id,
      bill: refreshedBill,
      data: {
        bill: refreshedBill,
        addons: assignedAddons,
        tenant_addons: assignedAddons,
      },
    });
  } catch (error) {
    await connection.rollback();
    connection.release();

    console.error("Add add-ons to bill error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to add add-ons to bill",
    });
  }
};

exports.assignAddon = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const tenantId = toPositiveInt(req.body.tenant_id);
    const addonId = toPositiveInt(req.body.addon_id);

    if (!tenantId || !addonId) {
      connection.release();

      return res.status(400).json({
        success: false,
        message: "tenant_id and addon_id required",
      });
    }

    await connection.beginTransaction();

    const [tenantRows] = await connection.query(
      `
      SELECT
        t.id AS tenant_id,
        t.name AS tenant_name,
        r.kos_id
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      WHERE t.id = ?
        AND t.is_active = 1
      LIMIT 1
      `,
      [tenantId]
    );

    if (tenantRows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Active tenant not found",
      });
    }

    const tenant = tenantRows[0];

    const [addonRows] = await connection.query(
      `
      SELECT
        id,
        kos_id,
        name,
        price
      FROM addons
      WHERE id = ?
        AND kos_id = ?
        AND is_active = 1
      LIMIT 1
      `,
      [addonId, tenant.kos_id]
    );

    if (addonRows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Active addon not found for this tenant kos",
      });
    }

    const selectedAddon = addonRows[0];

    const [existingRows] = await connection.query(
      `
      SELECT id, is_active
      FROM tenant_addons
      WHERE tenant_id = ?
        AND addon_id = ?
      LIMIT 1
      `,
      [tenantId, addonId]
    );

    let tenantAddonId;

    if (existingRows.length > 0) {
      const existing = existingRows[0];

      tenantAddonId = existing.id;

      if (Number(existing.is_active) === 1) {
        await connection.rollback();
        connection.release();

        return res.status(400).json({
          success: false,
          message: "Addon already assigned to this tenant",
        });
      }

      await connection.query(
        `
        UPDATE tenant_addons
        SET
          is_active = 1,
          start_date = CURDATE(),
          end_date = NULL
        WHERE id = ?
        `,
        [existing.id]
      );
    } else {
      const [result] = await connection.query(
        `
        INSERT INTO tenant_addons (
          tenant_id,
          addon_id,
          start_date,
          is_active
        )
        VALUES (?, ?, CURDATE(), 1)
        `,
        [tenantId, addonId]
      );

      tenantAddonId = result.insertId;
    }

    const refreshedBill = await refreshCurrentUnpaidBill(
      connection,
      tenantId,
      tenant.kos_id
    );

    const addon = {
      id: selectedAddon.id,
      tenant_addon_id: tenantAddonId,
      addon_id: selectedAddon.id,
      tenant_id: tenantId,
      kos_id: selectedAddon.kos_id,
      name: selectedAddon.name,
      addon_name: selectedAddon.name,
      price: toNumber(selectedAddon.price),
      addon_price: toNumber(selectedAddon.price),
      is_active: 1,
    };

    await connection.commit();
    connection.release();

    return res.status(200).json({
      success: true,
      message: "Addon assigned successfully",
      tenant_addon_id: tenantAddonId,
      addon,
      addons: [addon],
      tenant_addons: [addon],
      bill: refreshedBill,
      data: {
        addon,
        bill: refreshedBill,
      },
    });
  } catch (error) {
    await connection.rollback();
    connection.release();

    console.error("Assign addon error:", error);

    if (error.code === "ER_DUP_ENTRY") {
      return res.status(400).json({
        success: false,
        message: "Addon already assigned to this tenant",
      });
    }

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to assign addon",
    });
  }
};

exports.removeAddon = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const tenantId = toPositiveInt(
      req.body.tenant_id ||
        req.params.tenantId ||
        req.params.tenant_id ||
        req.query.tenant_id
    );

    const addonId = toPositiveInt(
      req.body.addon_id ||
        req.params.addonId ||
        req.params.addon_id ||
        req.params.id ||
        req.query.addon_id
    );

    if (!tenantId || !addonId) {
      connection.release();

      return res.status(400).json({
        success: false,
        message: "tenant_id and addon_id required",
      });
    }

    await connection.beginTransaction();

    const [addonRows] = await connection.query(
      `
      SELECT
        a.id,
        a.kos_id
      FROM addons a
      WHERE a.id = ?
      LIMIT 1
      `,
      [addonId]
    );

    if (addonRows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Add-on not found",
      });
    }

    const [result] = await connection.query(
      `
      UPDATE tenant_addons
      SET
        is_active = 0,
        end_date = CURDATE()
      WHERE tenant_id = ?
        AND addon_id = ?
        AND is_active = 1
      `,
      [tenantId, addonId]
    );

    if (result.affectedRows === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Active tenant addon not found",
      });
    }

    const refreshedBill = await refreshCurrentUnpaidBill(
      connection,
      tenantId,
      addonRows[0].kos_id
    );

    await connection.commit();
    connection.release();

    return res.json({
      success: true,
      message: "Addon removed from tenant",
      bill: refreshedBill,
      data: refreshedBill,
    });
  } catch (error) {
    await connection.rollback();
    connection.release();

    console.error("Remove addon error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to remove addon",
    });
  }
};

exports.getTenantAddons = async (req, res) => {
  try {
    const tenantId = toPositiveInt(
      req.params.tenantId ||
        req.params.tenant_id ||
        req.params.id ||
        req.query.tenant_id
    );

    if (!tenantId) {
      return res.status(400).json({
        success: false,
        message: "Invalid tenant selected",
      });
    }

    const [tenantRows] = await db.query(
      `
      SELECT
        t.id,
        t.name,
        t.is_active,
        r.kos_id,
        r.room_number
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      WHERE t.id = ?
      LIMIT 1
      `,
      [tenantId]
    );

    if (tenantRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Tenant not found",
      });
    }

    const tenant = tenantRows[0];

    const [rows] = await db.query(
      `
      SELECT
        ta.id AS tenant_addon_id,
        ta.tenant_id,
        ta.addon_id,
        ta.start_date,
        ta.end_date,
        ta.is_active,
        ta.created_at AS assigned_at,
        a.id AS id,
        a.kos_id,
        a.name,
        a.name AS addon_name,
        a.price,
        a.price AS addon_price,
        a.created_at,
        a.updated_at
      FROM tenant_addons ta
      JOIN addons a ON ta.addon_id = a.id
      WHERE ta.tenant_id = ?
        AND ta.is_active = 1
        AND a.is_active = 1
      ORDER BY ta.created_at DESC, ta.id DESC
      `,
      [tenantId]
    );

    const addons = rows.map((addon) => ({
      ...addon,
      tenant_id: toNumber(addon.tenant_id),
      addon_id: toNumber(addon.addon_id),
      id: toNumber(addon.id),
      tenant_addon_id: toNumber(addon.tenant_addon_id),
      kos_id: toNumber(addon.kos_id),
      quantity: 1,
      qty: 1,
      start_date: formatDate(addon.start_date),
      end_date: formatDate(addon.end_date),
      assigned_at: formatDate(addon.assigned_at),
      created_at: formatDate(addon.created_at),
      updated_at: formatDate(addon.updated_at),
      price: toNumber(addon.price),
      addon_price: toNumber(addon.addon_price),
      total: toNumber(addon.price),
      subtotal: toNumber(addon.price),
    }));

    const totalAddonAmount = addons.reduce((sum, addon) => {
      return sum + toNumber(addon.price);
    }, 0);

    return res.json({
      success: true,
      tenant: {
        id: tenant.id,
        name: tenant.name,
        is_active: tenant.is_active,
        kos_id: tenant.kos_id,
        room_number: tenant.room_number,
      },
      addons,
      tenant_addons: addons,
      total_addon_amount: totalAddonAmount,
      total: totalAddonAmount,
      count: addons.length,
      data: addons,
    });
  } catch (error) {
    console.error("Get tenant addons error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Database error",
    });
  }
};