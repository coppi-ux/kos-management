const express = require("express");
const router = express.Router();

const kosController = require("../controllers/kosController");
const verifyToken = require("../middleware/authMiddleware");

// Semua route kos wajib login
router.use(verifyToken);


// Route kos milik owner yang sedang login
// Ambil semua kos milik owner yang sedang login
router.get("/my", kosController.getMyKos);

// Buat kos baru
router.post("/", kosController.createKos);

// Route room type berdasarkan kosId

// Ambil semua tipe kamar dari kos tertentu
router.get("/:kosId/room-types", kosController.getRoomTypes);

// Buat tipe kamar baru untuk kos tertentu
router.post("/:kosId/room-types", kosController.createRoomType);

// Update tipe kamar tertentu
router.put(
  "/:kosId/room-types/:roomTypeId",
  kosController.updateRoomType
);

// Hapus tipe kamar tertentu
router.delete(
  "/:kosId/room-types/:roomTypeId",
  kosController.deleteRoomType
);

// Route detail, update, dan delete kos
// Route /:kosId diletakkan di bawah agar tidak bentrok
// dengan route khusus seperti /my dan /:kosId/room-types

// Ambil detail kos berdasarkan kosId
router.get("/:kosId", kosController.getKosById);

// Update data kos berdasarkan kosId
router.put("/:kosId", kosController.updateKos);

// Hapus kos berdasarkan kosId
router.delete("/:kosId", kosController.deleteKos);

module.exports = router;