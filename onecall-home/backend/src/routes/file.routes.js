const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Files
router.get('/', asyncHandler(async (req, res) => {
  const { type, uploaded_by, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (type) { where += ` AND file_type = $${idx}`; params.push(type); idx++; }
  if (uploaded_by) { where += ` AND uploaded_by = $${idx}`; params.push(uploaded_by); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM files ${where} ORDER BY uploaded_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM files WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'File not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { file_name, original_name, file_path, file_url, file_size_bytes, mime_type, file_extension, file_type, storage_provider, storage_bucket, storage_path, folder_id, uploaded_by, is_public, tags } = req.body;
  const { rows } = await query(
    `INSERT INTO files (file_name, original_name, file_path, file_url, file_size_bytes, mime_type, file_extension, file_type, storage_provider, storage_bucket, storage_path, folder_id, uploaded_by, is_public, tags)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15) RETURNING *`,
    [file_name, original_name, file_path, file_url, file_size_bytes, mime_type, file_extension, file_type, storage_provider || 'local', storage_bucket, storage_path, folder_id, uploaded_by, is_public || false, tags]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  await query('DELETE FROM files WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'File deleted' });
}));

// Folders
router.get('/folders/all', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM folders ORDER BY name');
  res.json({ status: 'success', data: rows });
}));

router.post('/folders', asyncHandler(async (req, res) => {
  const { name, parent_folder_id, created_by } = req.body;
  const { rows } = await query('INSERT INTO folders (name, parent_folder_id, created_by) VALUES ($1,$2,$3) RETURNING *', [name, parent_folder_id, created_by]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// File versions
router.get('/:id/versions', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM file_versions WHERE file_id = $1 ORDER BY version_number DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/versions', asyncHandler(async (req, res) => {
  const { file_path, file_size_bytes, checksum, uploaded_by, change_notes } = req.body;
  const maxVer = (await query('SELECT COALESCE(MAX(version_number), 0) as max_ver FROM file_versions WHERE file_id = $1', [req.params.id])).rows[0].max_ver;
  const { rows } = await query('INSERT INTO file_versions (file_id, version_number, file_path, file_size_bytes, checksum, uploaded_by, change_notes) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *', [req.params.id, maxVer + 1, file_path, file_size_bytes, checksum, uploaded_by, change_notes]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// File permissions
router.get('/:id/permissions', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM file_permissions WHERE file_id = $1', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/permissions', asyncHandler(async (req, res) => {
  const { user_id, role_id, permission_type, granted_by } = req.body;
  const { rows } = await query('INSERT INTO file_permissions (file_id, user_id, role_id, permission_type, granted_by) VALUES ($1,$2,$3,$4,$5) RETURNING *', [req.params.id, user_id, role_id, permission_type, granted_by]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Media library
router.get('/media/all', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT ml.*, f.file_name, f.file_url FROM media_library ml JOIN files f ON ml.file_id = f.id ORDER BY ml.sort_order');
  res.json({ status: 'success', data: rows });
}));

router.post('/media', asyncHandler(async (req, res) => {
  const { file_id, title, alt_text, caption, media_category, width, height, is_featured } = req.body;
  const { rows } = await query('INSERT INTO media_library (file_id, title, alt_text, caption, media_category, width, height, is_featured) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *', [file_id, title, alt_text, caption, media_category, width, height, is_featured]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Document categories
router.get('/document-categories/all', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM document_categories ORDER BY name');
  res.json({ status: 'success', data: rows });
}));

router.post('/document-categories', asyncHandler(async (req, res) => {
  const { name, code, description, parent_category_id, allowed_mime_types, max_file_size_bytes, is_required } = req.body;
  const { rows } = await query('INSERT INTO document_categories (name, code, description, parent_category_id, allowed_mime_types, max_file_size_bytes, is_required) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *', [name, code, description, parent_category_id, allowed_mime_types, max_file_size_bytes, is_required]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
