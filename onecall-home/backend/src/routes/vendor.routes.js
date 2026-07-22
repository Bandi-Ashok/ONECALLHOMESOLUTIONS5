const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

router.get('/', asyncHandler(async (req, res) => {
  const { status, category, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  if (category) { where += ` AND category = $${idx}`; params.push(category); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM vendors ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM vendors WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Vendor not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/', asyncHandler(async (req, res) => {
  const { vendor_code, company_name, display_name, vendor_type, category, primary_contact_name, primary_contact_email, primary_contact_phone, address_line1, city, state, pincode, gst_number, pan_number, payment_terms, commission_percentage, commission_type, onboarding_date, contract_start_date, contract_end_date, services_offered, service_cities, created_by } = req.body;
  const { rows } = await query(
    `INSERT INTO vendors (vendor_code, company_name, display_name, vendor_type, category, primary_contact_name, primary_contact_email, primary_contact_phone, address_line1, city, state, pincode, gst_number, pan_number, payment_terms, commission_percentage, commission_type, onboarding_date, contract_start_date, contract_end_date, services_offered, service_cities, created_by)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23) RETURNING *`,
    [vendor_code, company_name, display_name, vendor_type, category, primary_contact_name, primary_contact_email, primary_contact_phone, address_line1, city, state, pincode, gst_number, pan_number, payment_terms, commission_percentage, commission_type, onboarding_date, contract_start_date, contract_end_date, services_offered, service_cities, created_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const fields = ['company_name','display_name','vendor_type','category','primary_contact_name','primary_contact_email','primary_contact_phone','address_line1','city','state','pincode','gst_number','pan_number','payment_terms','commission_percentage','commission_type','rating','status','contract_end_date','services_offered','service_cities'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE vendors SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  await query('UPDATE vendors SET status = $1 WHERE id = $2', ['inactive', req.params.id]);
  res.json({ status: 'success', message: 'Vendor deactivated' });
}));

router.get('/:id/technicians', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT vt.*, t.technician_code, t.primary_skill FROM vendor_technicians vt JOIN technicians t ON vt.technician_id = t.id WHERE vt.vendor_id = $1', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/technicians', asyncHandler(async (req, res) => {
  const { technician_id, assignment_date, vendor_employee_id, contract_type } = req.body;
  const { rows } = await query('INSERT INTO vendor_technicians (vendor_id, technician_id, assignment_date, vendor_employee_id, contract_type) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (vendor_id, technician_id) DO UPDATE SET assignment_status = $6 RETURNING *', [req.params.id, technician_id, assignment_date, vendor_employee_id, contract_type, 'active']);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.get('/:id/invoices', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM vendor_invoices WHERE vendor_id = $1 ORDER BY created_at DESC', [req.params.id]);
  res.json({ status: 'success', data: rows });
}));

router.post('/:id/invoices', asyncHandler(async (req, res) => {
  const { invoice_number, vendor_invoice_number, invoice_date, due_date, subtotal, tax_amount, total_amount, notes } = req.body;
  const { rows } = await query('INSERT INTO vendor_invoices (vendor_id, invoice_number, vendor_invoice_number, invoice_date, due_date, subtotal, tax_amount, total_amount, balance_due, notes) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$8,$9) RETURNING *', [req.params.id, invoice_number, vendor_invoice_number, invoice_date, due_date, subtotal, tax_amount, total_amount, notes]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/:id/invoices/:invId', asyncHandler(async (req, res) => {
  const { status, amount_paid, payment_reference, payment_date, approved_by } = req.body;
  const { rows } = await query('UPDATE vendor_invoices SET status = $1, amount_paid = $2, payment_reference = $3, payment_date = $4, approved_by = $5 WHERE id = $6 RETURNING *', [status, amount_paid, payment_reference, payment_date, approved_by, req.params.invId]);
  res.json({ status: 'success', data: rows[0] });
}));

module.exports = router;
