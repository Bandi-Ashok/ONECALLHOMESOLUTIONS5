const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Support tickets
router.get('/', asyncHandler(async (req, res) => {
  const { status, priority, customer_id, assigned_to, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  if (priority) { where += ` AND priority = $${idx}`; params.push(priority); idx++; }
  if (customer_id) { where += ` AND customer_id = $${idx}`; params.push(customer_id); idx++; }
  if (assigned_to) { where += ` AND assigned_to = $${idx}`; params.push(assigned_to); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM support_tickets ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM support_tickets WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Ticket not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { customer_id, subject, description, category, priority, channel } = req.body;
  const ticketNumber = 'TKT-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO support_tickets (ticket_number, customer_id, subject, description, category, priority, channel) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [ticketNumber, customer_id, subject, description, category, priority || 'medium', channel || 'web']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const { status, priority, assigned_to, resolution_notes, resolved_at, satisfaction_rating, satisfaction_feedback } = req.body;
  const { rows } = await query(
    `UPDATE support_tickets SET status = $1, priority = $2, assigned_to = $3, resolution_notes = $4, resolved_at = $5, satisfaction_rating = $6, satisfaction_feedback = $7 WHERE id = $8 RETURNING *`,
    [status, priority, assigned_to, resolution_notes, resolved_at, satisfaction_rating, satisfaction_feedback, req.params.id]
  );
  res.json({ status: 'success', data: rows[0] });
}));

// Ticket comments
router.get('/:id/comments', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM ticket_comments WHERE ticket_id = $1 ORDER BY created_at ASC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/comments', asyncHandler(async (req, res) => {
  const { comment_by, comment_type, body, is_internal } = req.body;
  const { rows } = await query(
    `INSERT INTO ticket_comments (ticket_id, comment_by, comment_type, body, is_internal) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [req.params.id, comment_by, comment_type || 'customer', body, is_internal || false]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Ticket attachments
router.get('/:id/attachments', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM ticket_attachments WHERE ticket_id = $1 ORDER BY created_at DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/attachments', asyncHandler(async (req, res) => {
  const { uploaded_by, file_name, file_url, file_type, file_size } = req.body;
  const { rows } = await query(
    `INSERT INTO ticket_attachments (ticket_id, uploaded_by, file_name, file_url, file_type, file_size) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [req.params.id, uploaded_by, file_name, file_url, file_type, file_size]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Call logs
router.get('/calls/all', asyncHandler(async (req, res) => {
  const { call_type, call_status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (call_type) { where += ` AND call_type = $${idx}`; params.push(call_type); idx++; }
  if (call_status) { where += ` AND call_status = $${idx}`; params.push(call_status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM call_logs ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/calls', asyncHandler(async (req, res) => {
  const { ticket_id, customer_id, agent_id, call_type, call_status, duration_seconds, recording_url, notes } = req.body;
  const { rows } = await query(
    `INSERT INTO call_logs (ticket_id, customer_id, agent_id, call_type, call_status, duration_seconds, recording_url, notes) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [ticket_id, customer_id, agent_id, call_type, call_status, duration_seconds, recording_url, notes]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Agent performance
router.get('/agents/performance', asyncHandler(async (req, res) => {
  const { agent_id, start_date, end_date } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (agent_id) { where += ` AND agent_id = $${idx}`; params.push(agent_id); idx++; }
  if (start_date) { where += ` AND date >= $${idx}`; params.push(start_date); idx++; }
  if (end_date) { where += ` AND date <= $${idx}`; params.push(end_date); idx++; }
  const { rows } = await query(`SELECT * FROM agent_performance ${where} ORDER BY date DESC`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/agents/performance', asyncHandler(async (req, res) => {
  const { agent_id, date, calls_handled, avg_call_duration, resolution_rate, customer_satisfaction_score, tickets_resolved, tickets_escalated } = req.body;
  const { rows } = await query(
    `INSERT INTO agent_performance (agent_id, date, calls_handled, avg_call_duration, resolution_rate, customer_satisfaction_score, tickets_resolved, tickets_escalated) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [agent_id, date, calls_handled, avg_call_duration, resolution_rate, customer_satisfaction_score, tickets_resolved, tickets_escalated]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
