const express = require("express");
const router = express.Router();

const analyticsController = require("../controllers/analyticsController");
const verifyToken = require("../middleware/authMiddleware");

router.use(verifyToken);

router.get("/tenant/:tenantId/history", analyticsController.getTenantPaymentHistory);

router.get("/:kosId", analyticsController.getDashboardStats);

module.exports = router;