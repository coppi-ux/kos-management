const db = require("../config/db");

exports.getDashboardStats = async (req, res) => {
  try {
    const { kosId } = req.params;

    const [[rooms]] = await db.query(
      `
      SELECT
        COUNT(*) AS total_rooms,
        COALESCE(SUM(CASE WHEN status = 'occupied' THEN 1 ELSE 0 END), 0) AS occupied_rooms,
        COALESCE(SUM(CASE WHEN status = 'available' THEN 1 ELSE 0 END), 0) AS available_rooms
      FROM rooms
      WHERE kos_id = ?
      `,
      [kosId]
    );

    const [[tenants]] = await db.query(
      `
      SELECT
        COUNT(*) AS total_tenants
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      WHERE r.kos_id = ?
        AND t.is_active = 1
      `,
      [kosId]
    );

    const [[currentMonth]] = await db.query(
      `
      SELECT DATE_FORMAT(CURDATE(), '%Y-%m') AS billing_month
      `
    );

    const billingMonth = currentMonth.billing_month;

    const [[monthlyIncome]] = await db.query(
      `
      SELECT
        COALESCE(SUM(total_amount), 0) AS income
      FROM bills
      WHERE kos_id = ?
        AND billing_month = ?
        AND status = 'paid'
      `,
      [kosId, billingMonth]
    );

    const [[unpaidAmount]] = await db.query(
      `
      SELECT
        COUNT(*) AS unpaid_count,
        COALESCE(SUM(total_amount), 0) AS unpaid_amount
      FROM bills
      WHERE kos_id = ?
        AND status = 'unpaid'
      `,
      [kosId]
    );

    const [monthlyChart] = await db.query(
      `
      SELECT
        billing_month,
        COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) AS paid,
        COALESCE(SUM(CASE WHEN status = 'unpaid' THEN total_amount ELSE 0 END), 0) AS unpaid
      FROM bills
      WHERE kos_id = ?
      GROUP BY billing_month
      ORDER BY billing_month DESC
      LIMIT 6
      `,
      [kosId]
    );

    const [recentActivity] = await db.query(
      `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        b.billing_month,
        b.base_amount,
        b.penalty_amount,
        b.addon_amount,
        b.total_amount,
        b.due_date,
        b.status,
        b.created_at,
        t.name AS tenant_name,
        r.room_number
      FROM bills b
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      WHERE b.kos_id = ?
      ORDER BY b.created_at DESC
      LIMIT 5
      `,
      [kosId]
    );

    const totalRooms = Number(rooms.total_rooms || 0);
    const occupiedRooms = Number(rooms.occupied_rooms || 0);
    const availableRooms = Number(rooms.available_rooms || 0);

    const occupancyRate =
      totalRooms > 0 ? Math.round((occupiedRooms / totalRooms) * 100) : 0;

    return res.json({
      success: true,
      rooms: {
        total: totalRooms,
        occupied: occupiedRooms,
        available: availableRooms,
        occupancy_rate: occupancyRate,
      },
      tenants: {
        total: Number(tenants.total_tenants || 0),
      },
      billing: {
        monthly_income: Number(monthlyIncome.income || 0),
        unpaid_count: Number(unpaidAmount.unpaid_count || 0),
        unpaid_amount: Number(unpaidAmount.unpaid_amount || 0),
      },
      chart: monthlyChart.reverse(),
      recent_activity: recentActivity,
    });
  } catch (error) {
    console.error("[Analytics] Dashboard stats error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch analytics",
    });
  }
};

exports.getTenantPaymentHistory = async (req, res) => {
  try {
    const { tenantId } = req.params;

    const [history] = await db.query(
      `
      SELECT
        b.id,
        b.tenant_id,
        b.room_id,
        b.kos_id,
        b.billing_month,
        b.base_amount,
        b.penalty_amount,
        b.addon_amount,
        b.total_amount,
        b.due_date,
        b.status,
        b.created_at,
        b.updated_at,
        t.name AS tenant_name,
        r.room_number,
        rt.name AS room_type
      FROM bills b
      JOIN tenants t ON b.tenant_id = t.id
      JOIN rooms r ON b.room_id = r.id
      JOIN room_types rt ON r.room_type_id = rt.id
      WHERE b.tenant_id = ?
      ORDER BY b.billing_month DESC
      `,
      [tenantId]
    );

    return res.json({
      success: true,
      history,
      data: history,
    });
  } catch (error) {
    console.error("[Analytics] Payment history error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch payment history",
    });
  }
};