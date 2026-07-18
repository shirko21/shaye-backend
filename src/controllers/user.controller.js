const db = require("../config/db");

const profile = async (req, res) => {
  try {

    const result = await db.query(
      `SELECT
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
       FROM users
       WHERE id = $1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });

  } catch (err) {

    res.status(500).json({
      success: false,
      message: err.message
    });

  }
};

module.exports = {
  profile
};