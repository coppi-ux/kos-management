const db = require("../config/db");

const Room = {
  create: (data, callback) => {
    const sql = `
      INSERT INTO rooms (kos_id, room_type_id, room_number) 
      VALUES (?, ?, ?)
    `;
    db.query(sql, [data.kos_id, data.room_type_id, data.room_number], callback);
  },

  findByKosId: (kosId, callback) => {
    const sql = `
      SELECT r.*, rt.name as type_name, rt.base_price 
      FROM rooms r
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE r.kos_id = ?
    `;
    db.query(sql, [kosId], callback);
  },

  findById: (id, callback) => {
    const sql = "SELECT * FROM rooms WHERE id = ?";
    db.query(sql, [id], callback);
  },

  updateStatus: (id, status, callback) => {
    const sql = "UPDATE rooms SET status = ? WHERE id = ?";
    db.query(sql, [status, id], callback);
  },
};

module.exports = Room;