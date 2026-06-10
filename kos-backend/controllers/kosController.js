const db = require("../config/db");

// Helper untuk ambil owner_id dari token
function getOwnerId(req) {
  return req.user?.id || req.owner?.id || req.userId || req.ownerId || null;
}

// Helper untuk cek apakah kos milik owner yang sedang login
async function checkKosOwnership(kosId, ownerId) {
  const [rows] = await db.query(
    `
    SELECT id
    FROM kos
    WHERE id = ?
      AND owner_id = ?
    LIMIT 1
    `,
    [kosId, ownerId]
  );

  return rows.length > 0;
}

// ======================================================
// POST /api/kos
// Buat kos baru
// ======================================================
exports.createKos = async (req, res) => {
  try {
    const ownerId = getOwnerId(req);
    const { name, address } = req.body;

    console.log("CREATE KOS OWNER ID:", ownerId);
    console.log("CREATE KOS BODY:", req.body);

    if (!ownerId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized: owner id not found in token",
      });
    }

    if (!name || !address) {
      return res.status(400).json({
        success: false,
        message: "Name and address are required",
      });
    }

    const [result] = await db.query(
      `
      INSERT INTO kos (owner_id, name, address)
      VALUES (?, ?, ?)
      `,
      [ownerId, name, address]
    );

    return res.status(201).json({
      success: true,
      message: "Kos created successfully",
      kos_id: result.insertId,
      kos: {
        id: result.insertId,
        owner_id: ownerId,
        name,
        address,
      },
    });
  } catch (error) {
    console.error("Create kos error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to create kos",
    });
  }
};

// ======================================================
// GET /api/kos/my
// Ambil semua kos milik owner yang sedang login
// ======================================================
exports.getMyKos = async (req, res) => {
  try {
    const ownerId = getOwnerId(req);

    console.log("GET MY KOS OWNER ID:", ownerId);

    if (!ownerId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized: owner id not found in token",
      });
    }

    const [rows] = await db.query(
      `
      SELECT
        id,
        owner_id,
        name,
        address,
        created_at,
        updated_at
      FROM kos
      WHERE owner_id = ?
      ORDER BY created_at DESC
      `,
      [ownerId]
    );

    return res.json({
      success: true,
      kos: rows,
      data: rows,
    });
  } catch (error) {
    console.error("Get my kos error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Database error",
    });
  }
};

// ======================================================
// GET /api/kos/:kosId
// Ambil detail kos berdasarkan kosId
// ======================================================
exports.getKosById = async (req, res) => {
  try {
    const ownerId = getOwnerId(req);
    const { kosId } = req.params;

    console.log("GET KOS BY ID:", kosId);
    console.log("OWNER ID:", ownerId);

    if (!ownerId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    const [rows] = await db.query(
      `
      SELECT
        id,
        owner_id,
        name,
        address,
        created_at,
        updated_at
      FROM kos
      WHERE id = ?
        AND owner_id = ?
      LIMIT 1
      `,
      [kosId, ownerId]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Kos not found",
      });
    }

    return res.json({
      success: true,
      kos: rows[0],
      data: rows[0],
    });
  } catch (error) {
    console.error("Get kos by id error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Database error",
    });
  }
};

// ======================================================
// PUT /api/kos/:kosId
// Update data kos berdasarkan kosId
// ======================================================
exports.updateKos = async (req, res) => {
  try {
    const ownerId = getOwnerId(req);
    const { kosId } = req.params;
    const { name, address } = req.body;

    console.log("UPDATE KOS ID:", kosId);
    console.log("UPDATE KOS OWNER ID:", ownerId);
    console.log("UPDATE KOS BODY:", req.body);

    if (!ownerId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    if (!name || !address) {
      return res.status(400).json({
        success: false,
        message: "Name and address are required",
      });
    }

    const isOwner = await checkKosOwnership(kosId, ownerId);

    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: "Kos not found",
      });
    }

    await db.query(
      `
      UPDATE kos
      SET
        name = ?,
        address = ?,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
        AND owner_id = ?
      `,
      [name, address, kosId, ownerId]
    );

    const [updatedRows] = await db.query(
      `
      SELECT
        id,
        owner_id,
        name,
        address,
        created_at,
        updated_at
      FROM kos
      WHERE id = ?
        AND owner_id = ?
      LIMIT 1
      `,
      [kosId, ownerId]
    );

    return res.json({
      success: true,
      message: "Kos updated successfully",
      kos: updatedRows[0],
      data: updatedRows[0],
    });
  } catch (error) {
    console.error("Update kos error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to update kos",
    });
  }
};

// ======================================================
// DELETE /api/kos/:kosId
// Hapus kos berdasarkan kosId
// ======================================================
exports.deleteKos = async (req, res) => {
  try {
    const ownerId = getOwnerId(req);
    const { kosId } = req.params;

    console.log("DELETE KOS ID:", kosId);
    console.log("DELETE KOS OWNER ID:", ownerId);

    if (!ownerId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    const isOwner = await checkKosOwnership(kosId, ownerId);

    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: "Kos not found",
      });
    }

    // Hapus room_types dulu supaya tidak bentrok foreign key
    await db.query(
      `
      DELETE FROM room_types
      WHERE kos_id = ?
      `,
      [kosId]
    );

    // Setelah itu hapus kos
    await db.query(
      `
      DELETE FROM kos
      WHERE id = ?
        AND owner_id = ?
      `,
      [kosId, ownerId]
    );

    return res.json({
      success: true,
      message: "Kos deleted successfully",
      deleted_kos_id: Number(kosId),
    });
  } catch (error) {
    console.error("Delete kos error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to delete kos",
    });
  }
};

