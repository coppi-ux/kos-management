const jwt = require("jsonwebtoken");

const verifyToken = (req, res, next) => {
  try {
    const authHeader =
      req.headers.authorization || req.headers["authorization"];

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: "No token provided",
      });
    }

    if (typeof authHeader !== "string") {
      return res.status(401).json({
        success: false,
        message: "Invalid authorization header",
      });
    }

    const parts = authHeader.split(" ");

    if (parts.length !== 2) {
      return res.status(401).json({
        success: false,
        message: "Invalid token format. Use: Bearer <token>",
      });
    }

    const scheme = parts[0];
    const token = parts[1];

    if (scheme !== "Bearer") {
      return res.status(401).json({
        success: false,
        message: "Invalid token scheme. Use Bearer token",
      });
    }

    if (!token || token.trim() === "") {
      return res.status(401).json({
        success: false,
        message: "Token is empty",
      });
    }

    const secret = process.env.JWT_SECRET || "secret123";

    const decoded = jwt.verify(token, secret);

    req.user = decoded;

    console.log("AUTH SUCCESS:", {
      id: decoded.id || decoded.ownerId || decoded.tenantId || null,
      role: decoded.role || decoded.type || null,
      email: decoded.email || null,
    });

    next();
  } catch (error) {
    console.error("AUTH MIDDLEWARE ERROR:", error.message);

    if (error.name === "TokenExpiredError") {
      return res.status(403).json({
        success: false,
        message: "Token expired",
      });
    }

    if (error.name === "JsonWebTokenError") {
      return res.status(403).json({
        success: false,
        message: "Invalid token",
      });
    }

    return res.status(403).json({
      success: false,
      message: "Token expired or invalid",
    });
  }
};

module.exports = verifyToken;