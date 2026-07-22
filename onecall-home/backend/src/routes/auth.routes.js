const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const { query } = require('../config/db');
const { signToken, authenticate, authorize, optionalAuth } = require('../middleware/auth.middleware');
const { asyncHandler, validateBody } = require('../middleware/error.middleware');

// POST /api/auth/register
router.post('/register', validateBody(['email', 'password', 'user_type']), asyncHandler(async (req, res) => {
  const { email, password, user_type, phone, username, first_name, last_name } = req.body;
  const passwordHash = await bcrypt.hash(password, 10);
  const { rows } = await query(
    `INSERT INTO users (email, password_hash, user_type, phone, username)
     VALUES ($1, $2, $3, $4, $5) RETURNING id, email, user_type, status`,
    [email, passwordHash, user_type, phone || null, username || null]
  );
  const user = rows[0];
  if (first_name || last_name) {
    await query(
      `INSERT INTO user_profiles (user_id, first_name, last_name) VALUES ($1, $2, $3)`,
      [user.id, first_name || null, last_name || null]
    );
  }
  if (user_type === 'customer') {
    const customerCode = 'CUST-' + Date.now().toString(36).toUpperCase();
    await query(
      `INSERT INTO customers (user_id, customer_code) VALUES ($1, $2)`,
      [user.id, customerCode]
    );
  }
  const token = signToken({ id: user.id, email: user.email, user_type: user.user_type });
  res.status(201).json({ status: 'success', message: 'User registered successfully', data: { user, token } });
}));

// POST /api/auth/login
router.post('/login', validateBody(['email', 'password']), asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const { rows } = await query('SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL', [email]);
  if (rows.length === 0) return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
  const user = rows[0];
  if (user.status !== 'active') return res.status(403).json({ status: 'error', message: 'Account is not active' });
  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
  await query('UPDATE users SET last_login_at = NOW(), failed_login_attempts = 0 WHERE id = $1', [user.id]);
  await query('INSERT INTO login_attempts (user_id, email, attempt_status) VALUES ($1, $2, $3)', [user.id, email, 'success']);
  const token = signToken({ id: user.id, email: user.email, user_type: user.user_type });
  res.json({ status: 'success', message: 'Login successful', data: { token, user: { id: user.id, email: user.email, user_type: user.user_type } } });
}));

// GET /api/auth/me
router.get('/me', authenticate, asyncHandler(async (req, res) => {
  const { rows } = await query(
    `SELECT u.id, u.email, u.phone, u.username, u.user_type, u.status, u.email_verified, u.phone_verified,
     up.first_name, up.last_name, up.display_name, up.city, up.state
     FROM users u LEFT JOIN user_profiles up ON u.id = up.user_id WHERE u.id = $1`,
    [req.user.id]
  );
  res.json({ status: 'success', data: rows[0] });
}));

// POST /api/auth/refresh
router.post('/refresh', authenticate, asyncHandler(async (req, res) => {
  const token = signToken({ id: req.user.id, email: req.user.email, user_type: req.user.user_type });
  res.json({ status: 'success', data: { token } });
}));

// POST /api/auth/logout
router.post('/logout', authenticate, asyncHandler(async (req, res) => {
  await query('UPDATE user_sessions SET is_active = false, logged_out_at = NOW() WHERE user_id = $1', [req.user.id]);
  res.json({ status: 'success', message: 'Logged out successfully' });
}));

// PUT /api/auth/password
router.put('/password', authenticate, validateBody(['current_password', 'new_password']), asyncHandler(async (req, res) => {
  const { current_password, new_password } = req.body;
  const { rows } = await query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
  const valid = await bcrypt.compare(current_password, rows[0].password_hash);
  if (!valid) return res.status(401).json({ status: 'error', message: 'Current password is incorrect' });
  const newHash = await bcrypt.hash(new_password, 10);
  await query('UPDATE users SET password_hash = $1, password_changed_at = NOW() WHERE id = $2', [newHash, req.user.id]);
  await query('INSERT INTO password_history (user_id, password_hash) VALUES ($1, $2)', [req.user.id, rows[0].password_hash]);
  res.json({ status: 'success', message: 'Password changed successfully' });
}));

// GET /api/auth/sessions
router.get('/sessions', authenticate, asyncHandler(async (req, res) => {
  const { rows } = await query(
    `SELECT id, device_type, device_name, ip_address, is_active, last_activity_at, created_at, expires_at
     FROM user_sessions WHERE user_id = $1 ORDER BY created_at DESC`, [req.user.id]
  );
  res.json({ status: 'success', data: rows });
}));

