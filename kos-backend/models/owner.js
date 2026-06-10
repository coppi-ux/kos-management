const db = require("../config/db");

const Owner = {
  create: (data, callback) => {
    const sql = "INSERT INTO owners (name, email, password) VALUES (?, ?, ?)";
    db.query(sql, [data.name, data.email, data.password], callback);
  },

  findByEmail: (email, callback) => {
    const sql = "SELECT * FROM owners WHERE email = ?";
    db.query(sql, [email], callback);
  },
};

module.exports = Owner;