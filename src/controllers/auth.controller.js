const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const {
  createUser,
  findUserByUsername,
  findUserByEmail
} = require("../models/user.model");

// ثبت نام
const register = async (req, res) => {
  try {
    const {
      fullname,
      username,
      email,
      password,
      phone
    } = req.body;

    if (!fullname || !username || !password) {
      return res.status(400).json({
        success: false,
        message: "Required fields are missing"
      });
    }

    const usernameExists = await findUserByUsername(username);

    if (usernameExists) {
      return res.status(400).json({
        success: false,
        message: "Username already exists"
      });
    }

    if (email) {
      const emailExists = await findUserByEmail(email);

      if (emailExists) {
        return res.status(400).json({
          success: false,
          message: "Email already exists"
        });
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await createUser({
      fullname,
      username,
      email,
      password: hashedPassword,
      phone
    });

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      user
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// ورود
const login = async (req, res) => {
  try {

    const { username, password } = req.body;

    const user = await findUserByUsername(username);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid username or password"
      });
    }

    const match = await bcrypt.compare(password, user.password);

    if (!match) {
      return res.status(401).json({
        success: false,
        message: "Invalid username or password"
      });
    }

    const token = jwt.sign(
      {
        id: user.id,
        username: user.username,
        is_admin: user.is_admin
      },
      process.env.JWT_SECRET,
      {
        expiresIn: "7d"
      }
    );

    res.json({
      success: true,
      message: "Login successful",
      token,
      user
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: error.message
    });

  }
};

module.exports = {
  register,
  login
};