// DELETE /api/auth/sessions/:id
router.delete('/sessions/:id', authenticate, asyncHandler(async (req, res) => {
  await query('UPDATE user_sessions SET is_active = false, logged_out_at = NOW() WHERE id = $1 AND user_id = $2', [req.params.id, req.user.id]);
  res.json({ status: 'success', message: 'Session revoked' });
}));

// POST /api/auth/mfa/enable
router.post('/mfa/enable', authenticate, asyncHandler(async (req, res) => {
  const { mfa_type, secret_key } = req.body;
  const { rows } = await query(
    `INSERT INTO mfa_settings (user_id, mfa_type, is_enabled, secret_key, verified_at)
     VALUES ($1, $2, true, $3, NOW()) ON CONFLICT (user_id, mfa_type) DO UPDATE SET is_enabled = true, verified_at = NOW()
     RETURNING *`,
    [req.user.id, mfa_type || 'totp', secret_key]
  );
  res.json({ status: 'success', message: 'MFA enabled', data: rows[0] });
}));

// DELETE /api/auth/mfa/:mfa_type
router.delete('/mfa/:mfa_type', authenticate, asyncHandler(async (req, res) => {
  await query('UPDATE mfa_settings SET is_enabled = false WHERE user_id = $1 AND mfa_type = $2', [req.user.id, req.params.mfa_type]);
  res.json({ status: 'success', message: 'MFA disabled' });
}));

// POST /api/auth/api-keys
router.post('/api-keys', authenticate, asyncHandler(async (req, res) => {
  const { key_name, permissions, environment } = req.body;
  const crypto = require('crypto');
  const apiKey = 'ock_' + crypto.randomBytes(24).toString('hex');
  const { rows } = await query(
    `INSERT INTO api_keys (user_id, api_key, key_name, permissions, environment)
     VALUES ($1, $2, $3, $4, $5) RETURNING id, api_key, key_name, environment, is_active, created_at`,
    [req.user.id, apiKey, key_name, JSON.stringify(permissions || {}), environment || 'production']
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// GET /api/auth/api-keys
router.get('/api-keys', authenticate, asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT id, key_name, environment, is_active, last_used_at, created_at FROM api_keys WHERE user_id = $1', [req.user.id]);
  res.json({ status: 'success', data: rows });
}));

// DELETE /api/auth/api-keys/:id
router.delete('/api-keys/:id', authenticate, asyncHandler(async (req, res) => {
  await query('UPDATE api_keys SET is_active = false WHERE id = $1 AND user_id = $2', [req.params.id, req.user.id]);
  res.json({ status: 'success', message: 'API key revoked' });
}));

// POST /api/auth/devices
router.post('/devices', authenticate, asyncHandler(async (req, res) => {
  const { device_id, device_type, device_name, platform, push_token } = req.body;
  const { rows } = await query(
    `INSERT INTO device_registrations (user_id, device_id, device_type, device_name, platform, push_token)
     VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (device_id) DO UPDATE SET push_token = EXCLUDED.push_token, last_seen_at = NOW()
     RETURNING *`,
    [req.user.id, device_id, device_type, device_name, platform, push_token]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// GET /api/auth/devices
router.get('/devices', authenticate, asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM device_registrations WHERE user_id = $1 AND is_active = true', [req.user.id]);
  res.json({ status: 'success', data: rows });
}));

// DELETE /api/auth/devices/:id
router.delete('/devices/:id', authenticate, asyncHandler(async (req, res) => {
  await query('UPDATE device_registrations SET is_active = false WHERE id = $1 AND user_id = $2', [req.params.id, req.user.id]);
  res.json({ status: 'success', message: 'Device removed' });
}));

// GET /api/auth/security-events
router.get('/security-events', authenticate, asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM security_events WHERE user_id = $1 ORDER BY detected_at DESC LIMIT 50', [req.user.id]);
  res.json({ status: 'success', data: rows });
}));

// GET /api/auth/roles
router.get('/roles', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM roles ORDER BY priority');
  res.json({ status: 'success', data: rows });
}));

// GET /api/auth/permissions
router.get('/permissions', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM permissions ORDER BY module, name');
  res.json({ status: 'success', data: rows });
}));

module.exports = router;
