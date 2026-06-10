const express = require("express");
const router = express.Router();

const tenantBillController = require("../controllers/tenantBillController");
const verifyToken = require("../middleware/authMiddleware");

router.use(verifyToken);

router.get("/bills", tenantBillController.getMyBills);

router.get("/current-bill", tenantBillController.getCurrentBill);

router.get("/my-addons", tenantBillController.getMyActiveAddons);

router.post("/pay/:id", tenantBillController.payBill);

router.get("/my", tenantBillController.getMyBills);

router.get("/current", tenantBillController.getCurrentBill);

router.get("/addons", tenantBillController.getMyActiveAddons);

router.post("/:id/pay", tenantBillController.payBill);

module.exports = router;