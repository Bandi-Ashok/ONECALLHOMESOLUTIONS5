const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Departments
router.get('/departments', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM departments WHERE is_active = true ORDER BY name');
  res.json({ status: 'success', data: rows });
}));

router.post('/departments', asyncHandler(async (req, res) => {
  const { name, code, description, parent_department_id, head_of_department, budget } = req.body;
  const { rows } = await query('INSERT INTO departments (name, code, description, parent_department_id, head_of_department, budget) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [name, code, description, parent_department_id, head_of_department, budget]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/departments/:id', asyncHandler(async (req, res) => {
  const { name, description, head_of_department, budget, is_active } = req.body;
  const { rows } = await query('UPDATE departments SET name = $1, description = $2, head_of_department = $3, budget = $4, is_active = $5 WHERE id = $6 RETURNING *', [name, description, head_of_department, budget, is_active, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Employees
router.get('/employees', asyncHandler(async (req, res) => {
  const { department_id, is_active, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (department_id) { where += ` AND e.department_id = $${idx}`; params.push(department_id); idx++; }
  if (is_active !== undefined) { where += ` AND e.is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(
    `SELECT e.*, u.email, u.phone, up.first_name, up.last_name, d.name as department_name
     FROM employees e JOIN users u ON e.user_id = u.id LEFT JOIN user_profiles up ON u.id = up.user_id
     LEFT JOIN departments d ON e.department_id = d.id ${where} ORDER BY e.created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params
  );
  res.json({ status: 'success', data: rows });
}));

router.get('/employees/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT e.*, u.email, up.* FROM employees e JOIN users u ON e.user_id = u.id LEFT JOIN user_profiles up ON u.id = up.user_id WHERE e.id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Employee not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/employees', asyncHandler(async (req, res) => {
  const { user_id, employee_code, department_id, designation, employment_type, date_of_joining, salary_grade, current_salary } = req.body;
  const { rows } = await query(
    `INSERT INTO employees (user_id, employee_code, department_id, designation, employment_type, date_of_joining, salary_grade, current_salary) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [user_id, employee_code, department_id, designation, employment_type, date_of_joining, salary_grade, current_salary]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/employees/:id', asyncHandler(async (req, res) => {
  const fields = ['department_id','designation','reporting_manager','employment_type','date_of_confirmation','date_of_leaving','leaving_reason','salary_grade','current_salary','is_active'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE employees SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

// Shifts
router.get('/shifts', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM shift_management ORDER BY start_time');
  res.json({ status: 'success', data: rows });
}));

router.post('/shifts', asyncHandler(async (req, res) => {
  const { shift_name, shift_code, start_time, end_time, grace_period_minutes, break_duration_minutes, is_night_shift, applicable_days } = req.body;
  const { rows } = await query('INSERT INTO shift_management (shift_name, shift_code, start_time, end_time, grace_period_minutes, break_duration_minutes, is_night_shift, applicable_days) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *', [shift_name, shift_code, start_time, end_time, grace_period_minutes, break_duration_minutes, is_night_shift, applicable_days]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Attendance
router.get('/attendance', asyncHandler(async (req, res) => {
  const { employee_id, date, status, page = 1, limit = 31 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (employee_id) { where += ` AND employee_id = $${idx}`; params.push(employee_id); idx++; }
  if (date) { where += ` AND date = $${idx}`; params.push(date); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM employee_attendance ${where} ORDER BY date DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/attendance', asyncHandler(async (req, res) => {
  const { employee_id, date, shift_id, actual_in_time, actual_out_time, status, total_hours_worked, overtime_hours, late_by_minutes, remarks } = req.body;
  const { rows } = await query(
    `INSERT INTO employee_attendance (employee_id, date, shift_id, actual_in_time, actual_out_time, status, total_hours_worked, overtime_hours, late_by_minutes, remarks)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) ON CONFLICT (employee_id, date) DO UPDATE SET actual_in_time = EXCLUDED.actual_in_time, actual_out_time = EXCLUDED.actual_out_time, status = EXCLUDED.status, total_hours_worked = EXCLUDED.total_hours_worked RETURNING *`,
    [employee_id, date, shift_id, actual_in_time, actual_out_time, status, total_hours_worked, overtime_hours, late_by_minutes, remarks]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Leave
router.get('/leave', asyncHandler(async (req, res) => {
  const { employee_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (employee_id) { where += ` AND employee_id = $${idx}`; params.push(employee_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM leave_management ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/leave', asyncHandler(async (req, res) => {
  const { employee_id, leave_type, start_date, end_date, total_days, reason } = req.body;
  const { rows } = await query('INSERT INTO leave_management (employee_id, leave_type, start_date, end_date, total_days, reason) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [employee_id, leave_type, start_date, end_date, total_days, reason]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/leave/:id', asyncHandler(async (req, res) => {
  const { status, approved_by, rejection_reason } = req.body;
  const { rows } = await query('UPDATE leave_management SET status = $1, approved_by = $2, approved_at = CASE WHEN $1 = $3 THEN NOW() ELSE approved_at END, rejection_reason = $4 WHERE id = $5 RETURNING *', [status, approved_by, 'approved', rejection_reason, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

module.exports = router;
