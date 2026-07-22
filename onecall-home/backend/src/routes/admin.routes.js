const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// System settings
router.get('/settings', asyncHandler(async (req, res) => {
  const { module, is_public } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (module) { where += ` AND module = $${idx}`; params.push(module); idx++; }
  if (is_public === 'true') { where += ` AND is_public = true`; }
  const { rows } = await query(`SELECT * FROM system_settings ${where} ORDER BY setting_key`, params);
  res.json({ status: 'success', data: rows });
}));

router.put('/settings/:key', asyncHandler(async (req, res) => {
  const { setting_value, updated_by } = req.body;
  const { rows } = await query('UPDATE system_settings SET setting_value = $1, updated_by = $2 WHERE setting_key = $3 RETURNING *', [setting_value, updated_by, req.params.key]);
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/settings', asyncHandler(async (req, res) => {
  const { setting_key, setting_value, setting_type, description, is_public, module } = req.body;
  const { rows } = await query('INSERT INTO system_settings (setting_key, setting_value, setting_type, description, is_public, module) VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value RETURNING *', [setting_key, setting_value, setting_type || 'string', description, is_public || false, module]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Feature flags
router.get('/features', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM feature_flags ORDER BY created_at DESC');
  res.json({ status: 'success', data: rows });
}));

router.post('/features', asyncHandler(async (req, res) => {
  const { flag_code, flag_name, description, is_enabled, rollout_percentage, target_user_types, target_cities } = req.body;
  const { rows } = await query('INSERT INTO feature_flags (flag_code, flag_name, description, is_enabled, rollout_percentage, target_user_types, target_cities) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *', [flag_code, flag_name, description, is_enabled || false, rollout_percentage || 0, target_user_types, target_cities]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.patch('/features/:id/toggle', asyncHandler(async (req, res) => {
  const { is_enabled } = req.body;
  const { rows } = await query('UPDATE feature_flags SET is_enabled = $1 WHERE id = $2 RETURNING *', [is_enabled, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Business configurations
router.get('/config', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM business_configurations WHERE is_active = true ORDER BY config_key');
  res.json({ status: 'success', data: rows });
}));

router.post('/config', asyncHandler(async (req, res) => {
  const { config_key, config_value, config_type, description, applicable_scope, scope_value } = req.body;
  const { rows } = await query('INSERT INTO business_configurations (config_key, config_value, config_type, description, applicable_scope, scope_value) VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (config_key) DO UPDATE SET config_value = EXCLUDED.config_value RETURNING *', [config_key, JSON.stringify(config_value), config_type, description, applicable_scope || 'global', scope_value]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Holiday calendar
router.get('/holidays', asyncHandler(async (req, res) => {
  const { year } = req.query;
  let where = 'WHERE 1=1'; const params = [];
  if (year) { where += ` AND EXTRACT(YEAR FROM holiday_date) = $1`; params.push(year); }
  const { rows } = await query(`SELECT * FROM holiday_calendar ${where} ORDER BY holiday_date`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/holidays', asyncHandler(async (req, res) => {
  const { holiday_name, holiday_date, holiday_type, applicable_states, applicable_cities, is_recurring_yearly, description } = req.body;
  const { rows } = await query('INSERT INTO holiday_calendar (holiday_name, holiday_date, holiday_type, applicable_states, applicable_cities, is_recurring_yearly, description) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *', [holiday_name, holiday_date, holiday_type, applicable_states, applicable_cities, is_recurring_yearly || true, description]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.delete('/holidays/:id', asyncHandler(async (req, res) => {
  await query('DELETE FROM holiday_calendar WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Holiday deleted' });
}));

// Business hours
router.get('/business-hours', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM business_hours ORDER BY day_of_week');
  res.json({ status: 'success', data: rows });
}));

router.put('/business-hours/:id', asyncHandler(async (req, res) => {
  const { start_time, end_time, is_working_day } = req.body;
  const { rows } = await query('UPDATE business_hours SET start_time = $1, end_time = $2, is_working_day = $3 WHERE id = $4 RETURNING *', [start_time, end_time, is_working_day, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

module.exports = router;
