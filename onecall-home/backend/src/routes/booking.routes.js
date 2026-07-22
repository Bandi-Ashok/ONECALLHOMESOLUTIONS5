const express = require('express');
const router = express.Router();

router.post('/', (req, res) => {
  const { customer_id, service_id, scheduled_date, scheduled_time, total_amount } = req.body;
  res.status(201).json({
    status: 'success',
    message: 'Service booking created and technician dispatched',
    data: {
      booking_id: 'bk-' + Date.now(),
      booking_number: 'BK-MUM-26-' + Math.floor(100000 + Math.random() * 900000),
      customer_id,
      service_id,
      status: 'confirmed',
      scheduled_date,
      scheduled_time,
      total_amount: total_amount || 599.00,
      payment_status: 'paid',
      technician: {
        id: 'tech-156',
        name: 'Suresh Patel',
        phone: '+91-9876543221',
        rating: 4.9,
        estimated_arrival_minutes: 25
      }
    }
  });
});

router.get('/:id', (req, res) => {
  res.status(200).json({
    status: 'success',
    data: {
      booking_id: req.params.id,
      booking_number: 'BK-MUM-26-102938',
      service_name: 'Split AC Foam & Jet Service',
      status: 'en_route',
      scheduled_time: '2026-07-21T11:00:00Z',
      total_amount: 599.00,
      payment_status: 'paid',
      technician: {
        id: 'tech-156',
        name: 'Suresh Patel',
        phone: '+91-9876543221',
        rating: 4.9,
        latitude: 19.0585,
        longitude: 72.8285,
        estimated_arrival_time: '11:15 AM'
      }
    }
  });
});

module.exports = router;
