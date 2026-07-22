const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Templates
router.get('/templates', asyncHandler(async (req, res) => {
  const { channel } = req.query;
  let where = 'WHERE is_active = true'; const params = [];
  if (channel) { where += ' AND channel = $1'; params.push(channel); }
  const { rows } = await query(`SELECT * FROM notification_templates ${where} ORDER BY created_at DESC`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/templates', asyncHandler(async (req, res) => {
  const { template_code, template_name, channel, subject, body, variables } = req.body;
  const { rows } = await query('INSERT INTO notification_templates (template_code, template_name, channel, subject, body, variables) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [template_code, template_name, channel, subject, body, JSON.stringify(variables)]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/templates/:id', asyncHandler(async (req, res) => {
  const { template_name, channel, subject, body, variables, is_active } = req.body;
  const { rows } = await query('UPDATE notification_templates SET template_name = $1, channel = $2, subject = $3, body = $4, variables = $5, is_active = $6 WHERE id = $7 RETURNING *', [template_name, channel, subject, body, JSON.stringify(variables), is_active, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/templates/:id', asyncHandler(async (req, res) => {
  await query('UPDATE notification_templates SET is_active = false WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Template deactivated' });
}));

// Notifications
router.get('/', asyncHandler(async (req, res) => {
  const { user_id, status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (user_id) { where += ` AND user_id = $${idx}`; params.push(user_id); idx++; }
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM notifications ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { user_id, template_id, channel, title, body, data, priority } = req.body;
  const { rows } = await query('INSERT INTO notifications (user_id, template_id, channel, title, body, data, priority) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *', [user_id, template_id, channel, title, body, JSON.stringify(data), priority || 'normal']);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id/read', asyncHandler(async (req, res) => {
  await query('UPDATE notifications SET status = $1, read_at = NOW() WHERE id = $2', ['read', req.params.id]);
  res.json({ status: 'success', message: 'Notification marked as read' });
}));

router.put('/read-all', asyncHandler(async (req, res) => {
  const { user_id } = req.body;
  await query('UPDATE notifications SET status = $1, read_at = NOW() WHERE user_id = $2 AND status != $1', ['read', user_id]);
  res.json({ status: 'success', message: 'All notifications marked as read' });
}));

// Preferences
router.get('/preferences/:userId', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM notification_preferences WHERE user_id = $1', [req.params.userId]);
  res.json({ status: 'success', data: rows });
}));

router.put('/preferences/:userId', asyncHandler(async (req, res) => {
  const { notification_type, email_enabled, sms_enabled, push_enabled, whatsapp_enabled, in_app_enabled, quiet_hours_start, quiet_hours_end, frequency } = req.body;
  const { rows } = await query(
    `INSERT INTO notification_preferences (user_id, notification_type, email_enabled, sms_enabled, push_enabled, whatsapp_enabled, in_app_enabled, quiet_hours_start, quiet_hours_end, frequency)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) ON CONFLICT (user_id, notification_type) DO UPDATE SET email_enabled = EXCLUDED.email_enabled, sms_enabled = EXCLUDED.sms_enabled, push_enabled = EXCLUDED.push_enabled, whatsapp_enabled = EXCLUDED.whatsapp_enabled, in_app_enabled = EXCLUDED.in_app_enabled, quiet_hours_start = EXCLUDED.quiet_hours_start, quiet_hours_end = EXCLUDED.quiet_hours_end, frequency = EXCLUDED.frequency RETURNING *`,
    [req.params.userId, notification_type, email_enabled, sms_enabled, push_enabled, whatsapp_enabled, in_app_enabled, quiet_hours_start, quiet_hours_end, frequency]
  );
  res.json({ status: 'success', data: rows[0] });
}));

// SMS logs
router.get('/sms-logs', asyncHandler(async (req, res) => {
  const { status, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM sms_logs ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

// Email logs
router.get('/email-logs', asyncHandler(async (req, res) => {
  const { status, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM email_logs ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

// Chat
router.get('/chat/conversations', asyncHandler(async (req, res) => {
  const { user_id, booking_id } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (user_id) { where += ` AND (participant_1 = $${idx} OR participant_2 = $${idx})`; params.push(user_id); idx++; }
  if (booking_id) { where += ` AND booking_id = $${idx}`; params.push(booking_id); idx++; }
  const { rows } = await query(`SELECT * FROM chat_conversations ${where} ORDER BY last_message_at DESC NULLS LAST`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/chat/conversations', asyncHandler(async (req, res) => {
  const { booking_id, participant_1, participant_2, conversation_type } = req.body;
  const { rows } = await query('INSERT INTO chat_conversations (booking_id, participant_1, participant_2, conversation_type) VALUES ($1,$2,$3,$4) RETURNING *', [booking_id, participant_1, participant_2, conversation_type || 'booking']);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.get('/chat/conversations/:id/messages', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM chat_messages WHERE conversation_id = $1 ORDER BY created_at', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/chat/conversations/:id/messages', asyncHandler(async (req, res) => {
  const { sender_id, message_type, content, media_urls } = req.body;
  const { rows } = await query('INSERT INTO chat_messages (conversation_id, sender_id, message_type, content, media_urls) VALUES ($1,$2,$3,$4,$5) RETURNING *', [req.params.id, sender_id, message_type || 'text', content, media_urls]);
  await query('UPDATE chat_conversations SET last_message_at = NOW(), last_message_text = $1 WHERE id = $2', [content, req.params.id]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
