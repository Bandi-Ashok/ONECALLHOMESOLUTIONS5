const express = require('express');
const router = express.Router();
const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');

// Products
router.get('/products', asyncHandler(async (req, res) => {
  const { category_id, search, is_active, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (category_id) { where += ` AND category_id = $${idx}`; params.push(category_id); idx++; }
  if (search) { where += ` AND (name ILIKE $${idx} OR product_code ILIKE $${idx})`; params.push(`%${search}%`); idx++; }
  if (is_active !== undefined) { where += ` AND is_active = $${idx}`; params.push(is_active === 'true'); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM products ${where} ORDER BY name LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.get('/products/:id', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM products WHERE id = $1', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ status: 'error', message: 'Product not found' });
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/products', asyncHandler(async (req, res) => {
  const { product_code, name, description, category_id, product_type, brand, model_number, hsn_sac_code, unit, unit_price, selling_price, mrp, tax_percentage, minimum_stock_level, reorder_point, reorder_quantity } = req.body;
  const { rows } = await query(
    `INSERT INTO products (product_code, name, description, category_id, product_type, brand, model_number, hsn_sac_code, unit, unit_price, selling_price, mrp, tax_percentage, minimum_stock_level, reorder_point, reorder_quantity)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16) RETURNING *`,
    [product_code, name, description, category_id, product_type, brand, model_number, hsn_sac_code, unit, unit_price, selling_price, mrp, mrp, tax_percentage || 18, minimum_stock_level || 10, reorder_point || 20, reorder_quantity || 50]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/products/:id', asyncHandler(async (req, res) => {
  const fields = ['name','description','product_type','brand','unit_price','selling_price','mrp','tax_percentage','minimum_stock_level','reorder_point','reorder_quantity','is_active'];
  const updates = []; const params = []; let idx = 1;
  for (const f of fields) { if (req.body[f] !== undefined) { updates.push(`${f} = $${idx}`); params.push(req.body[f]); idx++; } }
  if (updates.length === 0) return res.status(400).json({ status: 'error', message: 'No fields to update' });
  params.push(req.params.id);
  const { rows } = await query(`UPDATE products SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, params);
  res.json({ status: 'success', data: rows[0] });
}));

router.delete('/products/:id', asyncHandler(async (req, res) => {
  await query('UPDATE products SET is_active = false WHERE id = $1', [req.params.id]);
  res.json({ status: 'success', message: 'Product deactivated' });
}));

// Warehouses
router.get('/warehouses', asyncHandler(async (req, res) => {
  const { rows } = await query('SELECT * FROM inventory_warehouses WHERE is_active = true ORDER BY name');
  res.json({ status: 'success', data: rows });
}));

router.post('/warehouses', asyncHandler(async (req, res) => {
  const { name, code, address_line1, city, state, pincode, warehouse_type, contact_person, contact_phone } = req.body;
  const { rows } = await query('INSERT INTO inventory_warehouses (name, code, address_line1, city, state, pincode, warehouse_type, contact_person, contact_phone) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *', [name, code, address_line1, city, state, pincode, warehouse_type, contact_person, contact_phone]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Stock
router.get('/stock', asyncHandler(async (req, res) => {
  const { warehouse_id, product_id, low_stock } = req.query;
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (warehouse_id) { where += ` AND ist.warehouse_id = $${idx}`; params.push(warehouse_id); idx++; }
  if (product_id) { where += ` AND ist.product_id = $${idx}`; params.push(product_id); idx++; }
  let queryStr = `SELECT ist.*, p.name as product_name, p.product_code, p.minimum_stock_level, p.reorder_point, w.name as warehouse_name
     FROM inventory_stock ist JOIN products p ON ist.product_id = p.id JOIN inventory_warehouses w ON ist.warehouse_id = w.id ${where}`;
  if (low_stock === 'true') { queryStr += ` AND (ist.quantity - COALESCE(ist.allocated_quantity,0)) <= p.reorder_point`; }
  queryStr += ' ORDER BY p.name';
  const { rows } = await query(queryStr, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/stock', asyncHandler(async (req, res) => {
  const { product_id, warehouse_id, quantity, batch_number, expiry_date } = req.body;
  const { rows } = await query(
    `INSERT INTO inventory_stock (product_id, warehouse_id, quantity, batch_number, expiry_date)
     VALUES ($1,$2,$3,$4,$5) ON CONFLICT (product_id, warehouse_id, batch_number) DO UPDATE SET quantity = inventory_stock.quantity + EXCLUDED.quantity RETURNING *`,
    [product_id, warehouse_id, quantity, batch_number || 'DEFAULT', expiry_date]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/stock/:id', asyncHandler(async (req, res) => {
  const { quantity, allocated_quantity, damaged_quantity } = req.body;
  const { rows } = await query('UPDATE inventory_stock SET quantity = $1, allocated_quantity = $2, damaged_quantity = $3 WHERE id = $4 RETURNING *', [quantity, allocated_quantity, damaged_quantity, req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

// Transactions
router.get('/transactions', asyncHandler(async (req, res) => {
  const { product_id, warehouse_id, transaction_type, page = 1, limit = 50 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (product_id) { where += ` AND product_id = $${idx}`; params.push(product_id); idx++; }
  if (warehouse_id) { where += ` AND warehouse_id = $${idx}`; params.push(warehouse_id); idx++; }
  if (transaction_type) { where += ` AND transaction_type = $${idx}`; params.push(transaction_type); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM inventory_transactions ${where} ORDER BY transaction_date DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/transactions', asyncHandler(async (req, res) => {
  const { product_id, warehouse_id, transaction_type, quantity, unit_price, total_amount, reference_type, reference_id, booking_id, vendor_id, technician_id, batch_number, notes, created_by } = req.body;
  const { rows } = await query(
    `INSERT INTO inventory_transactions (product_id, warehouse_id, transaction_type, quantity, unit_price, total_amount, reference_type, reference_id, booking_id, vendor_id, technician_id, batch_number, notes, created_by)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) RETURNING *`,
    [product_id, warehouse_id, transaction_type, quantity, unit_price, total_amount, reference_type, reference_id, booking_id, vendor_id, technician_id, batch_number, notes, created_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

// Purchase Orders
router.get('/purchase-orders', asyncHandler(async (req, res) => {
  const { status, vendor_id, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = 'WHERE 1=1'; const params = []; let idx = 1;
  if (status) { where += ` AND status = $${idx}`; params.push(status); idx++; }
  if (vendor_id) { where += ` AND vendor_id = $${idx}`; params.push(vendor_id); idx++; }
  params.push(parseInt(limit), offset);
  const { rows } = await query(`SELECT * FROM purchase_orders ${where} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`, params);
  res.json({ status: 'success', data: rows });
}));

router.post('/purchase-orders', asyncHandler(async (req, res) => {
  const { po_number, vendor_id, warehouse_id, order_date, expected_delivery_date, subtotal, tax_amount, shipping_charges, total_amount, payment_terms, notes, created_by } = req.body;
  const { rows } = await query(
    `INSERT INTO purchase_orders (po_number, vendor_id, warehouse_id, order_date, expected_delivery_date, subtotal, tax_amount, shipping_charges, total_amount, payment_terms, notes, created_by)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
    [po_number, vendor_id, warehouse_id, order_date, expected_delivery_date, subtotal, tax_amount, shipping_charges, total_amount, payment_terms, notes, created_by]
  );
  res.status(201).json({ status: 'success', data: rows[0] });
}));

router.put('/purchase-orders/:id', asyncHandler(async (req, res) => {
  const { status, actual_delivery_date, approved_by } = req.body;
  const { rows } = await query('UPDATE purchase_orders SET status = $1, actual_delivery_date = $2, approved_by = $3, approved_at = CASE WHEN $1 IN ($4,$5) THEN NOW() ELSE approved_at END WHERE id = $6 RETURNING *', [status, actual_delivery_date, approved_by, 'confirmed', 'received', req.params.id]);
  res.json({ status: 'success', data: rows[0] });
}));

router.post('/purchase-orders/:id/items', asyncHandler(async (req, res) => {
  const { product_id, quantity, unit_price, tax_percentage, total_amount } = req.body;
  const { rows } = await query('INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price, tax_percentage, total_amount) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [req.params.id, product_id, quantity, unit_price, tax_percentage, total_amount]);
  res.status(201).json({ status: 'success', data: rows[0] });
}));

module.exports = router;
