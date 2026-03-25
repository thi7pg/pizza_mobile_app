const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getDB } = require('../config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret';

async function register(req, res) {
  try {
    const { email, password, fullName } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, error: 'Email and password required' });
    }

    const db = getDB();
    const existing = await db.collection('users').findOne({ email });
    if (existing) {
      return res.status(400).json({ success: false, error: 'User already exists' });
    }

    const hashed = await bcrypt.hash(password, 10);
    const user = {
      email,
      password: hashed,
      fullName: fullName || email,
      role: 'user',
      createdAt: new Date().toISOString(),
    };

    await db.collection('users').insertOne(user);

    const token = jwt.sign({ email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });

    res.json({
      success: true,
      message: 'User registered successfully',
      token,
      user: { email: user.email, fullName: user.fullName, role: user.role },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, error: 'Email and password required' });
    }

    const db = getDB();
    const user = await db.collection('users').findOne({ email });
    if (!user) return res.status(401).json({ success: false, error: 'Invalid email or password' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, error: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { email: user.email, role: user.role || 'user' },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        email: user.email,
        fullName: user.fullName,
        role: user.role || 'user',
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
}

async function logout(req, res) {
  res.json({ success: true, message: 'Logged out successfully' });
}

async function getUserProfile(req, res) {
  try {
    const { email } = req.params;
    const db = getDB();
    const user = await db.collection('users').findOne({ email });
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    res.json({
      success: true,
      data: {
        userId: user.email,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone || '',
        address: user.address || '',
        profileImageUrl: user.profileImageUrl || '',
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
}

async function updateUserProfile(req, res) {
  try {
    const { email } = req.params;
    const { fullName, phone, address } = req.body;

    const update = {};
    if (fullName != null) update.fullName = fullName;
    if (phone != null) update.phone = phone;
    if (address != null) update.address = address;

    const db = getDB();
    const result = await db.collection('users').findOneAndUpdate(
      { email },
      { $set: update },
      { returnDocument: 'after' }
    );

    if (!result.value) return res.status(404).json({ success: false, error: 'User not found' });

    res.json({
      success: true,
      message: 'Profile updated',
      data: {
        email: result.value.email,
        fullName: result.value.fullName,
        phone: result.value.phone || '',
        address: result.value.address || '',
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
}

async function adminGetUsers(req, res) {
  try {
    const db = getDB();
    const allUsers = await db
      .collection('users')
      .find({}, { projection: { password: 0 } })
      .toArray();
    res.json({ success: true, data: allUsers });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
}

module.exports = {
  register,
  login,
  logout,
  getUserProfile,
  updateUserProfile,
  adminGetUsers,
};
