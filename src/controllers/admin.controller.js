const db = require("../config/db");

const dashboard = async (req, res) => {

    try {

        if (!req.user.is_admin) {
            return res.status(403).json({
                success: false,
                message: "Access denied"
            });
        }

        const users = await db.query(
            "SELECT COUNT(*) FROM users"
        );

        res.json({
            success: true,
            data: {
                totalUsers: users.rows[0].count
            }
        });

    } catch (err) {

        res.status(500).json({
            success: false,
            message: err.message
        });

    }

};

module.exports = {
    dashboard
};