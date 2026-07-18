const db = require("../config/db");

const PUBLIC_USER_COLUMNS = [
  "id",
  "fullname",
  "username",
  "email",
  "phone",
  "balance",
  "vip",
  "is_admin",
  "status",
  "referral_code",
  "referred_by",
  "created_at"
];

const PUBLIC_USER_FIELDS = PUBLIC_USER_COLUMNS.join(",\n  ");
const QUALIFIED_PUBLIC_USER_FIELDS = PUBLIC_USER_COLUMNS
  .map((column) => `u.${column}`)
  .join(",\n       ");

const createUser = async ({
  fullname,
  username,
  email,
  password,
  phone,
  referralCode,
  referredBy
}) => {
  const query = `
    INSERT INTO users
    (fullname, username, email, password, phone, referral_code, referred_by)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING ${PUBLIC_USER_FIELDS};
  `;

  const values = [
    fullname,
    username,
    email,
    password,
    phone,
    referralCode,
    referredBy
  ];

  const result = await db.query(query, values);
  return result.rows[0];
};

const findUserByEmail = async (email) => {
  const result = await db.query(
    "SELECT id FROM users WHERE LOWER(email) = LOWER($1) LIMIT 1",
    [email]
  );

  return result.rows[0];
};

const findUserByReferralCode = async (referralCode) => {
  const result = await db.query(
    `SELECT id, email, status, referral_code
     FROM users
     WHERE UPPER(referral_code) = UPPER($1)
     LIMIT 1`,
    [referralCode]
  );

  return result.rows[0];
};

const findUserByEmailForAuth = async (email) => {
  const result = await db.query(
    `SELECT
       ${QUALIFIED_PUBLIC_USER_FIELDS},
       referrer.email AS referred_by_email,
       u.password
     FROM users u
     LEFT JOIN users referrer ON referrer.id = u.referred_by
     WHERE LOWER(u.email) = LOWER($1)
     LIMIT 1`,
    [email]
  );

  return result.rows[0];
};

const findUserByIdForAuth = async (id) => {
  const result = await db.query(
    `SELECT id, password, status
     FROM users
     WHERE id = $1
     LIMIT 1`,
    [id]
  );

  return result.rows[0];
};

module.exports = {
  createUser,
  findUserByEmail,
  findUserByReferralCode,
  findUserByEmailForAuth,
  findUserByIdForAuth
};
