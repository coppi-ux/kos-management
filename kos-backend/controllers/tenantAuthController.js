const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const TenantAuth = require("../models/tenantAuth");

exports.setupPassword = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password required",
      });
    }

    const cleanEmail = email.toString().trim().toLowerCase();

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 6 characters",
      });
    }

    const rows = await TenantAuth.findByEmail(cleanEmail);

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Tenant not found. Contact your kos owner.",
      });
    }

    const tenant = rows[0];

    if (Number(tenant.password_set) === 1) {
      return res.status(400).json({
        success: false,
        message: "Password already set. Please login instead.",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await TenantAuth.setPassword(
      tenant.id,
      hashedPassword
    );

    if (result.affectedRows === 0) {
      return res.status(400).json({
        success: false,
        message: "Failed to update tenant password",
      });
    }

    return res.status(201).json({
      success: true,
      message: "Password set successfully. You can now login.",
    });
  } catch (error) {
    console.error("[TenantAuth] Setup password error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to set password",
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password required",
      });
    }

    const cleanEmail = email.toString().trim().toLowerCase();

    const rows = await TenantAuth.findByEmail(cleanEmail);

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Tenant not found",
      });
    }

    const tenant = rows[0];

    if (Number(tenant.password_set) !== 1) {
      return res.status(400).json({
        success: false,
        message: "Password not set yet. Please set your password first.",
        needs_setup: true,
      });
    }

    if (!tenant.password) {
      return res.status(400).json({
        success: false,
        message: "Password not found. Please set your password again.",
        needs_setup: true,
      });
    }

    const isMatch = await bcrypt.compare(password, tenant.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Wrong password",
      });
    }

    const token = jwt.sign(
      {
        id: tenant.id,
        email: tenant.email,
        role: "tenant",
      },
      process.env.JWT_SECRET,
      {
        expiresIn: "1d",
      }
    );

    return res.json({
      success: true,
      message: "Login successful",
      token,
      tenant: {
        id: tenant.id,
        name: tenant.name,
        email: tenant.email,
        room_number: tenant.room_number,
        room_type: tenant.room_type,
        base_price: tenant.base_price,
        kos_id: tenant.kos_id,
      },
    });
  } catch (error) {
    console.error("[TenantAuth] Login error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to login",
    });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const tenantId = req.user.id;

    const rows = await TenantAuth.findById(tenantId);

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Tenant not found",
      });
    }

    const tenant = rows[0];

    return res.json({
      success: true,
      tenant: {
        id: tenant.id,
        name: tenant.name,
        email: tenant.email,
        phone: tenant.phone,
        room_number: tenant.room_number,
        room_type: tenant.room_type,
        base_price: tenant.base_price,
        start_date: tenant.start_date,
        kos_id: tenant.kos_id,
      },
    });
  } catch (error) {
    console.error("[TenantAuth] Profile error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch profile",
    });
  }
};