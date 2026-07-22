const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Health check
router.get('/health', asyncHandler(async (req, res) => {
  const dbCheck = await query('SELECT 1 as ok');
  res.json({ status: 'success', data: { database: dbCheck.rows[0].ok === 1 ? 'healthy' : 'unhealthy', uptime: process.uptime(), timestamp: new Date().toISOString() } });
}));

// Application logs
router.get('/logs', asyncHandler(async (req, res) => {
  const { log_level, service_name, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (log_level) { where += ` AND log_level = $${idx}`; params.push(log_level); idx++; }
  if (service_name) { where += ` AND service_name = $${idx}`; params.push(service_name); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM application_logs ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/logs', asyncHandler(async (req, res) => {
  const { log_level, service_name, class_name, method_name, message, metadata, correlation_id, request_id, user_id } = req.body;
  const { rows } = await query(
    `INSERT INTO application_logs (log_level, service_name, class_name, method_name, message, metadata, correlation_id, request_id, user_id) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [log_level || 'INFO', service_name, class_name, method_name, message, JSON.stringify(metadata), correlation_id, request_id, user_id]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Error logs
router.get('/errors', asyncHandler(async (req, res) => {
  const { severity, service_name, resolved, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (severity) { where += ` AND severity = $${idx}`; params.push(severity); idx++; }
  if (service_name) { where += ` AND service_name = $${idx}`; params.push(service_name); idx++; }
  if (resolved === 'false') { where += ` AND resolved_at IS NULL`; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM error_logs ${where} ORDER BY last_seen_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/errors', asyncHandler(async (req, res) => {
  const { error_code, error_type, error_message, stack_trace, service_name, endpoint, request_method, severity } = req.body;
  const { rows } = await query(
    `INSERT INTO error_logs (error_code, error_type, error_message, stack_trace, service_name, endpoint, request_method, severity) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [error_code, error_type, error_message, stack_trace, service_name, endpoint, request_method, severity || 'error']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/errors/:id/resolve', asyncHandler(async (req, res) => {
  const { resolved_by, resolution_notes } = req.body;
  await query('UPDATE error_logs SET resolved_at = NOW(), resolved_by = $1, resolution_notes = $2 WHERE id = $3', [resolved_by, resolution_notes, req.params.id]);
  res.json({ status: 'success', message: 'Error resolved' });
}));

// Cron jobs
router.get('/cron', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM cron_jobs ORDER BY is_active DESC, job_name');
  res.json({ status: 'success', data: rows });
}));

router.post('/cron', asyncHandler(async (req, res) => {
  const { job_name, job_code, job_class, cron_expression, description, parameters, timeout_seconds, max_retries, is_active } = req.body;
  const { rows } = await query(
    `INSERT INTO cron_jobs (job_name, job_code, job_class, cron_expression, description, parameters, timeout_seconds, max_retries, is_active) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [job_name, job_code, job_class, cron_expression, description, JSON.stringify(parameters), timeout_seconds || 300, max_retries || 3, is_active !== false]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/cron/:id', asyncHandler(async (req, res) => {
  const { cron_expression, is_active, timeout_seconds, max_retries } = req.body;
  const { rows } = await query('UPDATE cron_jobs SET cron_expression = $1, is_active = $2, timeout_seconds = $3, max_retries = $4 WHERE id = $5 RETURNING *', [cron_expression, is_active, timeout_seconds, max_retries, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Job history
router.get('/cron/:id/history', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM job_history WHERE cron_job_id = $1 ORDER BY start_time DESC LIMIT 50', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

// Health checks
router.get('/health-checks', asyncHandler(async (req, res) => {
  const { status, service_name, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  if (service_name) { where += ` AND service_name = $${idx}`; params.push(service_name); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM health_checks ${where} ORDER BY checked_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/health-checks', asyncHandler(async (req, res) => {
  const { service_name, check_type, endpoint, status, response_time_ms, response_data, error_message } = req.body;
  const { rows } = await query(
    `INSERT INTO health_checks (service_name, check_type, endpoint, status, response_time_ms, response_data, error_message) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [service_name, check_type, endpoint, status || 'unknown', response_time_ms, JSON.stringify(response_data), error_message]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Performance metrics
router.get('/metrics', asyncHandler(async (req, res) => {
  const { metric_name, service_name, page = 1, limit = 100 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (metric_name) { where += ` AND metric_name = $${idx}`; params.push(metric_name); idx++; }
  if (service_name) { where += ` AND service_name = $${idx}`; params.push(service_name); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM performance_metrics ${where} ORDER BY recorded_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/metrics', asyncHandler(async (req, res) => {
  const { metric_name, metric_type, metric_value, unit, labels, service_name, host_name } = req.body;
  const { rows } = await query(
    `INSERT INTO performance_metrics (metric_name, metric_type, metric_value, unit, labels, service_name, host_name) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [metric_name, metric_type, metric_value, unit, JSON.stringify(labels), service_name, host_name]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Backup jobs
router.get('/backups', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM backup_jobs ORDER BY created_at DESC');
  res.json({ status: 'success', data: rows });
}));

router.post('/backups', asyncHandler(async (req, res) => {
  const { job_name, backup_type, target_resource, storage_provider, storage_path, retention_days, schedule_cron, is_encrypted, compression_enabled } = req.body;
  const { rows } = await query(
    `INSERT INTO backup_jobs (job_name, backup_type, target_resource, storage_provider, storage_path, retention_days, schedule_cron, is_encrypted, compression_enabled) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [job_name, backup_type, target_resource, storage_provider || 's3', storage_path, retention_days || 30, schedule_cron, is_encrypted !== false, compression_enabled !== false]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Backup history
router.get('/backups/:id/history', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM backup_history WHERE backup_job_id = $1 ORDER BY started_at DESC LIMIT 50', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/backups/:id/restore', asyncHandler(async (req, res) => {
  const { backup_history_id, restore_type, target_environment, restored_by } = req.body;
  const { rows } = await query(
    `INSERT INTO restore_history (backup_history_id, restore_type, target_environment, restored_by, started_at) VALUES ($1,$2,$3,$4,NOW()) RETURNING *`,
    [backup_history_id, restore_type || 'full', target_environment || 'staging', restored_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
