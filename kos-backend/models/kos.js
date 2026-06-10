const db = require("../config/db");

const Kos = {
  create: (data, callback) => {
    const sql = "INSERT INTO kos (owner_id, name, address) VALUES (?, ?, ?)";
    db.query(sql, [data.owner_id, data.name, data.address], callback);
  },

  findById: (id, callback) => {
    const sql = "SELECT * FROM kos WHERE id = ?";
    db.query(sql, [id], callback);
  },

  findByOwnerId: (ownerId, callback) => {
    const sql = "SELECT * FROM kos WHERE owner_id = ?";
    db.query(sql, [ownerId], callback);
  },
};

module.exports = Kos;