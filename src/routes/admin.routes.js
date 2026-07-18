const express = require("express");
const router = express.Router();

const auth = require("../middleware/auth");
const adminController = require("../controllers/admin.controller");

router.get("/dashboard", auth, adminController.dashboard);

module.exports = router;