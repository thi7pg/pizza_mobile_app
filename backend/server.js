const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { MongoClient, ObjectId } = require('mongodb');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017';
const MONGO_DB = process.env.MONGO_DB || 'pizza_app';
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret';

let db;
let usersCol;
let productsCol;
let ordersCol;

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

async function initMongo() {
  const client = new MongoClient(MONGO_URI);
  await client.connect();
  await client.db('admin').command({ ping: 1 });
  db = client.db(MONGO_DB);
  usersCol = db.collection('users');
  productsCol = db.collection('products');
  ordersCol = db.collection('orders');

  // Create admin if missing
  const adminEmail = 'admin@pizza.local';
  const admin = await usersCol.findOne({ email: adminEmail });
  if (!admin) {
    const hashed = await bcrypt.hash('admin123', 10);
    await usersCol.insertOne({
      email: adminEmail,
      password: hashed,
      fullName: 'Admin User',
      role: 'admin',
      createdAt: new Date().toISOString(),
    });
  }

  // Seed sample products if none exist
  const productCount = await productsCol.countDocuments();
  if (productCount === 0) {
    await productsCol.insertMany([
      {
        name: 'Margherita Pizza',
        description: 'Classic pizza with tomato and mozzarella',
        price: 12.99,
        khr: 52000,
        image: 'assets/products/margherita.png',
        createdAt: new Date().toISOString(),
      },
      {
        name: 'Pepperoni Pizza',
        description: 'Pizza with pepperoni slices',
        price: 14.99,
        khr: 60000,
        image: 'assets/products/pepperoni.png',
        createdAt: new Date().toISOString(),
      },
      {
        name: 'Vegetarian Pizza',
        description: 'Fresh vegetables on pizza',
        price: 11.99,
        khr: 48000,
        image: 'assets/products/vegetarian.png',
        createdAt: new Date().toISOString(),
      },
    ]);
  }

  console.log('MongoDB connected:', MONGO_DB);
  console.log('Products collection ready:', await productsCol.countDocuments());
}

// ============ Authentication Routes ============

app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, fullName } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const existing = await usersCol.findOne({ email });
    if (existing) {
      return res.status(400).json({ error: 'User already exists' });
    }

    const hashed = await bcrypt.hash(password, 10);
    const user = {
      email,
      password: hashed,
      fullName: fullName || email,
      role: 'user',
      createdAt: new Date().toISOString(),
    };

    await usersCol.insertOne(user);

    const token = jwt.sign({ email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });

    res.json({
      success: true,
      message: 'User registered successfully',
      token,
      user: { email, fullName: user.fullName, role: user.role },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const user = await usersCol.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign({ email: user.email, role: user.role || 'user' }, JWT_SECRET, { expiresIn: '7d' });

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
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/auth/logout', (req, res) => {
  res.json({ success: true, message: 'Logged out successfully' });
});

function getUserFromToken(req) {
  const auth = req.headers.authorization || '';
  const token = auth.replace(/^Bearer\s+/i, '');
  if (!token) return null;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    return decoded;
  } catch (err) {
    return null;
  }
}

