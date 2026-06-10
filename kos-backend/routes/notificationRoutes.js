const express = require("express");
const router = express.Router();

const notificationController = require("../controllers/notificationController");
const verifyToken = require("../middleware/authMiddleware");

router.get(
  "/owner/:ownerId/unread-count",
  verifyToken,
  notificationController.getUnreadCount
);

router.get(
  "/owner/:ownerId",
  verifyToken,
  notificationController.getOwnerNotifications
);

router.patch(
  "/owner/:ownerId/read-all",
  verifyToken,
  notificationController.markAllReadOwner
);

router.patch(
  "/:id/read",
  verifyToken,
  notificationController.markRead
);

router.get(
  "/tenant/:tenantId",
  verifyToken,
  notificationController.getTenantNotifications
);

module.exports = router;