const { MongoClient } = require('mongodb');
const bcrypt = require('bcryptjs');

const MONGO_URI = process.env.MONGO_URI;
const MONGO_DB = process.env.MONGO_DB;

let db;
let client;

async function connectDB() {
  if (db) return;

  if (!MONGO_URI) {
    throw new Error('MONGO_URI is missing in environment/.env');
  }
  if (!MONGO_DB) {
    throw new Error('MONGO_DB is missing in environment/.env');
  }

  client = new MongoClient(MONGO_URI);
  await client.connect();

  // Verify connectivity (auth, networking, TLS, etc.)
  await client.db('admin').command({ ping: 1 });

  db = client.db(MONGO_DB);
  console.log('MongoDB connected:', MONGO_DB);

  // Seed admin user if missing
  const adminEmail = 'admin@pizza.local';
  const usersCol = db.collection('users');
  const existingAdmin = await usersCol.findOne({ email: adminEmail });
  if (!existingAdmin) {
    const hashed = await bcrypt.hash('admin123', 10);
    await usersCol.insertOne({
      email: adminEmail,
      password: hashed,
      fullName: 'Admin User',
      role: 'admin',
      createdAt: new Date().toISOString(),
    });
  }
}

function getDB() {
  if (!db) throw new Error('DB not initialized');
  return db;
}

module.exports = { connectDB, getDB };