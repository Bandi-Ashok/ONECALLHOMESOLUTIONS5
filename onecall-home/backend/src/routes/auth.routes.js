const express = require('express');
const router = express.Router();

// Auth Endpoints
router.post('/register/customer', (req, res) => {
  const { email, phone, first_name, last_name, city } = req.body;
  res.status(201).json({
    status: 'success',
    message: 'Customer registered successfully. Please verify OTP.',
    data: {
      user_id: '550e8400-e29b-41d4-a716-446655440001',
      customer_code: 'CUST-MUM-24-000001',
      email,
      phone,
      first_name,
      last_name,
      city,
      email_verified: false,
      phone_verified: false
    }
  });
});

router.post('/login', (req, res) => {
  const { login_id } = req.body;
  res.status(200).json({
    status: 'success',
    message: 'Login successful',
    data: {
      user: {
        user_id: '550e8400-e29b-41d4-a716-446655440001',
        email: login_id.includes('@') ? login_id : 'john.doe@email.com',
        first_name: 'John',
        last_name: 'Doe',
        user_type: 'customer',
        customer_code: 'CUST-MUM-24-000001'
      },
      tokens: {
        access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.jwt-access-token-sample',
        refresh_token: 'refresh-token-sample-123456',
        expires_in: 900
      }
    }
  });
});

router.post('/verify/phone', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Phone verified successfully',
    data: { phone_verified: true, account_status: 'active' }
  });
});

router.post('/verify/email', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Email verified successfully',
    data: { email_verified: true, verified_at: new Date().toISOString() }
  });
});

module.exports = router;
