const db = require("../config/db");

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
    RETURNING *;
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
    "SELECT * FROM users WHERE username = $1",
    [username]
  );

  return result.rows[0];
};

const findUserByEmail = async (email) => {
  const result = await db.query(
    "SELECT * FROM users WHERE email = $1",
    [email]
  );

  return result.rows[0];
};

module.exports = {
  createUser,
  findUserByUsername,
  findUserByEmail
};