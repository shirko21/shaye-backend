const db = require("../config/db");

const PUBLIC_USER_FIELDS = `
  id,
  fullname,
  username,
  email,
  phone,
  balance,
  vip,
  is_admin,
  status,
  created_at
`;

const createUser = async ({
  fullname,
  username,
  email,
  password,
  phone
}) => {
  const query = `
    INSERT INTO users
    (fullname, username, email, password, phone)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING ${PUBLIC_USER_FIELDS};
  `;

  const values = [
    fullname,
    username,
    email,
    password,
    phone
  ];

  const result = await db.query(query, values);
  return result.rows[0];
};

const findUserByUsername = async (username) => {
  const result = await db.query(
    "SELECT id FROM users WHERE LOWER(username) = LOWER($1) LIMIT 1",
    [username]
  );

  return result.rows[0];
};

const findUserByEmail = async (email) => {
  const result = await db.query(
    "SELECT id FROM users WHERE LOWER(email) = LOWER($1) LIMIT 1",
    [email]
  );

  return result.rows[0];
};

const findUserByEmailForAuth = async (email) => {
  const result = await db.query(
    `SELECT
       ${PUBLIC_USER_FIELDS},
       password
     FROM users
     WHERE LOWER(email) = LOWER($1)
     LIMIT 1`,
    [email]
  );

  return result.rows[0];
};

module.exports = {
  createUser,
  findUserByUsername,
  findUserByEmail,
  findUserByEmailForAuth
};
