const { getDB } = require('../config/db');

function normalizeProduct(p) {
  const id = p?._id ? p._id.toString() : p?.id?.toString?.() ?? '';

  const priceUSD =
    typeof p?.priceUSD === 'number' ? p.priceUSD : typeof p?.price === 'number' ? p.price : 0;
  const priceKHR =
    typeof p?.priceKHR === 'number' ? p.priceKHR : typeof p?.khr === 'number' ? p.khr : 0;

  const image = p?.image ?? p?.imageUrl ?? '';

  return {
    id,
    name: p?.name ?? '',
    description: p?.description ?? '',
    image,
    imageUrl: p?.imageUrl ?? image,
    price: p?.price ?? priceUSD,
    khr: p?.khr ?? priceKHR,
    priceUSD,
    priceKHR,
    productType: p?.productType ?? 'unit',
    packingGroup: p?.packingGroup ?? 'general',
    deliveryRule: p?.deliveryRule ?? 'group_capacity',
    deliveryFactor: typeof p?.deliveryFactor === 'number' ? p.deliveryFactor : 1,
    deliveryBoxCapacity:
      typeof p?.deliveryBoxCapacity === 'number' ? p.deliveryBoxCapacity : 1,
    category: p?.category ?? 'General',
    isActive: typeof p?.isActive === 'boolean' ? p.isActive : true,
    createdAt: p?.createdAt ?? undefined,
  };
}

async function findAll() {
  const db = getDB();
  const docs = await db.collection('products').find().toArray();
  return docs.map(normalizeProduct);
}

async function findById(id) {
  const { ObjectId } = require('mongodb');
  const db = getDB();
  if (!ObjectId.isValid(id)) return null;
  const doc = await db.collection('products').findOne({ _id: new ObjectId(id) });
  return doc ? normalizeProduct(doc) : null;
}

module.exports = { normalizeProduct, findAll, findById };
