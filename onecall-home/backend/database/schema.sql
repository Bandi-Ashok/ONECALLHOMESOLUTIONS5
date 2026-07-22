-- ============================================
-- URBAN SERVICES ENTERPRISE PLATFORM
-- Complete Database Schema
-- Version: Enterprise 1.0
-- ============================================

-- Create Database
CREATE DATABASE urban_services_enterprise;
\c urban_services_enterprise;

-- Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "hstore";

-- ============================================
-- MODULE 1: AUTHENTICATION & IDENTITY
-- ============================================

-- Users master table
CREATE TABLE users (
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
    last_login_ip INET,
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

-- User profiles (extended info)
CREATE TABLE user_profiles (
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
    location GEOGRAPHY(POINT, 4326),
    bio TEXT,
    preferred_contact_method VARCHAR(20) DEFAULT 'email' CHECK (preferred_contact_method IN ('email', 'phone', 'sms', 'whatsapp', 'push')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Roles and permissions
CREATE TABLE roles (
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

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) UNIQUE NOT NULL,
    display_name VARCHAR(200),
    description TEXT,
    module VARCHAR(100),
    resource VARCHAR(100),
    action VARCHAR(50) CHECK (action IN ('create', 'read', 'update', 'delete', 'manage', 'export', 'import', 'approve')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID REFERENCES users(id),
    UNIQUE(role_id, permission_id)
);

CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, role_id)
);

-- ============================================
-- MODULE 2: CUSTOMER MANAGEMENT
-- ============================================

CREATE TABLE customers (
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

CREATE TABLE customer_addresses (
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
    location GEOGRAPHY(POINT, 4326),
    is_default BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    access_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE customer_wallets (
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

CREATE TABLE wallet_transactions (
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

CREATE TABLE customer_feedback (
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

-- ============================================
-- MODULE 3: PROPERTY MANAGEMENT
-- ============================================

CREATE TABLE properties (
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
    location GEOGRAPHY(POINT, 4326),
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

CREATE TABLE property_rooms (
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

CREATE TABLE property_appliances (
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

CREATE TABLE property_media (
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

CREATE TABLE property_service_history (
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

-- ============================================
-- MODULE 4: TECHNICIAN MANAGEMENT
-- ============================================

CREATE TABLE technicians (
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
    current_location GEOGRAPHY(POINT, 4326),
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

CREATE TABLE technician_skills (
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

CREATE TABLE technician_availability (
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

CREATE TABLE technician_earnings (
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

CREATE TABLE technician_ratings (
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

-- ============================================
-- MODULE 5: SERVICE CATALOG
-- ============================================

CREATE TABLE service_categories (
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

CREATE TABLE services (
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

CREATE TABLE service_pricing (
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

CREATE TABLE service_packages (
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

CREATE TABLE service_package_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_id UUID NOT NULL REFERENCES service_packages(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(15,2),
    total_price DECIMAL(15,2),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE service_faqs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 6: BOOKING MANAGEMENT
-- ============================================

CREATE TABLE bookings (
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
    service_location GEOGRAPHY(POINT, 4326),
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

CREATE TABLE booking_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_by UUID REFERENCES users(id),
    changed_by_type VARCHAR(20) CHECK (changed_by_type IN ('system', 'customer', 'technician', 'admin', 'vendor')),
    change_reason TEXT,
    change_notes TEXT,
    location GEOGRAPHY(POINT, 4326),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE booking_reschedules (
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

CREATE TABLE booking_quotes (
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

CREATE TABLE quote_items (
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

-- ============================================
-- MODULE 7: DISPATCH & SCHEDULING
-- ============================================

CREATE TABLE dispatch_queue (
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

CREATE TABLE scheduling_slots (
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

CREATE TABLE route_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    plan_status VARCHAR(20) DEFAULT 'created' CHECK (plan_status IN ('created', 'in_progress', 'completed', 'cancelled')),
    total_distance_km DECIMAL(10,2),
    total_duration_minutes INTEGER,
    total_jobs INTEGER,
    completed_jobs INTEGER DEFAULT 0,
    route_geometry GEOGRAPHY(LINESTRING, 4326),
    waypoints JSONB,
    optimization_score DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE route_stops (
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
    location GEOGRAPHY(POINT, 4326),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'skipped', 'arrived', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 8: PAYMENT & BILLING
-- ============================================

CREATE TABLE payments (
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

CREATE TABLE invoices (
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

CREATE TABLE invoice_items (
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

CREATE TABLE refunds (
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

CREATE TABLE payment_methods (
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

-- ============================================
-- MODULE 9: NOTIFICATION & COMMUNICATION
-- ============================================

CREATE TABLE notification_templates (
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

CREATE TABLE notifications (
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

CREATE TABLE notification_preferences (
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

CREATE TABLE sms_logs (
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

CREATE TABLE email_logs (
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

CREATE TABLE chat_conversations (
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

CREATE TABLE chat_messages (
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

-- ============================================
-- MODULE 10: INVENTORY & PRODUCT MANAGEMENT
-- ============================================

CREATE TABLE products (
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

CREATE TABLE inventory_warehouses (
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
    location GEOGRAPHY(POINT, 4326),
    warehouse_type VARCHAR(20) CHECK (warehouse_type IN ('main', 'regional', 'local', 'van', 'technician')),
    technician_id UUID REFERENCES technicians(id),
    is_active BOOLEAN DEFAULT true,
    contact_person VARCHAR(200),
    contact_phone VARCHAR(20),
    operating_hours JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE inventory_stock (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES inventory_warehouses(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 0,
    allocated_quantity INTEGER DEFAULT 0,
    available_quantity INTEGER GENERATED ALWAYS AS (quantity - allocated_quantity) STORED,
    damaged_quantity INTEGER DEFAULT 0,
    expiry_date DATE,
    batch_number VARCHAR(100),
    last_counted_at TIMESTAMP WITH TIME ZONE,
    last_counted_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(product_id, warehouse_id, batch_number)
);

CREATE TABLE inventory_transactions (
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

CREATE TABLE purchase_orders (
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

CREATE TABLE purchase_order_items (
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

-- ============================================
-- MODULE 11: CRM
-- ============================================

CREATE TABLE crm_leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_number VARCHAR(50) UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    alternate_phone VARCHAR(20),
    source VARCHAR(50) CHECK (source IN ('website', 'app', 'referral', 'social_media', 'google_ads', 'facebook_ads', 'organic', 'event', 'call_in', 'walk_in', 'partner')),
    source_detail TEXT,
    lead_type VARCHAR(50) CHECK (lead_type IN ('residential', 'commercial', 'corporate', 'government')),
    service_interest UUID[],
    property_type VARCHAR(50),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    budget_range JSONB,
    timeline VARCHAR(50),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'hot')),
    status VARCHAR(20) DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'qualified', 'proposal_sent', 'negotiation', 'won', 'lost', 'disqualified', 'junk')),
    assigned_to UUID REFERENCES users(id),
    last_contacted_at TIMESTAMP WITH TIME ZONE,
    next_follow_up TIMESTAMP WITH TIME ZONE,
    converted_to_customer_id UUID REFERENCES customers(id),
    conversion_date TIMESTAMP WITH TIME ZONE,
    lost_reason TEXT,
    notes TEXT,
    custom_fields JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE crm_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID REFERENCES crm_leads(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) CHECK (activity_type IN ('call', 'email', 'meeting', 'site_visit', 'demo', 'proposal', 'follow_up', 'note', 'task')),
    subject VARCHAR(500),
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled', 'rescheduled')),
    scheduled_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    outcome TEXT,
    performed_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE crm_deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    deal_number VARCHAR(50) UNIQUE,
    lead_id UUID REFERENCES crm_leads(id),
    customer_id UUID REFERENCES customers(id),
    deal_name VARCHAR(200),
    deal_value DECIMAL(15,2),
    expected_close_date DATE,
    actual_close_date DATE,
    stage VARCHAR(50) CHECK (stage IN ('prospecting', 'qualification', 'needs_analysis', 'proposal', 'negotiation', 'closed_won', 'closed_lost')),
    probability_percentage INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'won', 'lost', 'abandoned')),
    won_reason TEXT,
    lost_reason TEXT,
    competitor_info TEXT,
    assigned_to UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 12: VENDOR & PARTNER MANAGEMENT
-- ============================================

CREATE TABLE vendors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_code VARCHAR(50) UNIQUE NOT NULL,
    company_name VARCHAR(200) NOT NULL,
    display_name VARCHAR(200),
    vendor_type VARCHAR(50) CHECK (vendor_type IN ('individual', 'company', 'partnership', 'llp', 'private_limited', 'public_limited', 'proprietorship')),
    category VARCHAR(50) CHECK (category IN ('service_provider', 'product_supplier', 'equipment_supplier', 'logistics', 'training', 'insurance', 'technology', 'other')),
    primary_contact_name VARCHAR(200),
    primary_contact_email VARCHAR(255),
    primary_contact_phone VARCHAR(20),
    alternate_contact_name VARCHAR(200),
    alternate_contact_phone VARCHAR(20),
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'India',
    pincode VARCHAR(10),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    location GEOGRAPHY(POINT, 4326),
    website VARCHAR(255),
    gst_number VARCHAR(15),
    pan_number VARCHAR(10),
    tan_number VARCHAR(10),
    cin_number VARCHAR(21),
    msme_registered BOOLEAN DEFAULT false,
    msme_number VARCHAR(50),
    bank_account_name VARCHAR(200),
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(50),
    bank_ifsc_code VARCHAR(20),
    payment_terms VARCHAR(100),
    credit_limit DECIMAL(15,2),
    credit_period_days INTEGER,
    commission_percentage DECIMAL(5,2),
    commission_type VARCHAR(20) CHECK (commission_type IN ('fixed', 'percentage', 'tiered', 'hybrid')),
    rating DECIMAL(3,2),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'blacklisted', 'under_review')),
    onboarding_date DATE,
    contract_start_date DATE,
    contract_end_date DATE,
    contract_document UUID,
    insurance_certificate UUID,
    insurance_expiry DATE,
    services_offered UUID[],
    service_cities TEXT[],
    minimum_order_value DECIMAL(15,2),
    delivery_capability VARCHAR(50),
    quality_certifications TEXT[],
    notes TEXT,
    custom_attributes JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE vendor_technicians (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    assignment_date DATE NOT NULL,
    assignment_status VARCHAR(20) DEFAULT 'active' CHECK (assignment_status IN ('active', 'inactive', 'suspended', 'transferred')),
    vendor_employee_id VARCHAR(50),
    contract_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, technician_id)
);

CREATE TABLE vendor_invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
    invoice_number VARCHAR(100) NOT NULL,
    vendor_invoice_number VARCHAR(100),
    invoice_date DATE NOT NULL,
    due_date DATE,
    subtotal DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) NOT NULL,
    amount_paid DECIMAL(15,2) DEFAULT 0.00,
    balance_due DECIMAL(15,2),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'partial', 'paid', 'disputed', 'cancelled')),
    payment_reference VARCHAR(200),
    payment_date DATE,
    notes TEXT,
    approved_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 13: ADMIN, OPERATIONS & WORKFORCE
-- ============================================

CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    code VARCHAR(50) UNIQUE,
    description TEXT,
    parent_department_id UUID REFERENCES departments(id),
    head_of_department UUID REFERENCES users(id),
    budget DECIMAL(15,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    employee_code VARCHAR(50) UNIQUE NOT NULL,
    department_id UUID REFERENCES departments(id),
    designation VARCHAR(200),
    reporting_manager UUID REFERENCES employees(id),
    employment_type VARCHAR(20) CHECK (employment_type IN ('full_time', 'part_time', 'contract', 'intern', 'consultant')),
    date_of_joining DATE,
    date_of_confirmation DATE,
    date_of_leaving DATE,
    leaving_reason TEXT,
    salary_grade VARCHAR(50),
    current_salary DECIMAL(15,2),
    bank_account_number VARCHAR(50),
    bank_ifsc VARCHAR(20),
    pan_number VARCHAR(10),
    aadhar_number VARCHAR(12),
    pf_number VARCHAR(50),
    esi_number VARCHAR(50),
    uan_number VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    custom_attributes JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE shift_management (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_name VARCHAR(200),
    shift_code VARCHAR(50),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    grace_period_minutes INTEGER DEFAULT 15,
    break_duration_minutes INTEGER DEFAULT 30,
    total_working_hours DECIMAL(4,2),
    is_night_shift BOOLEAN DEFAULT false,
    night_shift_allowance_percentage DECIMAL(5,2),
    applicable_days INTEGER[] DEFAULT '{1,2,3,4,5,6}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE employee_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    shift_id UUID REFERENCES shift_management(id),
    scheduled_in_time TIME,
    scheduled_out_time TIME,
    actual_in_time TIMESTAMP WITH TIME ZONE,
    actual_out_time TIMESTAMP WITH TIME ZONE,
    in_location GEOGRAPHY(POINT, 4326),
    out_location GEOGRAPHY(POINT, 4326),
    status VARCHAR(20) DEFAULT 'absent' CHECK (status IN ('present', 'absent', 'half_day', 'late', 'on_leave', 'holiday', 'week_off')),
    total_hours_worked DECIMAL(5,2),
    overtime_hours DECIMAL(5,2),
    late_by_minutes INTEGER,
    early_departure_minutes INTEGER,
    remarks TEXT,
    verified_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(employee_id, date)
);

CREATE TABLE leave_management (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type VARCHAR(50) CHECK (leave_type IN ('sick', 'casual', 'earned', 'maternity', 'paternity', 'bereavement', 'unpaid', 'comp_off', 'other')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days DECIMAL(4,1) NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    attachment UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 14: ANALYTICS & BUSINESS INTELLIGENCE
-- ============================================

CREATE TABLE analytics_dashboards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    dashboard_type VARCHAR(50) CHECK (dashboard_type IN ('system', 'custom', 'shared', 'template')),
    owner_id UUID REFERENCES users(id),
    layout JSONB,
    filters JSONB,
    refresh_interval_seconds INTEGER DEFAULT 300,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE analytics_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_code VARCHAR(100) UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    report_type VARCHAR(50) CHECK (report_type IN ('sales', 'operations', 'financial', 'customer', 'technician', 'inventory', 'marketing', 'compliance', 'custom')),
    query_definition JSONB,
    parameters JSONB,
    visualization_type VARCHAR(50),
    schedule_cron VARCHAR(100),
    recipients UUID[],
    format VARCHAR(20) DEFAULT 'pdf' CHECK (format IN ('pdf', 'excel', 'csv', 'html', 'json')),
    last_run_at TIMESTAMP WITH TIME ZONE,
    next_run_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(200) NOT NULL,
    user_id UUID REFERENCES users(id),
    session_id VARCHAR(200),
    device_id VARCHAR(200),
    event_data JSONB,
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE kpi_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_name VARCHAR(200) NOT NULL,
    kpi_code VARCHAR(100) UNIQUE,
    description TEXT,
    category VARCHAR(100),
    calculation_method TEXT,
    unit VARCHAR(50),
    target_value DECIMAL(15,2),
    minimum_value DECIMAL(15,2),
    maximum_value DECIMAL(15,2),
    warning_threshold DECIMAL(15,2),
    critical_threshold DECIMAL(15,2),
    frequency VARCHAR(20) DEFAULT 'daily' CHECK (frequency IN ('realtime', 'hourly', 'daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE kpi_values (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL REFERENCES kpi_definitions(id) ON DELETE CASCADE,
    value DECIMAL(15,2) NOT NULL,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    dimension_type VARCHAR(100),
    dimension_value VARCHAR(200),
    metadata JSONB,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(kpi_id, period_start, period_end, dimension_type, dimension_value)
);

-- ============================================
-- MODULE 15: AI & AUTOMATION
-- ============================================

CREATE TABLE ai_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(200) NOT NULL,
    model_version VARCHAR(50),
    model_type VARCHAR(50) CHECK (model_type IN ('pricing', 'recommendation', 'routing', 'fraud_detection', 'sentiment', 'chatbot', 'prediction', 'classification', 'computer_vision')),
    description TEXT,
    algorithm VARCHAR(100),
    accuracy DECIMAL(5,4),
    precision_score DECIMAL(5,4),
    recall_score DECIMAL(5,4),
    f1_score DECIMAL(5,4),
    training_data_version VARCHAR(50),
    trained_at TIMESTAMP WITH TIME ZONE,
    trained_by UUID REFERENCES users(id),
    model_metadata JSONB,
    model_file_url TEXT,
    is_active BOOLEAN DEFAULT false,
    is_deployed BOOLEAN DEFAULT false,
    deployed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE ai_predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
    prediction_type VARCHAR(100),
    input_data JSONB,
    predicted_value JSONB,
    confidence_score DECIMAL(5,4),
    actual_value JSONB,
    is_accurate BOOLEAN,
    feedback_provided BOOLEAN DEFAULT false,
    user_id UUID REFERENCES users(id),
    booking_id UUID REFERENCES bookings(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE ai_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    recommendation_type VARCHAR(50) CHECK (recommendation_type IN ('service', 'technician', 'product', 'package', 'content', 'upsell', 'cross_sell')),
    context JSONB,
    recommended_items JSONB,
    confidence_score DECIMAL(5,4),
    served_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    clicked_at TIMESTAMP WITH TIME ZONE,
    converted_at TIMESTAMP WITH TIME ZONE,
    is_converted BOOLEAN DEFAULT false,
    conversion_reference VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE automation_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(200) NOT NULL,
    rule_code VARCHAR(100) UNIQUE,
    description TEXT,
    trigger_type VARCHAR(50) CHECK (trigger_type IN ('event', 'schedule', 'condition', 'webhook', 'manual')),
    trigger_conditions JSONB,
    actions JSONB,
    priority INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    last_triggered_at TIMESTAMP WITH TIME ZONE,
    execution_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE automation_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES automation_rules(id) ON DELETE CASCADE,
    trigger_event JSONB,
    execution_status VARCHAR(20) CHECK (execution_status IN ('success', 'failed', 'partial', 'skipped')),
    error_message TEXT,
    execution_duration_ms INTEGER,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 16: PLATFORM ADMINISTRATION
-- ============================================

CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key VARCHAR(200) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(50) DEFAULT 'string' CHECK (setting_type IN ('string', 'integer', 'boolean', 'json', 'decimal', 'array')),
    description TEXT,
    is_encrypted BOOLEAN DEFAULT false,
    is_public BOOLEAN DEFAULT false,
    module VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flag_code VARCHAR(100) UNIQUE NOT NULL,
    flag_name VARCHAR(200),
    description TEXT,
    is_enabled BOOLEAN DEFAULT false,
    rollout_percentage INTEGER DEFAULT 0,
    target_user_types TEXT[],
    target_cities TEXT[],
    target_pincodes TEXT[],
    dependencies JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE business_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(200) UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    config_type VARCHAR(50),
    description TEXT,
    applicable_scope VARCHAR(20) DEFAULT 'global' CHECK (applicable_scope IN ('global', 'city', 'branch', 'service', 'customer_type')),
    scope_value VARCHAR(200),
    effective_from TIMESTAMP WITH TIME ZONE,
    effective_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE holiday_calendar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_name VARCHAR(200) NOT NULL,
    holiday_date DATE NOT NULL,
    holiday_type VARCHAR(20) CHECK (holiday_type IN ('national', 'state', 'local', 'company', 'optional')),
    applicable_states TEXT[],
    applicable_cities TEXT[],
    is_recurring_yearly BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(holiday_date, holiday_name)
);

CREATE TABLE business_hours (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_working_day BOOLEAN DEFAULT true,
    applicable_city VARCHAR(100),
    applicable_branch VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE cities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    district VARCHAR(100),
    region_id UUID,
    is_active BOOLEAN DEFAULT true,
    is_tier_1 BOOLEAN DEFAULT false,
    population INTEGER,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    timezone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE service_pincodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pincode VARCHAR(10) NOT NULL,
    city_id UUID NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    area_name VARCHAR(200),
    is_serviceable BOOLEAN DEFAULT true,
    service_fees JSONB,
    delivery_available BOOLEAN DEFAULT true,
    minimum_order_value DECIMAL(15,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(pincode)
);

CREATE TABLE sla_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(200) NOT NULL,
    policy_code VARCHAR(100) UNIQUE,
    service_id UUID REFERENCES services(id),
    customer_tier VARCHAR(20),
    priority VARCHAR(20),
    response_time_minutes INTEGER,
    resolution_time_minutes INTEGER,
    escalation_time_minutes INTEGER,
    max_reschedule_count INTEGER DEFAULT 3,
    penalty_percentage DECIMAL(5,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE tax_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tax_name VARCHAR(200),
    tax_code VARCHAR(50) UNIQUE,
    tax_type VARCHAR(20) CHECK (tax_type IN ('cgst', 'sgst', 'igst', 'cess', 'vat', 'service_tax')),
    tax_percentage DECIMAL(5,2) NOT NULL,
    applicable_category VARCHAR(100),
    hsn_sac_code_prefix VARCHAR(10),
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 17: SECURITY & IDENTITY MANAGEMENT
-- ============================================

CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(500) UNIQUE NOT NULL,
    refresh_token VARCHAR(500),
    device_id VARCHAR(200),
    device_type VARCHAR(50),
    device_name VARCHAR(200),
    os_name VARCHAR(100),
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    ip_address INET,
    user_agent TEXT,
    location GEOGRAPHY(POINT, 4326),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_active BOOLEAN DEFAULT true,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    logged_out_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
    api_key VARCHAR(500) UNIQUE NOT NULL,
    api_secret_hash VARCHAR(500),
    key_name VARCHAR(200),
    environment VARCHAR(20) DEFAULT 'production' CHECK (environment IN ('development', 'staging', 'production')),
    permissions JSONB,
    rate_limit_per_minute INTEGER DEFAULT 60,
    rate_limit_per_day INTEGER DEFAULT 10000,
    ip_whitelist INET[],
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE device_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(200) UNIQUE,
    device_type VARCHAR(50),
    device_name VARCHAR(200),
    push_token VARCHAR(500),
    voip_token VARCHAR(500),
    platform VARCHAR(50) CHECK (platform IN ('ios', 'android', 'web', 'pwa')),
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mfa_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mfa_type VARCHAR(20) CHECK (mfa_type IN ('totp', 'sms', 'email', 'biometric', 'hardware_key')),
    is_enabled BOOLEAN DEFAULT false,
    secret_key VARCHAR(200),
    backup_codes TEXT[],
    verified_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, mfa_type)
);

CREATE TABLE login_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    email VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    attempt_status VARCHAR(20) CHECK (attempt_status IN ('success', 'failed', 'blocked', 'mfa_required', 'mfa_failed')),
    failure_reason VARCHAR(100),
    location GEOGRAPHY(POINT, 4326),
    device_fingerprint VARCHAR(500),
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE password_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES users(id),
    ip_address INET,
    description TEXT,
    severity VARCHAR(20) DEFAULT 'low' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    event_data JSONB,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id),
    resolution_notes TEXT
);

CREATE TABLE blocked_ips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ip_address INET NOT NULL,
    ip_range CIDR,
    reason TEXT,
    blocked_by UUID REFERENCES users(id),
    blocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(ip_address)
);

-- ============================================
-- MODULE 18: FILE & DOCUMENT MANAGEMENT
-- ============================================

CREATE TABLE files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_name VARCHAR(500) NOT NULL,
    original_name VARCHAR(500),
    file_path TEXT NOT NULL,
    file_url TEXT,
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    file_extension VARCHAR(20),
    file_type VARCHAR(50) CHECK (file_type IN ('image', 'video', 'document', 'audio', 'archive', 'other')),
    checksum VARCHAR(200),
    storage_provider VARCHAR(50) DEFAULT 'local' CHECK (storage_provider IN ('local', 's3', 'gcs', 'azure', 'cloudfront')),
    storage_bucket VARCHAR(200),
    storage_path TEXT,
    folder_id UUID,
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_public BOOLEAN DEFAULT false,
    is_encrypted BOOLEAN DEFAULT false,
    encryption_key_id VARCHAR(200),
    metadata JSONB,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE folders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(500) NOT NULL,
    parent_folder_id UUID REFERENCES folders(id),
    folder_path TEXT,
    created_by UUID REFERENCES users(id),
    is_system BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE file_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    file_path TEXT NOT NULL,
    file_size_bytes BIGINT,
    checksum VARCHAR(200),
    uploaded_by UUID REFERENCES users(id),
    change_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(file_id, version_number)
);

CREATE TABLE file_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    role_id UUID REFERENCES roles(id),
    permission_type VARCHAR(20) CHECK (permission_type IN ('read', 'write', 'delete', 'share', 'download')),
    granted_by UUID REFERENCES users(id),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(file_id, user_id, role_id, permission_type)
);

CREATE TABLE media_library (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID UNIQUE REFERENCES files(id) ON DELETE CASCADE,
    title VARCHAR(500),
    alt_text TEXT,
    caption TEXT,
    media_category VARCHAR(100),
    width INTEGER,
    height INTEGER,
    duration_seconds INTEGER,
    thumbnail_url TEXT,
    is_featured BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE document_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    code VARCHAR(100) UNIQUE,
    description TEXT,
    parent_category_id UUID REFERENCES document_categories(id),
    allowed_mime_types TEXT[],
    max_file_size_bytes BIGINT,
    is_required BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 19: SEARCH & LOCATION SERVICES
-- ============================================

CREATE TABLE search_index (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    searchable_type VARCHAR(100),
    searchable_id UUID,
    title VARCHAR(500),
    description TEXT,
    keywords TEXT,
    search_vector TSVECTOR,
    category VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    rating DECIMAL(3,2),
    popularity_score DECIMAL(10,2),
    indexed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_search_vector ON search_index USING GIN(search_vector);

CREATE TABLE geofence_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_name VARCHAR(200) NOT NULL,
    zone_code VARCHAR(100) UNIQUE,
    zone_type VARCHAR(50) CHECK (zone_type IN ('service_area', 'no_service', 'premium', 'restricted', 'high_demand')),
    boundary GEOGRAPHY(POLYGON, 4326) NOT NULL,
    center_point GEOGRAPHY(POINT, 4326),
    radius_km DECIMAL(10,2),
    city VARCHAR(100),
    state VARCHAR(100),
    properties JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE service_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) CHECK (entity_type IN ('technician', 'vendor', 'customer', 'branch', 'warehouse')),
    entity_id UUID NOT NULL,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    accuracy_meters DECIMAL(10,2),
    bearing DECIMAL(5,2),
    speed_kmh DECIMAL(5,2),
    altitude_meters DECIMAL(10,2),
    is_current BOOLEAN DEFAULT true,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE map_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key VARCHAR(500) UNIQUE NOT NULL,
    map_provider VARCHAR(50),
    request_type VARCHAR(50),
    request_parameters JSONB,
    response_data JSONB,
    tile_data BYTEA,
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    hit_count INTEGER DEFAULT 1
);

CREATE TABLE location_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    accuracy_meters DECIMAL(10,2),
    activity_type VARCHAR(50),
    battery_level DECIMAL(5,2),
    network_type VARCHAR(50),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 20: AUDIT & COMPLIANCE
-- ============================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(200) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(20) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'LOGIN', 'LOGOUT', 'EXPORT', 'IMPORT')),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    performed_by UUID REFERENCES users(id),
    performed_by_type VARCHAR(50),
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    request_id UUID,
    application_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    activity_type VARCHAR(100) NOT NULL,
    activity_description TEXT,
    entity_type VARCHAR(100),
    entity_id UUID,
    metadata JSONB,
    ip_address INET,
    user_agent TEXT,
    duration_ms INTEGER,
    status VARCHAR(20) DEFAULT 'success' CHECK (status IN ('success', 'failed', 'error', 'warning')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE compliance_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    compliance_type VARCHAR(100),
    regulation_name VARCHAR(200),
    description TEXT,
    compliance_status VARCHAR(20) DEFAULT 'pending' CHECK (compliance_status IN ('compliant', 'non_compliant', 'pending', 'exempt', 'in_progress')),
    last_audit_date DATE,
    next_audit_date DATE,
    auditor_id UUID REFERENCES users(id),
    audit_findings TEXT,
    remediation_plan TEXT,
    remediation_deadline DATE,
    documents UUID[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE data_retention (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    data_type VARCHAR(200) NOT NULL,
    retention_period_days INTEGER NOT NULL,
    archive_after_days INTEGER,
    delete_after_days INTEGER,
    is_personal_data BOOLEAN DEFAULT false,
    legal_basis TEXT,
    policy_reference VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE consent_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_type VARCHAR(100) NOT NULL,
    consent_version VARCHAR(50),
    consent_text TEXT,
    is_granted BOOLEAN DEFAULT false,
    granted_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 21: API GATEWAY & INTEGRATIONS
-- ============================================

CREATE TABLE api_integrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_name VARCHAR(200) NOT NULL,
    integration_code VARCHAR(100) UNIQUE,
    provider VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) CHECK (service_type IN ('payment', 'sms', 'email', 'whatsapp', 'map', 'firebase', 'erp', 'crm', 'accounting', 'custom')),
    api_endpoint TEXT,
    api_version VARCHAR(50),
    auth_type VARCHAR(50) CHECK (auth_type IN ('api_key', 'oauth2', 'basic_auth', 'bearer_token', 'mtls', 'none')),
    credentials JSONB,
    headers JSONB,
    timeout_ms INTEGER DEFAULT 30000,
    retry_count INTEGER DEFAULT 3,
    retry_delay_ms INTEGER DEFAULT 1000,
    rate_limit_per_second INTEGER,
    is_active BOOLEAN DEFAULT true,
    health_status VARCHAR(20) DEFAULT 'unknown' CHECK (health_status IN ('healthy', 'degraded', 'down', 'unknown')),
    last_checked_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id UUID REFERENCES api_integrations(id) ON DELETE CASCADE,
    event_name VARCHAR(200) NOT NULL,
    event_code VARCHAR(100) UNIQUE,
    description TEXT,
    payload_schema JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE webhook_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id UUID REFERENCES api_integrations(id) ON DELETE CASCADE,
    webhook_event_id UUID REFERENCES webhook_events(id),
    request_url TEXT NOT NULL,
    request_method VARCHAR(10) DEFAULT 'POST',
    request_headers JSONB,
    request_body JSONB,
    response_status_code INTEGER,
    response_headers JSONB,
    response_body JSONB,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed', 'retrying')),
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    duration_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE integration_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id UUID NOT NULL REFERENCES api_integrations(id) ON DELETE CASCADE,
    token_type VARCHAR(50) CHECK (token_type IN ('access', 'refresh', 'api_key', 'secret', 'certificate')),
    token_value TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_refreshed_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE api_usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    api_integration_id UUID REFERENCES api_integrations(id),
    endpoint VARCHAR(500),
    method VARCHAR(10),
    request_id UUID,
    user_id UUID REFERENCES users(id),
    api_key_id UUID REFERENCES api_keys(id),
    request_headers JSONB,
    request_body JSONB,
    response_status_code INTEGER,
    response_time_ms INTEGER,
    response_size_bytes INTEGER,
    ip_address INET,
    user_agent TEXT,
    is_error BOOLEAN DEFAULT false,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 22: MONITORING & DEVOPS
-- ============================================

CREATE TABLE application_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    log_level VARCHAR(20) CHECK (log_level IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')),
    service_name VARCHAR(200),
    class_name VARCHAR(500),
    method_name VARCHAR(200),
    line_number INTEGER,
    message TEXT,
    exception_type VARCHAR(500),
    exception_message TEXT,
    stack_trace TEXT,
    correlation_id UUID,
    request_id UUID,
    user_id UUID,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE error_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    error_code VARCHAR(100),
    error_type VARCHAR(200),
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    service_name VARCHAR(200),
    endpoint VARCHAR(500),
    request_method VARCHAR(10),
    request_body TEXT,
    request_headers JSONB,
    user_id UUID REFERENCES users(id),
    ip_address INET,
    user_agent TEXT,
    severity VARCHAR(20) DEFAULT 'error' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    occurrence_count INTEGER DEFAULT 1,
    first_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id),
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE cron_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_name VARCHAR(200) NOT NULL,
    job_code VARCHAR(100) UNIQUE,
    job_class VARCHAR(500),
    cron_expression VARCHAR(100) NOT NULL,
    description TEXT,
    parameters JSONB,
    is_active BOOLEAN DEFAULT true,
    timeout_seconds INTEGER DEFAULT 300,
    max_retries INTEGER DEFAULT 3,
    retry_delay_seconds INTEGER DEFAULT 60,
    last_run_at TIMESTAMP WITH TIME ZONE,
    next_run_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE job_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cron_job_id UUID NOT NULL REFERENCES cron_jobs(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_ms INTEGER,
    status VARCHAR(20) DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed', 'cancelled', 'timeout')),
    output TEXT,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    server_name VARCHAR(200),
    process_id INTEGER,
    memory_usage_mb DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE health_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(200) NOT NULL,
    check_type VARCHAR(50) CHECK (check_type IN ('http', 'database', 'redis', 'queue', 'storage', 'external_api', 'custom')),
    endpoint VARCHAR(500),
    status VARCHAR(20) DEFAULT 'unknown' CHECK (status IN ('healthy', 'degraded', 'unhealthy', 'unknown')),
    response_time_ms INTEGER,
    response_data JSONB,
    error_message TEXT,
    checked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(200) NOT NULL,
    metric_type VARCHAR(50) CHECK (metric_type IN ('counter', 'gauge', 'histogram', 'summary', 'timer')),
    metric_value DECIMAL(15,2) NOT NULL,
    unit VARCHAR(50),
    labels JSONB,
    service_name VARCHAR(200),
    host_name VARCHAR(200),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 23: BACKUP & DISASTER RECOVERY
-- ============================================

CREATE TABLE backup_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_name VARCHAR(200) NOT NULL,
    backup_type VARCHAR(50) CHECK (backup_type IN ('full', 'incremental', 'differential', 'snapshot', 'archive')),
    target_resource VARCHAR(200) NOT NULL,
    storage_provider VARCHAR(50) DEFAULT 's3',
    storage_path TEXT,
    retention_days INTEGER DEFAULT 30,
    schedule_cron VARCHAR(100),
    is_encrypted BOOLEAN DEFAULT true,
    compression_enabled BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE backup_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    backup_job_id UUID NOT NULL REFERENCES backup_jobs(id) ON DELETE CASCADE,
    backup_file_name VARCHAR(500),
    backup_file_path TEXT,
    file_size_bytes BIGINT,
    checksum VARCHAR(200),
    status VARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'failed', 'corrupted')),
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    error_message TEXT,
    verified_at TIMESTAMP WITH TIME ZONE,
    is_verified BOOLEAN DEFAULT false,
    storage_location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE restore_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    backup_history_id UUID NOT NULL REFERENCES backup_history(id) ON DELETE CASCADE,
    restore_type VARCHAR(50) CHECK (restore_type IN ('full', 'partial', 'point_in_time')),
    target_database VARCHAR(200),
    target_environment VARCHAR(50) CHECK (target_environment IN ('production', 'staging', 'development', 'dr')),
    status VARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'failed', 'verified')),
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    restored_by UUID REFERENCES users(id),
    verification_result JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 24: MULTI-CITY / MULTI-BRANCH MANAGEMENT
-- ============================================

CREATE TABLE regions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    region_name VARCHAR(200) NOT NULL,
    region_code VARCHAR(50) UNIQUE,
    description TEXT,
    country VARCHAR(100) DEFAULT 'India',
    regional_manager_id UUID REFERENCES users(id),
    headquarters_city VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_name VARCHAR(200) NOT NULL,
    branch_code VARCHAR(50) UNIQUE NOT NULL,
    region_id UUID REFERENCES regions(id),
    branch_type VARCHAR(50) CHECK (branch_type IN ('main', 'satellite', 'franchise', 'partner', 'warehouse', 'office')),
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    pincode VARCHAR(10),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    location GEOGRAPHY(POINT, 4326),
    contact_person VARCHAR(200),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    branch_manager_id UUID REFERENCES users(id),
    operating_since DATE,
    total_employees INTEGER DEFAULT 0,
    total_technicians INTEGER DEFAULT 0,
    total_customers INTEGER DEFAULT 0,
    monthly_revenue_target DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'INR',
    timezone VARCHAR(50),
    is_headquarters BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE branch_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    setting_key VARCHAR(200) NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(branch_id, setting_key)
);

CREATE TABLE city_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_id UUID NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    base_price DECIMAL(15,2) NOT NULL,
    minimum_price DECIMAL(15,2),
    maximum_price DECIMAL(15,2),
    surge_multiplier DECIMAL(5,2) DEFAULT 1.00,
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(city_id, service_id)
);

CREATE TABLE regional_managers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    region_id UUID NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
    designation VARCHAR(200),
    jurisdiction_type VARCHAR(50) CHECK (jurisdiction_type IN ('region', 'multiple_cities', 'single_city', 'multiple_branches')),
    managed_cities UUID[],
    managed_branches UUID[],
    performance_targets JSONB,
    is_active BOOLEAN DEFAULT true,
    assigned_at DATE NOT NULL,
    relieved_at DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, region_id)
);

-- ============================================
-- MODULE 25: SUBSCRIPTION & AMC MANAGEMENT
-- ============================================

CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_name VARCHAR(200) NOT NULL,
    plan_code VARCHAR(50) UNIQUE,
    plan_type VARCHAR(50) CHECK (plan_type IN ('amc', 'subscription', 'membership', 'maintenance', 'wellness')),
    description TEXT,
    services_covered UUID[],
    visits_per_year INTEGER,
    discount_percentage DECIMAL(5,2),
    priority_support BOOLEAN DEFAULT false,
    free_inspections BOOLEAN DEFAULT false,
    emergency_service_included BOOLEAN DEFAULT false,
    price DECIMAL(15,2) NOT NULL,
    billing_cycle VARCHAR(20) CHECK (billing_cycle IN ('monthly', 'quarterly', 'half_yearly', 'yearly', 'one_time')),
    contract_duration_months INTEGER,
    auto_renewal BOOLEAN DEFAULT true,
    cancellation_fee DECIMAL(15,2),
    terms_and_conditions TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE customer_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id) ON DELETE RESTRICT,
    subscription_number VARCHAR(50) UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE,
    next_billing_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'suspended', 'pending_activation')),
    auto_renewal BOOLEAN DEFAULT true,
    total_visits_allowed INTEGER,
    visits_used INTEGER DEFAULT 0,
    remaining_visits INTEGER GENERATED ALWAYS AS (total_visits_allowed - visits_used) STORED,
    last_service_date DATE,
    next_scheduled_service DATE,
    contract_document UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE subscription_invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES customer_subscriptions(id) ON DELETE CASCADE,
    invoice_number VARCHAR(50) UNIQUE,
    billing_period_start DATE,
    billing_period_end DATE,
    amount DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(15,2),
    total_amount DECIMAL(15,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'overdue', 'cancelled', 'failed')),
    due_date DATE,
    paid_at TIMESTAMP WITH TIME ZONE,
    payment_reference VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 26: EMERGENCY RESPONSE MANAGEMENT
-- ============================================

CREATE TABLE emergency_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_number VARCHAR(50) UNIQUE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id),
    emergency_type VARCHAR(100) CHECK (emergency_type IN ('medical', 'fire', 'flood', 'electrical', 'gas_leak', 'lockout', 'structural', 'pest', 'other')),
    service_type VARCHAR(200),
    description TEXT,
    location GEOGRAPHY(POINT, 4326),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    address TEXT,
    priority VARCHAR(20) DEFAULT 'critical' CHECK (priority IN ('critical', 'high', 'medium')),
    status VARCHAR(20) DEFAULT 'received' CHECK (status IN ('received', 'dispatched', 'en_route', 'on_site', 'resolved', 'escalated', 'cancelled')),
    response_time_seconds INTEGER,
    resolution_time_seconds INTEGER,
    assigned_technicians UUID[],
    escalation_level INTEGER DEFAULT 0,
    emergency_contacts_notified BOOLEAN DEFAULT false,
    authorities_notified BOOLEAN DEFAULT false,
    insurance_claimed BOOLEAN DEFAULT false,
    damage_assessment TEXT,
    incident_report_id UUID,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE incident_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_number VARCHAR(50) UNIQUE,
    emergency_request_id UUID REFERENCES emergency_requests(id),
    booking_id UUID REFERENCES bookings(id),
    reported_by UUID NOT NULL REFERENCES users(id),
    incident_type VARCHAR(100),
    incident_date TIMESTAMP WITH TIME ZONE NOT NULL,
    description TEXT,
    severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical', 'catastrophic')),
    affected_parties UUID[],
    injuries_reported BOOLEAN DEFAULT false,
    property_damage BOOLEAN DEFAULT false,
    damage_estimate DECIMAL(15,2),
    root_cause TEXT,
    corrective_actions TEXT,
    preventive_actions TEXT,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'closed', 'under_review')),
    investigated_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 27: CALL CENTER & CUSTOMER SUPPORT
-- ============================================

CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id),
    ticket_type VARCHAR(50) CHECK (ticket_type IN ('complaint', 'query', 'request', 'feedback', 'escalation', 'refund_request', 'cancellation_request')),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    subject VARCHAR(500),
    description TEXT,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'assigned', 'in_progress', 'waiting_customer', 'waiting_third_party', 'resolved', 'closed', 'reopened')),
    assigned_to UUID REFERENCES users(id),
    assigned_team VARCHAR(100),
    resolution TEXT,
    resolution_type VARCHAR(50),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id),
    first_response_time_minutes INTEGER,
    resolution_time_minutes INTEGER,
    customer_satisfaction_score INTEGER CHECK (customer_satisfaction_score BETWEEN 1 AND 5),
    customer_feedback TEXT,
    is_escalated BOOLEAN DEFAULT false,
    escalation_level INTEGER DEFAULT 0,
    escalation_reason TEXT,
    source VARCHAR(50) DEFAULT 'phone' CHECK (source IN ('phone', 'email', 'chat', 'app', 'website', 'social_media', 'walk_in', 'ivr')),
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE ticket_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    uploaded_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE ticket_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    comment_type VARCHAR(20) DEFAULT 'note' CHECK (comment_type IN ('note', 'reply', 'internal', 'system')),
    comment_text TEXT NOT NULL,
    is_private BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE call_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id VARCHAR(200) UNIQUE,
    call_type VARCHAR(20) CHECK (call_type IN ('inbound', 'outbound', 'missed', 'voicemail')),
    from_number VARCHAR(20),
    to_number VARCHAR(20),
    agent_id UUID REFERENCES users(id),
    customer_id UUID REFERENCES customers(id),
    booking_id UUID REFERENCES bookings(id),
    ticket_id UUID REFERENCES support_tickets(id),
    call_duration_seconds INTEGER,
    call_recording_url TEXT,
    transcription TEXT,
    call_status VARCHAR(20) CHECK (call_status IN ('completed', 'failed', 'busy', 'no_answer', 'cancelled', 'voicemail')),
    call_notes TEXT,
    sentiment_score DECIMAL(3,2),
    ivr_path JSONB,
    queue_wait_time_seconds INTEGER,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE agent_performance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES users(id),
    date DATE NOT NULL,
    total_calls INTEGER DEFAULT 0,
    answered_calls INTEGER DEFAULT 0,
    missed_calls INTEGER DEFAULT 0,
    average_handle_time_seconds INTEGER,
    average_wrap_up_time_seconds INTEGER,
    first_call_resolution_rate DECIMAL(5,2),
    customer_satisfaction_score DECIMAL(3,2),
    tickets_resolved INTEGER DEFAULT 0,
    tickets_reopened INTEGER DEFAULT 0,
    total_online_time_minutes INTEGER,
    total_break_time_minutes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(agent_id, date)
);

-- ============================================
-- MODULE 28: MARKETING & PROMOTIONS
-- ============================================

CREATE TABLE promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promotion_code VARCHAR(50) UNIQUE NOT NULL,
    promotion_name VARCHAR(200),
    promotion_type VARCHAR(50) CHECK (promotion_type IN ('discount', 'cashback', 'bogo', 'free_service', 'referral', 'loyalty', 'first_time', 'festival', 'clearance')),
    discount_type VARCHAR(20) CHECK (discount_type IN ('percentage', 'fixed_amount', 'tiered')),
    discount_value DECIMAL(15,2) NOT NULL,
    minimum_order_value DECIMAL(15,2),
    maximum_discount DECIMAL(15,2),
    applicable_services UUID[],
    applicable_categories UUID[],
    applicable_cities TEXT[],
    applicable_customer_types TEXT[],
    usage_limit_total INTEGER,
    usage_limit_per_customer INTEGER DEFAULT 1,
    usage_count INTEGER DEFAULT 0,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_stackable BOOLEAN DEFAULT false,
    terms_and_conditions TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE promotion_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id),
    discount_amount DECIMAL(15,2) NOT NULL,
    order_amount DECIMAL(15,2),
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(promotion_id, customer_id, booking_id)
);

CREATE TABLE marketing_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_name VARCHAR(200) NOT NULL,
    campaign_code VARCHAR(50) UNIQUE,
    campaign_type VARCHAR(50) CHECK (campaign_type IN ('email', 'sms', 'push', 'whatsapp', 'social_media', 'in_app', 'multi_channel')),
    target_audience JSONB,
    message_template_id UUID REFERENCES notification_templates(id),
    scheduled_start TIMESTAMP WITH TIME ZONE,
    scheduled_end TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'running', 'paused', 'completed', 'cancelled')),
    total_recipients INTEGER DEFAULT 0,
    total_sent INTEGER DEFAULT 0,
    total_delivered INTEGER DEFAULT 0,
    total_opened INTEGER DEFAULT 0,
    total_clicked INTEGER DEFAULT 0,
    total_converted INTEGER DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0.00,
    budget DECIMAL(15,2),
    spent DECIMAL(15,2) DEFAULT 0.00,
    roi DECIMAL(10,2),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE referral_program (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    referral_code VARCHAR(20) UNIQUE NOT NULL,
    total_referrals INTEGER DEFAULT 0,
    successful_referrals INTEGER DEFAULT 0,
    total_earnings DECIMAL(15,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE referral_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referral_id UUID NOT NULL REFERENCES referral_program(id) ON DELETE CASCADE,
    referred_customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    reward_type VARCHAR(20) CHECK (reward_type IN ('cash', 'credit', 'discount', 'service', 'points')),
    reward_amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'credited', 'cancelled', 'expired')),
    credited_at TIMESTAMP WITH TIME ZONE,
    reference_booking_id UUID REFERENCES bookings(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE loyalty_program (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    loyalty_tier VARCHAR(20) DEFAULT 'bronze' CHECK (loyalty_tier IN ('bronze', 'silver', 'gold', 'platinum', 'diamond')),
    total_points INTEGER DEFAULT 0,
    current_points INTEGER DEFAULT 0,
    lifetime_points INTEGER DEFAULT 0,
    points_expiring_next INTEGER DEFAULT 0,
    points_expiry_date DATE,
    tier_upgraded_at TIMESTAMP WITH TIME ZONE,
    tier_downgraded_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    loyalty_id UUID NOT NULL REFERENCES loyalty_program(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('earn', 'redeem', 'expire', 'adjustment', 'bonus', 'transfer')),
    points INTEGER NOT NULL,
    description TEXT,
    reference_type VARCHAR(50),
    reference_id UUID,
    booking_id UUID REFERENCES bookings(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 29: QUALITY ASSURANCE & INSPECTIONS
-- ============================================

CREATE TABLE inspection_checklists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    checklist_name VARCHAR(200) NOT NULL,
    checklist_code VARCHAR(50) UNIQUE,
    service_id UUID REFERENCES services(id),
    checklist_type VARCHAR(50) CHECK (checklist_type IN ('pre_service', 'post_service', 'safety', 'quality', 'compliance')),
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE checklist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    checklist_id UUID NOT NULL REFERENCES inspection_checklists(id) ON DELETE CASCADE,
    item_text TEXT NOT NULL,
    item_type VARCHAR(20) CHECK (item_type IN ('yes_no', 'multiple_choice', 'text', 'photo', 'number', 'rating', 'signature')),
    options JSONB,
    is_required BOOLEAN DEFAULT true,
    expected_value TEXT,
    failure_criteria TEXT,
    sort_order INTEGER DEFAULT 0,
    weightage DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE service_inspections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    checklist_id UUID NOT NULL REFERENCES inspection_checklists(id),
    inspector_id UUID REFERENCES users(id),
    inspection_type VARCHAR(20) CHECK (inspection_type IN ('pre_service', 'during_service', 'post_service', 'random', 'complaint_based')),
    inspection_date TIMESTAMP WITH TIME ZONE NOT NULL,
    overall_score DECIMAL(5,2),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed', 'needs_rework')),
    rework_required BOOLEAN DEFAULT false,
    rework_booking_id UUID REFERENCES bookings(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE inspection_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inspection_id UUID NOT NULL REFERENCES service_inspections(id) ON DELETE CASCADE,
    checklist_item_id UUID NOT NULL REFERENCES checklist_items(id),
    result_value TEXT,
    is_compliant BOOLEAN,
    photo_evidence UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE quality_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) CHECK (entity_type IN ('technician', 'vendor', 'branch', 'city')),
    entity_id UUID NOT NULL,
    score_type VARCHAR(50) CHECK (score_type IN ('service_quality', 'customer_satisfaction', 'safety_compliance', 'punctuality', 'overall')),
    score DECIMAL(5,2) NOT NULL,
    period_start DATE,
    period_end DATE,
    total_evaluations INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MODULE 30: KNOWLEDGE BASE & TRAINING
-- ============================================

CREATE TABLE knowledge_articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    slug VARCHAR(500) UNIQUE,
    content TEXT,
    category VARCHAR(100),
    sub_category VARCHAR(100),
    article_type VARCHAR(50) CHECK (article_type IN ('sop', 'faq', 'tutorial', 'troubleshooting', 'policy', 'guide', 'training', 'reference')),
    service_id UUID REFERENCES services(id),
    tags TEXT[],
    is_internal BOOLEAN DEFAULT false,
    is_published BOOLEAN DEFAULT true,
    view_count INTEGER DEFAULT 0,
    helpful_count INTEGER DEFAULT 0,
    not_helpful_count INTEGER DEFAULT 0,
    author_id UUID REFERENCES users(id),
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE training_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_name VARCHAR(200) NOT NULL,
    course_code VARCHAR(50) UNIQUE,
    description TEXT,
    course_type VARCHAR(50) CHECK (course_type IN ('onboarding', 'skill_upgrade', 'safety', 'certification', 'refresher', 'product', 'soft_skills')),
    duration_hours DECIMAL(5,2),
    is_mandatory BOOLEAN DEFAULT false,
    validity_months INTEGER,
    passing_score DECIMAL(5,2) DEFAULT 80.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE training_modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES training_courses(id) ON DELETE CASCADE,
    module_name VARCHAR(200),
    module_type VARCHAR(50) CHECK (module_type IN ('video', 'document', 'quiz', 'interactive', 'simulation', 'assessment')),
    content_url TEXT,
    duration_minutes INTEGER,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE training_enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES training_courses(id) ON DELETE CASCADE,
    enrollment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    start_date TIMESTAMP WITH TIME ZONE,
    completion_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'enrolled' CHECK (status IN ('enrolled', 'in_progress', 'completed', 'failed', 'expired', 'cancelled')),
    score DECIMAL(5,2),
    certificate_url TEXT,
    certificate_number VARCHAR(100),
    valid_until DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

CREATE TABLE certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certification_name VARCHAR(200) NOT NULL,
    certification_code VARCHAR(50) UNIQUE,
    issuing_authority VARCHAR(200),
    description TEXT,
    validity_months INTEGER,
    is_required_for_services UUID[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE technician_certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    certification_id UUID NOT NULL REFERENCES certifications(id) ON DELETE CASCADE,
    certificate_number VARCHAR(100),
    issue_date DATE NOT NULL,
    expiry_date DATE,
    certificate_document UUID,
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected', 'expired')),
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(technician_id, certification_id)
);

-- ============================================
-- CREATING INDEXES FOR PERFORMANCE
-- ============================================

-- Users and Authentication
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_login_attempts_user ON login_attempts(user_id);
CREATE INDEX idx_login_attempts_ip ON login_attempts(ip_address);

-- Bookings
CREATE INDEX idx_bookings_customer ON bookings(customer_id);
CREATE INDEX idx_bookings_technician ON bookings(technician_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_scheduled ON bookings(scheduled_start_time);
CREATE INDEX idx_bookings_number ON bookings(booking_number);
CREATE INDEX idx_bookings_payment_status ON bookings(payment_status);

-- Services
CREATE INDEX idx_services_category ON services(category_id);
CREATE INDEX idx_services_active ON services(is_active);
CREATE INDEX idx_services_slug ON services(slug);

-- Technicians
CREATE INDEX idx_technicians_user ON technicians(user_id);
CREATE INDEX idx_technicians_status ON technicians(current_status);
CREATE INDEX idx_technicians_vendor ON technicians(vendor_id);
CREATE INDEX idx_technician_availability_date ON technician_availability(date);
CREATE INDEX idx_technician_availability_tech ON technician_availability(technician_id);

-- Payments
CREATE INDEX idx_payments_booking ON payments(booking_id);
CREATE INDEX idx_payments_customer ON payments(customer_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_invoices_booking ON invoices(booking_id);
CREATE INDEX idx_invoices_customer ON invoices(customer_id);

-- Inventory
CREATE INDEX idx_inventory_stock_product ON inventory_stock(product_id);
CREATE INDEX idx_inventory_stock_warehouse ON inventory_stock(warehouse_id);
CREATE INDEX idx_inventory_transactions_product ON inventory_transactions(product_id);
CREATE INDEX idx_inventory_transactions_date ON inventory_transactions(transaction_date);

-- Notifications
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_sent ON notifications(sent_at);

-- CRM
CREATE INDEX idx_crm_leads_email ON crm_leads(email);
CREATE INDEX idx_crm_leads_phone ON crm_leads(phone);
CREATE INDEX idx_crm_leads_status ON crm_leads(status);
CREATE INDEX idx_crm_leads_assigned ON crm_leads(assigned_to);

-- Analytics
CREATE INDEX idx_analytics_events_name ON analytics_events(event_name);
CREATE INDEX idx_analytics_events_timestamp ON analytics_events(event_timestamp);
CREATE INDEX idx_kpi_values_kpi ON kpi_values(kpi_id);
CREATE INDEX idx_kpi_values_period ON kpi_values(period_start, period_end);

-- Location and GIS
CREATE INDEX idx_service_locations_entity ON service_locations(entity_type, entity_id);
CREATE INDEX idx_service_locations_geo ON service_locations USING GIST(location);
CREATE INDEX idx_location_history_user ON location_history(user_id);
CREATE INDEX idx_location_history_geo ON location_history USING GIST(location);
CREATE INDEX idx_customer_addresses_geo ON customer_addresses USING GIST(location);

-- Audit
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_record ON audit_logs(record_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_performed_by ON audit_logs(performed_by);

-- Search
CREATE INDEX idx_search_index_type ON search_index(searchable_type, searchable_id);
CREATE INDEX idx_search_index_vector ON search_index USING GIN(search_vector);
CREATE INDEX idx_search_index_city ON search_index(city);

-- Support
CREATE INDEX idx_support_tickets_customer ON support_tickets(customer_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);
CREATE INDEX idx_support_tickets_assigned ON support_tickets(assigned_to);
CREATE INDEX idx_support_tickets_priority ON support_tickets(priority);

-- Chat
CREATE INDEX idx_chat_conversations_booking ON chat_conversations(booking_id);
CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id);
CREATE INDEX idx_chat_messages_sender ON chat_messages(sender_id);

-- Security
CREATE INDEX idx_security_events_type ON security_events(event_type);
CREATE INDEX idx_security_events_user ON security_events(user_id);
CREATE INDEX idx_security_events_severity ON security_events(severity);
CREATE INDEX idx_blocked_ips_ip ON blocked_ips(ip_address);

-- Multi-tenancy
CREATE INDEX idx_branches_region ON branches(region_id);
CREATE INDEX idx_branches_city ON branches(city);
CREATE INDEX idx_regional_managers_region ON regional_managers(region_id);

-- Files
CREATE INDEX idx_files_uploaded_by ON files(uploaded_by);
CREATE INDEX idx_files_type ON files(file_type);
CREATE INDEX idx_file_permissions_file ON file_permissions(file_id);
CREATE INDEX idx_file_permissions_user ON file_permissions(user_id);

-- API & Integrations
CREATE INDEX idx_api_usage_logs_integration ON api_usage_logs(api_integration_id);
CREATE INDEX idx_api_usage_logs_user ON api_usage_logs(user_id);
CREATE INDEX idx_api_usage_logs_timestamp ON api_usage_logs(created_at);
CREATE INDEX idx_webhook_logs_integration ON webhook_logs(integration_id);

-- Monitoring
CREATE INDEX idx_application_logs_level ON application_logs(log_level);
CREATE INDEX idx_application_logs_timestamp ON application_logs(created_at);
CREATE INDEX idx_error_logs_code ON error_logs(error_code);
CREATE INDEX idx_error_logs_service ON error_logs(service_name);
CREATE INDEX idx_performance_metrics_name ON performance_metrics(metric_name);
CREATE INDEX idx_performance_metrics_recorded ON performance_metrics(recorded_at);

-- Marketing
CREATE INDEX idx_promotions_code ON promotions(promotion_code);
CREATE INDEX idx_promotions_dates ON promotions(start_date, end_date);
CREATE INDEX idx_campaigns_status ON marketing_campaigns(status);

-- Quality
CREATE INDEX idx_inspections_booking ON service_inspections(booking_id);
CREATE INDEX idx_quality_scores_entity ON quality_scores(entity_type, entity_id);

-- Training
CREATE INDEX idx_enrollments_user ON training_enrollments(user_id);
CREATE INDEX idx_enrollments_course ON training_enrollments(course_id);
CREATE INDEX idx_technician_certs_tech ON technician_certifications(technician_id);

-- ============================================
-- CREATING VIEWS FOR COMMON QUERIES
-- ============================================

-- Active Bookings View
CREATE VIEW v_active_bookings AS
SELECT 
    b.*,
    c.customer_code,
    u.email AS customer_email,
    up.first_name || ' ' || up.last_name AS customer_name,
    t.technician_code,
    tu.email AS technician_email,
    tup.first_name || ' ' || tup.last_name AS technician_name,
    s.name AS service_name,
    sc.name AS category_name
FROM bookings b
JOIN customers c ON b.customer_id = c.id
JOIN users u ON c.user_id = u.id
JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN technicians t ON b.technician_id = t.id
LEFT JOIN users tu ON t.user_id = tu.id
LEFT JOIN user_profiles tup ON tu.id = tup.user_id
JOIN services s ON b.service_id = s.id
JOIN service_categories sc ON s.category_id = sc.id
WHERE b.status IN ('pending', 'confirmed', 'assigned', 'in_progress');

-- Technician Performance View
CREATE VIEW v_technician_performance AS
SELECT 
    t.id,
    t.technician_code,
    up.first_name || ' ' || up.last_name AS technician_name,
    t.primary_skill,
    t.average_rating,
    t.total_jobs_completed,
    t.job_success_rate,
    t.on_time_rate,
    COUNT(b.id) AS jobs_this_month,
    AVG(tr.rating) AS avg_rating_this_month,
    SUM(b.total_amount) AS revenue_this_month
FROM technicians t
JOIN user_profiles up ON t.user_id = up.user_id
LEFT JOIN bookings b ON t.id = b.technician_id 
    AND DATE_TRUNC('month', b.completed_at) = DATE_TRUNC('month', CURRENT_DATE)
LEFT JOIN technician_ratings tr ON t.id = tr.technician_id
    AND DATE_TRUNC('month', tr.created_at) = DATE_TRUNC('month', CURRENT_DATE)
WHERE t.current_status != 'suspended'
GROUP BY t.id, t.technician_code, up.first_name, up.last_name, t.primary_skill, 
         t.average_rating, t.total_jobs_completed, t.job_success_rate, t.on_time_rate;

-- Revenue Dashboard View
CREATE VIEW v_revenue_dashboard AS
SELECT 
    DATE_TRUNC('day', b.completed_at) AS date,
    b.city,
    sc.name AS category,
    COUNT(b.id) AS total_bookings,
    SUM(b.total_amount) AS total_revenue,
    SUM(b.discount_amount) AS total_discounts,
    AVG(b.total_amount) AS average_order_value,
    COUNT(DISTINCT b.customer_id) AS unique_customers
FROM bookings b
JOIN services s ON b.service_id = s.id
JOIN service_categories sc ON s.category_id = sc.id
WHERE b.status = 'completed'
    AND b.completed_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', b.completed_at), b.city, sc.name;

-- Inventory Alert View
CREATE VIEW v_inventory_alerts AS
SELECT 
    p.id AS product_id,
    p.product_code,
    p.name AS product_name,
    p.minimum_stock_level,
    p.reorder_point,
    w.name AS warehouse_name,
    w.city,
    ist.quantity AS current_stock,
    ist.allocated_quantity,
    ist.available_quantity,
    CASE 
        WHEN ist.available_quantity <= p.reorder_point THEN 'REORDER'
        WHEN ist.available_quantity <= p.minimum_stock_level THEN 'CRITICAL'
        ELSE 'OK'
    END AS stock_status
FROM products p
JOIN inventory_stock ist ON p.id = ist.product_id
JOIN inventory_warehouses w ON ist.warehouse_id = w.id
WHERE ist.available_quantity <= p.reorder_point
    AND p.is_active = true;

-- Customer Lifetime Value View
CREATE VIEW v_customer_ltv AS
SELECT 
    c.id AS customer_id,
    c.customer_code,
    up.first_name || ' ' || up.last_name AS customer_name,
    c.customer_tier,
    COUNT(b.id) AS total_bookings,
    SUM(b.total_amount) AS total_spent,
    AVG(b.total_amount) AS avg_order_value,
    MAX(b.completed_at) AS last_order_date,
    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - MAX(b.completed_at))) AS days_since_last_order,
    COUNT(CASE WHEN b.completed_at >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) AS bookings_last_90_days
FROM customers c
JOIN user_profiles up ON c.user_id = up.user_id
LEFT JOIN bookings b ON c.id = b.customer_id AND b.status = 'completed'
GROUP BY c.id, c.customer_code, up.first_name, up.last_name, c.customer_tier;

-- ============================================
-- CREATING FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to all tables with updated_at column
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name 
        FROM information_schema.columns 
        WHERE column_name = 'updated_at' 
        AND table_schema = 'public'
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_%s_updated_at 
            BEFORE UPDATE ON %I 
            FOR EACH ROW 
            EXECUTE FUNCTION update_updated_at_column()', 
            t, t);
    END LOOP;
END;
$$ language 'plpgsql';

-- Function to generate booking number
CREATE OR REPLACE FUNCTION generate_booking_number()
RETURNS TRIGGER AS $$
DECLARE
    city_code VARCHAR(3);
    year_code VARCHAR(2);
    seq_number INTEGER;
BEGIN
    SELECT LEFT(COALESCE(ca.city, 'IND'), 3) INTO city_code
    FROM customer_addresses ca
    WHERE ca.id = NEW.service_address_id;
    
    year_code := TO_CHAR(NOW(), 'YY');
    
    SELECT COALESCE(MAX(SUBSTRING(booking_number FROM 10)::INTEGER), 0) + 1 INTO seq_number
    FROM bookings
    WHERE booking_number LIKE 'BK-' || city_code || '-' || year_code || '%';
    
    NEW.booking_number := 'BK-' || UPPER(city_code) || '-' || year_code || '-' || LPAD(seq_number::TEXT, 6, '0');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_booking_number
BEFORE INSERT ON bookings
FOR EACH ROW
WHEN (NEW.booking_number IS NULL)
EXECUTE FUNCTION generate_booking_number();

-- Function to update customer statistics
CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'completed' THEN
        UPDATE customers 
        SET total_bookings = total_bookings + 1,
            total_spent = total_spent + NEW.total_amount,
            last_service_date = NEW.completed_at
        WHERE id = NEW.customer_id;
    ELSIF TG_OP = 'UPDATE' AND NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE customers 
        SET total_bookings = total_bookings + 1,
            total_spent = total_spent + NEW.total_amount,
            last_service_date = NEW.completed_at
        WHERE id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_customer_stats
AFTER INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION update_customer_stats();

-- Function to log audit changes
CREATE OR REPLACE FUNCTION log_audit_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (table_name, record_id, action, new_values, performed_by, ip_address)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), current_setting('app.current_user_id', true)::UUID, 
                inet_client_addr());
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, changed_fields, performed_by, ip_address)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW),
                ARRAY(SELECT jsonb_object_keys(to_jsonb(NEW) - to_jsonb(OLD))),
                current_setting('app.current_user_id', true)::UUID, inet_client_addr());
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_values, performed_by, ip_address)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), current_setting('app.current_user_id', true)::UUID,
                inet_client_addr());
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to critical tables
CREATE TRIGGER audit_bookings AFTER INSERT OR UPDATE OR DELETE ON bookings FOR EACH ROW EXECUTE FUNCTION log_audit_changes();
CREATE TRIGGER audit_payments AFTER INSERT OR UPDATE OR DELETE ON payments FOR EACH ROW EXECUTE FUNCTION log_audit_changes();
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users FOR EACH ROW EXECUTE FUNCTION log_audit_changes();
CREATE TRIGGER audit_technicians AFTER INSERT OR UPDATE OR DELETE ON technicians FOR EACH ROW EXECUTE FUNCTION log_audit_changes();
CREATE TRIGGER audit_customers AFTER INSERT OR UPDATE OR DELETE ON customers FOR EACH ROW EXECUTE FUNCTION log_audit_changes();

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Create roles
CREATE ROLE app_readonly;
CREATE ROLE app_readwrite;
CREATE ROLE app_admin;
CREATE ROLE app_superadmin;

-- Grant basic permissions
GRANT CONNECT ON DATABASE urban_services_enterprise TO app_readonly, app_readwrite, app_admin, app_superadmin;
GRANT USAGE ON SCHEMA public TO app_readonly, app_readwrite, app_admin, app_superadmin;

-- Read-only role
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_readonly;

-- Read-write role
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_readwrite;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_readwrite;

-- Admin role
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO app_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO app_admin;

-- Superadmin role
GRANT ALL PRIVILEGES ON DATABASE urban_services_enterprise TO app_superadmin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_superadmin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_superadmin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO app_superadmin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO app_superadmin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO app_superadmin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO app_superadmin;

-- ============================================
-- INSERT DEFAULT DATA
-- ============================================

-- Insert default roles
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
('call_center_agent', 'Call Center Agent', 'Customer support agent', 'call_center_agent', true);

-- Insert default permissions
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
('audit.view', 'View Audit Logs', 'audit', 'audit', 'read');

-- Insert default business hours
INSERT INTO business_hours (day_of_week, start_time, end_time, is_working_day) VALUES
(0, '10:00', '18:00', true),  -- Sunday
(1, '08:00', '20:00', true),  -- Monday
(2, '08:00', '20:00', true),  -- Tuesday
(3, '08:00', '20:00', true),  -- Wednesday
(4, '08:00', '20:00', true),  -- Thursday
(5, '08:00', '20:00', true),  -- Friday
(6, '08:00', '20:00', true);  -- Saturday

-- Insert default tax configuration
INSERT INTO tax_configurations (tax_name, tax_code, tax_type, tax_percentage, applicable_category, effective_from) VALUES
('CGST', 'CGST-9', 'cgst', 9.00, 'services', '2024-01-01'),
('SGST', 'SGST-9', 'sgst', 9.00, 'services', '2024-01-01'),
('IGST', 'IGST-18', 'igst', 18.00, 'services', '2024-01-01');

-- Insert default SLA policies
INSERT INTO sla_policies (policy_name, policy_code, priority, response_time_minutes, resolution_time_minutes, escalation_time_minutes) VALUES
('Emergency SLA', 'SLA-EMG-001', 'urgent', 15, 120, 30),
('High Priority SLA', 'SLA-HIGH-001', 'high', 30, 240, 60),
('Standard SLA', 'SLA-STD-001', 'normal', 60, 480, 120),
('Low Priority SLA', 'SLA-LOW-001', 'low', 120, 1440, 240);

-- Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, setting_type, description, module) VALUES
('platform.name', 'Urban Services Pro', 'string', 'Platform name', 'general'),
('platform.version', '1.0.0', 'string', 'Platform version', 'general'),
('platform.timezone', 'Asia/Kolkata', 'string', 'Default timezone', 'general'),
('booking.auto_assign', 'true', 'boolean', 'Enable auto assignment', 'booking'),
('booking.cancellation_window_hours', '24', 'integer', 'Cancellation window in hours', 'booking'),
('payment.default_currency', 'INR', 'string', 'Default currency', 'payment'),
('notification.email_enabled', 'true', 'boolean', 'Enable email notifications', 'notification'),
('notification.sms_enabled', 'true', 'boolean', 'Enable SMS notifications', 'notification'),
('security.max_login_attempts', '5', 'integer', 'Maximum login attempts', 'security'),
('security.session_timeout_minutes', '30', 'integer', 'Session timeout in minutes', 'security');

-- ============================================
-- END OF DATABASE SCHEMA
-- ============================================

COMMENT ON DATABASE urban_services_enterprise IS 'Urban Services Enterprise Platform - Complete Database Schema';
