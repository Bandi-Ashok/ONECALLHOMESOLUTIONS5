const express = require('express');
const router = express.Router();

// Module 15: Platform Administration

router.get('/config', (req, res) => {
  res.status(200).json({
    status: 'success',
    data: {
      platform_settings: {
        platform_name: 'OneCall Home Solutions Enterprise',
        default_currency: 'INR',
        tax_gst_percentage: 18.0,
        platform_commission_percentage: 15.0,
        support_hotline: '+91-1800-ONECALL'
      }
    }
  });
});

router.patch('/features/:id/enable', (req, res) => {
  const { feature_id } = req.params;
  const { is_enabled } = req.body;
  res.status(200).json({
    status: 'success',
    message: 'Feature flag updated',
    data: { feature_id, is_enabled }
  });
});

module.exports = router;
