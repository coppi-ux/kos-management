const express = require("express");
const router = express.Router();

const tenantAuthController = require("../controllers/tenantAuthController");
const verifyToken = require("../middleware/authMiddleware");

router.post("/setup-password", tenantAuthController.setupPassword);

router.post("/login", tenantAuthController.login);

router.get("/profile", verifyToken, tenantAuthController.getProfile);

module.exports = router;