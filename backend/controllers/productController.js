const { getDB } = require('../config/db');

function normalizeProduct(p) {
  const id = p?._id ? p._id.toString() : p?.id?.toString?.() ?? '';

  const priceUSD =
    typeof p?.priceUSD === 'number' ? p.priceUSD : typeof p?.price === 'number' ? p.price : 0;
  const priceKHR =
    typeof p?.priceKHR === 'number' ? p.priceKHR : typeof p?.khr === 'number' ? p.khr : 0;

  return {
    id,
    name: p?.name ?? '',
    description: p?.description ?? '',
    image: p?.image ?? p?.imageUrl ?? '',
    imageUrl: p?.imageUrl ?? p?.image ?? '',
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

async function getProducts(req, res) {
  try {
    const db = getDB();
    const products = await db.collection('products').find().toArray();

    res.json({ success: true, data: products.map(normalizeProduct) });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}

async function getProductById(req, res) {
  try {
    const { ObjectId } = require('mongodb');
    const { id } = req.params;

    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, error: 'Invalid product id' });
    }

    const db = getDB();
    const product = await db.collection('products').findOne({ _id: new ObjectId(id) });
    if (!product) return res.status(404).json({ success: false, error: 'Product not found' });

    res.json({ success: true, data: normalizeProduct(product) });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}

// ============ Admin product CRUD ============
async function adminGetProducts(req, res) {
  try {
    const db = getDB();
    const products = await db.collection('products').find().toArray();
    res.json({ success: true, data: products.map(normalizeProduct) });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}

async function adminCreateProduct(req, res) {
  try {
    const db = getDB();
    const { name, description, price, khr, image } = req.body;

    if (!name || price == null || khr == null) {
      return res.status(400).json({ success: false, error: 'name, price, khr required' });
    }

    const product = {
      name,
      description: description ?? '',
      price,
      khr,
      image: image ?? '',
      createdAt: new Date().toISOString(),
    };

    const result = await db.collection('products').insertOne(product);
    const created = await db.collection('products').findOne({ _id: result.insertedId });
    res.json({ success: true, data: normalizeProduct(created) });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}

async function adminUpdateProduct(req, res) {
  try {
    const { ObjectId } = require('mongodb');
    const { id } = req.params;
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, error: 'Invalid product id' });
    }

    const { name, description, price, khr, image } = req.body;
    const update = {};
    if (name != null) update.name = name;
    if (description != null) update.description = description;
    if (price != null) update.price = price;
    if (khr != null) update.khr = khr;
    if (image != null) update.image = image;

    const db = getDB();
    const result = await db
      .collection('products')
      .findOneAndUpdate(
        { _id: new ObjectId(id) },
        { $set: update },
        { returnDocument: 'after' }
      );

    if (!result.value) {
      return res.status(404).json({ success: false, error: 'Product not found' });
    }

    res.json({ success: true, data: normalizeProduct(result.value) });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}

async function adminDeleteProduct(req, res) {
  try {
    const { ObjectId } = require('mongodb');
    const { id } = req.params;
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, error: 'Invalid product id' });
    }

    const db = getDB();
    const result = await db.collection('products').deleteOne({ _id: new ObjectId(id) });
    if (result.deletedCount === 0) {
      return res.status(404).json({ success: false, error: 'Product not found' });
    }

    res.json({ success: true, message: 'Product removed' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}

module.exports = {
  getProducts,
  getProductById,
  adminGetProducts,
  adminCreateProduct,
  adminUpdateProduct,
  adminDeleteProduct,
};