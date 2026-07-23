const db = require("../config/db");

const profile = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT
          u.id,
          u.fullname,
          u.username,
          u.email,
          u.phone,
          u.balance,
          u.vip,
          u.is_admin,
          u.status,
          u.referral_code,
          u.referred_by,
          referrer.email AS referred_by_email,
          u.created_at
       FROM users u
       LEFT JOIN users referrer ON referrer.id = u.referred_by
       WHERE u.id = $1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_FOUND",
        message: "User not found"
      });
    }

    const user = result.rows[0];

    if (user.status && user.status !== "active") {
      return res.status(403).json({
        success: false,
        code: "ACCOUNT_INACTIVE",
        message: "Account is not active"
      });
    }

    return res.json({
      success: true,
      user
    });
  } catch (error) {
    console.error("Profile error:", error);
    return res.status(500).json({
      success: false,
      code: "INTERNAL_ERROR",
      message: "Internal server error"
    });
  }
};

module.exports = {
  profile
};