// ======================================================
// POST /api/kos/:kosId/room-types
// Buat tipe kamar baru
// ======================================================
exports.createRoomType = async (req, res) => {
  try {
    const ownerId = getOwnerId(req);
    const { kosId } = req.params;
    const { name, base_price } = req.body;

    console.log("CREATE ROOM TYPE KOS ID:", kosId);
    console.log("CREATE ROOM TYPE OWNER ID:", ownerId);
    console.log("CREATE ROOM TYPE BODY:", req.body);

    if (!ownerId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    if (!name || base_price === undefined || base_price === null) {
      return res.status(400).json({
        success: false,
        message: "Name and base price are required",
      });
    }

    const priceNumber = Number(base_price);

    if (Number.isNaN(priceNumber) || priceNumber <= 0) {
      return res.status(400).json({
        success: false,
        message: "Price must be a positive number",
      });
    }

    const isOwner = await checkKosOwnership(kosId, ownerId);

    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: "Kos not found",
      });
    }

    const [result] = await db.query(
      `
      INSERT INTO room_types (kos_id, name, base_price)
      VALUES (?, ?, ?)
      `,
      [kosId, name, priceNumber]
    );

    return res.status(201).json({
      success: true,
      message: "Room type created successfully",
      room_type_id: result.insertId,
      room_type: {
        id: result.insertId,
        kos_id: Number(kosId),
        name,
        base_price: priceNumber,
      },
    });
  } catch (error) {
    console.error("Create room type error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to create room type",
    });
  }
};

// ======================================================
// GET /api/kos/:kosId/room-types
// Ambil semua tipe kamar dari kos tertentu
// ======================================================
exports.getRoomTypes = async (req, res) => {
  try {
    const ownerId = getOwnerId(req);
    const { kosId } = req.params;

    console.log("GET ROOM TYPES KOS ID:", kosId);
    console.log("GET ROOM TYPES OWNER ID:", ownerId);

    if (!ownerId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    const isOwner = await checkKosOwnership(kosId, ownerId);

    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: "Kos not found",
      });
    }

    const [rows] = await db.query(
      `
      SELECT
        id,
        kos_id,
        name,
        base_price,
        created_at,
        updated_at
      FROM room_types
      WHERE kos_id = ?
      ORDER BY created_at DESC
      `,
      [kosId]
    );

    return res.json({
      success: true,
      room_types: rows,
      data: rows,
    });
  } catch (error) {
    console.error("Get room types error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Database error",
    });
  }
};

// ======================================================
// PUT /api/kos/:kosId/room-types/:roomTypeId
// Update tipe kamar tertentu
// ======================================================
exports.updateRoomType = async (req, res) => {
  try {
    const ownerId = getOwnerId(req);
    const { kosId, roomTypeId } = req.params;
    const { name, base_price } = req.body;

    console.log("UPDATE ROOM TYPE KOS ID:", kosId);
    console.log("UPDATE ROOM TYPE ID:", roomTypeId);
    console.log("UPDATE ROOM TYPE OWNER ID:", ownerId);
    console.log("UPDATE ROOM TYPE BODY:", req.body);

    if (!ownerId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    if (!name || base_price === undefined || base_price === null) {
      return res.status(400).json({
        success: false,
        message: "Name and base price are required",
      });
    }

    const priceNumber = Number(base_price);

    if (Number.isNaN(priceNumber) || priceNumber <= 0) {
      return res.status(400).json({
        success: false,
        message: "Price must be a positive number",
      });
    }

    const isOwner = await checkKosOwnership(kosId, ownerId);

    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: "Kos not found",
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
      [roomTypeId, kosId]
    );

    if (roomTypeRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Room type not found",
      });
    }

    await db.query(
      `
      UPDATE room_types
      SET
        name = ?,
        base_price = ?,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
        AND kos_id = ?
      `,
      [name, priceNumber, roomTypeId, kosId]
    );

    const [updatedRows] = await db.query(
      `
      SELECT
        id,
        kos_id,
        name,
        base_price,
        created_at,
        updated_at
      FROM room_types
      WHERE id = ?
        AND kos_id = ?
      LIMIT 1
      `,
      [roomTypeId, kosId]
    );

    return res.json({
      success: true,
      message: "Room type updated successfully",
      room_type: updatedRows[0],
      data: updatedRows[0],
    });
  } catch (error) {
    console.error("Update room type error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to update room type",
    });
  }
};

// ======================================================
// DELETE /api/kos/:kosId/room-types/:roomTypeId
// Hapus tipe kamar tertentu
// ======================================================
exports.deleteRoomType = async (req, res) => {
  try {
    const ownerId = getOwnerId(req);
    const { kosId, roomTypeId } = req.params;

    console.log("DELETE ROOM TYPE KOS ID:", kosId);
    console.log("DELETE ROOM TYPE ID:", roomTypeId);
    console.log("DELETE ROOM TYPE OWNER ID:", ownerId);

    if (!ownerId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    const isOwner = await checkKosOwnership(kosId, ownerId);

    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: "Kos not found",
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
      [roomTypeId, kosId]
    );

    if (roomTypeRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Room type not found",
      });
    }

    await db.query(
      `
      DELETE FROM room_types
      WHERE id = ?
        AND kos_id = ?
      `,
      [roomTypeId, kosId]
    );

    return res.json({
      success: true,
      message: "Room type deleted successfully",
      deleted_room_type_id: Number(roomTypeId),
    });
  } catch (error) {
    console.error("Delete room type error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to delete room type",
    });
  }
};