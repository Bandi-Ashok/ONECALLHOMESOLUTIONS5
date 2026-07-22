/*
# OneCall Home Solutions — Modules 11-20: CRM, Vendors, HR, Analytics, AI, Admin, Location, Files, Audit, Integrations

11. CRM: crm_leads, crm_activities, crm_deals
12. Vendors: vendors, vendor_technicians, vendor_invoices
13. HR: departments, employees, shift_management, employee_attendance, leave_management
14. Analytics: analytics_dashboards, analytics_reports, analytics_events, kpi_definitions, kpi_values
15. AI: ai_models, ai_predictions, ai_recommendations, automation_rules, automation_logs
16. Platform Admin: system_settings, feature_flags, business_configurations, holiday_calendar, business_hours, cities, service_pincodes, sla_policies, tax_configurations
17. Security & Identity: user_sessions, api_keys, device_registrations, mfa_settings, login_attempts, password_history, security_events, blocked_ips
18. Files: files, folders, file_versions, file_permissions, media_library, document_categories
19. Search & Location: search_index, geofence_zones, service_locations, map_cache, location_history
20. Audit & Integrations: audit_logs, activity_logs, compliance_records, data_retention, consent_records, api_integrations, webhook_events, webhook_logs, integration_tokens, api_usage_logs

Security: RLS enabled with anon+authenticated access.
*/

