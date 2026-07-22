const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Payments
router.get('/', asyncHandler(async (req, res) => {
  const { booking_id, customer_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (booking_id) { where += ` AND booking_id = $${idx}`; params.push(booking_id); idx++; }
  if (customer_id) { where += ` AND customer_id = $${idx}`; params.push(customer_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM payments ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM payments WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Payment not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { booking_id, customer_id, amount, currency, payment_method, payment_gateway, payment_mode, status } = req.body;
  const paymentNumber = 'PAY-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO payments (payment_number, booking_id, customer_id, amount, currency, payment_method, payment_gateway, payment_mode, status, payment_initiated_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,NOW()) RETURNING *`,
    [paymentNumber, booking_id, customer_id, amount, currency || 'INR', payment_method, payment_gateway, payment_mode || 'online', status || 'initiated']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const { status, gateway_transaction_id, gateway_response, payment_completed_at, settlement_status } = req.body;
  const { rows } = await query(
    `UPDATE payments SET status = $1, gateway_transaction_id = $2, gateway_response = $3, payment_completed_at = $4, settlement_status = $5 WHERE id = $6 RETURNING *`,
    [status, gateway_transaction_id, JSON.stringify(gateway_response), payment_completed_at, settlement_status, req.params.id]
  );
  res.json({ status: 'success', data: rows[0] });
}));

// Invoices
router.get('/invoices/all', asyncHandler(async (req, res) => {
  const { customer_id, booking_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (customer_id) { where += ` AND customer_id = $${idx}`; params.push(customer_id); idx++; }
  if (booking_id) { where += ` AND booking_id = $${idx}`; params.push(booking_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM invoices ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/invoices/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM invoices WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Invoice not found' });
  const items = (await query('SELECT * FROM invoice_items WHERE invoice_id = $1 ORDER BY sort_order', [req.params.id])).rows;
  res.json({ status: 'success', data: { ...rows[0], items } });
}));

router.post('/invoices', asyncHandler(async (req, res) => {
  const { booking_id, customer_id, invoice_type, invoice_date, due_date, subtotal, discount_amount, total_tax, total_amount, notes, terms_and_conditions, generated_by } = req.body;
  const invoiceNumber = 'INV-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO invoices (invoice_number, booking_id, customer_id, invoice_type, invoice_date, due_date, subtotal, discount_amount, total_tax, total_amount, amount_due, notes, terms_and_conditions, generated_by)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$10,$11,$12,$13) RETURNING *`,
    [invoiceNumber, booking_id, customer_id, invoice_type || 'tax_invoice', invoice_date, due_date, subtotal, discount_amount || 0, total_tax || 0, total_amount, notes, terms_and_conditions, generated_by]
  );
  await query('UPDATE bookings SET is_invoice_generated = true, invoice_id = $1 WHERE id = $2', [rows[0].id, booking_id]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.post('/invoices/:id/items', asyncHandler(async (req, res) => {
  const { item_type, description, hsn_sac_code, quantity, unit_price, total_amount, tax_percentage } = req.body;
  const { rows } = await query('INSERT INTO invoice_items (invoice_id, item_type, description, hsn_sac_code, quantity, unit_price, total_amount, tax_percentage) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *', [req.params.id, item_type, description, hsn_sac_code, quantity, unit_price, total_amount, tax_percentage]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Refunds
router.get('/refunds/all', asyncHandler(async (req, res) => {
  const { payment_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (payment_id) { where += ` AND payment_id = $${idx}`; params.push(payment_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM refunds ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/refunds', asyncHandler(async (req, res) => {
  const { payment_id, booking_id, customer_id, amount, refund_type, refund_method, reason, processed_by, approved_by } = req.body;
  const refundNumber = 'RFD-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO refunds (refund_number, payment_id, booking_id, customer_id, amount, refund_type, refund_method, reason, processed_by, approved_by, status)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
    [refundNumber, payment_id, booking_id, customer_id, amount, refund_type, refund_method, reason, processed_by, approved_by, 'initiated']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/refunds/:id', asyncHandler(async (req, res) => {
  const { status, refund_reference, processed_at, completed_at } = req.body;
  const { rows } = await query('UPDATE refunds SET status = $1, refund_reference = $2, processed_at = $3, completed_at = $4 WHERE id = $5 RETURNING *', [status, refund_reference, processed_at, completed_at, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Payment methods
router.get('/methods/:customerId', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM payment_methods WHERE customer_id = $1 ORDER BY is_default DESC', [req.params.customerId]);
  res.json({ status: 'success', data: rows });
}));

router.post('/methods', asyncHandler(async (req, res) => {
  const { customer_id, method_type, token_id, masked_number, card_network, card_type, cardholder_name, expiry_month, expiry_year, bank_name, is_default } = req.body;
  const { rows } = await query(
    `INSERT INTO payment_methods (customer_id, method_type, token_id, masked_number, card_network, card_type, cardholder_name, expiry_month, expiry_year, bank_name, is_default)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
    [customer_id, method_type, token_id, masked_number, card_network, card_type, cardholder_name, expiry_month, expiry_year, bank_name, is_default || false]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.delete('/methods/:id', asyncHandler(async (req, res) => {
  await query('DELETE FROM payment_methods WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Payment method deleted' });
}));

module.exports = router;
