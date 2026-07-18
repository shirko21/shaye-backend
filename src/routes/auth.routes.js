const express = require("express");
const router = express.Router();

const auth = require("../middleware/auth");
const authController = require("../controllers/auth.controller");

// ثبت نام
router.post("/register", authController.register);

// ورود
router.post("/login", authController.login);

// بررسی رمز برای عملیات حساس
router.post("/verify-password", auth, authController.verifyPassword);

module.exports = router;
