require("dotenv").config();

const app = require("./app");

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log("=================================");
  console.log(`🚀 SHAYE Backend Running`);
  console.log(`📡 Port: ${PORT}`);
  console.log(`🌐 http://localhost:${PORT}`);
  console.log("=================================");
});