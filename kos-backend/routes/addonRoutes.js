const express = require("express");
const router = express.Router();

const addonController = require("../controllers/addonController");
const verifyToken = require("../middleware/authMiddleware");

router.use(verifyToken);

router.post("/", addonController.createAddon);

router.get("/tenant/:tenantId", addonController.getTenantAddons);
router.get("/tenant/:tenantId/active", addonController.getTenantAddons);
router.get("/tenants/:tenantId/addons", addonController.getTenantAddons);

router.get("/tenants/by-kos/:kosId", addonController.getTenantsByKosForAddon);
router.get("/tenants/:kosId", addonController.getTenantsByKosForAddon);

router.post("/add-to-bill", addonController.addAddonsToBill);
router.post("/assign", addonController.assignAddon);

router.delete("/remove", addonController.removeAddon);
router.delete("/tenant/:tenantId/:addonId", addonController.removeAddon);
router.delete("/tenants/:tenantId/addons/:addonId", addonController.removeAddon);

router.delete("/kos/:kosId/clear", addonController.clearKosAddons);

router.get("/kos/:kosId", addonController.getAddonsByKos);

router.delete("/:id", addonController.deleteAddon);

router.get("/:kosId", addonController.getAddonsByKos);

module.exports = router;
