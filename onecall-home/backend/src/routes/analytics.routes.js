const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

router.get('/dashboards', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM analytics_dashboards ORDER BY created_at DESC');
  res.json({ status: 'success', data: rows });
}));

router.post('/dashboards', asyncHandler(async (req, res) => {
  const { name, description, dashboard_type, layout, filters, is_public } = req.body;
  const { rows } = await query('INSERT INTO analytics_dashboards (name, description, dashboard_type, layout, filters, is_public) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [name, description, dashboard_type, JSON.stringify(layout), JSON.stringify(filters), is_public]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.get('/reports', asyncHandler(async (req, res) => {
  const { report_type, is_active, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (report_type) { where += ` AND report_type = $${idx}`; params.push(report_type); idx++; }
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM analytics_reports ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/reports', asyncHandler(async (req, res) => {
  const { report_code, name, description, report_type, query_definition, parameters, visualization_type, schedule_cron, format, created_by } = req.body;
  const { rows } = await query(
    `INSERT INTO analytics_reports (report_code, name, description, report_type, query_definition, parameters, visualization_type, schedule_cron, format, created_by) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
    [report_code, name, description, report_type, JSON.stringify(query_definition), JSON.stringify(parameters), visualization_type, schedule_cron, format || 'pdf', created_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.post('/events', asyncHandler(async (req, res) => {
  const { event_name, user_id, session_id, device_id, event_data } = req.body;
  const { rows } = await query('INSERT INTO analytics_events (event_name, user_id, session_id, device_id, event_data) VALUES ($1,$2,$3,$4,$5) RETURNING *', [event_name, user_id, session_id, device_id, JSON.stringify(event_data)]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.get('/events', asyncHandler(async (req, res) => {
  const { event_name, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (event_name) { where += ` AND event_name = $${idx}`; params.push(event_name); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM analytics_events ${where} ORDER BY event_timestamp DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

// KPIs
router.get('/kpis', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM kpi_definitions WHERE is_active = true ORDER BY category');
  res.json({ status: 'success', data: rows });
}));

router.post('/kpis', asyncHandler(async (req, res) => {
  const { kpi_name, kpi_code, description, category, calculation_method, unit, target_value, frequency } = req.body;
  const { rows } = await query('INSERT INTO kpi_definitions (kpi_name, kpi_code, description, category, calculation_method, unit, target_value, frequency) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *', [kpi_name, kpi_code, description, category, calculation_method, unit, target_value, frequency || 'daily']);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.get('/kpis/:id/values', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM kpi_values WHERE kpi_id = $1 ORDER BY period_start DESC LIMIT 30', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/kpis/:id/values', asyncHandler(async (req, res) => {
  const { value, period_start, period_end, dimension_type, dimension_value } = req.body;
  const { rows } = await query('INSERT INTO kpi_values (kpi_id, value, period_start, period_end, dimension_type, dimension_value) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [req.params.id, value, period_start, period_end, dimension_type, dimension_value]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Query endpoint for custom analytics
router.post('/query', asyncHandler(async (req, res) => {
  const { metrics, dimensions, filters, start_date, end_date } = req.body;
  let sql = 'SELECT ';
  const selectParts = [];
  if (dimensions && dimensions.length > 0) {
    selectParts.push(...dimensions.map(d => `${d} AS ${d.replace('.', '_')}`));
  }
  if (metrics && metrics.length > 0) {
    selectParts.push(...metrics.map(m => {
      if (m === 'total_orders') return 'COUNT(*) AS total_orders';
      if (m === 'gross_gmv') return 'SUM(total_amount) AS gross_gmv';
      if (m === 'avg_order_value') return 'AVG(total_amount) AS avg_order_value';
      if (m === 'unique_customers') return 'COUNT(DISTINCT customer_id) AS unique_customers';
      return `${m} AS ${m}`;
    }));
  }
  sql += selectParts.join(', ');
  sql += ' FROM bookings WHERE status = $1';
  const params = ['completed'];
  let idx = 2;
  if (start_date) { sql += ` AND created_at >= $${idx}`; params.push(start_date); idx++; }
  if (end_date) { sql += ` AND created_at <= $${idx}`; params.push(end_date); idx++; }
  if (dimensions && dimensions.length > 0) {
    sql += ` GROUP BY ${dimensions.join(', ')}`;
  }
  sql += ' ORDER BY 1 DESC LIMIT 100';
  const { rows } = await query(sql, params);
  res.json({ status: 'success', data: { rows } });
}));

module.exports = router;
