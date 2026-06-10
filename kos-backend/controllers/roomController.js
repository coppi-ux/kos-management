const db = require("../config/db");

// POST /api/rooms
// Body: { kos_id, room_type_id, room_number }
exports.createRoom = async (req, res) => {
  try {
    const { kos_id, room_type_id, room_number } = req.body;

    if (!kos_id || !room_type_id || !room_number) {
      return res.status(400).json({
        success: false,
        message: "kos_id, room_type_id, and room_number are required",
      });
    }

    const [roomTypeRows] = await db.query(
      `
      SELECT id
      FROM room_types
      WHERE id = ?
        AND kos_id = ?
      LIMIT 1
      `,
      [room_type_id, kos_id]
    );

    if (roomTypeRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Room type not found for this kos",
      });
    }

    const [existingRoom] = await db.query(
      `
      SELECT id
      FROM rooms
      WHERE kos_id = ?
        AND room_number = ?
      LIMIT 1
      `,
      [kos_id, room_number]
    );

    if (existingRoom.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Room number already exists in this kos",
      });
    }

    const [result] = await db.query(
      `
      INSERT INTO rooms (
        kos_id,
        room_type_id,
        room_number,
        status
      )
      VALUES (?, ?, ?, 'available')
      `,
      [kos_id, room_type_id, room_number]
    );

    return res.status(201).json({
      success: true,
      message: "Room created successfully",
      room_id: result.insertId,
      room: {
        id: result.insertId,
        kos_id: Number(kos_id),
        room_type_id: Number(room_type_id),
        room_number,
        status: "available",
      },
    });
  } catch (error) {
    console.error("Create room error:", error);

    if (error.code === "ER_DUP_ENTRY") {
      return res.status(400).json({
        success: false,
        message: "Room number already exists in this kos",
      });
    }

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to create room",
    });
  }
};

// GET /api/rooms/:kosId
exports.getRoomsByKos = async (req, res) => {
  try {
    const { kosId } = req.params;

    const [rows] = await db.query(
      `
      SELECT
        r.id,
        r.kos_id,
        r.room_type_id,
        r.room_number,
        r.status,
        r.created_at,
        r.updated_at,

        rt.name AS type_name,
        rt.name AS room_type,
        rt.base_price
      FROM rooms r
      LEFT JOIN room_types rt ON r.room_type_id = rt.id
      WHERE r.kos_id = ?
      ORDER BY r.room_number ASC
      `,
      [kosId]
    );

    return res.json({
      success: true,
      rooms: rows,
    });
  } catch (error) {
    console.error("Get rooms error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch rooms",
    });
  }
};

// POST /api/tenants
// Body: { name, email, phone, room_id, start_date }
exports.createTenant = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const { name, email, phone, room_id, start_date } = req.body;

    if (!name || !email || !room_id || !start_date) {
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Name, email, room and start date are required",
      });
    }

    await connection.beginTransaction();

    const [roomRows] = await connection.query(
      `
      SELECT
        id,
        status
      FROM rooms
      WHERE id = ?
      LIMIT 1
      `,
      [room_id]
    );

    if (roomRows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Room not found",
      });
    }

    if (roomRows[0].status === "occupied") {
      await connection.rollback();
      connection.release();

      return res.status(400).json({
        success: false,
        message: "Room is already occupied",
      });
    }

    const [tenantResult] = await connection.query(
      `
      INSERT INTO tenants (
        room_id,
        name,
        email,
        phone,
        start_date,
        is_active
      )
      VALUES (?, ?, ?, ?, ?, 1)
      `,
      [
        room_id,
        name,
        email,
        phone || null,
        start_date,
      ]
    );

    await connection.query(
      `
      UPDATE rooms
      SET status = 'occupied'
      WHERE id = ?
      `,
      [room_id]
    );

    await connection.commit();
    connection.release();

    return res.status(201).json({
      success: true,
      message: "Tenant added successfully",
      tenant_id: tenantResult.insertId,
    });
  } catch (error) {
    await connection.rollback();
    connection.release();

    console.error("Create tenant error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to create tenant",
    });
  }
};

// GET /api/tenants/:kosId
// Query optional: ?active=false
exports.getTenantsByKos = async (req, res) => {
  try {
    const { kosId } = req.params;
    const activeOnly = req.query.active !== "false";

    let sql = `
      SELECT
        t.id,
        t.room_id,
        t.name,
        t.email,
        t.phone,
        t.start_date,
        t.is_active,
        t.created_at,
        t.updated_at,

        r.kos_id,
        r.room_number,
        r.status AS room_status,

        rt.id AS room_type_id,
        rt.name AS type_name,
        rt.name AS room_type,
        rt.base_price
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      LEFT JOIN room_types rt ON r.room_type_id = rt.id
      WHERE r.kos_id = ?
    `;

    const params = [kosId];

    if (activeOnly) {
      sql += " AND t.is_active = 1";
    }

    sql += " ORDER BY t.created_at DESC";

    const [rows] = await db.query(sql, params);

    return res.json({
      success: true,
      tenants: rows,
    });
  } catch (error) {
    console.error("Get tenants error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch tenants",
    });
  }
};

// DELETE /api/tenants/:id
// Soft delete tenant, then free the room
exports.deactivateTenant = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const { id } = req.params;

    await connection.beginTransaction();

    const [tenantRows] = await connection.query(
      `
      SELECT
        id,
        room_id,
        is_active
      FROM tenants
      WHERE id = ?
      LIMIT 1
      `,
      [id]
    );

    if (tenantRows.length === 0) {
      await connection.rollback();
      connection.release();

      return res.status(404).json({
        success: false,
        message: "Tenant not found",
      });
    }

    const roomId = tenantRows[0].room_id;

    await connection.query(
      `
      UPDATE tenants
      SET is_active = 0
      WHERE id = ?
      `,
      [id]
    );

    const [activeTenantRows] = await connection.query(
      `
      SELECT id
      FROM tenants
      WHERE room_id = ?
        AND is_active = 1
      LIMIT 1
      `,
      [roomId]
    );

    if (activeTenantRows.length === 0) {
      await connection.query(
        `
        UPDATE rooms
        SET status = 'available'
        WHERE id = ?
        `,
        [roomId]
      );
    }

    await connection.commit();
    connection.release();

    return res.json({
      success: true,
      message: "Tenant removed and room is now available",
    });
  } catch (error) {
    await connection.rollback();
    connection.release();

    console.error("Deactivate tenant error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to deactivate tenant",
    });
  }
};