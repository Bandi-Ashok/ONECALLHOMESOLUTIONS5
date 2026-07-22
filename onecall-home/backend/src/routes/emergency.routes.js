const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

router.get('/', asyncHandler(async (req, res) => {
  const { status, priority, customer_id, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  if (priority) { where += ` AND priority = $${idx}`; params.push(priority); idx++; }
  if (customer_id) { where += ` AND customer_id = $${idx}`; params.push(customer_id); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM emergency_requests ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM emergency_requests WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Emergency request not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { customer_id, booking_id, emergency_type, service_type, description, latitude, longitude, address, priority } = req.body;
  const emergencyNumber = 'EMG-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO emergency_requests (emergency_number, customer_id, booking_id, emergency_type, service_type, description, latitude, longitude, address, priority) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
    [emergencyNumber, customer_id, booking_id, emergency_type, service_type, description, latitude, longitude, address, priority || 'critical']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const { status, assigned_technicians, escalation_level, response_time_seconds, resolution_time_seconds, damage_assessment, resolved_at, emergency_contacts_notified, authorities_notified, insurance_claimed } = req.body;
  const { rows } = await query(
    `UPDATE emergency_requests SET status = $1, assigned_technicians = $2, escalation_level = $3, response_time_seconds = $4, resolution_time_seconds = $5, damage_assessment = $6, resolved_at = $7, emergency_contacts_notified = $8, authorities_notified = $9, insurance_claimed = $10 WHERE id = $11 RETURNING *`,
    [status, assigned_technicians, escalation_level, response_time_seconds, resolution_time_seconds, damage_assessment, resolved_at, emergency_contacts_notified, authorities_notified, insurance_claimed, req.params.id]
  );
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/:id/escalate', asyncHandler(async (req, res) => {
  const { escalation_reason } = req.body;
  const { rows } = await query('UPDATE emergency_requests SET escalation_level = escalation_level + 1, status = $1 WHERE id = $2 RETURNING *', ['escalated', req.params.id]);
  res.json({ status: 'success', message: 'Emergency escalated', data: rows[0] });
}));

// Incident reports
router.get('/incidents/all', asyncHandler(async (req, res) => {
  const { status, severity, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  if (severity) { where += ` AND severity = $${idx}`; params.push(severity); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM incident_reports ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/incidents/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM incident_reports WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Incident report not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/incidents', asyncHandler(async (req, res) => {
  const { emergency_request_id, booking_id, reported_by, incident_type, incident_date, description, severity, injuries_reported, property_damage, damage_estimate } = req.body;
  const incidentNumber = 'INC-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO incident_reports (incident_number, emergency_request_id, booking_id, reported_by, incident_type, incident_date, description, severity, injuries_reported, property_damage, damage_estimate) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
    [incidentNumber, emergency_request_id, booking_id, reported_by, incident_type, incident_date, description, severity || 'medium', injuries_reported || false, property_damage || false, damage_estimate]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/incidents/:id', asyncHandler(async (req, res) => {
  const { status, root_cause, corrective_actions, preventive_actions, investigated_by, resolved_at } = req.body;
  const { rows } = await query('UPDATE incident_reports SET status = $1, root_cause = $2, corrective_actions = $3, preventive_actions = $4, investigated_by = $5, resolved_at = $6 WHERE id = $7 RETURNING *', [status, root_cause, corrective_actions, preventive_actions, investigated_by, resolved_at, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

module.exports = router;
