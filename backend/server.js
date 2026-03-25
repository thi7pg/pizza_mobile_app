const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { connectDB } = require('./config/db');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/profile', require('./routes/profileRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));

// Simple connectivity check (Mongo ping)
app.get('/api/health', async (req, res) => {
  try {
    // connectDB is already awaited at startup, but this keeps it safe.
    const { getDB } = require('./config/db');
    getDB(); // throws if not initialized
    res.json({ success: true, status: 'OK' });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

async function startServer() {
  await connectDB();

  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

startServer().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});