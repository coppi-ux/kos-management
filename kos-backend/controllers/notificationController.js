const db = require("../config/db");

exports.getOwnerNotifications = async (req, res) => {
  const { ownerId } = req.params;

  console.log("GET OWNER NOTIFICATIONS:", ownerId);

  try {
    const [rows] = await db.query(
      `
      SELECT
        id,
        owner_id,
        bill_id,
        kos_id,
        tenant_id,
        tenant_name,
        room_number,
        billing_month,
        total_amount,
        bill_status,
        type,
        title,
        message,
        is_read,
        created_at,
        updated_at
      FROM v_notification_details
      WHERE owner_id = ?
      ORDER BY created_at DESC
      `,
      [ownerId]
    );

    console.log("OWNER NOTIFICATIONS RESULT:", rows);

    return res.json({
      success: true,
      notifications: rows,
      data: rows,
    });
  } catch (error) {
    console.error("Get owner notifications error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Database error",
    });
  }
};

exports.getUnreadCount = async (req, res) => {
  const { ownerId } = req.params;

  console.log("GET OWNER UNREAD NOTIFICATION COUNT:", ownerId);

  try {
    const [rows] = await db.query(
      `
      SELECT COUNT(*) AS count
      FROM notifications
      WHERE owner_id = ?
        AND is_read = 0
      `,
      [ownerId]
    );

    return res.json({
      success: true,
      count: rows[0]?.count || 0,
    });
  } catch (error) {
    console.error("Get unread notification count error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Database error",
    });
  }
};

exports.markRead = async (req, res) => {
  const { id } = req.params;

  console.log("MARK NOTIFICATION READ:", id);

  try {
    const [result] = await db.query(
      `
      UPDATE notifications
      SET is_read = 1
      WHERE id = ?
      `,
      [id]
    );

    return res.json({
      success: true,
      message: "Notification marked as read",
      affectedRows: result.affectedRows,
    });
  } catch (error) {
    console.error("Mark notification read error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to update notification",
    });
  }
};

exports.markAllReadOwner = async (req, res) => {
  const { ownerId } = req.params;

  console.log("MARK ALL OWNER NOTIFICATIONS READ:", ownerId);

  try {
    const [result] = await db.query(
      `
      UPDATE notifications
      SET is_read = 1
      WHERE owner_id = ?
        AND is_read = 0
      `,
      [ownerId]
    );

    return res.json({
      success: true,
      message: "All owner notifications marked as read",
      affectedRows: result.affectedRows,
    });
  } catch (error) {
    console.error("Mark all owner notifications read error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to update notifications",
    });
  }
};

exports.getTenantNotifications = async (req, res) => {
  const { tenantId } = req.params;

  console.log("GET TENANT NOTIFICATIONS:", tenantId);

  return res.json({
    success: true,
    notifications: [],
    data: [],
    message:
      "Tenant notifications are not enabled in the current database schema",
  });
};