const express = require("express");
const cors = require("cors");
require("dotenv").config();

const authRoutes = require("./routes/authRoutes");
const kosRoutes = require("./routes/kosRoutes");
const roomRoutes = require("./routes/roomRoutes");
const billRoutes = require("./routes/billRoutes");
const addonRoutes = require("./routes/addonRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const analyticsRoutes = require("./routes/analyticsRoutes");
const exportRoutes = require("./routes/exportRoutes");
const tenantAuthRoutes = require("./routes/tenantAuthRoutes");
const tenantBillRoutes = require("./routes/tenantBillRoutes");
const sheetsRoutes = require("./routes/sheetsRoutes");

const startBillingCron = require("./jobs/billingCron");

const app = express();

app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "Accept"],
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get("/", (req, res) => {
  return res.json({
    success: true,
    message: "Kos Management API is running",
  });
});

app.get("/test", (req, res) => {
  return res.json({
    success: true,
    message: "API is working",
  });
});

app.get("/api/test", (req, res) => {
  return res.json({
    success: true,
    message: "API route is working",
  });
});

app.use("/api/auth", authRoutes);
app.use("/api/kos", kosRoutes);
app.use("/api/rooms", roomRoutes);
app.use("/api/bills", billRoutes);
app.use("/api/addons", addonRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/analytics", analyticsRoutes);
app.use("/api/export", exportRoutes);
app.use("/api/tenant-auth", tenantAuthRoutes);
app.use("/api/tenant", tenantBillRoutes);
app.use("/api/tenant-bills", tenantBillRoutes);
app.use("/api/sheets", sheetsRoutes);

app.use((req, res) => {
  return res.status(404).json({
    success: false,
    message: "Route not found",
    method: req.method,
    path: req.originalUrl,
  });
});

app.use((err, req, res, next) => {
  console.error("[Server Error]", err);

  return res.status(err.status || 500).json({
    success: false,
    message: err.message || "Internal server error",
  });
});

try {
  startBillingCron();
  console.log("Billing cron started");
} catch (error) {
  console.error("Failed to start billing cron:", error);
}

const PORT = process.env.PORT || 3000;

app.listen(PORT, "0.0.0.0", () => {
  console.log("======================================");
  console.log(`Server running on http://0.0.0.0:${PORT}`);
  console.log(`Local test: http://localhost:${PORT}/api/test`);
  console.log(`LAN test: http://192.168.1.4:${PORT}/api/test`);
  console.log("--------------------------------------");
  console.log(`Owner notifications: http://localhost:${PORT}/api/notifications/owner/1`);
  console.log(`Tenant bills: http://localhost:${PORT}/api/tenant/bills`);
  console.log(`Tenant current bill: http://localhost:${PORT}/api/tenant/current-bill`);
  console.log(`Tenant pay bill: http://localhost:${PORT}/api/tenant/pay/1`);
  console.log("======================================");
});
