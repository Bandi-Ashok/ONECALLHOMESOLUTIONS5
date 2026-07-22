const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Cities
router.get('/cities', asyncHandler(async (req, res) => {
  const { state, is_active } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (state) { where += ` AND state = $${idx}`; params.push(state); idx++; }
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  const { rows } = await query(`SELECT * FROM cities ${where} ORDER BY city_name`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/cities', asyncHandler(async (req, res) => {
  const { city_name, state, country, district, is_tier_1, latitude, longitude, timezone } = req.body;
  const { rows } = await query('INSERT INTO cities (city_name, state, country, district, is_tier_1, latitude, longitude, timezone) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *', [city_name, state, country || 'India', district, is_tier_1 || false, latitude, longitude, timezone]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/cities/:id', asyncHandler(async (req, res) => {
  const { city_name, state, is_active, is_tier_1 } = req.body;
  const { rows } = await query('UPDATE cities SET city_name = $1, state = $2, is_active = $3, is_tier_1 = $4 WHERE id = $5 RETURNING *', [city_name, state, is_active, is_tier_1, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Pincodes
router.get('/pincodes', asyncHandler(async (req, res) => {
  const { city_id, is_serviceable } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (city_id) { where += ` AND city_id = $${idx}`; params.push(city_id); idx++; }
  if (is_serviceable !== undefined) { where += ` AND is_serviceable = $${idx}`; params.push(is_serviceable === 'true'); idx++; }
  const { rows } = await query(`SELECT * FROM service_pincodes ${where} ORDER BY pincode`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/pincodes', asyncHandler(async (req, res) => {
  const { pincode, city_id, area_name, is_serviceable, delivery_available, minimum_order_value } = req.body;
  const { rows } = await query('INSERT INTO service_pincodes (pincode, city_id, area_name, is_serviceable, delivery_available, minimum_order_value) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [pincode, city_id, area_name, is_serviceable !== false, delivery_available !== false, minimum_order_value]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// SLA Policies
router.get('/sla', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM sla_policies WHERE is_active = true ORDER BY priority');
  res.json({ status: 'success', data: rows });
}));

router.post('/sla', asyncHandler(async (req, res) => {
  const { policy_name, policy_code, service_id, customer_tier, priority, response_time_minutes, resolution_time_minutes, escalation_time_minutes, max_reschedule_count, penalty_percentage } = req.body;
  const { rows } = await query(
    `INSERT INTO sla_policies (policy_name, policy_code, service_id, customer_tier, priority, response_time_minutes, resolution_time_minutes, escalation_time_minutes, max_reschedule_count, penalty_percentage) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
    [policy_name, policy_code, service_id, customer_tier, priority, response_time_minutes, resolution_time_minutes, escalation_time_minutes, max_reschedule_count || 3, penalty_percentage]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Tax configurations
router.get('/tax', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM tax_configurations WHERE is_active = true ORDER BY effective_from DESC');
  res.json({ status: 'success', data: rows });
}));

router.post('/tax', asyncHandler(async (req, res) => {
  const { tax_name, tax_code, tax_type, tax_percentage, applicable_category, hsn_sac_code_prefix, effective_from, effective_to } = req.body;
  const { rows } = await query('INSERT INTO tax_configurations (tax_name, tax_code, tax_type, tax_percentage, applicable_category, hsn_sac_code_prefix, effective_from, effective_to) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *', [tax_name, tax_code, tax_type, tax_percentage, applicable_category, hsn_sac_code_prefix, effective_from, effective_to]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Geofence zones
router.get('/geofence', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM geofence_zones WHERE is_active = true ORDER BY created_at DESC');
  res.json({ status: 'success', data: rows });
}));

router.post('/geofence', asyncHandler(async (req, res) => {
  const { zone_name, zone_code, zone_type, center_latitude, center_longitude, radius_km, city, state, properties } = req.body;
  const { rows } = await query('INSERT INTO geofence_zones (zone_name, zone_code, zone_type, center_latitude, center_longitude, radius_km, city, state, properties) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *', [zone_name, zone_code, zone_type, center_latitude, center_longitude, radius_km, city, state, JSON.stringify(properties)]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Service locations
router.get('/service-locations', asyncHandler(async (req, res) => {
  const { entity_type, entity_id } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (entity_type) { where += ` AND entity_type = $${idx}`; params.push(entity_type); idx++; }
  if (entity_id) { where += ` AND entity_id = $${idx}`; params.push(entity_id); idx++; }
  const { rows } = await query(`SELECT * FROM service_locations ${where} ORDER BY recorded_at DESC LIMIT 100`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/service-locations', asyncHandler(async (req, res) => {
  const { entity_type, entity_id, latitude, longitude, accuracy_meters, bearing, speed_kmh } = req.body;
  await query('UPDATE service_locations SET is_current = false WHERE entity_type = $1 AND entity_id = $2', [entity_type, entity_id]);
  const { rows } = await query('INSERT INTO service_locations (entity_type, entity_id, latitude, longitude, accuracy_meters, bearing, speed_kmh, is_current) VALUES ($1,$2,$3,$4,$5,$6,$7,true) RETURNING *', [entity_type, entity_id, latitude, longitude, accuracy_meters, bearing, speed_kmh]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Search
router.get('/search', asyncHandler(async (req, res) => {
  const { q, category, city, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (q) { where += ` AND (title ILIKE $${idx} OR keywords ILIKE $${idx})`; params.push(`%${q}%`); idx++; }
  if (category) { where += ` AND category = $${idx}`; params.push(category); idx++; }
  if (city) { where += ` AND city = $${idx}`; params.push(city); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM search_index ${where} ORDER BY popularity_score DESC NULLS LAST LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

module.exports = router;