-- MODULE 11: CRM
CREATE TABLE IF NOT EXISTS crm_leads (
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

CREATE TABLE IF NOT EXISTS crm_activities (
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

CREATE TABLE IF NOT EXISTS crm_deals (
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

-- MODULE 12: VENDOR MANAGEMENT
CREATE TABLE IF NOT EXISTS vendors (
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

CREATE TABLE IF NOT EXISTS vendor_technicians (
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

CREATE TABLE IF NOT EXISTS vendor_invoices (
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

-- MODULE 13: HR MANAGEMENT
CREATE TABLE IF NOT EXISTS departments (
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

CREATE TABLE IF NOT EXISTS employees (
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

CREATE TABLE IF NOT EXISTS shift_management (
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

CREATE TABLE IF NOT EXISTS employee_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    shift_id UUID REFERENCES shift_management(id),
    scheduled_in_time TIME,
    scheduled_out_time TIME,
    actual_in_time TIMESTAMP WITH TIME ZONE,
    actual_out_time TIMESTAMP WITH TIME ZONE,
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

CREATE TABLE IF NOT EXISTS leave_management (
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

-- MODULE 14: ANALYTICS
CREATE TABLE IF NOT EXISTS analytics_dashboards (
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

CREATE TABLE IF NOT EXISTS analytics_reports (
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

CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(200) NOT NULL,
    user_id UUID REFERENCES users(id),
    session_id VARCHAR(200),
    device_id VARCHAR(200),
    event_data JSONB,
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS kpi_definitions (
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

CREATE TABLE IF NOT EXISTS kpi_values (
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

-- MODULE 15: AI & AUTOMATION
CREATE TABLE IF NOT EXISTS ai_models (
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

CREATE TABLE IF NOT EXISTS ai_predictions (
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

CREATE TABLE IF NOT EXISTS ai_recommendations (
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

CREATE TABLE IF NOT EXISTS automation_rules (
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

CREATE TABLE IF NOT EXISTS automation_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES automation_rules(id) ON DELETE CASCADE,
    trigger_event JSONB,
    execution_status VARCHAR(20) CHECK (execution_status IN ('success', 'failed', 'partial', 'skipped')),
    error_message TEXT,
    execution_duration_ms INTEGER,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 16: PLATFORM ADMINISTRATION
CREATE TABLE IF NOT EXISTS system_settings (
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

CREATE TABLE IF NOT EXISTS feature_flags (
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

CREATE TABLE IF NOT EXISTS business_configurations (
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

CREATE TABLE IF NOT EXISTS holiday_calendar (
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

CREATE TABLE IF NOT EXISTS business_hours (
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

CREATE TABLE IF NOT EXISTS cities (
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

CREATE TABLE IF NOT EXISTS service_pincodes (
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

CREATE TABLE IF NOT EXISTS sla_policies (
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

CREATE TABLE IF NOT EXISTS tax_configurations (
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

-- MODULE 17: SECURITY & IDENTITY
CREATE TABLE IF NOT EXISTS user_sessions (
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
    ip_address TEXT,
    user_agent TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_active BOOLEAN DEFAULT true,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    logged_out_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS api_keys (
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
    ip_whitelist TEXT[],
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS device_registrations (
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

CREATE TABLE IF NOT EXISTS mfa_settings (
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

CREATE TABLE IF NOT EXISTS login_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    email VARCHAR(255),
    ip_address TEXT,
    user_agent TEXT,
    attempt_status VARCHAR(20) CHECK (attempt_status IN ('success', 'failed', 'blocked', 'mfa_required', 'mfa_failed')),
    failure_reason VARCHAR(100),
    device_fingerprint VARCHAR(500),
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS password_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES users(id),
    ip_address TEXT,
    description TEXT,
    severity VARCHAR(20) DEFAULT 'low' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    event_data JSONB,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id),
    resolution_notes TEXT
);

CREATE TABLE IF NOT EXISTS blocked_ips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ip_address TEXT NOT NULL,
    reason TEXT,
    blocked_by UUID REFERENCES users(id),
    blocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(ip_address)
);

-- MODULE 18: FILE & DOCUMENT MANAGEMENT
CREATE TABLE IF NOT EXISTS files (
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

CREATE TABLE IF NOT EXISTS folders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(500) NOT NULL,
    parent_folder_id UUID REFERENCES folders(id),
    folder_path TEXT,
    created_by UUID REFERENCES users(id),
    is_system BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS file_versions (
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

CREATE TABLE IF NOT EXISTS file_permissions (
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

CREATE TABLE IF NOT EXISTS media_library (
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

CREATE TABLE IF NOT EXISTS document_categories (
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

-- MODULE 19: SEARCH & LOCATION
CREATE TABLE IF NOT EXISTS search_index (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    searchable_type VARCHAR(100),
    searchable_id UUID,
    title VARCHAR(500),
    description TEXT,
    keywords TEXT,
    category VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    rating DECIMAL(3,2),
    popularity_score DECIMAL(10,2),
    indexed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS geofence_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_name VARCHAR(200) NOT NULL,
    zone_code VARCHAR(100) UNIQUE,
    zone_type VARCHAR(50) CHECK (zone_type IN ('service_area', 'no_service', 'premium', 'restricted', 'high_demand')),
    center_latitude DECIMAL(10,8),
    center_longitude DECIMAL(11,8),
    radius_km DECIMAL(10,2),
    city VARCHAR(100),
    state VARCHAR(100),
    properties JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS service_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) CHECK (entity_type IN ('technician', 'vendor', 'customer', 'branch', 'warehouse')),
    entity_id UUID NOT NULL,
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

CREATE TABLE IF NOT EXISTS map_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key VARCHAR(500) UNIQUE NOT NULL,
    map_provider VARCHAR(50),
    request_type VARCHAR(50),
    request_parameters JSONB,
    response_data JSONB,
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    hit_count INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS location_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    accuracy_meters DECIMAL(10,2),
    activity_type VARCHAR(50),
    battery_level DECIMAL(5,2),
    network_type VARCHAR(50),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 20: AUDIT & INTEGRATIONS
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(200) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(20) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'LOGIN', 'LOGOUT', 'EXPORT', 'IMPORT')),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    performed_by UUID REFERENCES users(id),
    performed_by_type VARCHAR(50),
    ip_address TEXT,
    user_agent TEXT,
    session_id UUID,
    request_id UUID,
    application_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    activity_type VARCHAR(100) NOT NULL,
    activity_description TEXT,
    entity_type VARCHAR(100),
    entity_id UUID,
    metadata JSONB,
    ip_address TEXT,
    user_agent TEXT,
    duration_ms INTEGER,
    status VARCHAR(20) DEFAULT 'success' CHECK (status IN ('success', 'failed', 'error', 'warning')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS compliance_records (
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

CREATE TABLE IF NOT EXISTS data_retention (
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

CREATE TABLE IF NOT EXISTS consent_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_type VARCHAR(100) NOT NULL,
    consent_version VARCHAR(50),
    consent_text TEXT,
    is_granted BOOLEAN DEFAULT false,
    granted_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS api_integrations (
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

CREATE TABLE IF NOT EXISTS webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id UUID REFERENCES api_integrations(id) ON DELETE CASCADE,
    event_name VARCHAR(200) NOT NULL,
    event_code VARCHAR(100) UNIQUE,
    description TEXT,
    payload_schema JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS webhook_logs (
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

CREATE TABLE IF NOT EXISTS integration_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id UUID NOT NULL REFERENCES api_integrations(id) ON DELETE CASCADE,
    token_type VARCHAR(50) CHECK (token_type IN ('access', 'refresh', 'api_key', 'secret', 'certificate')),
    token_value TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_refreshed_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS api_usage_logs (
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
    ip_address TEXT,
    user_agent TEXT,
    is_error BOOLEAN DEFAULT false,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MODULE 21: MONITORING & DEVOPS
CREATE TABLE IF NOT EXISTS application_logs (
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

CREATE TABLE IF NOT EXISTS error_logs (
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
    ip_address TEXT,
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

CREATE TABLE IF NOT EXISTS cron_jobs (
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

CREATE TABLE IF NOT EXISTS job_history (
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

CREATE TABLE IF NOT EXISTS health_checks (
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

CREATE TABLE IF NOT EXISTS performance_metrics (
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

-- MODULE 22: BACKUP & DISASTER RECOVERY
CREATE TABLE IF NOT EXISTS backup_jobs (
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

CREATE TABLE IF NOT EXISTS backup_history (
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

CREATE TABLE IF NOT EXISTS restore_history (
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

-- MODULE 23: MULTI-CITY / MULTI-BRANCH
CREATE TABLE IF NOT EXISTS regions (
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

CREATE TABLE IF NOT EXISTS branches (
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

CREATE TABLE IF NOT EXISTS branch_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    setting_key VARCHAR(200) NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(branch_id, setting_key)
);

CREATE TABLE IF NOT EXISTS city_pricing (
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

CREATE TABLE IF NOT EXISTS regional_managers (
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

-- MODULE 24: SUBSCRIPTION & AMC
CREATE TABLE IF NOT EXISTS subscription_plans (
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

CREATE TABLE IF NOT EXISTS customer_subscriptions (
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
    last_service_date DATE,
    next_scheduled_service DATE,
    contract_document UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscription_invoices (
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

-- MODULE 25: EMERGENCY RESPONSE
CREATE TABLE IF NOT EXISTS emergency_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_number VARCHAR(50) UNIQUE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id),
    emergency_type VARCHAR(100) CHECK (emergency_type IN ('medical', 'fire', 'flood', 'electrical', 'gas_leak', 'lockout', 'structural', 'pest', 'other')),
    service_type VARCHAR(200),
    description TEXT,
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

CREATE TABLE IF NOT EXISTS incident_reports (
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

-- MODULE 26: CALL CENTER & SUPPORT
CREATE TABLE IF NOT EXISTS support_tickets (
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

CREATE TABLE IF NOT EXISTS ticket_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    uploaded_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ticket_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    comment_type VARCHAR(20) DEFAULT 'note' CHECK (comment_type IN ('note', 'reply', 'internal', 'system')),
    comment_text TEXT NOT NULL,
    is_private BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS call_logs (
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

CREATE TABLE IF NOT EXISTS agent_performance (
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

-- MODULE 27: MARKETING & PROMOTIONS
CREATE TABLE IF NOT EXISTS promotions (
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

CREATE TABLE IF NOT EXISTS promotion_usage (
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

CREATE TABLE IF NOT EXISTS marketing_campaigns (
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

CREATE TABLE IF NOT EXISTS referral_program (
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

CREATE TABLE IF NOT EXISTS referral_transactions (
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

CREATE TABLE IF NOT EXISTS loyalty_program (
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

CREATE TABLE IF NOT EXISTS loyalty_transactions (
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

-- MODULE 28: QUALITY ASSURANCE
CREATE TABLE IF NOT EXISTS inspection_checklists (
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

CREATE TABLE IF NOT EXISTS checklist_items (
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

CREATE TABLE IF NOT EXISTS service_inspections (
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

CREATE TABLE IF NOT EXISTS inspection_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inspection_id UUID NOT NULL REFERENCES service_inspections(id) ON DELETE CASCADE,
    checklist_item_id UUID NOT NULL REFERENCES checklist_items(id),
    result_value TEXT,
    is_compliant BOOLEAN,
    photo_evidence UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS quality_scores (
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

-- MODULE 29: KNOWLEDGE BASE & TRAINING
CREATE TABLE IF NOT EXISTS knowledge_articles (
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

CREATE TABLE IF NOT EXISTS training_courses (
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

CREATE TABLE IF NOT EXISTS training_modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES training_courses(id) ON DELETE CASCADE,
    module_name VARCHAR(200),
    module_type VARCHAR(50) CHECK (module_type IN ('video', 'document', 'quiz', 'interactive', 'simulation', 'assessment')),
    content_url TEXT,
    duration_minutes INTEGER,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS training_enrollments (
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

CREATE TABLE IF NOT EXISTS certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certification_name VARCHAR(200) NOT NULL,
    certification_code VARCHAR(50) UNIQUE,
    issuing_authority VARCHAR(200),
    description TEXT,
    validity_months INTEGER,
    is_required_for_services UUID[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS technician_certifications (
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

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_crm_leads_email ON crm_leads(email);
CREATE INDEX IF NOT EXISTS idx_crm_leads_phone ON crm_leads(phone);
CREATE INDEX IF NOT EXISTS idx_crm_leads_status ON crm_leads(status);
CREATE INDEX IF NOT EXISTS idx_crm_leads_assigned ON crm_leads(assigned_to);
CREATE INDEX IF NOT EXISTS idx_analytics_events_name ON analytics_events(event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_timestamp ON analytics_events(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_kpi_values_kpi ON kpi_values(kpi_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_record ON audit_logs(record_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_security_events_type ON security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_security_events_severity ON security_events(severity);
CREATE INDEX IF NOT EXISTS idx_files_uploaded_by ON files(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_files_type ON files(file_type);
CREATE INDEX IF NOT EXISTS idx_api_usage_logs_integration ON api_usage_logs(api_integration_id);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_integration ON webhook_logs(integration_id);
CREATE INDEX IF NOT EXISTS idx_application_logs_level ON application_logs(log_level);
CREATE INDEX IF NOT EXISTS idx_application_logs_timestamp ON application_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_name ON performance_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_support_tickets_customer ON support_tickets(customer_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_assigned ON support_tickets(assigned_to);
CREATE INDEX IF NOT EXISTS idx_support_tickets_priority ON support_tickets(priority);
CREATE INDEX IF NOT EXISTS idx_promotions_code ON promotions(promotion_code);
CREATE INDEX IF NOT EXISTS idx_branches_region ON branches(region_id);
CREATE INDEX IF NOT EXISTS idx_branches_city ON branches(city);
CREATE INDEX IF NOT EXISTS idx_inspections_booking ON service_inspections(booking_id);
CREATE INDEX IF NOT EXISTS idx_quality_scores_entity ON quality_scores(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_user ON training_enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON training_enrollments(course_id);

-- RLS for all tables
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

-- Triggers
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

-- DEFAULT DATA
INSERT INTO business_hours (day_of_week, start_time, end_time, is_working_day) VALUES
(0, '10:00', '18:00', true),
(1, '08:00', '20:00', true),
(2, '08:00', '20:00', true),
(3, '08:00', '20:00', true),
(4, '08:00', '20:00', true),
(5, '08:00', '20:00', true),
(6, '08:00', '20:00', true)
ON CONFLICT DO NOTHING;

INSERT INTO tax_configurations (tax_name, tax_code, tax_type, tax_percentage, applicable_category, effective_from) VALUES
('CGST', 'CGST-9', 'cgst', 9.00, 'services', '2024-01-01'),
('SGST', 'SGST-9', 'sgst', 9.00, 'services', '2024-01-01'),
('IGST', 'IGST-18', 'igst', 18.00, 'services', '2024-01-01')
ON CONFLICT (tax_code) DO NOTHING;

INSERT INTO sla_policies (policy_name, policy_code, priority, response_time_minutes, resolution_time_minutes, escalation_time_minutes) VALUES
('Emergency SLA', 'SLA-EMG-001', 'urgent', 15, 120, 30),
('High Priority SLA', 'SLA-HIGH-001', 'high', 30, 240, 60),
('Standard SLA', 'SLA-STD-001', 'normal', 60, 480, 120),
('Low Priority SLA', 'SLA-LOW-001', 'low', 120, 1440, 240)
ON CONFLICT (policy_code) DO NOTHING;

INSERT INTO system_settings (setting_key, setting_value, setting_type, description, module) VALUES
('platform.name', 'OneCall Home Solutions', 'string', 'Platform name', 'general'),
('platform.version', '1.0.0', 'string', 'Platform version', 'general'),
('platform.timezone', 'Asia/Kolkata', 'string', 'Default timezone', 'general'),
('booking.auto_assign', 'true', 'boolean', 'Enable auto assignment', 'booking'),
('booking.cancellation_window_hours', '24', 'integer', 'Cancellation window in hours', 'booking'),
('payment.default_currency', 'INR', 'string', 'Default currency', 'payment'),
('notification.email_enabled', 'true', 'boolean', 'Enable email notifications', 'notification'),
('notification.sms_enabled', 'true', 'boolean', 'Enable SMS notifications', 'notification'),
('security.max_login_attempts', '5', 'integer', 'Maximum login attempts', 'security'),
('security.session_timeout_minutes', '30', 'integer', 'Session timeout in minutes', 'security')
ON CONFLICT (setting_key) DO NOTHING;