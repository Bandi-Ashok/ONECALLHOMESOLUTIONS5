const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

router.get('/', asyncHandler(async (req, res) => {
  const { customer_id, technician_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (customer_id) { where += ` AND b.customer_id = $${idx}`; params.push(customer_id); idx++; }
  if (technician_id) { where += ` AND b.technician_id = $${idx}`; params.push(technician_id); idx++; }
  if (status) { where += ` AND b.status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(
    `SELECT b.*, s.name as service_name, c.customer_code FROM bookings b
     LEFT JOIN services s ON b.service_id = s.id LEFT JOIN customers c ON b.customer_id = c.id
     ${where} ORDER BY b.created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params
  );
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query(
    `SELECT b.*, s.name as service_name, s.service_type, c.customer_code, t.technician_code
     FROM bookings b LEFT JOIN services s ON b.service_id = s.id LEFT JOIN customers c ON b.customer_id = c.id
     LEFT JOIN technicians t ON b.technician_id = t.id WHERE b.id = $1`, [req.params.id]
  );
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Booking not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { customer_id, service_id, property_id, booking_type, priority, scheduled_start_time, scheduled_end_time, service_address_id, service_notes, issue_description, source, total_amount } = req.body;
  const bookingNumber = 'BK-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO bookings (booking_number, customer_id, service_id, property_id, booking_type, priority, scheduled_start_time, scheduled_end_time, service_address_id, service_notes, issue_description, source, total_amount)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) RETURNING *`,
    [bookingNumber, customer_id, service_id, property_id, booking_type || 'standard', priority || 'normal', scheduled_start_time, scheduled_end_time, service_address_id, service_notes, issue_description, source || 'app', total_amount || 0]
  );
  await query('INSERT INTO booking_status_history (booking_id, new_status, changed_by_type) VALUES ($1, $2, $3)', [rows[0].id, 'pending', 'system']);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const fields = ['booking_type','status','sub_status','priority','scheduled_start_time','scheduled_end_time','technician_id','service_notes','access_instructions','customer_instructions','technician_notes','internal_notes','issue_description','diagnosis','solution','parts_required','parts_replaced','total_labour_cost','total_material_cost','total_parts_cost','subtotal','discount_amount','tax_amount','emergency_surcharge','convenience_fee','total_amount','payment_status','payment_method','customer_rating','technician_rating','customer_feedback','cancellation_reason'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE bookings SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  if (req.body.status) {
    await query('INSERT INTO booking_status_history (booking_id, new_status, changed_by_type) VALUES ($1, $2, $3)', [req.params.id, req.body.status, req.body.changed_by_type || 'system']);
  }
  res.json({ status: 'success', data: rows[0] });
}));

router.put('/:id/status', asyncHandler(async (req, res) => {
  const { status, changed_by_type, change_reason } = req.body;
  const old = await query('SELECT status FROM bookings WHERE id = $1', [req.params.id]);
  await query('UPDATE bookings SET status = $1 WHERE id = $2', [status, req.params.id]);
  await query('INSERT INTO booking_status_history (booking_id, old_status, new_status, changed_by_type, change_reason) VALUES ($1, $2, $3, $4, $5)', [req.params.id, old.rows[0]?.status, status, changed_by_type || 'system', change_reason]);
  res.json({ status: 'success', message: 'Booking status updated' });
}));

router.post('/:id/reschedule', asyncHandler(async (req, res) => {
  const { new_schedule, reason, rescheduled_by, rescheduled_by_type, charges_applied } = req.body;
  const old = await query('SELECT scheduled_start_time FROM bookings WHERE id = $1', [req.params.id]);
  await query('UPDATE bookings SET scheduled_start_time = $1, reschedule_count = reschedule_count + 1, status = $2 WHERE id = $3', [new_schedule, 'rescheduled', req.params.id]);
  await query('INSERT INTO booking_reschedules (booking_id, original_schedule, new_schedule, rescheduled_by, rescheduled_by_type, reason, charges_applied) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *', [req.params.id, old.rows[0]?.scheduled_start_time, new_schedule, rescheduled_by, rescheduled_by_type, reason, charges_applied || 0]);
  res.json({ status: 'success', message: 'Booking rescheduled' });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  const { cancellation_reason, cancelled_by } = req.body;
  await query('UPDATE bookings SET status = $1, cancellation_reason = $2, cancelled_by = $3, cancelled_at = NOW() WHERE id = $4', ['cancelled', cancellation_reason, cancelled_by, req.params.id]);
  res.json({ status: 'success', message: 'Booking cancelled' });
}));

router.get('/:id/history', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM booking_status_history WHERE booking_id = $1 ORDER BY created_at DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

// Quotes
router.get('/:id/quotes', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM booking_quotes WHERE booking_id = $1 ORDER BY created_at DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/quotes', asyncHandler(async (req, res) => {
  const { labour_cost, parts_cost, material_cost, tax_amount, total_amount, validity_hours, terms_and_conditions, created_by } = req.body;
  const quoteNumber = 'QT-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO booking_quotes (booking_id, quote_number, labour_cost, parts_cost, material_cost, tax_amount, total_amount, validity_hours, valid_until, terms_and_conditions, created_by)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW() + ($9 || ' hours')::interval,$10,$11) RETURNING *`,
    [req.params.id, quoteNumber, labour_cost || 0, parts_cost || 0, material_cost || 0, tax_amount || 0, total_amount, validity_hours || 24, String(validity_hours || 24), terms_and_conditions, created_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id/quotes/:quoteId', asyncHandler(async (req, res) => {
  const { status, approved_by, rejection_reason } = req.body;
  const { rows } = await query(
    `UPDATE booking_quotes SET status = $1, approved_by = $2, approved_at = CASE WHEN $1 = 'approved' THEN NOW() ELSE approved_at END, rejection_reason = $3 WHERE id = $4 RETURNING *`,
    [status, approved_by, rejection_reason, req.params.quoteId]
  );
  res.json({ status: 'success', data: rows[0] });
}));

router.get('/:id/quotes/:quoteId/items', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM quote_items WHERE quote_id = $1', [req.params.quoteId]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/quotes/:quoteId/items', asyncHandler(async (req, res) => {
  const { item_type, item_name, description, quantity, unit_price, total_price, tax_percentage } = req.body;
  const { rows } = await query('INSERT INTO quote_items (quote_id, item_type, item_name, description, quantity, unit_price, total_price, tax_percentage) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *', [req.params.quoteId, item_type, item_name, description, quantity, unit_price, total_price, tax_percentage]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
