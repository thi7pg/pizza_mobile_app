const express = require('express');
const router = express.Router();

const { requireAdmin } = require('../middleware/authMiddleware');
const { adminGetUsers } = require('../controllers/authController');
const {
  adminGetProducts,
  adminCreateProduct,
  adminUpdateProduct,
  adminDeleteProduct,
} = require('../controllers/productController');
const { adminGetOrders } = require('../controllers/orderController');

router.get('/users', requireAdmin, adminGetUsers);

router.get('/products', requireAdmin, adminGetProducts);
router.post('/products', requireAdmin, adminCreateProduct);
router.put('/products/:id', requireAdmin, adminUpdateProduct);
router.delete('/products/:id', requireAdmin, adminDeleteProduct);

router.get('/orders', requireAdmin, adminGetOrders);

module.exports = router;

