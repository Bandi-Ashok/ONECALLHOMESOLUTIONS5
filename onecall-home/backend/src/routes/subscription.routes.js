const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Plans
router.get('/plans', asyncHandler(async (req, res) => {
  const { plan_type, is_active } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (plan_type) { where += ` AND plan_type = $${idx}`; params.push(plan_type); idx++; }
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  const { rows } = await query(`SELECT * FROM subscription_plans ${where} ORDER BY price`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/plans/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM subscription_plans WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Plan not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/plans', asyncHandler(async (req, res) => {
  const { plan_name, plan_code, plan_type, description, services_covered, visits_per_year, discount_percentage, priority_support, free_inspections, emergency_service_included, price, billing_cycle, contract_duration_months, auto_renewal, cancellation_fee, terms_and_conditions } = req.body;
  const { rows } = await query(
    `INSERT INTO subscription_plans (plan_name, plan_code, plan_type, description, services_covered, visits_per_year, discount_percentage, priority_support, free_inspections, emergency_service_included, price, billing_cycle, contract_duration_months, auto_renewal, cancellation_fee, terms_and_conditions) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16) RETURNING *`,
    [plan_name, plan_code, plan_type, description, services_covered, visits_per_year, discount_percentage, priority_support || false, free_inspections || false, emergency_service_included || false, price, billing_cycle, contract_duration_months, auto_renewal !== false, cancellation_fee, terms_and_conditions]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/plans/:id', asyncHandler(async (req, res) => {
  const fields = ['plan_name','description','price','billing_cycle','is_active','is_featured','discount_percentage','visits_per_year','priority_support','auto_renewal'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE subscription_plans SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

// Customer subscriptions
router.get('/', asyncHandler(async (req, res) => {
  const { customer_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (customer_id) { where += ` AND cs.customer_id = $${idx}`; params.push(customer_id); idx++; }
  if (status) { where += ` AND cs.status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(
    `SELECT cs.*, sp.plan_name, sp.plan_type, sp.price FROM customer_subscriptions cs JOIN subscription_plans sp ON cs.plan_id = sp.id ${where} ORDER BY cs.created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params
  );
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT cs.*, sp.plan_name, sp.plan_type FROM customer_subscriptions cs JOIN subscription_plans sp ON cs.plan_id = sp.id WHERE cs.id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Subscription not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { customer_id, plan_id, start_date, end_date, next_billing_date, auto_renewal, total_visits_allowed } = req.body;
  const subNumber = 'SUB-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO customer_subscriptions (customer_id, plan_id, subscription_number, start_date, end_date, next_billing_date, auto_renewal, total_visits_allowed) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [customer_id, plan_id, subNumber, start_date, end_date, next_billing_date, auto_renewal !== false, total_visits_allowed]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const { status, auto_renewal, end_date, next_billing_date, visits_used, next_scheduled_service } = req.body;
  const { rows } = await query('UPDATE customer_subscriptions SET status = $1, auto_renewal = $2, end_date = $3, next_billing_date = $4, visits_used = $5, next_scheduled_service = $6 WHERE id = $7 RETURNING *', [status, auto_renewal, end_date, next_billing_date, visits_used, next_scheduled_service, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Subscription invoices
router.get('/:id/invoices', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM subscription_invoices WHERE subscription_id = $1 ORDER BY created_at DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/invoices', asyncHandler(async (req, res) => {
  const { billing_period_start, billing_period_end, amount, tax_amount, total_amount, due_date } = req.body;
  const invNumber = 'SUBINV-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO subscription_invoices (subscription_id, invoice_number, billing_period_start, billing_period_end, amount, tax_amount, total_amount, due_date) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [req.params.id, invNumber, billing_period_start, billing_period_end, amount, tax_amount, total_amount, due_date]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
