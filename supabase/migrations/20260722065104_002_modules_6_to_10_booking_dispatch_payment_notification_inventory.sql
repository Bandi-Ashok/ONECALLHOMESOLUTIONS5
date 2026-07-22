/*
# OneCall Home Solutions — Modules 6-10: Bookings, Dispatch, Payments, Notifications, Inventory

6. Module 6 — Booking Management: bookings, booking_status_history, booking_reschedules, booking_quotes, quote_items
7. Module 7 — Dispatch & Scheduling: dispatch_queue, scheduling_slots, route_plans, route_stops
8. Module 8 — Payment & Billing: payments, invoices, invoice_items, refunds, payment_methods
9. Module 9 — Notification & Communication: notification_templates, notifications, notification_preferences, sms_logs, email_logs, chat_conversations, chat_messages
10. Module 10 — Inventory & Product Management: products, inventory_warehouses, inventory_stock, inventory_transactions, purchase_orders, purchase_order_items

Security: RLS enabled with anon+authenticated access.
*/

-- MODULE 6: BOOKING MANAGEMENT
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    property_id UUID REFERENCES properties(id) ON DELETE SET NULL,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
    package_id UUID REFERENCES service_packages(id) ON DELETE SET NULL,
    booking_type VARCHAR(20) CHECK (booking_type IN ('standard', 'emergency', 'scheduled', 'recurring', 'amc', 'quote')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'assigned', 'in_progress', 'completed', 'cancelled', 'rescheduled', 'no_show', 'on_hold', 'awaiting_parts', 'awaiting_payment', 'disputed')),
    sub_status VARCHAR(100),
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent', 'emergency')),
    scheduled_start_time TIMESTAMP WITH TIME ZONE,
    scheduled_end_time TIMESTAMP WITH TIME ZONE,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    technician_id UUID REFERENCES technicians(id) ON DELETE SET NULL,
    vendor_id UUID,
    assigned_technicians UUID[],
    service_address_id UUID REFERENCES customer_addresses(id),
    service_latitude DECIMAL(10,8),
    service_longitude DECIMAL(11,8),
    service_notes TEXT,
    access_instructions TEXT,
    customer_instructions TEXT,
    technician_notes TEXT,
    internal_notes TEXT,
    issue_description TEXT,
    issue_images UUID[],
    diagnosis TEXT,
    solution TEXT,
    parts_required BOOLEAN DEFAULT false,
    parts_replaced TEXT[],
    materials_used JSONB,
    total_labour_cost DECIMAL(15,2) DEFAULT 0.00,
    total_material_cost DECIMAL(15,2) DEFAULT 0.00,
    total_parts_cost DECIMAL(15,2) DEFAULT 0.00,
    subtotal DECIMAL(15,2) DEFAULT 0.00,
    discount_amount DECIMAL(15,2) DEFAULT 0.00,
    discount_code VARCHAR(50),
    tax_amount DECIMAL(15,2) DEFAULT 0.00,
    emergency_surcharge DECIMAL(15,2) DEFAULT 0.00,
    convenience_fee DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'INR',
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'partial', 'paid', 'refunded', 'partial_refund', 'failed', 'cancelled')),
    payment_method VARCHAR(50),
    is_invoice_generated BOOLEAN DEFAULT false,
    invoice_id UUID,
    customer_rating INTEGER CHECK (customer_rating BETWEEN 1 AND 5),
    technician_rating INTEGER CHECK (technician_rating BETWEEN 1 AND 5),
    customer_feedback TEXT,
    cancellation_reason TEXT,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    rescheduled_from UUID REFERENCES bookings(id),
    reschedule_count INTEGER DEFAULT 0,
    is_recurring BOOLEAN DEFAULT false,
    recurring_pattern JSONB,
    parent_booking_id UUID REFERENCES bookings(id),
    source VARCHAR(50) DEFAULT 'app' CHECK (source IN ('app', 'website', 'call_center', 'walk_in', 'partner', 'chat', 'ivr')),
    tracking_id VARCHAR(100),
    estimated_cost_range JSONB,
    before_service_photos UUID[],
    after_service_photos UUID[],
    service_report_id UUID,
    checklist_completed JSONB,
    custom_fields JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS booking_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_by UUID REFERENCES users(id),
    changed_by_type VARCHAR(20) CHECK (changed_by_type IN ('system', 'customer', 'technician', 'admin', 'vendor')),
    change_reason TEXT,
    change_notes TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS booking_reschedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    original_schedule TIMESTAMP WITH TIME ZONE,
    new_schedule TIMESTAMP WITH TIME ZONE,
    rescheduled_by UUID REFERENCES users(id),
    rescheduled_by_type VARCHAR(20) CHECK (rescheduled_by_type IN ('customer', 'technician', 'admin', 'system')),
    reason TEXT,
    customer_approved BOOLEAN DEFAULT false,
    technician_approved BOOLEAN DEFAULT false,
    charges_applied DECIMAL(15,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS booking_quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    quote_number VARCHAR(50) UNIQUE,
    labour_cost DECIMAL(15,2) DEFAULT 0.00,
    parts_cost DECIMAL(15,2) DEFAULT 0.00,
    material_cost DECIMAL(15,2) DEFAULT 0.00,
    tax_amount DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) NOT NULL,
    validity_hours INTEGER DEFAULT 24,
    valid_until TIMESTAMP WITH TIME ZONE,
    terms_and_conditions TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired', 'revised')),
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    rejection_reason TEXT,
    revision_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS quote_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_id UUID NOT NULL REFERENCES booking_quotes(id) ON DELETE CASCADE,
    item_type VARCHAR(20) CHECK (item_type IN ('labour', 'part', 'material', 'service', 'miscellaneous')),
    item_name VARCHAR(200),
    description TEXT,
    quantity DECIMAL(10,2) DEFAULT 1,
    unit_price DECIMAL(15,2),
    total_price DECIMAL(15,2),
    tax_percentage DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 7: DISPATCH & SCHEDULING
