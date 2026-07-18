const express = require("express");
const router = express.Router();

const auth = require("../middleware/auth");
const userController = require("../controllers/user.controller");

// پروفایل کاربر
router.get("/profile", auth, userController.profile);

module.exports = router;