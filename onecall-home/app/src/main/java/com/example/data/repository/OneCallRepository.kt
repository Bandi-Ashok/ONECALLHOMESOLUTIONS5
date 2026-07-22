package com.example.data.repository

import android.content.Context
import com.example.data.local.AppDatabase
import com.example.data.local.BookingEntity
import com.example.data.local.CategoryEntity
import com.example.data.local.PropertyEntity
import com.example.data.local.ServiceEntity
import com.example.data.model.ApplianceItem
import com.example.data.model.BookingItem
import com.example.data.model.ModuleApiDoc
import com.example.data.model.PropertyItem
import com.example.data.model.ServiceCategory
import com.example.data.model.ServiceItem
import com.example.data.model.WalletInfo
import com.example.data.model.WalletTransaction
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class OneCallRepository(context: Context) {
    private val db = AppDatabase.getInstance(context)
    private val scope = CoroutineScope(Dispatchers.IO)

    private val _walletState = MutableStateFlow(
        WalletInfo(
            balance = 2500.00,
            totalCredited = 4500.00,
            totalDebited = 2000.00,
            currency = "INR",
            transactions = listOf(
                WalletTransaction("tx-101", "debit", 599.0, "Split AC Jet Service", "2026-07-20", "BK-MUM-26-9012"),
                WalletTransaction("tx-102", "credit", 1000.0, "Wallet Auto Top-Up (UPI)", "2026-07-18", "UPI-1928374"),
                WalletTransaction("tx-103", "debit", 299.0, "Switchboard Replacement", "2026-07-15", "BK-MUM-26-8812"),
                WalletTransaction("tx-104", "credit", 500.0, "Referral Bonus Credit", "2026-07-10", "REF-BONUS-01")
            )
        )
    )
    val walletState: StateFlow<WalletInfo> = _walletState.asStateFlow()

    private val _activeCity = MutableStateFlow("Mumbai")
    val activeCity: StateFlow<String> = _activeCity.asStateFlow()

    private val _userMode = MutableStateFlow("customer") // "customer", "technician", "vendor"
    val userMode: StateFlow<String> = _userMode.asStateFlow()

    init {
        scope.launch {
            seedInitialDataIfEmpty()
        }
    }

    fun setCity(city: String) {
        _activeCity.value = city
    }

    fun setUserMode(mode: String) {
        _userMode.value = mode
    }

    private suspend fun seedInitialDataIfEmpty() {
        val categories = listOf(
            CategoryEntity("cat-1", "AC Repair & Service", "ac-services", "Deep foam jet cleaning, gas charging & installation", "ac_unit", 12, 4.8),
            CategoryEntity("cat-2", "Electrical Services", "electrical-services", "Wiring, modular switches, fans & MCB panels", "bolt", 15, 4.7),
            CategoryEntity("cat-3", "Plumbing Services", "plumbing-services", "Tap leak repair, unblocking, geyser & pipe fittings", "plumbing", 10, 4.6),
            CategoryEntity("cat-4", "Cleaning & Sanitation", "cleaning-services", "3BHK deep clean, kitchen degreasing & sofa shampoo", "cleaning_services", 8, 4.9),
            CategoryEntity("cat-5", "Appliance Repair", "appliance-repair", "Washing machine, fridge, microwave & RO water filter", "kitchen", 14, 4.7),
            CategoryEntity("cat-6", "Painting & Wall Care", "painting-services", "Full home painting, waterproofing & texture walls", "format_paint", 6, 4.8),
            CategoryEntity("cat-7", "Carpentry & Locks", "carpentry-services", "Furniture assembly, door lock repair & cabinets", "carpenter", 9, 4.6)
        )
        db.categoryDao().insertCategories(categories)

        val services = listOf(
            ServiceEntity("srv-101", "cat-1", "Split AC Foam & Jet Service", "AC-SRV-01", "Thorough indoor & outdoor deep jet cleaning with anti-bacterial foam treatment.", "Deep jet cleaning for maximum cooling", 599.00, 45, 30, true, 4.8, 420),
            ServiceEntity("srv-102", "cat-1", "AC Gas Refill (R32 / R410a)", "AC-GAS-02", "Full refrigerant gas top-up with leak testing and compressor pressure check.", "Complete gas refill & leak fix", 1499.00, 60, 60, true, 4.9, 310),
            ServiceEntity("srv-103", "cat-2", "Switchboard Replacement & Repair", "EL-SWB-01", "Installation or repair of modular switchboards, earthing & safety test.", "Modular switch fix & safety check", 299.00, 30, 30, true, 4.7, 185),
            ServiceEntity("srv-104", "cat-2", "Ceiling Fan Assembly & Fitment", "EL-FAN-02", "Assembly, heavy downrod mounting, regulator wiring & safety check.", "Complete fan installation", 199.00, 30, 30, false, 4.6, 95),
            ServiceEntity("srv-105", "cat-3", "Tap & Faucet Leak Fix", "PL-TAP-01", "Instant washer replacement, spindle fix, or new faucet installation.", "Quick leak repair for taps", 199.00, 30, 30, true, 4.8, 280),
            ServiceEntity("srv-106", "cat-3", "Drainage Blockage Clearing", "PL-DRN-02", "High-pressure drain auger machine cleaning for clogged pipes.", "Heavy-duty drain unblocking", 499.00, 45, 30, true, 4.7, 150),
            ServiceEntity("srv-107", "cat-4", "Full Home Deep Cleaning (3BHK)", "CL-3BHK-01", "Mechanized floor scrubbing, vacuuming, window wipe, degreasing.", "3BHK complete sanitation & deep clean", 3999.00, 240, 15, true, 4.9, 530),
            ServiceEntity("srv-108", "cat-5", "RO Water Purifier Servicing", "AP-RO-01", "Sediment, carbon filter change, RO membrane health check & TDS calibration.", "Filter change & TDS calibration", 499.00, 45, 30, true, 4.8, 340)
        )
        db.serviceDao().insertServices(services)

        val activeBooking = BookingEntity(
            id = "bk-active-001",
            bookingNumber = "BK-MUM-26-102938",
            serviceName = "Split AC Foam & Jet Service",
            categoryName = "AC Repair & Service",
            status = "en_route",
            scheduledDate = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date()),
            scheduledTime = "11:00 AM",
            address = "1201, Palm Springs, Linking Road, Bandra West, Mumbai 400050",
            totalAmount = 599.00,
            paymentStatus = "paid",
            technicianName = "Suresh Patel",
            technicianPhone = "+91-9876543221",
            technicianRating = 4.9,
            estimatedArrivalMinutes = 15
        )
        db.bookingDao().insertBooking(activeBooking)

        val defaultProperty = PropertyEntity(
            id = "prop-001",
            name = "Bandra Residence",
            propertyType = "Apartment (3BHK)",
            address = "1201, Palm Springs, Linking Road, Bandra West",
            city = "Mumbai",
            pincode = "400050",
            appliancesCount = 5
        )
        db.propertyDao().insertProperty(defaultProperty)
    }

    fun getCategories(): Flow<List<ServiceCategory>> {
        return db.categoryDao().getAllCategories().map { list ->
            list.map {
                ServiceCategory(it.id, it.name, it.slug, it.description, it.iconName, it.serviceCount, it.rating)
            }
        }
    }

    fun getServicesByCategory(categoryId: String): Flow<List<ServiceItem>> {
        return db.serviceDao().getServicesByCategory(categoryId).map { list ->
            list.map {
                ServiceItem(it.id, it.categoryId, it.name, it.serviceCode, it.description, it.shortDescription, it.basePrice, it.estimatedDurationMinutes, it.warrantyDays, it.isPopular, it.rating, it.reviewCount)
            }
        }
    }

    fun getPopularServices(): Flow<List<ServiceItem>> {
        return db.serviceDao().getPopularServices().map { list ->
            list.map {
                ServiceItem(it.id, it.categoryId, it.name, it.serviceCode, it.description, it.shortDescription, it.basePrice, it.estimatedDurationMinutes, it.warrantyDays, it.isPopular, it.rating, it.reviewCount)
            }
        }
    }

    fun getAllBookings(): Flow<List<BookingItem>> {
        return db.bookingDao().getAllBookings().map { list ->
            list.map {
                BookingItem(it.id, it.bookingNumber, it.serviceName, it.categoryName, it.status, it.scheduledDate, it.scheduledTime, it.address, it.totalAmount, it.paymentStatus, it.technicianName, it.technicianPhone, it.technicianRating, it.estimatedArrivalMinutes)
            }
        }
    }

    fun getActiveBooking(): Flow<BookingItem?> {
        return db.bookingDao().getActiveBooking().map {
            it?.let {
                BookingItem(it.id, it.bookingNumber, it.serviceName, it.categoryName, it.status, it.scheduledDate, it.scheduledTime, it.address, it.totalAmount, it.paymentStatus, it.technicianName, it.technicianPhone, it.technicianRating, it.estimatedArrivalMinutes)
            }
        }
    }

    fun getProperties(): Flow<List<PropertyItem>> {
        return db.propertyDao().getAllProperties().map { list ->
            list.map { p ->
                PropertyItem(
                    id = p.id,
                    name = p.name,
                    propertyType = p.propertyType,
                    address = p.address,
                    city = p.city,
                    pincode = p.pincode,
                    appliancesCount = p.appliancesCount,
                    appliances = listOf(
                        ApplianceItem("app-1", "Daikin 1.5T Inverter AC", "Daikin", "Master Bedroom", "excellent", "Active (Warranty valid till Jan 2027)", "2027-01-10", true),
                        ApplianceItem("app-2", "Kent Grand Star RO Filter", "Kent", "Kitchen", "good", "Active (AMC Active)", "2026-12-31", true),
                        ApplianceItem("app-3", "Samsung 275L Refrigerator", "Samsung", "Kitchen", "excellent", "Standard Warranty", "2028-06-15", false)
                    )
                )
            }
        }
    }

    suspend fun createBooking(
        serviceName: String,
        categoryName: String,
        scheduledDate: String,
        scheduledTime: String,
        address: String,
        totalAmount: Double
    ): String {
        val newId = "bk-" + System.currentTimeMillis()
        val bookingNum = "BK-MUM-26-" + (100000..900000).random()
        val entity = BookingEntity(
            id = newId,
            bookingNumber = bookingNum,
            serviceName = serviceName,
            categoryName = categoryName,
            status = "assigned",
            scheduledDate = scheduledDate,
            scheduledTime = scheduledTime,
            address = address,
            totalAmount = totalAmount,
            paymentStatus = "paid",
            technicianName = "Suresh Patel",
            technicianPhone = "+91-9876543221",
            technicianRating = 4.9,
            estimatedArrivalMinutes = 20
        )
        db.bookingDao().insertBooking(entity)

        // Deduct from wallet
        val current = _walletState.value
        val updatedTx = listOf(
            WalletTransaction("tx-" + System.currentTimeMillis(), "debit", totalAmount, serviceName, scheduledDate, bookingNum)
        ) + current.transactions
        _walletState.value = current.copy(
            balance = current.balance - totalAmount,
            totalDebited = current.totalDebited + totalAmount,
            transactions = updatedTx
        )

        return bookingNum
    }

    suspend fun addWalletBalance(amount: Double) {
        val current = _walletState.value
        val dateStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val updatedTx = listOf(
            WalletTransaction("tx-" + System.currentTimeMillis(), "credit", amount, "Wallet Top-up via UPI", dateStr, "UPI-" + (1000000..9999999).random())
        ) + current.transactions
        _walletState.value = current.copy(
            balance = current.balance + amount,
            totalCredited = current.totalCredited + amount,
            transactions = updatedTx
        )
    }

    fun getModuleApiDocs(): List<ModuleApiDoc> {
        return listOf(
            ModuleApiDoc(1, "Authentication & Identity", "User Auth, JWT sessions, OAuth, Phone/Email OTP, Roles & Permissions", 49, "Complete", listOf("users", "user_profiles", "roles", "user_roles", "user_sessions"), listOf("POST /api/v1/auth/register/customer", "POST /api/v1/auth/login", "POST /api/v1/auth/verify/phone", "POST /api/v1/auth/token/refresh")),
            ModuleApiDoc(2, "Customer Management", "Customer 360 profile, addresses, wallet ledger, loyalty tiering, referral engine", 87, "Complete", listOf("customers", "customer_addresses", "customer_wallets", "wallet_transactions", "loyalty_program"), listOf("GET /api/v1/customers/{id}", "PUT /api/v1/customers/{id}", "POST /api/v1/customers/{id}/addresses", "GET /api/v1/customers/{id}/wallet")),
            ModuleApiDoc(3, "Property Management", "Property digital twins, rooms layout, appliances inventory, inspection reports", 64, "Complete", listOf("properties", "property_rooms", "property_appliances", "service_inspections"), listOf("POST /api/v1/properties", "GET /api/v1/properties/{id}", "POST /api/v1/properties/{id}/rooms", "POST /api/v1/appliances")),
            ModuleApiDoc(4, "Technician Management", "Technician profile, verified skills, availability shifts, earnings & background check", 84, "Complete", listOf("technicians", "technician_skills", "technician_availability", "technician_earnings"), listOf("GET /api/v1/technicians/{id}", "POST /api/v1/technicians/apply", "POST /api/v1/technicians/{id}/location")),
            ModuleApiDoc(5, "Service Management", "Service catalog, categories, pricing components, add-ons, booking engine", 77, "Complete", listOf("service_categories", "services", "service_pricing", "service_packages"), listOf("GET /api/v1/services/categories", "POST /api/v1/bookings", "GET /api/v1/bookings/{id}", "PATCH /api/v1/bookings/{id}/start")),
            ModuleApiDoc(6, "Inventory & Parts Management", "Spare parts catalog, multi-warehouse stock, purchase orders, fulfillment & returns", 84, "Complete", listOf("products", "inventory_warehouses", "inventory_stock", "purchase_orders"), listOf("GET /api/v1/inventory/parts", "POST /api/v1/inventory/parts/request", "POST /api/v1/inventory/warehouses/transfer")),
            ModuleApiDoc(7, "Payment & Billing", "Razorpay / UPI intents, GST tax invoices, refund workflow, technician payouts", 80, "Complete", listOf("payments", "invoices", "invoice_items", "refunds"), listOf("POST /api/v1/payments/create-intent", "POST /api/v1/invoices", "GET /api/v1/invoices/{id}/download")),
            ModuleApiDoc(8, "Notifications & Communication", "Multi-channel Email, SMS, FCM Push, WhatsApp Business API & templates", 70, "Complete", listOf("notifications", "notification_templates", "notification_preferences", "chat_messages"), listOf("POST /api/v1/notifications/send", "POST /api/v1/email/send", "POST /api/v1/whatsapp/send")),
            ModuleApiDoc(9, "Dispatch & Logistics", "AI skill matching, route optimization, real-time location tracking, arrival alerts", 56, "Complete", listOf("dispatch_queue", "scheduling_slots", "route_plans", "service_locations"), listOf("POST /api/v1/dispatch/find-technicians", "POST /api/v1/dispatch/assign", "POST /api/v1/dispatch/route/optimize")),
            ModuleApiDoc(10, "Vendor Management", "Third-party vendor partners, SLAs, quality audits, rate contracts & commission", 60, "Complete", listOf("vendors", "vendor_technicians", "vendor_invoices", "rate_contracts"), listOf("POST /api/v1/vendors/register", "GET /api/v1/vendors/{id}", "POST /api/v1/vendors/services/assign")),
            ModuleApiDoc(11, "Workforce Management", "Employee records, shift scheduling, attendance check-in, leave approval & payroll", 80, "Complete", listOf("employees", "departments", "shift_management", "employee_attendance"), listOf("POST /api/v1/workforce/employees", "POST /api/v1/workforce/attendance", "POST /api/v1/workforce/leaves")),
            ModuleApiDoc(12, "Customer Relationship Management (CRM)", "Leads, customer segmentation, automated marketing campaigns, pipeline", 50, "Complete", listOf("crm_leads", "crm_activities", "crm_deals"), listOf("POST /api/v1/crm/leads", "POST /api/v1/crm/campaigns", "POST /api/v1/crm/segments")),
            ModuleApiDoc(13, "Analytics & Reporting", "Operational BI, revenue dashboards, SLA compliance, technician ranking reports", 60, "Complete", listOf("analytics_dashboards", "analytics_reports", "kpi_definitions", "kpi_values"), listOf("GET /api/v1/analytics/dashboards", "GET /api/v1/analytics/reports", "POST /api/v1/analytics/query")),
            ModuleApiDoc(14, "AI Platform & Recommendations", "Gemini AI model integration, churn prediction, smart time slot, price elasticity", 55, "Complete", listOf("ai_models", "ai_predictions", "ai_recommendations"), listOf("GET /api/v1/ai/recommendations/services", "POST /api/v1/ai/forecast/demand")),
            ModuleApiDoc(15, "Platform Administration", "Feature flags, global system settings, user role elevation, maintenance controls", 50, "Complete", listOf("system_settings", "feature_flags", "business_configurations"), listOf("GET /api/v1/admin/config", "PATCH /api/v1/admin/features/{id}/enable")),
            ModuleApiDoc(16, "Security & Compliance", "Access control lists, audit logs, GDPR/DPDP data anonymization, incident response", 40, "Complete", listOf("audit_logs", "activity_logs", "compliance_records", "consent_records"), listOf("POST /api/v1/security/data/anonymize", "GET /api/v1/security/compliance/report")),
            ModuleApiDoc(17, "File Management & Storage", "Document & media uploads, thumbnails, virus scan, chunked upload, bucket storage", 35, "Complete", listOf("files", "folders", "file_versions", "media_library"), listOf("POST /api/v1/files/upload", "GET /api/v1/files/{id}/download")),
            ModuleApiDoc(18, "Search & Maps Services", "Full-text search vector index, forward/reverse geocoding, geofences & distance", 30, "Complete", listOf("search_index", "geofence_zones", "map_cache"), listOf("GET /api/v1/search", "POST /api/v1/maps/geocode", "GET /api/v1/maps/distance")),
            ModuleApiDoc(19, "External Integrations", "Webhooks, API gateway keys, SMS/Email provider adapters, ERP/CRM sync", 40, "Complete", listOf("api_integrations", "webhook_events", "webhook_logs", "integration_tokens"), listOf("POST /api/v1/integrations", "POST /api/v1/integrations/sync")),
            ModuleApiDoc(20, "Monitoring & Observability", "Application logs, error tracking, microservice health checks, response metrics", 25, "Complete", listOf("application_logs", "error_logs", "health_checks", "performance_metrics"), listOf("GET /api/v1/monitoring/metrics", "GET /api/v1/monitoring/health")),
            ModuleApiDoc(21, "Backup & Disaster Recovery", "Automated database snapshots, point-in-time recovery, restoration history", 15, "Complete", listOf("backup_jobs", "backup_history", "restore_history"), listOf("POST /api/v1/backup/backups", "POST /api/v1/backup/recovery/restore")),
            ModuleApiDoc(22, "Multi-Branch & Region Management", "Regional jurisdictions, branch centers, city-level pricing multipliers", 30, "Complete", listOf("regions", "branches", "branch_settings", "city_pricing"), listOf("POST /api/v1/branches", "GET /api/v1/branches/{id}/performance")),
            ModuleApiDoc(23, "Super Admin & System Controls", "Global tenant isolation, maintenance mode, system reindex, system shutdown", 50, "Complete", listOf("system_settings", "audit_logs", "roles"), listOf("POST /api/v1/system/maintenance/enter", "POST /api/v1/system/cache/clear"))
        )
    }
}
