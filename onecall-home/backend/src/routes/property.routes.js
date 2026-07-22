const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

router.get('/', asyncHandler(async (req, res) => {
  const { customer_id, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (customer_id) { where += ` AND customer_id = $${idx}`; params.push(customer_id); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM properties ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM properties WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Property not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { customer_id, property_name, property_type, address_line1, address_line2, city, state, pincode, total_area, number_of_rooms, number_of_bathrooms, furnishing_status } = req.body;
  const { rows } = await query(
    `INSERT INTO properties (customer_id, property_name, property_type, address_line1, address_line2, city, state, pincode, total_area, number_of_rooms, number_of_bathrooms, furnishing_status)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
    [customer_id, property_name, property_type, address_line1, address_line2, city, state, pincode, total_area, number_of_rooms, number_of_bathrooms, furnishing_status]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const fields = ['property_name','property_type','address_line1','address_line2','city','state','pincode','total_area','number_of_rooms','number_of_bathrooms','furnishing_status','property_condition','is_verified','access_instructions','gate_code','security_contact'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE properties SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  await query('DELETE FROM properties WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Property deleted' });
}));

router.get('/:id/rooms', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM property_rooms WHERE property_id = $1 ORDER BY created_at', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/rooms', asyncHandler(async (req, res) => {
  const { room_name, room_type, floor_number, area, has_ac, has_window } = req.body;
  const { rows } = await query('INSERT INTO property_rooms (property_id, room_name, room_type, floor_number, area, has_ac, has_window) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *', [req.params.id, room_name, room_type, floor_number, area, has_ac, has_window]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.delete('/:id/rooms/:roomId', asyncHandler(async (req, res) => {
  await query('DELETE FROM property_rooms WHERE id = $1 AND property_id = $2', [req.params.roomId, req.params.id]);
  res.json({ status: 'success', message: 'Room deleted' });
}));

router.get('/:id/appliances', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM property_appliances WHERE property_id = $1 ORDER BY created_at', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/appliances', asyncHandler(async (req, res) => {
  const { appliance_type, brand, model_number, serial_number, room_id, condition_status, installation_date, warranty_end_date } = req.body;
  const { rows } = await query('INSERT INTO property_appliances (property_id, room_id, appliance_type, brand, model_number, serial_number, condition_status, installation_date, warranty_end_date) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *', [req.params.id, room_id, appliance_type, brand, model_number, serial_number, condition_status, installation_date, warranty_end_date]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.delete('/:id/appliances/:appId', asyncHandler(async (req, res) => {
  await query('DELETE FROM property_appliances WHERE id = $1 AND property_id = $2', [req.params.appId, req.params.id]);
  res.json({ status: 'success', message: 'Appliance deleted' });
}));

router.get('/:id/media', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM property_media WHERE property_id = $1 ORDER BY sort_order', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/media', asyncHandler(async (req, res) => {
  const { media_type, file_id, title, description, is_primary } = req.body;
  const { rows } = await query('INSERT INTO property_media (property_id, media_type, file_id, title, description, is_primary) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [req.params.id, media_type, file_id, title, description, is_primary]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.get('/:id/service-history', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM property_service_history WHERE property_id = $1 ORDER BY service_date DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

module.exports = router;
