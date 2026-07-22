const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// API Integrations
router.get('/', asyncHandler(async (req, res) => {
  const { service_type, is_active, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (service_type) { where += ` AND service_type = $${idx}`; params.push(service_type); idx++; }
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM api_integrations ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM api_integrations WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Integration not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { integration_name, integration_code, provider, service_type, api_endpoint, api_version, auth_type, credentials, headers, timeout_ms, retry_count, rate_limit_per_second } = req.body;
  const { rows } = await query(
    `INSERT INTO api_integrations (integration_name, integration_code, provider, service_type, api_endpoint, api_version, auth_type, credentials, headers, timeout_ms, retry_count, rate_limit_per_second) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
    [integration_name, integration_code, provider, service_type, api_endpoint, api_version, auth_type, JSON.stringify(credentials), JSON.stringify(headers), timeout_ms || 30000, retry_count || 3, rate_limit_per_second]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const { is_active, health_status, credentials, headers, timeout_ms, retry_count } = req.body;
  const { rows } = await query('UPDATE api_integrations SET is_active = $1, health_status = $2, credentials = $3, headers = $4, timeout_ms = $5, retry_count = $6, last_checked_at = NOW() WHERE id = $7 RETURNING *', [is_active, health_status, JSON.stringify(credentials), JSON.stringify(headers), timeout_ms, retry_count, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  await query('UPDATE api_integrations SET is_active = false WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Integration deactivated' });
}));

// Webhook events
router.get('/:id/webhooks', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM webhook_events WHERE integration_id = $1 AND is_active = true', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/webhooks', asyncHandler(async (req, res) => {
  const { event_name, event_code, description, payload_schema } = req.body;
  const { rows } = await query('INSERT INTO webhook_events (integration_id, event_name, event_code, description, payload_schema) VALUES ($1,$2,$3,$4,$5) RETURNING *', [req.params.id, event_name, event_code, description, JSON.stringify(payload_schema)]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Webhook logs
router.get('/:id/webhook-logs', asyncHandler(async (req, res) => {
  const { status, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE integration_id = $1'; const params = [req.params.id]; let idx = 2;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM webhook_logs ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

// Integration tokens
router.get('/:id/tokens', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT id, integration_id, token_type, expires_at, last_refreshed_at, is_active, created_at FROM integration_tokens WHERE integration_id = $1', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/tokens', asyncHandler(async (req, res) => {
  const { token_type, token_value, expires_at } = req.body;
  const { rows } = await query('INSERT INTO integration_tokens (integration_id, token_type, token_value, expires_at) VALUES ($1,$2,$3,$4) RETURNING id, integration_id, token_type, expires_at, is_active, created_at', [req.params.id, token_type, token_value, expires_at]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// API usage logs
router.get('/usage/logs', asyncHandler(async (req, res) => {
  const { api_integration_id, is_error, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (api_integration_id) { where += ` AND api_integration_id = $${idx}`; params.push(api_integration_id); idx++; }
  if (is_error === 'true') { where += ` AND is_error = true`; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM api_usage_logs ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

module.exports = router;
