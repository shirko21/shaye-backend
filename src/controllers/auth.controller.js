const bcrypt = require("bcrypt");
const crypto = require("node:crypto");
const jwt = require("jsonwebtoken");

const {
  createUser,
  findUserByEmail,
  findUserByEmailForAuth,
  findUserByIdForAuth,
  findUserByReferralCode
} = require("../models/user.model");

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const normalizeEmail = (value) =>
  String(value || "").trim().toLowerCase();

const normalizeInviteCode = (value) =>
  String(value || "").trim().toUpperCase();

const createInternalFullname = (email) =>
  email.split("@")[0].slice(0, 100) || "User";

const createInternalUsername = (email) =>
  `user_${crypto.createHash("sha256").update(email).digest("hex").slice(0, 24)}`;

const createReferralCode = () =>
  `SH${crypto.randomBytes(8).toString("hex").toUpperCase()}`;

const signToken = (user) =>
  jwt.sign(
    {
      id: user.id,
      username: user.username,
      is_admin: user.is_admin
    },
    process.env.JWT_SECRET,
    { expiresIn: "7d" }
  );

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
  referral_code: user.referral_code,
  referred_by: user.referred_by,
  referred_by_email: user.referred_by_email || null,
  created_at: user.created_at
});

// ثبت نام
const register = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || "");
    const inviteCode = normalizeInviteCode(req.body.inviteCode);

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        code: "MISSING_CREDENTIALS",
        message: "Email and password are required"
      });
    }

    if (email.length > 150 || !EMAIL_PATTERN.test(email)) {
      return res.status(400).json({
        success: false,
        code: "INVALID_EMAIL",
        message: "A valid email address is required"
      });
    }

    if (password.length < 8 || password.length > 128) {
      return res.status(400).json({
        success: false,
        code: "INVALID_PASSWORD_LENGTH",
        message: "Password must be between 8 and 128 characters"
      });
    }

    const emailExists = await findUserByEmail(email);

    if (emailExists) {
      return res.status(409).json({
        success: false,
        code: "EMAIL_EXISTS",
        message: "Email already exists"
      });
    }

    let referrer = null;

    if (inviteCode) {
      referrer = await findUserByReferralCode(inviteCode);

      if (!referrer || referrer.status !== "active") {
        return res.status(400).json({
          success: false,
          code: "INVALID_INVITE_CODE",
          message: "Invite code is invalid"
        });
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await createUser({
      fullname: createInternalFullname(email),
      username: createInternalUsername(email),
      email,
      password: hashedPassword,
      phone: null,
      referralCode: createReferralCode(),
      referredBy: referrer ? referrer.id : null
    });

    user.referred_by_email = referrer ? referrer.email : null;
    const token = signToken(user);

    return res.status(201).json({
      success: true,
      message: "User registered successfully",
      token,
      user: publicUser(user)
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        success: false,
        code: "EMAIL_EXISTS",
        message: "Email already exists"
      });
    }

    console.error("Register error:", error);
    return res.status(500).json({
      success: false,
      code: "INTERNAL_ERROR",
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
        code: "MISSING_CREDENTIALS",
        message: "Email and password are required"
      });
    }

    const user = await findUserByEmailForAuth(email);

    if (!user) {
      return res.status(401).json({
        success: false,
        code: "INVALID_CREDENTIALS",
        message: "Invalid email or password"
      });
    }

    const match = await bcrypt.compare(password, user.password);

    if (!match) {
      return res.status(401).json({
        success: false,
        code: "INVALID_CREDENTIALS",
        message: "Invalid email or password"
      });
    }

    if (user.status && user.status !== "active") {
      return res.status(403).json({
        success: false,
        code: "ACCOUNT_INACTIVE",
        message: "Account is not active"
      });
    }

    const token = signToken(user);

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
      code: "INTERNAL_ERROR",
      message: "Internal server error"
    });
  }
};

// بررسی رمز برای عملیات حساس بدون ذخیره رمز در مرورگر
const verifyPassword = async (req, res) => {
  try {
    const password = String(req.body.password || "");

    if (!password) {
      return res.status(400).json({
        success: false,
        code: "MISSING_PASSWORD",
        message: "Password is required"
      });
    }

    const user = await findUserByIdForAuth(req.user.id);

    if (!user || user.status !== "active") {
      return res.status(403).json({
        success: false,
        code: "ACCOUNT_INACTIVE",
        message: "Account is not active"
      });
    }

    const match = await bcrypt.compare(password, user.password);

    if (!match) {
      return res.status(401).json({
        success: false,
        code: "INVALID_PASSWORD",
        message: "Password is invalid"
      });
    }

    return res.json({
      success: true,
      message: "Password verified"
    });
  } catch (error) {
    console.error("Verify password error:", error);
    return res.status(500).json({
      success: false,
      code: "INTERNAL_ERROR",
      message: "Internal server error"
    });
  }
};

module.exports = {
  register,
  login,
  verifyPassword
};
