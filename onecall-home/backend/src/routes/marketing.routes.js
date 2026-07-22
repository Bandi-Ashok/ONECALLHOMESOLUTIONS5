const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Promotions
router.get('/promotions', asyncHandler(async (req, res) => {
  const { is_active, promo_type, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  if (promo_type) { where += ` AND promo_type = $${idx}`; params.push(promo_type); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM promotions ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/promotions/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM promotions WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Promotion not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/promotions', asyncHandler(async (req, res) => {
  const { promo_code, promo_name, promo_type, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, per_customer_limit, start_date, end_date, applicable_services, applicable_categories, is_featured } = req.body;
  const { rows } = await query(
    `INSERT INTO promotions (promo_code, promo_name, promo_type, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, per_customer_limit, start_date, end_date, applicable_services, applicable_categories, is_featured) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15) RETURNING *`,
    [promo_code, promo_name, promo_type, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, per_customer_limit, start_date, end_date, applicable_services, applicable_categories, is_featured || false]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/promotions/:id', asyncHandler(async (req, res) => {
  const { promo_name, description, is_active, is_featured, usage_limit, end_date } = req.body;
  const { rows } = await query('UPDATE promotions SET promo_name = $1, description = $2, is_active = $3, is_featured = $4, usage_limit = $5, end_date = $6 WHERE id = $7 RETURNING *', [promo_name, description, is_active, is_featured, usage_limit, end_date, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Promotion usage
router.get('/promotions/:id/usage', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM promotion_usage WHERE promotion_id = $1 ORDER BY created_at DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/promotions/:id/usage', asyncHandler(async (req, res) => {
  const { customer_id, booking_id, order_amount, discount_amount } = req.body;
  const { rows } = await query(
    `INSERT INTO promotion_usage (promotion_id, customer_id, booking_id, order_amount, discount_amount) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [req.params.id, customer_id, booking_id, order_amount, discount_amount]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Marketing campaigns
router.get('/campaigns', asyncHandler(async (req, res) => {
  const { status, channel, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  if (channel) { where += ` AND channel = $${idx}`; params.push(channel); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM marketing_campaigns ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/campaigns/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM marketing_campaigns WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Campaign not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/campaigns', asyncHandler(async (req, res) => {
  const { campaign_name, campaign_type, channel, target_audience, start_date, end_date, budget, goals, content_template } = req.body;
  const { rows } = await query(
    `INSERT INTO marketing_campaigns (campaign_name, campaign_type, channel, target_audience, start_date, end_date, budget, goals, content_template) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [campaign_name, campaign_type, channel, target_audience, start_date, end_date, budget, goals, content_template]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/campaigns/:id', asyncHandler(async (req, res) => {
  const { status, sent_count, delivered_count, opened_count, clicked_count, converted_count, total_cost, roi } = req.body;
  const { rows } = await query('UPDATE marketing_campaigns SET status = $1, sent_count = $2, delivered_count = $3, opened_count = $4, clicked_count = $5, converted_count = $6, total_cost = $7, roi = $8 WHERE id = $9 RETURNING *', [status, sent_count, delivered_count, opened_count, clicked_count, converted_count, total_cost, roi, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Referral program
router.get('/referrals', asyncHandler(async (req, res) => {
  const { is_active } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  const { rows } = await query(`SELECT * FROM referral_program ${where} ORDER BY created_at DESC`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/referrals', asyncHandler(async (req, res) => {
  const { program_name, description, referrer_reward_type, referrer_reward_value, referee_reward_type, referee_reward_value, min_order_value, max_referrals_per_person, start_date, end_date } = req.body;
  const { rows } = await query(
    `INSERT INTO referral_program (program_name, description, referrer_reward_type, referrer_reward_value, referee_reward_type, referee_reward_value, min_order_value, max_referrals_per_person, start_date, end_date) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
    [program_name, description, referrer_reward_type, referrer_reward_value, referee_reward_type, referee_reward_value, min_order_value, max_referrals_per_person, start_date, end_date]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Referral transactions
router.get('/referrals/transactions', asyncHandler(async (req, res) => {
  const { referrer_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (referrer_id) { where += ` AND referrer_id = $${idx}`; params.push(referrer_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM referral_transactions ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/referrals/transactions', asyncHandler(async (req, res) => {
  const { program_id, referrer_id, referee_id, referral_code, booking_id, reward_amount, status } = req.body;
  const { rows } = await query(
    `INSERT INTO referral_transactions (program_id, referrer_id, referee_id, referral_code, booking_id, reward_amount, status) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [program_id, referrer_id, referee_id, referral_code, booking_id, reward_amount, status || 'pending']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Loyalty program
router.get('/loyalty', asyncHandler(async (req, res) => {
  const { is_active } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  const { rows } = await query(`SELECT * FROM loyalty_program ${where} ORDER BY created_at DESC`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/loyalty', asyncHandler(async (req, res) => {
  const { tier_name, tier_level, min_points_required, points_per_currency, benefits_description, perks } = req.body;
  const { rows } = await query(
    `INSERT INTO loyalty_program (tier_name, tier_level, min_points_required, points_per_currency, benefits_description, perks) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [tier_name, tier_level, min_points_required, points_per_currency, benefits_description, perks]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Loyalty transactions
router.get('/loyalty/transactions', asyncHandler(async (req, res) => {
  const { customer_id, transaction_type, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (customer_id) { where += ` AND customer_id = $${idx}`; params.push(customer_id); idx++; }
  if (transaction_type) { where += ` AND transaction_type = $${idx}`; params.push(transaction_type); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM loyalty_transactions ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/loyalty/transactions', asyncHandler(async (req, res) => {
  const { customer_id, transaction_type, points, description, reference_id, reference_type } = req.body;
  const { rows } = await query(
    `INSERT INTO loyalty_transactions (customer_id, transaction_type, points, description, reference_id, reference_type) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [customer_id, transaction_type, points, description, reference_id, reference_type]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
