const express = require("express");
const router = express.Router();

const sheetsController = require("../controllers/sheetsController");
const verifyToken = require("../middleware/authMiddleware");

router.use(verifyToken);

router.post("/sync/:kosId", sheetsController.sync);

module.exports = router;