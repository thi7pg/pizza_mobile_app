const express = require('express');
const router = express.Router();

// This file is kept for compatibility; your app currently uses `routes/orderRoutes.js`.
const { createOrder, getOrders } = require('../controllers/orderController');

router.post('/', createOrder);
router.get('/:email', getOrders);

module.exports = router;
