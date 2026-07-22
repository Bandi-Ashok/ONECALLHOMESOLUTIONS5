/*
# OneCall Home Solutions — Modules 1-5: Auth, Customers, Properties, Technicians, Services

Creates foundational tables for the platform:
1. Module 1 — Authentication & Identity: users, user_profiles, roles, permissions, role_permissions, user_roles
2. Module 2 — Customer Management: customers, customer_addresses, customer_wallets, wallet_transactions, customer_feedback
3. Module 3 — Property Management: properties, property_rooms, property_appliances, property_media, property_service_history
4. Module 4 — Technician Management: technicians, technician_skills, technician_availability, technician_earnings, technician_ratings
5. Module 5 — Service Catalog: service_categories, services, service_pricing, service_packages, service_package_items, service_faqs

Security: RLS enabled on all tables with anon+authenticated access (API-first backend).
*/

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- MODULE 1: AUTHENTICATION & IDENTITY
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    username VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('customer', 'technician', 'vendor', 'admin', 'operations', 'super_admin', 'branch_manager', 'regional_manager', 'call_center_agent')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'deleted', 'pending_verification')),
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    profile_image_url TEXT,
    language_preference VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip TEXT,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    password_changed_at TIMESTAMP WITH TIME ZONE,
    requires_password_change BOOLEAN DEFAULT false,
    accepted_terms_at TIMESTAMP WITH TIME ZONE,
    accepted_privacy_at TIMESTAMP WITH TIME ZONE,
    marketing_consent BOOLEAN DEFAULT false,
    data_processing_consent BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    display_name VARCHAR(200),
    date_of_birth DATE,
    gender VARCHAR(20),
    alternate_email VARCHAR(255),
    alternate_phone VARCHAR(20),
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'India',
    pincode VARCHAR(10),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    bio TEXT,
    preferred_contact_method VARCHAR(20) DEFAULT 'email' CHECK (preferred_contact_method IN ('email', 'phone', 'sms', 'whatsapp', 'push')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200),
    description TEXT,
    role_type VARCHAR(50) NOT NULL,
    parent_role_id UUID REFERENCES roles(id),
    is_system BOOLEAN DEFAULT false,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) UNIQUE NOT NULL,
    display_name VARCHAR(200),
    description TEXT,
    module VARCHAR(100),
    resource VARCHAR(100),
    action VARCHAR(50) CHECK (action IN ('create', 'read', 'update', 'delete', 'manage', 'export', 'import', 'approve')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID REFERENCES users(id),
    UNIQUE(role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, role_id)
);

