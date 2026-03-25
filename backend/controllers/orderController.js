const { getDB } = require('../config/db');

function normalizeOrder(o) {
  return {
    id: o?._id ? o._id.toString() : o?.id?.toString?.() ?? '',
    email: o?.email ?? '',
    items: o?.items ?? [],
    totalPrice: typeof o?.totalPrice === 'number' ? o.totalPrice : Number(o?.totalPrice ?? 0),
    totalKhr: typeof o?.totalKhr === 'number' ? o.totalKhr : Number(o?.totalKhr ?? 0),
    status: o?.status ?? 'pending',
    createdAt: o?.createdAt ?? '',
  };
}

async function createOrder(req, res) {
  try {
    const { email, items, totalPrice, totalKhr, status } = req.body;
    if (!email || !items || items.length === 0) {
      return res.status(400).json({ success: false, error: 'Invalid order data' });
    }

    const order = {
      email,
      items,
      totalPrice: typeof totalPrice === 'number' ? totalPrice : Number(totalPrice ?? 0),
      totalKhr: typeof totalKhr === 'number' ? totalKhr : Number(totalKhr ?? 0),
      status: status || 'pending',
      createdAt: new Date().toISOString(),
    };

    const db = getDB();
    const result = await db.collection('orders').insertOne(order);
    order.id = result.insertedId.toString();

    res.json({ success: true, message: 'Order created', data: order });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
}

async function getOrders(req, res) {
  try {
    const { email } = req.params;
    const db = getDB();
    const userOrders = await db
      .collection('orders')
      .find({ email })
      .sort({ createdAt: -1 })
      .toArray();

    res.json({ success: true, data: userOrders.map(normalizeOrder) });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
}

async function adminGetOrders(req, res) {
  try {
    const db = getDB();
    const allOrders = await db.collection('orders').find().sort({ createdAt: -1 }).toArray();
    res.json({ success: true, data: allOrders.map(normalizeOrder) });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
}

module.exports = { createOrder, getOrders, adminGetOrders };
