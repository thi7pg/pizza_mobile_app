const { getDB } = require('../config/db');

function normalizeUser(u) {
  if (!u) return null;
  return {
    id: u?._id ? u._id.toString() : u?.id?.toString?.() ?? '',
    email: u?.email ?? '',
    fullName: u?.fullName ?? '',
    role: u?.role ?? 'user',
    createdAt: u?.createdAt ?? '',
    phone: u?.phone ?? '',
    address: u?.address ?? '',
    profileImageUrl: u?.profileImageUrl ?? '',
  };
}

async function findByEmail(email) {
  const db = getDB();
  const doc = await db.collection('users').findOne({ email });
  return normalizeUser(doc);
}

async function findAllPublic() {
  const db = getDB();
  const docs = await db.collection('users').find({}, { projection: { password: 0 } }).toArray();
  return docs.map(normalizeUser);
}

module.exports = { normalizeUser, findByEmail, findAllPublic };
