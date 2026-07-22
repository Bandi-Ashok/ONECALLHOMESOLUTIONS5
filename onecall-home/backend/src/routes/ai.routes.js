const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Models
router.get('/models', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM ai_models ORDER BY created_at DESC');
  res.json({ status: 'success', data: rows });
}));

router.post('/models', asyncHandler(async (req, res) => {
  const { model_name, model_version, model_type, description, algorithm, accuracy, is_active, is_deployed, trained_by } = req.body;
  const { rows } = await query(
    `INSERT INTO ai_models (model_name, model_version, model_type, description, algorithm, accuracy, is_active, is_deployed, trained_by)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [model_name, model_version, model_type, description, algorithm, accuracy, is_active || false, is_deployed || false, trained_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/models/:id', asyncHandler(async (req, res) => {
  const { is_active, is_deployed, accuracy } = req.body;
  const { rows } = await query('UPDATE ai_models SET is_active = $1, is_deployed = $2, accuracy = $3, deployed_at = CASE WHEN $2 = true THEN NOW() ELSE deployed_at END WHERE id = $4 RETURNING *', [is_active, is_deployed, accuracy, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Predictions
router.get('/predictions', asyncHandler(async (req, res) => {
  const { model_id, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (model_id) { where += ` AND model_id = $${idx}`; params.push(model_id); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM ai_predictions ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/predictions', asyncHandler(async (req, res) => {
  const { model_id, prediction_type, input_data, predicted_value, confidence_score, user_id, booking_id } = req.body;
  const { rows } = await query(
    `INSERT INTO ai_predictions (model_id, prediction_type, input_data, predicted_value, confidence_score, user_id, booking_id) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [model_id, prediction_type, JSON.stringify(input_data), JSON.stringify(predicted_value), confidence_score, user_id, booking_id]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Recommendations
router.get('/recommendations/:userId', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM ai_recommendations WHERE user_id = $1 ORDER BY created_at DESC LIMIT 20', [req.params.userId]);
  res.json({ status: 'success', data: rows });
}));

router.post('/recommendations', asyncHandler(async (req, res) => {
  const { user_id, recommendation_type, context, recommended_items, confidence_score } = req.body;
  const { rows } = await query(
    `INSERT INTO ai_recommendations (user_id, recommendation_type, context, recommended_items, confidence_score) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [user_id, recommendation_type, JSON.stringify(context), JSON.stringify(recommended_items), confidence_score]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/recommendations/:id/click', asyncHandler(async (req, res) => {
  await query('UPDATE ai_recommendations SET clicked_at = NOW() WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Recommendation clicked' });
}));

router.put('/recommendations/:id/convert', asyncHandler(async (req, res) => {
  const { conversion_reference } = req.body;
  await query('UPDATE ai_recommendations SET converted_at = NOW(), is_converted = true, conversion_reference = $1 WHERE id = $2', [conversion_reference, req.params.id]);
  res.json({ status: 'success', message: 'Recommendation converted' });
}));

// Automation rules
router.get('/automation/rules', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM automation_rules ORDER BY priority DESC');
  res.json({ status: 'success', data: rows });
}));

router.post('/automation/rules', asyncHandler(async (req, res) => {
  const { rule_name, rule_code, description, trigger_type, trigger_conditions, actions, priority, is_active, created_by } = req.body;
  const { rows } = await query(
    `INSERT INTO automation_rules (rule_name, rule_code, description, trigger_type, trigger_conditions, actions, priority, is_active, created_by) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [rule_name, rule_code, description, trigger_type, JSON.stringify(trigger_conditions), JSON.stringify(actions), priority || 0, is_active !== false, created_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/automation/rules/:id', asyncHandler(async (req, res) => {
  const { is_active, trigger_conditions, actions, priority } = req.body;
  const { rows } = await query('UPDATE automation_rules SET is_active = $1, trigger_conditions = $2, actions = $3, priority = $4 WHERE id = $5 RETURNING *', [is_active, JSON.stringify(trigger_conditions), JSON.stringify(actions), priority, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

router.get('/automation/logs', asyncHandler(async (req, res) => {
  const { rule_id, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (rule_id) { where += ` AND rule_id = $${idx}`; params.push(rule_id); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT al.*, r.rule_name FROM automation_logs al JOIN automation_rules r ON al.rule_id = r.id ${where} ORDER BY al.executed_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

module.exports = router;
