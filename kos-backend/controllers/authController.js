const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const db = require("../config/db");

// REGISTER
exports.register = async (req, res) => {
  try {
    console.log("REGISTER START");

    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    const [existingUsers] = await db.query(
      `
      SELECT id, name, email
      FROM owners
      WHERE email = ?
      LIMIT 1
      `,
      [email]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Email already exists",
      });
    }

    console.log("HASHING PASSWORD");

    const hashedPassword = await bcrypt.hash(password, 10);

    const [result] = await db.query(
      `
      INSERT INTO owners (name, email, password)
      VALUES (?, ?, ?)
      `,
      [name, email, hashedPassword]
    );

    console.log("REGISTER SUCCESS");

    return res.status(201).json({
      success: true,
      message: "Owner registered successfully",
      user: {
        id: result.insertId,
        name,
        email,
      },
    });
  } catch (error) {
    console.error("REGISTER ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Server error",
    });
  }
};

// LOGIN
exports.login = async (req, res) => {
  try {
    console.log("LOGIN START");

    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    const [users] = await db.query(
      `
      SELECT id, name, email, password
      FROM owners
      WHERE email = ?
      LIMIT 1
      `,
      [email]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const user = users[0];

    console.log("CHECK PASSWORD");

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Wrong password",
      });
    }

    console.log("GENERATE TOKEN");

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
      },
      process.env.JWT_SECRET || "secret123",
      {
        expiresIn: "1d",
      }
    );

    console.log("LOGIN SUCCESS");

    return res.json({
      success: true,
      message: "Login successful",
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
    });
  } catch (error) {
    console.error("LOGIN ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Server error",
    });
  }
};