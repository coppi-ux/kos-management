const db = require("../config/db");

const Tenant = {
  create: (data, callback) => {
    const sql = `
      INSERT INTO tenants (name, email, phone, room_id, start_date) 
      VALUES (?, ?, ?, ?, ?)
    `;
    db.query(
      sql,
      [data.name, data.email, data.phone, data.room_id, data.start_date],
      callback
    );
  },

  findByKosId: (kosId, activeOnly = true, callback) => {
  const sql = `
    SELECT t.*, r.room_number, rt.name as room_type, rt.base_price
    FROM tenants t
    JOIN rooms r ON t.room_id = r.id
    JOIN room_types rt ON r.room_type_id = rt.id
    WHERE r.kos_id = ?
    ${activeOnly ? 'AND t.is_active = true' : ''}
    ORDER BY t.is_active DESC, t.name ASC
  `;
  db.query(sql, [kosId], callback);
  },

  findById: (id, callback) => {
    const sql = "SELECT * FROM tenants WHERE id = ?";
    db.query(sql, [id], callback);
  },

  deactivate: (id, callback) => {
    const sql = "UPDATE tenants SET is_active = false WHERE id = ?";
    db.query(sql, [id], callback);
  },
};

module.exports = Tenant;