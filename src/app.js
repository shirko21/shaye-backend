const express = require("express");
const cors = require("cors");
require("dotenv").config();

// اتصال به دیتابیس
require("./config/db");

const authRoutes = require("./routes/auth.routes");
const userRoutes = require("./routes/user.routes");
const adminRoutes = require("./routes/admin.routes");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// تست API
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "SHAYE Backend API is running 🚀"
  });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/user", userRoutes);
app.use("/api/admin", adminRoutes);

// اگر Route پیدا نشد
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found"
  });
});

module.exports = app;