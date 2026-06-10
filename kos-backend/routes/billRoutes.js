const express = require("express");
const router = express.Router();

const billController = require("../controllers/billController");
const verifyToken = require("../middleware/authMiddleware");

// Get bills by tenant
router.get("/tenant/:tenantId", verifyToken, billController.getBillsByTenant);

// Get overdue bills
router.get("/overdue/:kosId", verifyToken, billController.getOverdueBills);

// Generate bills by kos
router.post("/generate/:kosId", verifyToken, billController.manualGenerate);

// Mark bill as paid
router.patch("/:id/pay", verifyToken, billController.markPaid);

// Get bills by kos
// Route ini wajib paling bawah karena "/:kosId" sifatnya umum.
router.get("/:kosId", verifyToken, billController.getBillsByKos);

module.exports = router;