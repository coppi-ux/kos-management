const express = require("express");
const router = express.Router();

const exportController = require("../controllers/exportController");
const verifyToken = require("../middleware/authMiddleware");

router.use(verifyToken);

router.get("/bills/:kosId", exportController.exportBills);

router.get("/tenants/:kosId", exportController.exportTenants);

module.exports = router;