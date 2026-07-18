const fs = require("node:fs/promises");
const path = require("node:path");

const db = require("../config/db");

const initializeDatabase = async () => {
  const schemaPath = path.join(__dirname, "schema.sql");
  const schema = await fs.readFile(schemaPath, "utf8");
  await db.query(schema);
};

if (require.main === module) {
  initializeDatabase()
    .then(async () => {
      console.log("✅ Database schema is ready");
      await db.end();
    })
    .catch(async (error) => {
      console.error("❌ Database initialization failed:", error.message);
      await db.end();
      process.exitCode = 1;
    });
}

module.exports = {
  initializeDatabase
};
