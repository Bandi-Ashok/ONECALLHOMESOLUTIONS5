const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Categories
router.get('/categories', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM service_categories WHERE is_active = true ORDER BY sort_order, name');
  res.json({ status: 'success', data: rows });
}));

router.post('/categories', asyncHandler(async (req, res) => {
  const { name, slug, description, parent_category_id, icon_url, is_featured } = req.body;
  const { rows } = await query('INSERT INTO service_categories (name, slug, description, parent_category_id, icon_url, is_featured) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [name, slug, description, parent_category_id, icon_url, is_featured]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/categories/:id', asyncHandler(async (req, res) => {
  const fields = ['name','slug','description','icon_url','is_active','is_featured','sort_order'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE service_categories SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/categories/:id', asyncHandler(async (req, res) => {
  await query('DELETE FROM service_categories WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Category deleted' });
}));

// Services
router.get('/', asyncHandler(async (req, res) => {
  const { category_id, search, is_featured, is_emergency, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE s.is_active = true'; const params = []; let idx = 1;
  if (category_id) { where += ` AND s.category_id = $${idx}`; params.push(category_id); idx++; }
  if (search) { where += ` AND (s.name ILIKE $${idx} OR s.description ILIKE $${idx})`; params.push(`%${search}%`); idx++; }
  if (is_featured === 'true') { where += ` AND s.is_featured = true`; }
  if (is_emergency === 'true') { where += ` AND s.is_emergency_service = true`; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(
    `SELECT s.*, sc.name as category_name FROM services s LEFT JOIN service_categories sc ON s.category_id = sc.id ${where} ORDER BY s.sort_order, s.name LIMIT $${idx} OFFSET $${idx + 1}`, params
  );
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT s.*, sc.name as category_name FROM services s LEFT JOIN service_categories sc ON s.category_id = sc.id WHERE s.id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Service not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { category_id, name, slug, description, short_description, service_code, service_type, estimated_duration_minutes, base_price, price_type, is_emergency_service, warranty_days } = req.body;
  const { rows } = await query(
    `INSERT INTO services (category_id, name, slug, description, short_description, service_code, service_type, estimated_duration_minutes, base_price, price_type, is_emergency_service, warranty_days)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
    [category_id, name, slug, description, short_description, service_code, service_type, estimated_duration_minutes, base_price, price_type || 'fixed', is_emergency_service || false, warranty_days || 30]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const fields = ['name','slug','description','short_description','service_type','estimated_duration_minutes','base_price','price_type','is_active','is_featured','is_popular','is_emergency_service','warranty_days','required_skills','tools_required','service_instructions'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE services SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  await query('UPDATE services SET is_active = false WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Service deactivated' });
}));

// Pricing
router.get('/:id/pricing', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM service_pricing WHERE service_id = $1 AND is_active = true ORDER BY effective_from DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/pricing', asyncHandler(async (req, res) => {
  const { city, state, pincode, customer_tier, price, minimum_price, maximum_price, discount_percentage, effective_from, effective_to } = req.body;
  const { rows } = await query(
    `INSERT INTO service_pricing (service_id, city, state, pincode, customer_tier, price, minimum_price, maximum_price, discount_percentage, effective_from, effective_to)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
    [req.params.id, city, state, pincode, customer_tier, price, minimum_price, maximum_price, discount_percentage, effective_from, effective_to]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Packages
router.get('/packages/all', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM service_packages WHERE is_active = true ORDER BY created_at DESC');
  res.json({ status: 'success', data: rows });
}));

router.get('/packages/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM service_packages WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Package not found' });
  const items = (await query('SELECT spi.*, s.name as service_name FROM service_package_items spi JOIN services s ON spi.service_id = s.id WHERE spi.package_id = $1', [req.params.id])).rows;
  res.json({ status: 'success', data: { ...rows[0], items } });
}));

router.post('/packages', asyncHandler(async (req, res) => {
  const { name, description, package_code, package_type, total_price, discount_percentage, discounted_price, validity_days, max_bookings, terms_and_conditions } = req.body;
  const { rows } = await query(
    `INSERT INTO service_packages (name, description, package_code, package_type, total_price, discount_percentage, discounted_price, validity_days, max_bookings, terms_and_conditions)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
    [name, description, package_code, package_type, total_price, discount_percentage, discounted_price, validity_days, max_bookings, terms_and_conditions]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// FAQs
router.get('/:id/faqs', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM service_faqs WHERE service_id = $1 AND is_active = true ORDER BY sort_order', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/faqs', asyncHandler(async (req, res) => {
  const { question, answer, sort_order } = req.body;
  const { rows } = await query('INSERT INTO service_faqs (service_id, question, answer, sort_order) VALUES ($1,$2,$3,$4) RETURNING *', [req.params.id, question, answer, sort_order || 0]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
