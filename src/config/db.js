const { Pool } = require("pg");
require("dotenv").config();

const connectionString = String(process.env.DATABASE_URL || "").trim();
const sslDisabled = String(process.env.DB_SSL || "").toLowerCase() === "false";

const poolConfig = connectionString
  ? { connectionString }
  : {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME
    };

if (!sslDisabled) {
  poolConfig.ssl = {
    rejectUnauthorized: false
  };
}

const pool = new Pool(poolConfig);

pool
  .connect()
  .then((client) => {
    console.log("✅ PostgreSQL Connected");
    client.release();
  })
  .catch((error) => {
    console.error("❌ Database Connection Error:", error.message);
  });

module.exports = pool;
