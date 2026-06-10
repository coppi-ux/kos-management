const cron = require("node-cron");
const { generateDueBills, updatePenalties, checkDueSoon } = require("../services/billingService");

const startBillingCron = () => {
  cron.schedule("0 0 * * *", () => {
    console.log("[Cron] Running midnight jobs...");
    generateDueBills();
    updatePenalties();
    checkDueSoon();
  });

  console.log("[Cron] Billing cron started");
};

module.exports = startBillingCron;