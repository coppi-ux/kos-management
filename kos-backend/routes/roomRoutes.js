const express = require("express");
const router = express.Router();
const roomController = require("../controllers/roomController");
const verifyToken = require("../middleware/authMiddleware");

// Room routes
router.post("/", verifyToken, roomController.createRoom);
router.get("/:kosId", verifyToken, roomController.getRoomsByKos);

// Tenant routes
router.post("/tenants", verifyToken, roomController.createTenant);
router.get("/tenants/:kosId", verifyToken, roomController.getTenantsByKos);
router.delete("/tenants/:id", verifyToken, roomController.deactivateTenant);

module.exports = router;