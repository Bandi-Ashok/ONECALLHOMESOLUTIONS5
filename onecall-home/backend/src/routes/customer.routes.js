const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { authenticate, authorize, optionalAuth } = require('../middleware/auth.middleware');
const { asyncHandler } = require('../middleware/error.middleware');

// GET /api/customers
router.get('/', asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, tier, status } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1';
  const params = [];
  let idx = 1;
  if (search) { where += ` AND (c.customer_code ILIKE $${idx} OR u.email ILIKE $${idx} OR up.first_name ILIKE $${idx} OR up.last_name ILIKE $${idx})`; params.push(`%${search}%`); idx++; }
  if (tier) { where += ` AND c.customer_tier = $${idx}`; params.push(tier); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(
    `SELECT c.*, u.email, u.phone, u.status, up.first_name, up.last_name, up.display_name
     FROM customers c JOIN users u ON c.user_id = u.id LEFT JOIN user_profiles up ON u.id = up.user_id
     ${where} ORDER BY c.created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params
  );
  res.json({ status: 'success', data: rows });
}));

// GET /api/customers/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query(
    `SELECT c.*, u.email, u.phone, u.status, up.* FROM customers c
     JOIN users u ON c.user_id = u.id LEFT JOIN user_profiles up ON u.id = up.user_id WHERE c.id = $1`, [req.params.id]
  );
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Customer not found' });
  res.json({ status: 'success', data: rows[0] });
}));

// POST /api/customers
router.post('/', asyncHandler(async (req, res) => {
  const { user_id, customer_type, customer_tier, referral_code, is_vip, source, tags, special_instructions } = req.body;
  const customerCode = 'CUST-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO customers (user_id, customer_code, customer_type, customer_tier, referral_code, is_vip, source, tags, special_instructions)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
    [user_id, customerCode, customer_type || 'individual', customer_tier || 'standard', referral_code, is_vip || false, source || 'direct', tags || null, special_instructions || null]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// PUT /api/customers/:id
router.put('/:id', asyncHandler(async (req, res) => {
  const fields = ['customer_type', 'customer_tier', 'is_vip', 'tags', 'special_instructions', 'preferred_technicians', 'blocked_technicians', 'custom_attributes'];
  const updates = [];
  const params = [];
  let idx = 1;
  for (const f of fields) {
    if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; }
  }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE customers SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

// DELETE /api/customers/:id
router.delete('/:id', asyncHandler(async (req, res) => {
  await query('DELETE FROM customers WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Customer deleted' });
}));

// GET /api/customers/:id/addresses
router.get('/:id/addresses', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM customer_addresses WHERE customer_id = $1 ORDER BY is_default DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

// POST /api/customers/:id/addresses
router.post('/:id/addresses', asyncHandler(async (req, res) => {
  const { address_type, label, address_line1, address_line2, landmark, city, state, pincode, latitude, longitude, is_default } = req.body;
  const { rows } = await query(
    `INSERT INTO customer_addresses (customer_id, address_type, label, address_line1, address_line2, landmark, city, state, pincode, latitude, longitude, is_default)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *`,
    [req.params.id, address_type || 'home', label, address_line1, address_line2, landmark, city, state, pincode, latitude, longitude, is_default || false]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// PUT /api/customers/:id/addresses/:addressId
router.put('/:id/addresses/:addressId', asyncHandler(async (req, res) => {
  const fields = ['address_type', 'label', 'address_line1', 'address_line2', 'landmark', 'city', 'state', 'pincode', 'latitude', 'longitude', 'is_default', 'is_verified'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.addressId);
  const { rows } = await query(`UPDATE customer_addresses SET ${updates.join(', ')} WHERE id = $${idx} AND customer_id = $${idx + 1} RETURNING *`, [...params, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// DELETE /api/customers/:id/addresses/:addressId
router.delete('/:id/addresses/:addressId', asyncHandler(async (req, res) => {
  await query('DELETE FROM customer_addresses WHERE id = $1 AND customer_id = $2', [req.params.addressId, req.params.id]);
  res.json({ status: 'success', message: 'Address deleted' });
}));

// GET /api/customers/:id/wallet
router.get('/:id/wallet', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM customer_wallets WHERE customer_id = $1', [req.params.id]);
  res.json({ status: 'success', data: rows[0] || null });
}));

// GET /api/customers/:id/wallet/transactions
router.get('/:id/wallet/transactions', asyncHandler(async (req, res) => {
  const { rows } = await query(
    `SELECT wt.* FROM wallet_transactions wt JOIN customer_wallets cw ON wt.wallet_id = cw.id WHERE cw.customer_id = $1 ORDER BY wt.transaction_at DESC LIMIT 50`, [req.params.id]
  );
  res.json({ status: 'success', data: rows });
}));

// POST /api/customers/:id/wallet/transactions
router.post('/:id/wallet/transactions', asyncHandler(async (req, res) => {
  const { transaction_type, amount, source, description } = req.body;
  const wallet = (await query('SELECT * FROM customer_wallets WHERE customer_id = $1', [req.params.id])).rows[0];
  if (!wallet) return res.status(404).json({ status: 'error', message: 'Wallet not found' });
  const balanceBefore = parseFloat(wallet.balance);
  const balanceAfter = transaction_type === 'credit' ? balanceBefore + parseFloat(amount) : balanceBefore - parseFloat(amount);
  const { rows } = await query(
    `INSERT INTO wallet_transactions (wallet_id, transaction_type, amount, balance_before, balance_after, source, description)
     VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
    [wallet.id, transaction_type, amount, balanceBefore, balanceAfter, source, description]
  );
  await query('UPDATE customer_wallets SET balance = $1, last_transaction_at = NOW() WHERE id = $2', [balanceAfter, wallet.id]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// GET /api/customers/:id/feedback
router.get('/:id/feedback', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM customer_feedback WHERE customer_id = $1 ORDER BY created_at DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

// POST /api/customers/:id/feedback
router.post('/:id/feedback', asyncHandler(async (req, res) => {
  const { feedback_type, category, severity, title, description, satisfaction_score, booking_id } = req.body;
  const { rows } = await query(
    `INSERT INTO customer_feedback (customer_id, booking_id, feedback_type, category, severity, title, description, satisfaction_score)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
    [req.params.id, booking_id, feedback_type || 'general', category, severity || 'medium', title, description, satisfaction_score]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
