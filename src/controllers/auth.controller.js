const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const {
  createUser,
  findUserByUsername,
  findUserByEmail,
  findUserByEmailForAuth
} = require("../models/user.model");

const USERNAME_PATTERN = /^[a-zA-Z0-9_.-]{3,32}$/;
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_PATTERN = /^[0-9+\s()-]{7,20}$/;

const normalizeEmail = (value) =>
  String(value || "").trim().toLowerCase();

const normalizeUsername = (value) =>
  String(value || "").trim().toLowerCase();

const publicUser = (user) => ({
  id: user.id,
  fullname: user.fullname,
  username: user.username,
  email: user.email,
  phone: user.phone,
  balance: user.balance,
  vip: user.vip,
  is_admin: user.is_admin,
  status: user.status,
  created_at: user.created_at
});

// ثبت نام
const register = async (req, res) => {
  try {
    const fullname = String(req.body.fullname || "").trim();
    const username = normalizeUsername(req.body.username);
    const email = normalizeEmail(req.body.email);
    const phone = String(req.body.phone || "").trim();
    const password = String(req.body.password || "");

    if (!fullname || !username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "Full name, username, email and password are required"
      });
    }

    if (fullname.length < 2 || fullname.length > 100) {
      return res.status(400).json({
        success: false,
        message: "Full name must be between 2 and 100 characters"
      });
    }

    if (!USERNAME_PATTERN.test(username)) {
      return res.status(400).json({
        success: false,
        message:
          "Username must be 3-32 characters and contain only letters, numbers, dot, dash or underscore"
      });
    }

    if (email.length > 150 || !EMAIL_PATTERN.test(email)) {
      return res.status(400).json({
        success: false,
        message: "A valid email address is required"
      });
    }

    if (phone && !PHONE_PATTERN.test(phone)) {
      return res.status(400).json({
        success: false,
        message: "Phone number is invalid"
      });
    }

    if (password.length < 8 || password.length > 128) {
      return res.status(400).json({
        success: false,
        message: "Password must be between 8 and 128 characters"
      });
    }

    const [usernameExists, emailExists] = await Promise.all([
      findUserByUsername(username),
      findUserByEmail(email)
    ]);

    if (usernameExists) {
      return res.status(409).json({
        success: false,
        message: "Username already exists"
      });
    }

    if (emailExists) {
      return res.status(409).json({
        success: false,
        message: "Email already exists"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await createUser({
      fullname,
      username,
      email,
      password: hashedPassword,
      phone: phone || null
    });

    return res.status(201).json({
      success: true,
      message: "User registered successfully",
      user
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        success: false,
        message: "Username or email already exists"
      });
    }

    console.error("Register error:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error"
    });
  }
};

// ورود با ایمیل و رمز عبور
const login = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || "");

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required"
      });
    }

    const user = await findUserByEmailForAuth(email);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password"
      });
    }

    const match = await bcrypt.compare(password, user.password);

    if (!match) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password"
      });
    }

    if (user.status && user.status !== "active") {
      return res.status(403).json({
        success: false,
        message: "Account is not active"
      });
    }

    const token = jwt.sign(
      {
        id: user.id,
        username: user.username,
        is_admin: user.is_admin
      },
      process.env.JWT_SECRET,
      {
        expiresIn: "7d"
      }
    );

    return res.json({
      success: true,
      message: "Login successful",
      token,
      user: publicUser(user)
    });
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error"
    });
  }
};

module.exports = {
  register,
  login
};
