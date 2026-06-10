const db = require("../config/db");

const RoomType = {
  create: (data, callback) => {
    const sql = "INSERT INTO room_types (kos_id, name, base_price) VALUES (?, ?, ?)";
    db.query(sql, [data.kos_id, data.name, data.base_price], callback);
  },

  findByKosId: (kosId, callback) => {
    const sql = "SELECT * FROM room_types WHERE kos_id = ?";
    db.query(sql, [kosId], callback);
  },
};

module.exports = RoomType;