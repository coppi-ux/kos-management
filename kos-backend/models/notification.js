const db = require("../config/db");

const Notification = {
  findByRecipient: (recipientType, recipientId, callback) => {
    const sql = `
      SELECT * FROM notifications
      WHERE recipient_type = ? AND recipient_id = ?
      ORDER BY created_at DESC
      LIMIT 50
    `;
    db.query(sql, [recipientType, recipientId], callback);
  },

  markRead: (id, callback) => {
    const sql = "UPDATE notifications SET is_read = true WHERE id = ?";
    db.query(sql, [id], callback);
  },

  markAllRead: (recipientType, recipientId, callback) => {
    const sql = `
      UPDATE notifications SET is_read = true
      WHERE recipient_type = ? AND recipient_id = ?
    `;
    db.query(sql, [recipientType, recipientId], callback);
  },

  getUnreadCount: (recipientType, recipientId, callback) => {
    const sql = `
      SELECT COUNT(*) as count FROM notifications
      WHERE recipient_type = ? AND recipient_id = ? AND is_read = false
    `;
    db.query(sql, [recipientType, recipientId], callback);
  },
};

module.exports = Notification;