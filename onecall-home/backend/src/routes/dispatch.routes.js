const express = require('express');
const router = express.Router();

// Module 9: Dispatch & Logistics

router.post('/find-technicians', (req, res) => {
  const { booking_id, latitude, longitude, required_skills } = req.body;
  res.status(200).json({
    status: 'success',
    data: {
      matched_technicians: [
        { technician_id: 'tech-156', name: 'Suresh Patel', distance_km: 1.8, eta_minutes: 12, rating: 4.9, match_score: 98.5 },
        { technician_id: 'tech-204', name: 'Ramesh Sharma', distance_km: 3.2, eta_minutes: 20, rating: 4.7, match_score: 92.0 }
      ]
    }
  });
});

router.post('/assign', (req, res) => {
  const { booking_id, technician_id, auto_dispatch } = req.body;
  res.status(200).json({
    status: 'success',
    message: 'Booking assigned to technician',
    data: {
      dispatch_id: 'disp-' + Date.now(),
      booking_id,
      technician_id,
      dispatch_status: 'accepted_by_technician',
      estimated_arrival: new Date(Date.now() + 15 * 60000).toISOString()
    }
  });
});

router.post('/route/optimize', (req, res) => {
  const { technician_id, date } = req.body;
  res.status(200).json({
    status: 'success',
    message: 'Day route optimized',
    data: {
      technician_id,
      total_stops: 5,
      total_distance_km: 28.4,
      optimized_order: ['bk-101', 'bk-102', 'bk-103', 'bk-104', 'bk-105']
    }
  });
});

module.exports = router;
