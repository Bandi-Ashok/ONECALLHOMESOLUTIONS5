const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Knowledge articles
router.get('/articles', asyncHandler(async (req, res) => {
  const { category, is_published, is_featured, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (category) { where += ` AND category = $${idx}`; params.push(category); idx++; }
  if (is_published !== undefined) { where += ` AND is_published = $${idx}`; params.push(is_published === 'true'); idx++; }
  if (is_featured !== undefined) { where += ` AND is_featured = $${idx}`; params.push(is_featured === 'true'); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM knowledge_articles ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/articles/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM knowledge_articles WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Article not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/articles', asyncHandler(async (req, res) => {
  const { title, slug, content, summary, category, tags, author_id, is_published, is_featured, attachments } = req.body;
  const { rows } = await query(
    `INSERT INTO knowledge_articles (title, slug, content, summary, category, tags, author_id, is_published, is_featured, attachments) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
    [title, slug, content, summary, category, tags, author_id, is_published || false, is_featured || false, attachments]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/articles/:id', asyncHandler(async (req, res) => {
  const { title, content, summary, category, tags, is_published, is_featured, attachments } = req.body;
  const { rows } = await query('UPDATE knowledge_articles SET title = $1, content = $2, summary = $3, category = $4, tags = $5, is_published = $6, is_featured = $7, attachments = $8 WHERE id = $9 RETURNING *', [title, content, summary, category, tags, is_published, is_featured, attachments, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Training courses
router.get('/courses', asyncHandler(async (req, res) => {
  const { category, is_published, difficulty_level, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (category) { where += ` AND category = $${idx}`; params.push(category); idx++; }
  if (is_published !== undefined) { where += ` AND is_published = $${idx}`; params.push(is_published === 'true'); idx++; }
  if (difficulty_level) { where += ` AND difficulty_level = $${idx}`; params.push(difficulty_level); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM training_courses ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/courses/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM training_courses WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Course not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/courses', asyncHandler(async (req, res) => {
  const { course_name, description, category, difficulty_level, duration_hours, is_published, thumbnail_url, instructor_id } = req.body;
  const { rows } = await query(
    `INSERT INTO training_courses (course_name, description, category, difficulty_level, duration_hours, is_published, thumbnail_url, instructor_id) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [course_name, description, category, difficulty_level, duration_hours, is_published || false, thumbnail_url, instructor_id]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/courses/:id', asyncHandler(async (req, res) => {
  const { course_name, description, is_published, difficulty_level, duration_hours } = req.body;
  const { rows } = await query('UPDATE training_courses SET course_name = $1, description = $2, is_published = $3, difficulty_level = $4, duration_hours = $5 WHERE id = $6 RETURNING *', [course_name, description, is_published, difficulty_level, duration_hours, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Training modules
router.get('/courses/:id/modules', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM training_modules WHERE course_id = $1 ORDER BY sort_order ASC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/courses/:id/modules', asyncHandler(async (req, res) => {
  const { module_name, content, content_type, duration_minutes, sort_order, video_url, resources } = req.body;
  const { rows } = await query(
    `INSERT INTO training_modules (course_id, module_name, content, content_type, duration_minutes, sort_order, video_url, resources) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [req.params.id, module_name, content, content_type || 'text', duration_minutes, sort_order || 0, video_url, resources]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Training enrollments
router.get('/enrollments', asyncHandler(async (req, res) => {
  const { employee_id, course_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (employee_id) { where += ` AND employee_id = $${idx}`; params.push(employee_id); idx++; }
  if (course_id) { where += ` AND course_id = $${idx}`; params.push(course_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM training_enrollments ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/enrollments', asyncHandler(async (req, res) => {
  const { employee_id, course_id, enrolled_by, due_date } = req.body;
  const { rows } = await query(
    `INSERT INTO training_enrollments (employee_id, course_id, enrolled_by, due_date) VALUES ($1,$2,$3,$4) RETURNING *`,
    [employee_id, course_id, enrolled_by, due_date]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/enrollments/:id', asyncHandler(async (req, res) => {
  const { status, progress_percentage, completed_at, score, certificate_id } = req.body;
  const { rows } = await query('UPDATE training_enrollments SET status = $1, progress_percentage = $2, completed_at = $3, score = $4, certificate_id = $5 WHERE id = $6 RETURNING *', [status, progress_percentage, completed_at, score, certificate_id, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Certifications
router.get('/certifications', asyncHandler(async (req, res) => {
  const { is_active, issuing_authority, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  if (issuing_authority) { where += ` AND issuing_authority = $${idx}`; params.push(issuing_authority); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM certifications ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/certifications', asyncHandler(async (req, res) => {
  const { certification_name, description, issuing_authority, validity_months, is_active } = req.body;
  const { rows } = await query(
    `INSERT INTO certifications (certification_name, description, issuing_authority, validity_months, is_active) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [certification_name, description, issuing_authority, validity_months, is_active !== false]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Technician certifications
router.get('/technician-certs', asyncHandler(async (req, res) => {
  const { technician_id, certification_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (technician_id) { where += ` AND technician_id = $${idx}`; params.push(technician_id); idx++; }
  if (certification_id) { where += ` AND certification_id = $${idx}`; params.push(certification_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM technician_certifications ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/technician-certs', asyncHandler(async (req, res) => {
  const { technician_id, certification_id, issue_date, expiry_date, certificate_number, status } = req.body;
  const { rows } = await query(
    `INSERT INTO technician_certifications (technician_id, certification_id, issue_date, expiry_date, certificate_number, status) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [technician_id, certification_id, issue_date, expiry_date, certificate_number, status || 'active']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