-- MODULE 2: CUSTOMER MANAGEMENT
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    customer_code VARCHAR(50) UNIQUE NOT NULL,
    customer_type VARCHAR(20) DEFAULT 'individual' CHECK (customer_type IN ('individual', 'corporate', 'government', 'senior_citizen', 'special_needs')),
    customer_tier VARCHAR(20) DEFAULT 'standard' CHECK (customer_tier IN ('standard', 'silver', 'gold', 'platinum', 'diamond')),
    total_bookings INTEGER DEFAULT 0,
    total_spent DECIMAL(15,2) DEFAULT 0.00,
    average_rating DECIMAL(3,2),
    lifetime_value DECIMAL(15,2) DEFAULT 0.00,
    credit_score DECIMAL(5,2),
    referral_code VARCHAR(20) UNIQUE,
    referred_by UUID REFERENCES customers(id),
    tags TEXT[],
    special_instructions TEXT,
    preferred_technicians UUID[],
    blocked_technicians UUID[],
    is_vip BOOLEAN DEFAULT false,
    source VARCHAR(50) DEFAULT 'direct' CHECK (source IN ('direct', 'referral', 'organic', 'paid', 'partnership', 'app_store', 'play_store')),
    acquisition_channel VARCHAR(100),
    churn_risk_score DECIMAL(3,2),
    last_service_date TIMESTAMP WITH TIME ZONE,
    next_amc_date TIMESTAMP WITH TIME ZONE,
    custom_attributes JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS customer_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    address_type VARCHAR(20) DEFAULT 'home' CHECK (address_type IN ('home', 'office', 'other', 'billing', 'shipping')),
    label VARCHAR(100),
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    landmark TEXT,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    pincode VARCHAR(10) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_default BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    access_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS customer_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    balance DECIMAL(15,2) DEFAULT 0.00,
    total_credited DECIMAL(15,2) DEFAULT 0.00,
    total_debited DECIMAL(15,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'INR',
    is_active BOOLEAN DEFAULT true,
    last_transaction_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL REFERENCES customer_wallets(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('credit', 'debit')),
    amount DECIMAL(15,2) NOT NULL,
    balance_before DECIMAL(15,2),
    balance_after DECIMAL(15,2),
    source VARCHAR(50) CHECK (source IN ('refund', 'referral', 'promotion', 'payment', 'adjustment', 'cashback')),
    reference_type VARCHAR(50),
    reference_id UUID,
    description TEXT,
    transaction_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS customer_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    booking_id UUID,
    feedback_type VARCHAR(20) CHECK (feedback_type IN ('complaint', 'suggestion', 'compliment', 'general', 'escalation')),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    title VARCHAR(500),
    description TEXT,
    attachments UUID[],
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed', 'escalated')),
    resolution TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id),
    satisfaction_score INTEGER CHECK (satisfaction_score BETWEEN 1 AND 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 3: PROPERTY MANAGEMENT
CREATE TABLE IF NOT EXISTS properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    property_name VARCHAR(200),
    property_type VARCHAR(50) CHECK (property_type IN ('apartment', 'villa', 'independent_house', 'office', 'shop', 'warehouse', 'hospital', 'school', 'hotel', 'other')),
    property_subtype VARCHAR(100),
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    landmark TEXT,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    pincode VARCHAR(10) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    total_area DECIMAL(10,2),
    area_unit VARCHAR(20) DEFAULT 'sqft',
    construction_year INTEGER,
    number_of_floors INTEGER,
    number_of_rooms INTEGER,
    number_of_bathrooms INTEGER,
    furnishing_status VARCHAR(20) CHECK (furnishing_status IN ('fully_furnished', 'semi_furnished', 'unfurnished')),
    property_age VARCHAR(50),
    property_condition VARCHAR(50),
    property_value DECIMAL(15,2),
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    access_instructions TEXT,
    gate_code VARCHAR(50),
    security_contact VARCHAR(200),
    custom_attributes JSONB,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS property_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    room_name VARCHAR(200),
    room_type VARCHAR(50) CHECK (room_type IN ('living_room', 'bedroom', 'kitchen', 'bathroom', 'balcony', 'study', 'dining_room', 'garage', 'basement', 'attic', 'laundry', 'other')),
    floor_number INTEGER,
    area DECIMAL(10,2),
    area_unit VARCHAR(20) DEFAULT 'sqft',
    has_ac BOOLEAN DEFAULT false,
    has_window BOOLEAN DEFAULT false,
    custom_attributes JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS property_appliances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    room_id UUID REFERENCES property_rooms(id) ON DELETE SET NULL,
    appliance_type VARCHAR(100),
    brand VARCHAR(100),
    model_number VARCHAR(100),
    serial_number VARCHAR(100),
    installation_date DATE,
    warranty_start_date DATE,
    warranty_end_date DATE,
    last_service_date DATE,
    next_service_date DATE,
    condition_status VARCHAR(20) CHECK (condition_status IN ('excellent', 'good', 'fair', 'poor', 'not_working')),
    amc_id UUID,
    notes TEXT,
    custom_attributes JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS property_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    media_type VARCHAR(20) CHECK (media_type IN ('image', 'video', 'document', 'floor_plan', '3d_tour')),
    file_id UUID,
    title VARCHAR(200),
    description TEXT,
    tags TEXT[],
    is_primary BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS property_service_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    booking_id UUID,
    service_type VARCHAR(100),
    service_date DATE,
    technician_id UUID,
    total_cost DECIMAL(15,2),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    feedback TEXT,
    issues_found TEXT,
    recommendations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 4: TECHNICIAN MANAGEMENT
CREATE TABLE IF NOT EXISTS technicians (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    technician_code VARCHAR(50) UNIQUE NOT NULL,
    employment_type VARCHAR(20) CHECK (employment_type IN ('full_time', 'part_time', 'contract', 'freelance', 'vendor_assigned')),
    vendor_id UUID,
    primary_skill VARCHAR(100),
    secondary_skills TEXT[],
    certification_level VARCHAR(20) DEFAULT 'junior' CHECK (certification_level IN ('trainee', 'junior', 'senior', 'master', 'specialist')),
    experience_years INTEGER DEFAULT 0,
    total_jobs_completed INTEGER DEFAULT 0,
    total_earnings DECIMAL(15,2) DEFAULT 0.00,
    average_rating DECIMAL(3,2),
    job_success_rate DECIMAL(5,2),
    on_time_rate DECIMAL(5,2),
    repeat_customer_rate DECIMAL(5,2),
    background_check_status VARCHAR(20) DEFAULT 'pending' CHECK (background_check_status IN ('pending', 'in_progress', 'cleared', 'failed')),
    background_check_date DATE,
    police_verification BOOLEAN DEFAULT false,
    police_verification_doc UUID,
    id_proof_type VARCHAR(50),
    id_proof_number VARCHAR(100),
    id_proof_doc UUID,
    address_proof_doc UUID,
    photo_id_doc UUID,
    bank_account_verified BOOLEAN DEFAULT false,
    pan_number VARCHAR(10),
    aadhar_number VARCHAR(12),
    gst_number VARCHAR(15),
    current_status VARCHAR(20) DEFAULT 'offline' CHECK (current_status IN ('online', 'offline', 'on_job', 'break', 'training', 'leave', 'suspended')),
    current_latitude DECIMAL(10,8),
    current_longitude DECIMAL(11,8),
    last_location_update TIMESTAMP WITH TIME ZONE,
    service_radius_km DECIMAL(5,2) DEFAULT 10.00,
    max_daily_jobs INTEGER DEFAULT 8,
    preferred_areas UUID[],
    shift_start_time TIME,
    shift_end_time TIME,
    working_days INTEGER[] DEFAULT '{1,2,3,4,5,6}',
    tools_owned TEXT[],
    vehicle_type VARCHAR(50),
    vehicle_number VARCHAR(20),
    has_driving_license BOOLEAN DEFAULT false,
    driving_license_number VARCHAR(50),
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    blood_group VARCHAR(5),
    medical_conditions TEXT,
    insurance_active BOOLEAN DEFAULT false,
    insurance_policy_number VARCHAR(100),
    insurance_expiry_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS technician_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    skill_category VARCHAR(100),
    proficiency_level VARCHAR(20) DEFAULT 'intermediate' CHECK (proficiency_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
    years_of_experience DECIMAL(4,1),
    certified BOOLEAN DEFAULT false,
    certification_name VARCHAR(200),
    certification_date DATE,
    certification_expiry DATE,
    certification_doc UUID,
    last_used_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(technician_id, skill_name)
);

CREATE TABLE IF NOT EXISTS technician_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    availability_type VARCHAR(20) DEFAULT 'available' CHECK (availability_type IN ('available', 'unavailable', 'partial', 'on_leave', 'training')),
    reason TEXT,
    slots_available INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(technician_id, date)
);

CREATE TABLE IF NOT EXISTS technician_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    booking_id UUID,
    earning_type VARCHAR(50) CHECK (earning_type IN ('service_fee', 'tip', 'bonus', 'incentive', 'referral', 'overtime', 'adjustment')),
    amount DECIMAL(15,2) NOT NULL,
    commission_percentage DECIMAL(5,2),
    commission_amount DECIMAL(15,2),
    net_amount DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'INR',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processed', 'paid', 'cancelled', 'disputed')),
    processed_at TIMESTAMP WITH TIME ZONE,
    payment_reference VARCHAR(200),
    description TEXT,
    earning_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS technician_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    booking_id UUID,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    punctuality_rating INTEGER CHECK (punctuality_rating BETWEEN 1 AND 5),
    quality_rating INTEGER CHECK (quality_rating BETWEEN 1 AND 5),
    communication_rating INTEGER CHECK (communication_rating BETWEEN 1 AND 5),
    professionalism_rating INTEGER CHECK (professionalism_rating BETWEEN 1 AND 5),
    value_rating INTEGER CHECK (value_rating BETWEEN 1 AND 5),
    review_text TEXT,
    review_title VARCHAR(200),
    is_anonymous BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    admin_response TEXT,
    admin_responded_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'published' CHECK (status IN ('published', 'hidden', 'flagged', 'removed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 5: SERVICE CATALOG
CREATE TABLE IF NOT EXISTS service_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    description TEXT,
    parent_category_id UUID REFERENCES service_categories(id),
    icon_url TEXT,
    image_url TEXT,
    banner_url TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    meta_title VARCHAR(500),
    meta_description TEXT,
    meta_keywords TEXT,
    custom_attributes JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES service_categories(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    description TEXT,
    short_description VARCHAR(500),
    service_code VARCHAR(50) UNIQUE,
    service_type VARCHAR(50) CHECK (service_type IN ('one_time', 'recurring', 'subscription', 'amc', 'emergency', 'inspection', 'consultation', 'installation', 'repair', 'maintenance')),
    estimated_duration_minutes INTEGER,
    base_price DECIMAL(15,2),
    minimum_price DECIMAL(15,2),
    maximum_price DECIMAL(15,2),
    price_type VARCHAR(20) DEFAULT 'fixed' CHECK (price_type IN ('fixed', 'hourly', 'daily', 'custom', 'quote_based', 'range')),
    currency VARCHAR(3) DEFAULT 'INR',
    tax_percentage DECIMAL(5,2) DEFAULT 18.00,
    requires_inspection BOOLEAN DEFAULT false,
    requires_material BOOLEAN DEFAULT false,
    is_emergency_service BOOLEAN DEFAULT false,
    emergency_surcharge_percentage DECIMAL(5,2),
    warranty_days INTEGER DEFAULT 30,
    minimum_experience_required INTEGER DEFAULT 0,
    required_skills TEXT[],
    tools_required TEXT[],
    safety_equipment_required TEXT[],
    pre_service_checklist TEXT[],
    post_service_checklist TEXT[],
    before_photo_required BOOLEAN DEFAULT false,
    after_photo_required BOOLEAN DEFAULT false,
    service_instructions TEXT,
    safety_instructions TEXT,
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    is_popular BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    tags TEXT[],
    meta_title VARCHAR(500),
    meta_description TEXT,
    meta_keywords TEXT,
    custom_attributes JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS service_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    customer_tier VARCHAR(20),
    price DECIMAL(15,2) NOT NULL,
    minimum_price DECIMAL(15,2),
    maximum_price DECIMAL(15,2),
    discount_percentage DECIMAL(5,2),
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS service_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    package_code VARCHAR(50) UNIQUE,
    package_type VARCHAR(50) CHECK (package_type IN ('bundle', 'combo', 'subscription', 'amc', 'annual')),
    total_price DECIMAL(15,2) NOT NULL,
    discount_percentage DECIMAL(5,2),
    discounted_price DECIMAL(15,2),
    validity_days INTEGER,
    max_bookings INTEGER,
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    terms_and_conditions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS service_package_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_id UUID NOT NULL REFERENCES service_packages(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(15,2),
    total_price DECIMAL(15,2),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS service_faqs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_services_category ON services(category_id);
CREATE INDEX IF NOT EXISTS idx_services_active ON services(is_active);
CREATE INDEX IF NOT EXISTS idx_services_slug ON services(slug);
CREATE INDEX IF NOT EXISTS idx_technicians_user ON technicians(user_id);
CREATE INDEX IF NOT EXISTS idx_technicians_status ON technicians(current_status);
CREATE INDEX IF NOT EXISTS idx_technician_availability_date ON technician_availability(date);
CREATE INDEX IF NOT EXISTS idx_technician_availability_tech ON technician_availability(technician_id);

-- RLS + POLICIES
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

-- DEFAULT DATA
INSERT INTO roles (name, display_name, description, role_type, is_system) VALUES
('super_admin', 'Super Administrator', 'Full system access', 'super_admin', true),
('admin', 'Administrator', 'Administrative access', 'admin', true),
('operations_manager', 'Operations Manager', 'Operations management', 'operations', true),
('branch_manager', 'Branch Manager', 'Branch level management', 'branch_manager', true),
('regional_manager', 'Regional Manager', 'Regional management', 'regional_manager', true),
('technician', 'Technician', 'Service technician', 'technician', true),
('senior_technician', 'Senior Technician', 'Senior service technician', 'technician', true),
('customer', 'Customer', 'Platform customer', 'customer', true),
('vendor', 'Vendor', 'Vendor/Partner', 'vendor', true),
('call_center_agent', 'Call Center Agent', 'Customer support agent', 'call_center_agent', true)
ON CONFLICT (name) DO NOTHING;

INSERT INTO permissions (name, display_name, module, resource, action) VALUES
('user.create', 'Create User', 'users', 'user', 'create'),
('user.read', 'View User', 'users', 'user', 'read'),
('user.update', 'Update User', 'users', 'user', 'update'),
('user.delete', 'Delete User', 'users', 'user', 'delete'),
('booking.create', 'Create Booking', 'bookings', 'booking', 'create'),
('booking.read', 'View Booking', 'bookings', 'booking', 'read'),
('booking.update', 'Update Booking', 'bookings', 'booking', 'update'),
('booking.delete', 'Delete Booking', 'bookings', 'booking', 'delete'),
('booking.assign', 'Assign Booking', 'bookings', 'booking', 'manage'),
('payment.process', 'Process Payment', 'payments', 'payment', 'manage'),
('payment.refund', 'Refund Payment', 'payments', 'payment', 'manage'),
('inventory.manage', 'Manage Inventory', 'inventory', 'inventory', 'manage'),
('analytics.view', 'View Analytics', 'analytics', 'analytics', 'read'),
('analytics.export', 'Export Analytics', 'analytics', 'analytics', 'export'),
('settings.manage', 'Manage Settings', 'settings', 'settings', 'manage'),
('security.manage', 'Manage Security', 'security', 'security', 'manage'),
('audit.view', 'View Audit Logs', 'audit', 'audit', 'read')
ON CONFLICT (name) DO NOTHING;

-- updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

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