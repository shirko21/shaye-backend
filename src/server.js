require("dotenv").config();

const app = require("./app");
const { initializeDatabase } = require("./database/init");

const PORT = process.env.PORT || 3000;

const start = async () => {
  try {
    await initializeDatabase();

    app.listen(PORT, () => {
      console.log("=================================");
      console.log("🚀 SHAYE Backend Running");
      console.log(`📡 Port: ${PORT}`);
      console.log(`🌐 http://localhost:${PORT}`);
      console.log("=================================");
    });
  } catch (error) {
    console.error("❌ Could not start SHAYE Backend:", error.message);
    process.exitCode = 1;
  }
};

start();
