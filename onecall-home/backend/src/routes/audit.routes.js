const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Audit logs
router.get('/logs', asyncHandler(async (req, res) => {
  const { table_name, action, performed_by, start_date, end_date, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (table_name) { where += ` AND table_name = $${idx}`; params.push(table_name); idx++; }
  if (action) { where += ` AND action = $${idx}`; params.push(action); idx++; }
  if (performed_by) { where += ` AND performed_by = $${idx}`; params.push(performed_by); idx++; }
  if (start_date) { where += ` AND created_at >= $${idx}`; params.push(start_date); idx++; }
  if (end_date) { where += ` AND created_at <= $${idx}`; params.push(end_date); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM audit_logs ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

// Activity logs
router.get('/activity', asyncHandler(async (req, res) => {
  const { user_id, activity_type, status, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (user_id) { where += ` AND user_id = $${idx}`; params.push(user_id); idx++; }
  if (activity_type) { where += ` AND activity_type = $${idx}`; params.push(activity_type); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM activity_logs ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/activity', asyncHandler(async (req, res) => {
  const { user_id, activity_type, activity_description, entity_type, entity_id, metadata, ip_address, user_agent, status } = req.body;
  const { rows } = await query(
    `INSERT INTO activity_logs (user_id, activity_type, activity_description, entity_type, entity_id, metadata, ip_address, user_agent, status) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [user_id, activity_type, activity_description, entity_type, entity_id, JSON.stringify(metadata), ip_address, user_agent, status || 'success']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Compliance records
router.get('/compliance', asyncHandler(async (req, res) => {
  const { compliance_status } = req.query;
  let where = 'WHERE 1=1'; const params = [];
  if (compliance_status) { where += ` AND compliance_status = $1`; params.push(compliance_status); }
  const { rows } = await query(`SELECT * FROM compliance_records ${where} ORDER BY next_audit_date`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/compliance', asyncHandler(async (req, res) => {
  const { compliance_type, regulation_name, description, compliance_status, last_audit_date, next_audit_date, auditor_id, audit_findings, remediation_plan, remediation_deadline } = req.body;
  const { rows } = await query(
    `INSERT INTO compliance_records (compliance_type, regulation_name, description, compliance_status, last_audit_date, next_audit_date, auditor_id, audit_findings, remediation_plan, remediation_deadline) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
    [compliance_type, regulation_name, description, compliance_status || 'pending', last_audit_date, next_audit_date, auditor_id, audit_findings, remediation_plan, remediation_deadline]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Data retention
router.get('/retention', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM data_retention ORDER BY data_type');
  res.json({ status: 'success', data: rows });
}));

router.post('/retention', asyncHandler(async (req, res) => {
  const { data_type, retention_period_days, archive_after_days, delete_after_days, is_personal_data, legal_basis, policy_reference } = req.body;
  const { rows } = await query('INSERT INTO data_retention (data_type, retention_period_days, archive_after_days, delete_after_days, is_personal_data, legal_basis, policy_reference) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *', [data_type, retention_period_days, archive_after_days, delete_after_days, is_personal_data || false, legal_basis, policy_reference]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Consent records
router.get('/consent/:userId', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM consent_records WHERE user_id = $1 ORDER BY created_at DESC', [req.params.userId]);
  res.json({ status: 'success', data: rows });
}));

router.post('/consent', asyncHandler(async (req, res) => {
  const { user_id, consent_type, consent_version, consent_text, is_granted, ip_address, user_agent } = req.body;
  const { rows } = await query(
    `INSERT INTO consent_records (user_id, consent_type, consent_version, consent_text, is_granted, granted_at, ip_address, user_agent) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [user_id, consent_type, consent_version, consent_text, is_granted, is_granted ? new Date().toISOString() : null, ip_address, user_agent]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
