const db = require("../config/db");

const TenantAuth = {
  findByEmail: async (email) => {
    const cleanEmail = email.toString().trim().toLowerCase();

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
        t.password,
        t.password_set,
        t.created_at,
        t.updated_at,

        r.room_number,
        r.kos_id,

        rt.name AS room_type,
        rt.base_price
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE LOWER(t.email) = ?
        AND t.is_active = 1
      LIMIT 1
      `,
      [cleanEmail]
    );

    return rows;
  },

  setPassword: async (tenantId, hashedPassword) => {
    const [result] = await db.query(
      `
      UPDATE tenants
      SET
        password = ?,
        password_set = 1
      WHERE id = ?
        AND is_active = 1
      `,
      [hashedPassword, tenantId]
    );

    return result;
  },

  findById: async (id) => {
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
        t.password_set,
        t.created_at,
        t.updated_at,

        r.room_number,
        r.kos_id,

        rt.name AS room_type,
        rt.base_price
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE t.id = ?
      LIMIT 1
      `,
      [id]
    );

    return rows;
  },
};

module.exports = TenantAuth;