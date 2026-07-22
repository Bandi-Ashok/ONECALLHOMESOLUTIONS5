const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Regions
router.get('/regions', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM regions WHERE is_active = true ORDER BY region_name');
  res.json({ status: 'success', data: rows });
}));

router.post('/regions', asyncHandler(async (req, res) => {
  const { region_name, region_code, description, regional_manager_id, headquarters_city } = req.body;
  const { rows } = await query('INSERT INTO regions (region_name, region_code, description, regional_manager_id, headquarters_city) VALUES ($1,$2,$3,$4,$5) RETURNING *', [region_name, region_code, description, regional_manager_id, headquarters_city]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Branches
router.get('/', asyncHandler(async (req, res) => {
  const { region_id, city, is_active, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (region_id) { where += ` AND region_id = $${idx}`; params.push(region_id); idx++; }
  if (city) { where += ` AND city = $${idx}`; params.push(city); idx++; }
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM branches ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM branches WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Branch not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { branch_name, branch_code, region_id, branch_type, address_line1, city, state, pincode, latitude, longitude, contact_person, contact_email, contact_phone, branch_manager_id, is_headquarters } = req.body;
  const { rows } = await query(
    `INSERT INTO branches (branch_name, branch_code, region_id, branch_type, address_line1, city, state, pincode, latitude, longitude, contact_person, contact_email, contact_phone, branch_manager_id, is_headquarters) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15) RETURNING *`,
    [branch_name, branch_code, region_id, branch_type, address_line1, city, state, pincode, latitude, longitude, contact_person, contact_email, contact_phone, branch_manager_id, is_headquarters || false]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const fields = ['branch_name','branch_type','address_line1','city','state','pincode','contact_person','contact_email','contact_phone','branch_manager_id','is_active','monthly_revenue_target'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE branches SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  await query('UPDATE branches SET is_active = false WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Branch deactivated' });
}));

// Branch settings
router.get('/:id/settings', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM branch_settings WHERE branch_id = $1', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.put('/:id/settings', asyncHandler(async (req, res) => {
  const { setting_key, setting_value, description } = req.body;
  const { rows } = await query(
    `INSERT INTO branch_settings (branch_id, setting_key, setting_value, description) VALUES ($1,$2,$3,$4) ON CONFLICT (branch_id, setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, description = EXCLUDED.description RETURNING *`,
    [req.params.id, setting_key, JSON.stringify(setting_value), description]
  );
  res.json({ status: 'success', data: rows[0] });
}));

// City pricing
router.get('/pricing/city', asyncHandler(async (req, res) => {
  const { city_id, service_id } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (city_id) { where += ` AND city_id = $${idx}`; params.push(city_id); idx++; }
  if (service_id) { where += ` AND service_id = $${idx}`; params.push(service_id); idx++; }
  const { rows } = await query(`SELECT cp.*, c.city_name, s.name as service_name FROM city_pricing cp JOIN cities c ON cp.city_id = c.id JOIN services s ON cp.service_id = s.id ${where} ORDER BY cp.created_at DESC`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/pricing/city', asyncHandler(async (req, res) => {
  const { city_id, service_id, base_price, minimum_price, maximum_price, surge_multiplier, effective_from, effective_to } = req.body;
  const { rows } = await query(
    `INSERT INTO city_pricing (city_id, service_id, base_price, minimum_price, maximum_price, surge_multiplier, effective_from, effective_to) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT (city_id, service_id) DO UPDATE SET base_price = EXCLUDED.base_price, minimum_price = EXCLUDED.minimum_price, maximum_price = EXCLUDED.maximum_price, surge_multiplier = EXCLUDED.surge_multiplier RETURNING *`,
    [city_id, service_id, base_price, minimum_price, maximum_price, surge_multiplier || 1.0, effective_from, effective_to]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Regional managers
router.get('/regional-managers', asyncHandler(async (req, res) => {
  const { region_id } = req.query;
  let where = 'WHERE 1=1'; const params = [];
  if (region_id) { where += ` AND region_id = $1`; params.push(region_id); }
  const { rows } = await query(`SELECT rm.*, r.region_name, u.email FROM regional_managers rm JOIN regions r ON rm.region_id = r.id JOIN users u ON rm.user_id = u.id ${where} ORDER BY rm.assigned_at DESC`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/regional-managers', asyncHandler(async (req, res) => {
  const { user_id, region_id, designation, jurisdiction_type, managed_cities, managed_branches, performance_targets, assigned_at } = req.body;
  const { rows } = await query(
    `INSERT INTO regional_managers (user_id, region_id, designation, jurisdiction_type, managed_cities, managed_branches, performance_targets, assigned_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT (user_id, region_id) DO UPDATE SET designation = EXCLUDED.designation, jurisdiction_type = EXCLUDED.jurisdiction_type RETURNING *`,
    [user_id, region_id, designation, jurisdiction_type, managed_cities, managed_branches, JSON.stringify(performance_targets), assigned_at || new Date().toISOString().slice(0, 10)]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