CREATE TABLE IF NOT EXISTS dispatch_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    dispatch_status VARCHAR(20) DEFAULT 'queued' CHECK (dispatch_status IN ('queued', 'matching', 'offered', 'accepted', 'declined', 'assigned', 'en_route', 'arrived', 'completed')),
    priority_score DECIMAL(5,2),
    matching_started_at TIMESTAMP WITH TIME ZONE,
    matching_completed_at TIMESTAMP WITH TIME ZONE,
    offered_to_technicians UUID[],
    accepted_by_technician UUID REFERENCES technicians(id),
    assignment_type VARCHAR(20) CHECK (assignment_type IN ('auto', 'manual', 'preferred', 'nearest')),
    decline_reasons JSONB,
    matching_algorithm_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scheduling_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_type VARCHAR(20) DEFAULT 'available' CHECK (slot_type IN ('available', 'booked', 'blocked', 'break', 'training', 'meeting')),
    booking_id UUID REFERENCES bookings(id),
    is_recurring BOOLEAN DEFAULT false,
    recurring_rule JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS route_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    plan_status VARCHAR(20) DEFAULT 'created' CHECK (plan_status IN ('created', 'in_progress', 'completed', 'cancelled')),
    total_distance_km DECIMAL(10,2),
    total_duration_minutes INTEGER,
    total_jobs INTEGER,
    completed_jobs INTEGER DEFAULT 0,
    waypoints JSONB,
    optimization_score DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS route_stops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_plan_id UUID NOT NULL REFERENCES route_plans(id) ON DELETE CASCADE,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    stop_order INTEGER NOT NULL,
    estimated_arrival TIMESTAMP WITH TIME ZONE,
    actual_arrival TIMESTAMP WITH TIME ZONE,
    estimated_departure TIMESTAMP WITH TIME ZONE,
    actual_departure TIMESTAMP WITH TIME ZONE,
    distance_from_previous_km DECIMAL(10,2),
    duration_from_previous_minutes INTEGER,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'skipped', 'arrived', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 8: PAYMENT & BILLING
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_number VARCHAR(50) UNIQUE,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'INR',
    payment_method VARCHAR(50) CHECK (payment_method IN ('credit_card', 'debit_card', 'net_banking', 'upi', 'wallet', 'cash', 'cheque', 'bank_transfer', 'emi', 'bnpl')),
    payment_gateway VARCHAR(50),
    gateway_transaction_id VARCHAR(200),
    gateway_response JSONB,
    status VARCHAR(20) DEFAULT 'initiated' CHECK (status IN ('initiated', 'processing', 'completed', 'failed', 'refunded', 'partial_refund', 'cancelled', 'expired', 'pending')),
    payment_mode VARCHAR(20) DEFAULT 'online' CHECK (payment_mode IN ('online', 'offline', 'cod')),
    is_international BOOLEAN DEFAULT false,
    card_type VARCHAR(50),
    card_last_four VARCHAR(4),
    bank_name VARCHAR(100),
    payment_initiated_at TIMESTAMP WITH TIME ZONE,
    payment_completed_at TIMESTAMP WITH TIME ZONE,
    settlement_status VARCHAR(20) DEFAULT 'pending' CHECK (settlement_status IN ('pending', 'settled', 'failed')),
    settlement_date DATE,
    settlement_reference VARCHAR(200),
    refund_status VARCHAR(20),
    refund_amount DECIMAL(15,2),
    refund_reason TEXT,
    refund_initiated_at TIMESTAMP WITH TIME ZONE,
    refund_completed_at TIMESTAMP WITH TIME ZONE,
    refund_reference VARCHAR(200),
    fee_amount DECIMAL(15,2) DEFAULT 0.00,
    gst_on_fee DECIMAL(15,2) DEFAULT 0.00,
    net_settlement_amount DECIMAL(15,2),
    reconciliation_status VARCHAR(20) DEFAULT 'pending' CHECK (reconciliation_status IN ('pending', 'matched', 'unmatched', 'discrepancy')),
    reconciliation_notes TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    invoice_type VARCHAR(20) DEFAULT 'tax_invoice' CHECK (invoice_type IN ('tax_invoice', 'proforma', 'credit_note', 'debit_note')),
    invoice_date DATE NOT NULL,
    due_date DATE,
    subtotal DECIMAL(15,2) NOT NULL,
    discount_amount DECIMAL(15,2) DEFAULT 0.00,
    taxable_amount DECIMAL(15,2),
    cgst_amount DECIMAL(15,2) DEFAULT 0.00,
    sgst_amount DECIMAL(15,2) DEFAULT 0.00,
    igst_amount DECIMAL(15,2) DEFAULT 0.00,
    cess_amount DECIMAL(15,2) DEFAULT 0.00,
    total_tax DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) NOT NULL,
    amount_paid DECIMAL(15,2) DEFAULT 0.00,
    amount_due DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'INR',
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'partial', 'paid', 'overdue', 'cancelled', 'written_off')),
    payment_terms VARCHAR(100),
    billing_address_id UUID REFERENCES customer_addresses(id),
    shipping_address_id UUID REFERENCES customer_addresses(id),
    place_of_supply VARCHAR(100),
    reverse_charge BOOLEAN DEFAULT false,
    notes TEXT,
    terms_and_conditions TEXT,
    generated_by UUID REFERENCES users(id),
    sent_at TIMESTAMP WITH TIME ZONE,
    pdf_url TEXT,
    e_invoice_number VARCHAR(200),
    irn_number VARCHAR(200),
    qr_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_type VARCHAR(20) CHECK (item_type IN ('service', 'part', 'material', 'labour', 'fee', 'discount', 'tax')),
    description TEXT NOT NULL,
    hsn_sac_code VARCHAR(20),
    quantity DECIMAL(10,2) DEFAULT 1,
    unit VARCHAR(50),
    unit_price DECIMAL(15,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    taxable_amount DECIMAL(15,2),
    cgst_percentage DECIMAL(5,2),
    sgst_percentage DECIMAL(5,2),
    igst_percentage DECIMAL(5,2),
    cgst_amount DECIMAL(15,2) DEFAULT 0,
    sgst_amount DECIMAL(15,2) DEFAULT 0,
    igst_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS refunds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    refund_number VARCHAR(50) UNIQUE,
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE RESTRICT,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    amount DECIMAL(15,2) NOT NULL,
    refund_type VARCHAR(20) CHECK (refund_type IN ('full', 'partial', 'cancellation', 'service_charge', 'goodwill')),
    refund_method VARCHAR(50) CHECK (refund_method IN ('original_payment', 'wallet', 'bank_transfer', 'cheque', 'cash')),
    reason TEXT,
    status VARCHAR(20) DEFAULT 'initiated' CHECK (status IN ('initiated', 'processing', 'completed', 'failed', 'cancelled')),
    refund_reference VARCHAR(200),
    processed_by UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    initiated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    method_type VARCHAR(50) CHECK (method_type IN ('credit_card', 'debit_card', 'bank_account', 'upi', 'wallet')),
    token_id VARCHAR(200),
    masked_number VARCHAR(50),
    card_network VARCHAR(50),
    card_type VARCHAR(50),
    cardholder_name VARCHAR(200),
    expiry_month INTEGER,
    expiry_year INTEGER,
    bank_name VARCHAR(100),
    is_default BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    billing_address_id UUID REFERENCES customer_addresses(id),
    gateway_customer_id VARCHAR(200),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 9: NOTIFICATION & COMMUNICATION
CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_code VARCHAR(100) UNIQUE NOT NULL,
    template_name VARCHAR(200),
    channel VARCHAR(20) CHECK (channel IN ('email', 'sms', 'push', 'whatsapp', 'in_app', 'voice')),
    subject VARCHAR(500),
    body TEXT,
    variables JSONB,
    is_active BOOLEAN DEFAULT true,
    locale VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    template_id UUID REFERENCES notification_templates(id),
    channel VARCHAR(20) CHECK (channel IN ('email', 'sms', 'push', 'whatsapp', 'in_app', 'voice')),
    title VARCHAR(500),
    body TEXT,
    data JSONB,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed', 'bounced', 'complained')),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    message_id VARCHAR(200),
    provider_message_id VARCHAR(200),
    provider_response JSONB,
    cost DECIMAL(10,4),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(100),
    email_enabled BOOLEAN DEFAULT true,
    sms_enabled BOOLEAN DEFAULT true,
    push_enabled BOOLEAN DEFAULT true,
    whatsapp_enabled BOOLEAN DEFAULT false,
    in_app_enabled BOOLEAN DEFAULT true,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    frequency VARCHAR(20) DEFAULT 'immediate' CHECK (frequency IN ('immediate', 'hourly', 'daily', 'weekly')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, notification_type)
);

