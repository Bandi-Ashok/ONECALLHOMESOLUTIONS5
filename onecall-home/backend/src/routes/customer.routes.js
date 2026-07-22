const express = require('express');
const router = express.Router();

router.get('/:id', (req, res) => {
  res.status(200).json({
    status: 'success',
    data: {
      customer_id: req.params.id,
      customer_code: 'CUST-MUM-24-000001',
      personal_info: {
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@email.com',
        phone: '+91-9876543210',
        city: 'Mumbai'
      },
      account_info: {
        customer_tier: 'gold',
        total_bookings: 24,
        total_spent: 125000.00,
        average_rating: 4.8
      },
      wallet: {
        balance: 2500.00,
        currency: 'INR'
      }
    }
  });
});

router.get('/:id/addresses', (req, res) => {
  res.status(200).json({
    status: 'success',
    data: {
      addresses: [
        {
          address_id: 'addr-001',
          label: 'Home - Bandra',
          address_line1: '1201, Palm Springs Apartments',
          address_line2: 'Linking Road, Bandra West',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400050',
          is_default: true,
          latitude: 19.0596,
          longitude: 72.8295
        }
      ]
    }
  });
});

module.exports = router;