function ensureAdmin(req, res, next) {
  const user = getUserFromToken(req);
  if (!user || user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  req.user = user;
  next();
}

function normalizeProduct(product) {
  if (!product) return null;
  const { _id, ...rest } = product;
  const price =
    typeof rest.price === 'number'
      ? rest.price
      : typeof rest.priceUSD === 'number'
      ? rest.priceUSD
      : 0;
  const khr =
    typeof rest.khr === 'number'
      ? rest.khr
      : typeof rest.priceKHR === 'number'
      ? rest.priceKHR
      : 0;
  const image = rest.image || rest.imageUrl || '';

  return {
    id: _id ? _id.toString() : rest.id,
    ...rest,
    image,
    price,
    khr,
    priceUSD: price,
    priceKHR: khr,
    imageUrl: image,
  };
}

function normalizeProducts(products) {
  return products.map(normalizeProduct);
}

function normalizeOrder(order) {
  if (!order) return null;
  const { _id, ...rest } = order;
  return {
    id: _id ? _id.toString() : rest.id,
    ...rest,
  };
}

function normalizeOrders(orders) {
  return orders.map(normalizeOrder);
}

// ============ Products Routes ============

app.get('/api/products', async (req, res) => {
  try {
    const products = await productsCol.find().toArray();
    res.json({ success: true, data: normalizeProducts(products) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid product id' });
    }
    const product = await productsCol.findOne({ _id: new ObjectId(req.params.id) });
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }
    res.json({ success: true, data: normalizeProduct(product) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============ Profile Routes ============

app.get('/api/profile/:email', async (req, res) => {
  try {
    const user = await usersCol.findOne({ email: req.params.email });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
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
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/profile/:email', async (req, res) => {
  try {
    const { fullName, phone, address } = req.body;
    const update = {};
    if (fullName) update.fullName = fullName;
    if (phone) update.phone = phone;
    if (address) update.address = address;

    const result = await usersCol.findOneAndUpdate(
      { email: req.params.email },
      { $set: update },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      return res.status(404).json({ error: 'User not found' });
    }

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
    res.status(500).json({ error: error.message });
  }
});

// ============ Admin routes ============

app.get('/api/admin/users', ensureAdmin, async (req, res) => {
  const allUsers = await usersCol
    .find({}, { projection: { password: 0 } })
    .toArray();
  res.json({ success: true, data: allUsers });
});

app.get('/api/admin/products', ensureAdmin, async (req, res) => {
  const products = await productsCol.find().toArray();
  res.json({ success: true, data: normalizeProducts(products) });
});

app.post('/api/admin/products', ensureAdmin, async (req, res) => {
  const { name, description, price, khr, image } = req.body;
  if (!name || price == null || khr == null) {
    return res.status(400).json({ error: 'name, price, khr required' });
  }

  const product = {
    name,
    description: description || '',
    price,
    khr,
    image: image || '',
    createdAt: new Date().toISOString(),
  };

  const result = await productsCol.insertOne(product);
  product.id = result.insertedId.toString();
  res.json({ success: true, data: normalizeProduct(product) });
});

app.put('/api/admin/products/:id', ensureAdmin, async (req, res) => {
  const { id } = req.params;
  const { name, description, price, khr, image } = req.body;
  const update = {};
  if (name != null) update.name = name;
  if (description != null) update.description = description;
  if (price != null) update.price = price;
  if (khr != null) update.khr = khr;
  if (image != null) update.image = image;

  const result = await productsCol.findOneAndUpdate(
    { _id: new ObjectId(id) },
    { $set: update },
    { returnDocument: 'after' }
  );

  if (!result.value) {
    return res.status(404).json({ error: 'Product not found' });
  }

  res.json({ success: true, data: normalizeProduct(result.value) });
});

app.delete('/api/admin/products/:id', ensureAdmin, async (req, res) => {
  const { id } = req.params;
  const result = await productsCol.deleteOne({ _id: new ObjectId(id) });
  if (result.deletedCount === 0) {
    return res.status(404).json({ error: 'Product not found' });
  }
  res.json({ success: true, message: 'Product removed' });
});

app.get('/api/admin/orders', ensureAdmin, async (req, res) => {
  const allOrders = await ordersCol.find().toArray();
  res.json({ success: true, data: normalizeOrders(allOrders) });
});

// ============ Orders Routes ============

app.post('/api/orders', async (req, res) => {
  try {
    const { email, items, totalPrice, totalKhr, status } = req.body;

    if (!email || !items || items.length === 0) {
      return res.status(400).json({ error: 'Invalid order data' });
    }

    const order = {
      email,
      items,
      totalPrice,
      totalKhr,
      status: status || 'pending',
      createdAt: new Date().toISOString(),
    };

    const result = await ordersCol.insertOne(order);
    order.id = result.insertedId.toString();

    res.json({ success: true, message: 'Order created', data: order });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/orders/:email', async (req, res) => {
  try {
    const userOrders = await ordersCol
      .find({ email: req.params.email })
      .sort({ createdAt: -1 })
      .toArray();

    res.json({ success: true, data: normalizeOrders(userOrders) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============ Health Check ============

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Pizza app backend is running' });
});

initMongo()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server listening on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error('Failed to start server:', error);
    process.exit(1);
  });

