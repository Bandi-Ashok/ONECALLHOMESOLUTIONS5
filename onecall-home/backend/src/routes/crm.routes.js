const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Leads
router.get('/leads', asyncHandler(async (req, res) => {
  const { status, priority, assigned_to, source, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  if (priority) { where += ` AND priority = $${idx}`; params.push(priority); idx++; }
  if (assigned_to) { where += ` AND assigned_to = $${idx}`; params.push(assigned_to); idx++; }
  if (source) { where += ` AND source = $${idx}`; params.push(source); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM crm_leads ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/leads/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM crm_leads WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Lead not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/leads', asyncHandler(async (req, res) => {
  const { first_name, last_name, email, phone, alternate_phone, source, source_detail, lead_type, service_interest, property_type, city, state, pincode, budget_range, timeline, priority, assigned_to, notes, created_by } = req.body;
  const leadNumber = 'LD-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO crm_leads (lead_number, first_name, last_name, email, phone, alternate_phone, source, source_detail, lead_type, service_interest, property_type, city, state, pincode, budget_range, timeline, priority, assigned_to, notes, created_by)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20) RETURNING *`,
    [leadNumber, first_name, last_name, email, phone, alternate_phone, source, source_detail, lead_type, service_interest, property_type, city, state, pincode, JSON.stringify(budget_range), timeline, priority || 'medium', assigned_to, notes, created_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/leads/:id', asyncHandler(async (req, res) => {
  const fields = ['first_name','last_name','email','phone','source','lead_type','city','state','pincode','priority','status','assigned_to','last_contacted_at','next_follow_up','lost_reason','notes','converted_to_customer_id','conversion_date'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE crm_leads SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/leads/:id', asyncHandler(async (req, res) => {
  await query('DELETE FROM crm_leads WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Lead deleted' });
}));

// Activities
router.get('/activities', asyncHandler(async (req, res) => {
  const { lead_id, customer_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (lead_id) { where += ` AND lead_id = $${idx}`; params.push(lead_id); idx++; }
  if (customer_id) { where += ` AND customer_id = $${idx}`; params.push(customer_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM crm_activities ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/activities', asyncHandler(async (req, res) => {
  const { lead_id, customer_id, activity_type, subject, description, scheduled_at, duration_minutes, performed_by } = req.body;
  const { rows } = await query(
    `INSERT INTO crm_activities (lead_id, customer_id, activity_type, subject, description, scheduled_at, duration_minutes, performed_by) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [lead_id, customer_id, activity_type, subject, description, scheduled_at, duration_minutes, performed_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/activities/:id', asyncHandler(async (req, res) => {
  const { status, completed_at, outcome } = req.body;
  const { rows } = await query('UPDATE crm_activities SET status = $1, completed_at = $2, outcome = $3 WHERE id = $4 RETURNING *', [status, completed_at, outcome, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Deals
router.get('/deals', asyncHandler(async (req, res) => {
  const { status, stage, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  if (stage) { where += ` AND stage = $${idx}`; params.push(stage); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM crm_deals ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/deals', asyncHandler(async (req, res) => {
  const { lead_id, customer_id, deal_name, deal_value, expected_close_date, stage, probability_percentage, assigned_to } = req.body;
  const dealNumber = 'DL-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO crm_deals (deal_number, lead_id, customer_id, deal_name, deal_value, expected_close_date, stage, probability_percentage, assigned_to) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [dealNumber, lead_id, customer_id, deal_name, deal_value, expected_close_date, stage || 'prospecting', probability_percentage || 0, assigned_to]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/deals/:id', asyncHandler(async (req, res) => {
  const { stage, status, probability_percentage, actual_close_date, won_reason, lost_reason } = req.body;
  const { rows } = await query('UPDATE crm_deals SET stage = $1, status = $2, probability_percentage = $3, actual_close_date = $4, won_reason = $5, lost_reason = $6 WHERE id = $7 RETURNING *', [stage, status, probability_percentage, actual_close_date, won_reason, lost_reason, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

module.exports = router;
