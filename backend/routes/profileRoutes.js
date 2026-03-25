const express = require('express');
const router = express.Router();

const { requireAuth } = require('../middleware/authMiddleware');
const { getUserProfile, updateUserProfile } = require('../controllers/authController');

router.get('/:email', requireAuth, getUserProfile);
router.put('/:email', requireAuth, updateUserProfile);

module.exports = router;

