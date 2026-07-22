const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Inspection checklists
router.get('/checklists', asyncHandler(async (req, res) => {
  const { is_active, category, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  if (category) { where += ` AND category = $${idx}`; params.push(category); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM inspection_checklists ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/checklists/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM inspection_checklists WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Checklist not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/checklists', asyncHandler(async (req, res) => {
  const { checklist_name, description, category, applicable_service_types, version } = req.body;
  const { rows } = await query(
    `INSERT INTO inspection_checklists (checklist_name, description, category, applicable_service_types, version) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [checklist_name, description, category, applicable_service_types, version || '1.0']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/checklists/:id', asyncHandler(async (req, res) => {
  const { checklist_name, description, is_active, version } = req.body;
  const { rows } = await query('UPDATE inspection_checklists SET checklist_name = $1, description = $2, is_active = $3, version = $4 WHERE id = $5 RETURNING *', [checklist_name, description, is_active, version, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Checklist items
router.get('/checklists/:id/items', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM checklist_items WHERE checklist_id = $1 ORDER BY sort_order ASC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/checklists/:id/items', asyncHandler(async (req, res) => {
  const { item_text, item_description, item_type, is_required, sort_order, possible_values } = req.body;
  const { rows } = await query(
    `INSERT INTO checklist_items (checklist_id, item_text, item_description, item_type, is_required, sort_order, possible_values) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [req.params.id, item_text, item_description, item_type || 'boolean', is_required !== false, sort_order || 0, possible_values]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Service inspections
router.get('/inspections', asyncHandler(async (req, res) => {
  const { booking_id, inspector_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (booking_id) { where += ` AND booking_id = $${idx}`; params.push(booking_id); idx++; }
  if (inspector_id) { where += ` AND inspector_id = $${idx}`; params.push(inspector_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM service_inspections ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/inspections/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM service_inspections WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Inspection not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/inspections', asyncHandler(async (req, res) => {
  const { booking_id, checklist_id, inspector_id, inspection_date, scheduled_date, notes } = req.body;
  const { rows } = await query(
    `INSERT INTO service_inspections (booking_id, checklist_id, inspector_id, inspection_date, scheduled_date, notes) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [booking_id, checklist_id, inspector_id, inspection_date, scheduled_date, notes]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/inspections/:id', asyncHandler(async (req, res) => {
  const { status, overall_score, passed, findings_summary, recommendations, completed_at } = req.body;
  const { rows } = await query(
    `UPDATE service_inspections SET status = $1, overall_score = $2, passed = $3, findings_summary = $4, recommendations = $5, completed_at = $6 WHERE id = $7 RETURNING *`,
    [status, overall_score, passed, findings_summary, recommendations, completed_at, req.params.id]
  );
  res.json({ status: 'success', data: rows[0] });
}));

// Inspection results
router.get('/inspections/:id/results', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM inspection_results WHERE inspection_id = $1 ORDER BY created_at ASC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/inspections/:id/results', asyncHandler(async (req, res) => {
  const { checklist_item_id, result_value, result_status, notes, photo_url } = req.body;
  const { rows } = await query(
    `INSERT INTO inspection_results (inspection_id, checklist_item_id, result_value, result_status, notes, photo_url) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [req.params.id, checklist_item_id, result_value, result_status, notes, photo_url]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Quality scores
router.get('/scores', asyncHandler(async (req, res) => {
  const { entity_type, entity_id, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (entity_type) { where += ` AND entity_type = $${idx}`; params.push(entity_type); idx++; }
  if (entity_id) { where += ` AND entity_id = $${idx}`; params.push(entity_id); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM quality_scores ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/scores', asyncHandler(async (req, res) => {
  const { entity_type, entity_id, score_type, score_value, max_score, evaluated_by, evaluation_date, comments } = req.body;
  const { rows } = await query(
    `INSERT INTO quality_scores (entity_type, entity_id, score_type, score_value, max_score, evaluated_by, evaluation_date, comments) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [entity_type, entity_id, score_type, score_value, max_score, evaluated_by, evaluation_date, comments]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
