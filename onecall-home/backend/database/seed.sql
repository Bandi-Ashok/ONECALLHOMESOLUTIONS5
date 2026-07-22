-- ============================================
-- ONE CALL HOME SOLUTIONS - Seed Data
-- ============================================

-- Roles
INSERT INTO roles (name, display_name, description, role_type, is_system) VALUES
('customer', 'Customer', 'End user of services', 'customer', true),
('technician', 'Technician', 'Service provider', 'technician', true),
('vendor', 'Vendor', 'Third-party vendor', 'vendor', true),
('admin', 'Admin', 'System Administrator', 'admin', true)
ON CONFLICT (name) DO NOTHING;

-- Service Categories
INSERT INTO service_categories (id, name, slug, description, icon_url, sort_order) VALUES
('c1000000-0000-0000-0000-000000000001', 'AC Repair & Service', 'ac-services', 'Air Conditioner servicing, gas refill, installation, and deep cleaning', 'https://cdn.onecall.com/icons/ac.svg', 1),
('c1000000-0000-0000-0000-000000000002', 'Electrical Services', 'electrical-services', 'Wiring, switch board installation, fan repair, MCB replacement', 'https://cdn.onecall.com/icons/electrical.svg', 2),
('c1000000-0000-0000-0000-000000000003', 'Plumbing Services', 'plumbing-services', 'Pipe repair, tap installation, water heater service, blockage clearing', 'https://cdn.onecall.com/icons/plumbing.svg', 3),
('c1000000-0000-0000-0000-000000000004', 'Cleaning & Deep Hygiene', 'cleaning-services', 'Full home deep cleaning, sofa cleaning, kitchen & bathroom sanitation', 'https://cdn.onecall.com/icons/cleaning.svg', 4),
('c1000000-0000-0000-0000-000000000005', 'Appliance Repair', 'appliance-repair', 'Washing machine, refrigerator, microwave, water purifier repair', 'https://cdn.onecall.com/icons/appliance.svg', 5),
('c1000000-0000-0000-0000-000000000006', 'Painters & Wall Care', 'painting-services', 'Full home painting, accent wall, waterproofing, texture painting', 'https://cdn.onecall.com/icons/painting.svg', 6),
('c1000000-0000-0000-0000-000000000007', 'Carpentry & Furniture', 'carpentry-services', 'Furniture assembly, door lock repair, modular kitchen fixes', 'https://cdn.onecall.com/icons/carpentry.svg', 7)
ON CONFLICT (slug) DO NOTHING;

-- Services
INSERT INTO services (id, category_id, name, slug, service_code, description, short_description, base_price, estimated_duration_minutes, warranty_days, is_popular) VALUES
('s2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'Split AC Foam & Jet Service', 'split-ac-service', 'AC-SRV-01', 'Thorough deep jet cleaning of indoor and outdoor coils with anti-bacterial foam treatment.', 'Deep jet & foam cleaning for maximum cooling', 599.00, 45, 30, true),
('s2000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 'AC Gas Refill (R32 / R410a)', 'ac-gas-refill', 'AC-GAS-02', 'Full refrigerant gas charging with leak detection and pressure check.', 'Complete refrigerant gas top-up', 1499.00, 60, 60, true),
('s2000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000002', 'Switchboard Repair & Replacement', 'switchboard-repair', 'EL-SWB-01', 'Safe replacement or repair of modular switchboards, sockets, and earthing checks.', 'Modular switch replacement and safety check', 299.00, 30, 30, true),
('s2000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000002', 'Complete Ceiling Fan Installation', 'fan-installation', 'EL-FAN-02', 'Assembly, mounting, downrod installation, and regulator wiring.', 'Fan assembly, mounting, and wiring', 199.00, 30, 30, false),
('s2000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000003', 'Tap & Faucet Leak Repair', 'tap-repair', 'PL-TAP-01', 'Washer replacement, spindle fix, or new faucet fitting with pressure testing.', 'Instant leak fix for taps & mixers', 199.00, 30, 30, true),
('s2000000-0000-0000-0000-000000000006', 'c1000000-0000-0000-0000-000000000003', 'Drainage Blockage Removal', 'drainage-unblock', 'PL-DRN-02', 'Heavy-duty drain auger machine cleaning for kitchen and bathroom drains.', 'High-pressure drain unblocking', 499.00, 45, 30, true),
('s2000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000004', 'Full Home Deep Cleaning (3BHK)', 'full-home-cleaning', 'CL-3BHK-01', 'Mechanized floor scrubbing, vacuuming, window pane wipe, kitchen and bathroom degreasing.', '3BHK complete home sanitation and deep clean', 3999.00, 240, 15, true),
('s2000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000005', 'RO Water Purifier Servicing', 'ro-filter-service', 'AP-RO-01', 'Sediment, carbon filter, and RO membrane health check and replacement.', 'Filter change, TDS calibration & sanitization', 499.00, 45, 30, true)
ON CONFLICT (slug) DO NOTHING;
