const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const { errorHandler, notFoundHandler } = require('./middleware/error.middleware');

const app = express();

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(morgan('dev'));

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'success', message: 'OneCall Home Solutions API is running', timestamp: new Date().toISOString() });
});

app.get('/api', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'OneCall Home Solutions Enterprise REST API',
    version: '1.0.0',
    modules: [
      'auth', 'customers', 'properties', 'technicians', 'services',
      'bookings', 'dispatch', 'payments', 'notifications', 'inventory',
      'crm', 'vendors', 'hr', 'analytics', 'ai', 'admin',
      'locations', 'files', 'audit', 'integrations', 'system',
      'branches', 'subscriptions', 'emergency', 'tickets', 'marketing',
      'quality', 'knowledge',
    ],
  });
});

app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/customers', require('./routes/customer.routes'));
app.use('/api/properties', require('./routes/property.routes'));
app.use('/api/technicians', require('./routes/technician.routes'));
app.use('/api/services', require('./routes/service.routes'));
app.use('/api/bookings', require('./routes/booking.routes'));
app.use('/api/dispatch', require('./routes/dispatch.routes'));
app.use('/api/payments', require('./routes/payment.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));
app.use('/api/inventory', require('./routes/inventory.routes'));
app.use('/api/crm', require('./routes/crm.routes'));
app.use('/api/vendors', require('./routes/vendor.routes'));
app.use('/api/hr', require('./routes/hr.routes'));
app.use('/api/analytics', require('./routes/analytics.routes'));
app.use('/api/ai', require('./routes/ai.routes'));
app.use('/api/admin', require('./routes/admin.routes'));
app.use('/api/locations', require('./routes/location.routes'));
app.use('/api/files', require('./routes/file.routes'));
app.use('/api/audit', require('./routes/audit.routes'));
app.use('/api/integrations', require('./routes/integration.routes'));
app.use('/api/system', require('./routes/system.routes'));
app.use('/api/branches', require('./routes/branch.routes'));
app.use('/api/subscriptions', require('./routes/subscription.routes'));
app.use('/api/emergency', require('./routes/emergency.routes'));
app.use('/api/tickets', require('./routes/ticket.routes'));
app.use('/api/marketing', require('./routes/marketing.routes'));
app.use('/api/quality', require('./routes/quality.routes'));
app.use('/api/knowledge', require('./routes/knowledge.routes'));

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
