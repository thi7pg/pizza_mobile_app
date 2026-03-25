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

async function create(order) {
  const db = getDB();
  const result = await db.collection('orders').insertOne(order);
  const created = await db.collection('orders').findOne({ _id: result.insertedId });
  return created ? normalizeOrder(created) : null;
}

async function findByEmail(email) {
  const db = getDB();
  const docs = await db.collection('orders').find({ email }).sort({ createdAt: -1 }).toArray();
  return docs.map(normalizeOrder);
}

async function findAll() {
  const db = getDB();
  const docs = await db.collection('orders').find().sort({ createdAt: -1 }).toArray();
  return docs.map(normalizeOrder);
}

module.exports = { normalizeOrder, create, findByEmail, findAll };
