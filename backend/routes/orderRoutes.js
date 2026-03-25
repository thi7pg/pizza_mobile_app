const express = require('express');
const router = express.Router();

const { createOrder, getOrders } = require('../controllers/orderController');

router.post('/', createOrder);
router.get('/:email', getOrders);

module.exports = router;

