const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

router.get('/', asyncHandler(async (req, res) => {
  const { status, skill, city, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND t.current_status = $${idx}`; params.push(status); idx++; }
  if (skill) { where += ` AND t.primary_skill ILIKE $${idx}`; params.push(`%${skill}%`); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(
    `SELECT t.*, u.email, u.phone, up.first_name, up.last_name FROM technicians t
     JOIN users u ON t.user_id = u.id LEFT JOIN user_profiles up ON u.id = up.user_id
     ${where} ORDER BY t.created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params
  );
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query(
    `SELECT t.*, u.email, u.phone, up.* FROM technicians t
     JOIN users u ON t.user_id = u.id LEFT JOIN user_profiles up ON u.id = up.user_id WHERE t.id = $1`, [req.params.id]
  );
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Technician not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { user_id, employment_type, primary_skill, certification_level, experience_years, service_radius_km, max_daily_jobs, vehicle_type, vehicle_number } = req.body;
  const techCode = 'TECH-' + Date.now().toString(36).toUpperCase();
  const { rows } = await query(
    `INSERT INTO technicians (user_id, technician_code, employment_type, primary_skill, certification_level, experience_years, service_radius_km, max_daily_jobs, vehicle_type, vehicle_number)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
    [user_id, techCode, employment_type, primary_skill, certification_level || 'junior', experience_years || 0, service_radius_km || 10, max_daily_jobs || 8, vehicle_type, vehicle_number]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const fields = ['employment_type','primary_skill','secondary_skills','certification_level','experience_years','current_status','service_radius_km','max_daily_jobs','shift_start_time','shift_end_time','working_days','vehicle_type','vehicle_number','background_check_status','bank_account_verified'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE technicians SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  await query('DELETE FROM technicians WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Technician deleted' });
}));

router.put('/:id/location', asyncHandler(async (req, res) => {
  const { latitude, longitude } = req.body;
  await query('UPDATE technicians SET current_latitude = $1, current_longitude = $2, last_location_update = NOW(), current_status = $3 WHERE id = $4', [latitude, longitude, 'online', req.params.id]);
  res.json({ status: 'success', message: 'Location updated' });
}));

router.get('/:id/skills', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM technician_skills WHERE technician_id = $1', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/skills', asyncHandler(async (req, res) => {
  const { skill_name, skill_category, proficiency_level, years_of_experience, certified } = req.body;
  const { rows } = await query('INSERT INTO technician_skills (technician_id, skill_name, skill_category, proficiency_level, years_of_experience, certified) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [req.params.id, skill_name, skill_category, proficiency_level, years_of_experience, certified]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.delete('/:id/skills/:skillId', asyncHandler(async (req, res) => {
  await query('DELETE FROM technician_skills WHERE id = $1 AND technician_id = $2', [req.params.skillId, req.params.id]);
  res.json({ status: 'success', message: 'Skill deleted' });
}));

router.get('/:id/availability', asyncHandler(async (req, res) => {
  const { date } = req.query;
  if (date) {
    const { rows } = await query('SELECT * FROM technician_availability WHERE technician_id = $1 AND date = $2', [req.params.id, date]);
    res.json({ status: 'success', data: rows });
  } else {
    const { rows } = await query('SELECT * FROM technician_availability WHERE technician_id = $1 ORDER BY date DESC LIMIT 30', [req.params.id]);
    res.json({ status: 'success', data: rows });
  }
}));

router.post('/:id/availability', asyncHandler(async (req, res) => {
  const { date, start_time, end_time, availability_type, reason } = req.body;
  const { rows } = await query(
    `INSERT INTO technician_availability (technician_id, date, start_time, end_time, availability_type, reason)
     VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (technician_id, date) DO UPDATE SET start_time = EXCLUDED.start_time, end_time = EXCLUDED.end_time, availability_type = EXCLUDED.availability_type, reason = EXCLUDED.reason RETURNING *`,
    [req.params.id, date, start_time, end_time, availability_type || 'available', reason]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.get('/:id/earnings', asyncHandler(async (req, res) => {
  const { start_date, end_date } = req.query;
  let where = 'WHERE technician_id = $1'; const params = [req.params.id];
  if (start_date && end_date) { where += ' AND earning_date BETWEEN $2 AND $3'; params.push(start_date, end_date); }
  const { rows } = await query(`SELECT * FROM technician_earnings ${where} ORDER BY earning_date DESC LIMIT 100`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/:id/ratings', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM technician_ratings WHERE technician_id = $1 ORDER BY created_at DESC LIMIT 50', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/ratings', asyncHandler(async (req, res) => {
  const { customer_id, booking_id, rating, punctuality_rating, quality_rating, communication_rating, professionalism_rating, review_text, review_title } = req.body;
  const { rows } = await query(
    `INSERT INTO technician_ratings (technician_id, customer_id, booking_id, rating, punctuality_rating, quality_rating, communication_rating, professionalism_rating, review_text, review_title)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
    [req.params.id, customer_id, booking_id, rating, punctuality_rating, quality_rating, communication_rating, professionalism_rating, review_text, review_title]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
