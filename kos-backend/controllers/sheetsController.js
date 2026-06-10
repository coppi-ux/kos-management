const { syncToSheets } = require("../services/sheetsService");

exports.sync = async (req, res) => {
  try {
    const { kosId } = req.params;

    if (!kosId) {
      return res.status(400).json({
        success: false,
        message: "kosId is required",
      });
    }

    const parsedKosId = Number(kosId);

    if (Number.isNaN(parsedKosId) || parsedKosId <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid kosId",
      });
    }

    const result = await syncToSheets(parsedKosId);

    return res.status(200).json({
      success: true,
      message: "Sync successful",
      bills_synced: result?.bills_synced ?? 0,
      tenants_synced: result?.tenants_synced ?? 0,
      sheet_url: process.env.GOOGLE_SHEET_ID
        ? `https://docs.google.com/spreadsheets/d/${process.env.GOOGLE_SHEET_ID}`
        : null,
    });
  } catch (error) {
    console.error("[Sheets] Sync failed:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Sync failed",
    });
  }
};