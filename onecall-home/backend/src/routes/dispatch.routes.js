const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

router.get('/queue', asyncHandler(async (req, res) => {
  const { status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND dq.dispatch_status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(
    `SELECT dq.*, b.booking_number, b.priority, b.scheduled_start_time, s.name as service_name
     FROM dispatch_queue dq JOIN bookings b ON dq.booking_id = b.id LEFT JOIN services s ON b.service_id = s.id
     ${where} ORDER BY dq.created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params
  );
  res.json({ status: 'success', data: rows });
}));

router.post('/queue', asyncHandler(async (req, res) => {
  const { booking_id, priority_score, assignment_type } = req.body;
  const { rows } = await query(
    `INSERT INTO dispatch_queue (booking_id, priority_score, assignment_type, matching_started_at) VALUES ($1,$2,$3,NOW()) RETURNING *`,
    [booking_id, priority_score, assignment_type || 'auto']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/queue/:id', asyncHandler(async (req, res) => {
  const { dispatch_status, accepted_by_technician, assignment_type, decline_reasons } = req.body;
  const { rows } = await query(
    `UPDATE dispatch_queue SET dispatch_status = $1, accepted_by_technician = $2, assignment_type = $3, decline_reasons = $4, matching_completed_at = CASE WHEN $1 IN ('assigned','accepted') THEN NOW() ELSE matching_completed_at END WHERE id = $5 RETURNING *`,
    [dispatch_status, accepted_by_technician, assignment_type, decline_reasons, req.params.id]
  );
  if (dispatch_status === 'assigned' && accepted_by_technician) {
    const dq = rows[0];
    await query('UPDATE bookings SET technician_id = $1, status = $2 WHERE id = $3', [accepted_by_technician, 'assigned', dq.booking_id]);
  }
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/auto-assign/:bookingId', asyncHandler(async (req, res) => {
  const { bookingId } = req.params;
  const booking = (await query('SELECT * FROM bookings WHERE id = $1', [bookingId])).rows[0];
  if (!booking) return res.status(404).json({ status: 'error', message: 'Booking not found' });
  const techs = (await query(
    `SELECT t.id FROM technicians t WHERE t.current_status = 'online' ORDER BY t.average_rating DESC NULLS LAST, t.total_jobs_completed ASC LIMIT 1`
  )).rows;
  if (techs.length === 0) return res.status(404).json({ status: 'error', message: 'No available technicians' });
  const techId = techs[0].id;
  await query('UPDATE bookings SET technician_id = $1, status = $2 WHERE id = $3', [techId, 'assigned', bookingId]);
  const dq = (await query('INSERT INTO dispatch_queue (booking_id, dispatch_status, accepted_by_technician, assignment_type, matching_started_at, matching_completed_at) VALUES ($1,$2,$3,$4,NOW(),NOW()) RETURNING *', [bookingId, 'assigned', techId, 'auto'])).rows[0];
  res.json({ status: 'success', message: 'Technician auto-assigned', data: { technician_id: techId, dispatch: dq } });
}));

// Scheduling slots
router.get('/slots', asyncHandler(async (req, res) => {
  const { technician_id, date } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (technician_id) { where += ` AND technician_id = $${idx}`; params.push(technician_id); idx++; }
  if (date) { where += ` AND date = $${idx}`; params.push(date); idx++; }
  const { rows } = await query(`SELECT * FROM scheduling_slots ${where} ORDER BY date, start_time`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/slots', asyncHandler(async (req, res) => {
  const { technician_id, date, start_time, end_time, slot_type, booking_id } = req.body;
  const { rows } = await query('INSERT INTO scheduling_slots (technician_id, date, start_time, end_time, slot_type, booking_id) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [technician_id, date, start_time, end_time, slot_type || 'available', booking_id]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/slots/:id', asyncHandler(async (req, res) => {
  const { slot_type, booking_id } = req.body;
  const { rows } = await query('UPDATE scheduling_slots SET slot_type = $1, booking_id = $2 WHERE id = $3 RETURNING *', [slot_type, booking_id, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/slots/:id', asyncHandler(async (req, res) => {
  await query('DELETE FROM scheduling_slots WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Slot deleted' });
}));

// Route plans
router.get('/routes', asyncHandler(async (req, res) => {
  const { technician_id, date } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (technician_id) { where += ` AND rp.technician_id = $${idx}`; params.push(technician_id); idx++; }
  if (date) { where += ` AND rp.date = $${idx}`; params.push(date); idx++; }
  const { rows } = await query(`SELECT rp.*, t.technician_code FROM route_plans rp LEFT JOIN technicians t ON rp.technician_id = t.id ${where} ORDER BY rp.date DESC`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/routes', asyncHandler(async (req, res) => {
  const { technician_id, date, total_distance_km, total_duration_minutes, total_jobs, waypoints, optimization_score } = req.body;
  const { rows } = await query(
    `INSERT INTO route_plans (technician_id, date, total_distance_km, total_duration_minutes, total_jobs, waypoints, optimization_score) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [technician_id, date, total_distance_km, total_duration_minutes, total_jobs, JSON.stringify(waypoints), optimization_score]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.get('/routes/:id/stops', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT rs.*, b.booking_number FROM route_stops rs LEFT JOIN bookings b ON rs.booking_id = b.id WHERE rs.route_plan_id = $1 ORDER BY rs.stop_order', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/routes/:id/stops', asyncHandler(async (req, res) => {
  const { booking_id, stop_order, estimated_arrival, distance_from_previous_km, duration_from_previous_minutes, latitude, longitude } = req.body;
  const { rows } = await query(
    `INSERT INTO route_stops (route_plan_id, booking_id, stop_order, estimated_arrival, distance_from_previous_km, duration_from_previous_minutes, latitude, longitude) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [req.params.id, booking_id, stop_order, estimated_arrival, distance_from_previous_km, duration_from_previous_minutes, latitude, longitude]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/routes/:id/stops/:stopId', asyncHandler(async (req, res) => {
  const { status, actual_arrival, actual_departure } = req.body;
  const { rows } = await query('UPDATE route_stops SET status = $1, actual_arrival = $2, actual_departure = $3 WHERE id = $4 RETURNING *', [status, actual_arrival, actual_departure, req.params.stopId]);
  res.json({ status: 'success', data: rows[0] });
}));

module.exports = router;