CREATE TABLE IF NOT EXISTS sms_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID REFERENCES notifications(id),
    phone_number VARCHAR(20) NOT NULL,
    message_body TEXT NOT NULL,
    provider VARCHAR(50),
    provider_message_id VARCHAR(200),
    status VARCHAR(20) DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'delivered', 'failed', 'undelivered')),
    delivery_status_code VARCHAR(50),
    delivery_status_description TEXT,
    credits_used DECIMAL(10,4),
    cost DECIMAL(10,4),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID REFERENCES notifications(id),
    to_email VARCHAR(255) NOT NULL,
    cc_email TEXT[],
    bcc_email TEXT[],
    subject VARCHAR(500) NOT NULL,
    body_html TEXT,
    body_text TEXT,
    attachments JSONB,
    provider VARCHAR(50),
    provider_message_id VARCHAR(200),
    status VARCHAR(20) DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'delivered', 'opened', 'clicked', 'bounced', 'complained', 'failed')),
    delivery_status_code VARCHAR(50),
    delivery_status_description TEXT,
    opened_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(id),
    participant_1 UUID NOT NULL REFERENCES users(id),
    participant_2 UUID NOT NULL REFERENCES users(id),
    conversation_type VARCHAR(20) CHECK (conversation_type IN ('booking', 'support', 'general')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'archived', 'closed')),
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_message_text TEXT,
    unread_count_p1 INTEGER DEFAULT 0,
    unread_count_p2 INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'video', 'document', 'location', 'system')),
    content TEXT,
    media_urls TEXT[],
    metadata JSONB,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 10: INVENTORY & PRODUCT MANAGEMENT
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id UUID,
    product_type VARCHAR(20) CHECK (product_type IN ('part', 'material', 'consumable', 'tool', 'equipment', 'accessory', 'chemical', 'cleaning_agent')),
    brand VARCHAR(100),
    model_number VARCHAR(100),
    hsn_sac_code VARCHAR(20),
    unit VARCHAR(50),
    unit_price DECIMAL(15,2) NOT NULL,
    selling_price DECIMAL(15,2),
    mrp DECIMAL(15,2),
    tax_percentage DECIMAL(5,2) DEFAULT 18.00,
    minimum_stock_level INTEGER DEFAULT 10,
    maximum_stock_level INTEGER DEFAULT 1000,
    reorder_point INTEGER DEFAULT 20,
    reorder_quantity INTEGER DEFAULT 50,
    lead_time_days INTEGER DEFAULT 7,
    weight_kg DECIMAL(10,3),
    dimensions JSONB,
    is_active BOOLEAN DEFAULT true,
    is_returnable BOOLEAN DEFAULT true,
    warranty_period_months INTEGER,
    shelf_life_days INTEGER,
    requires_cold_storage BOOLEAN DEFAULT false,
    hazardous_material BOOLEAN DEFAULT false,
    safety_instructions TEXT,
    compatible_services UUID[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventory_warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    code VARCHAR(50) UNIQUE,
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    warehouse_type VARCHAR(20) CHECK (warehouse_type IN ('main', 'regional', 'local', 'van', 'technician')),
    technician_id UUID REFERENCES technicians(id),
    is_active BOOLEAN DEFAULT true,
    contact_person VARCHAR(200),
    contact_phone VARCHAR(20),
    operating_hours JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventory_stock (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES inventory_warehouses(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 0,
    allocated_quantity INTEGER DEFAULT 0,
    damaged_quantity INTEGER DEFAULT 0,
    expiry_date DATE,
    batch_number VARCHAR(100),
    last_counted_at TIMESTAMP WITH TIME ZONE,
    last_counted_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(product_id, warehouse_id, batch_number)
);

CREATE TABLE IF NOT EXISTS inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    warehouse_id UUID NOT NULL REFERENCES inventory_warehouses(id) ON DELETE RESTRICT,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('purchase', 'sale', 'transfer_in', 'transfer_out', 'return', 'adjustment', 'damage', 'write_off', 'consumption')),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(15,2),
    total_amount DECIMAL(15,2),
    reference_type VARCHAR(50),
    reference_id UUID,
    booking_id UUID REFERENCES bookings(id),
    vendor_id UUID,
    technician_id UUID REFERENCES technicians(id),
    batch_number VARCHAR(100),
    notes TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    po_number VARCHAR(50) UNIQUE NOT NULL,
    vendor_id UUID,
    warehouse_id UUID REFERENCES inventory_warehouses(id),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'confirmed', 'partially_received', 'received', 'cancelled', 'rejected')),
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    subtotal DECIMAL(15,2) DEFAULT 0.00,
    tax_amount DECIMAL(15,2) DEFAULT 0.00,
    shipping_charges DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) DEFAULT 0.00,
    payment_terms VARCHAR(100),
    notes TEXT,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL,
    received_quantity INTEGER DEFAULT 0,
    unit_price DECIMAL(15,2) NOT NULL,
    tax_percentage DECIMAL(5,2),
    total_amount DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_bookings_customer ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_technician ON bookings(technician_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_scheduled ON bookings(scheduled_start_time);
CREATE INDEX IF NOT EXISTS idx_bookings_number ON bookings(booking_number);
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status ON bookings(payment_status);
CREATE INDEX IF NOT EXISTS idx_payments_booking ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_invoices_booking ON invoices(booking_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_inventory_stock_product ON inventory_stock(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_stock_warehouse ON inventory_stock(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_product ON inventory_transactions(product_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_booking ON chat_conversations(booking_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation ON chat_messages(conversation_id);

-- RLS
DO $$
DECLARE t text;
BEGIN
  FOR t IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name NOT IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND EXISTS (SELECT 1 FROM information_schema.columns WHERE information_schema.columns.table_name = information_schema.tables.table_name AND column_name = 'id' AND data_type = 'uuid'))
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS "anon_all_%s" ON %I', t, t);
    EXECUTE format('CREATE POLICY "anon_all_%s" ON %I FOR ALL TO anon, authenticated USING (true) WITH CHECK (true)', t, t);
  END LOOP;
END $$;

-- Add policies for tables that already exist (from migration 001)
DO $$
DECLARE t text;
BEGIN
  FOR t IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS "anon_all_%s" ON %I', t, t);
    EXECUTE format('CREATE POLICY "anon_all_%s" ON %I FOR ALL TO anon, authenticated USING (true) WITH CHECK (true)', t, t);
  END LOOP;
END $$;

-- Triggers for new tables
DO $$
DECLARE t text;
BEGIN
  FOR t IN
    SELECT table_name
    FROM information_schema.columns
    WHERE column_name = 'updated_at'
    AND table_schema = 'public'
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS update_%s_updated_at ON %I', t, t);
    EXECUTE format('CREATE TRIGGER update_%s_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', t, t);
  END LOOP;
END $$;