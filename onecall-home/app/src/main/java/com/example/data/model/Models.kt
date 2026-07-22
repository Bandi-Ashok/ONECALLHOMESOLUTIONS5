package com.example.data.model

data class ServiceCategory(
    val id: String,
    val name: String,
    val slug: String,
    val description: String,
    val iconName: String,
    val serviceCount: Int,
    val rating: Double
)

data class ServiceItem(
    val id: String,
    val categoryId: String,
    val name: String,
    val serviceCode: String,
    val description: String,
    val shortDescription: String,
    val basePrice: Double,
    val estimatedDurationMinutes: Int,
    val warrantyDays: Int,
    val isPopular: Boolean,
    val rating: Double,
    val reviewCount: Int
)

data class BookingItem(
    val id: String,
    val bookingNumber: String,
    val serviceName: String,
    val categoryName: String,
    val status: String, // pending, confirmed, assigned, en_route, in_progress, completed, cancelled
    val scheduledDate: String,
    val scheduledTime: String,
    val address: String,
    val totalAmount: Double,
    val paymentStatus: String,
    val technicianName: String?,
    val technicianPhone: String?,
    val technicianRating: Double?,
    val estimatedArrivalMinutes: Int?
)

data class PropertyItem(
    val id: String,
    val name: String,
    val propertyType: String, // apartment, villa, office
    val address: String,
    val city: String,
    val pincode: String,
    val appliancesCount: Int,
    val appliances: List<ApplianceItem>
)

data class ApplianceItem(
    val id: String,
    val name: String,
    val brand: String,
    val roomName: String,
    val condition: String, // excellent, good, needs_service
    val warrantyStatus: String,
    val warrantyExpiryDate: String,
    val amcActive: Boolean
)

data class WalletInfo(
    val balance: Double,
    val totalCredited: Double,
    val totalDebited: Double,
    val currency: String = "INR",
    val transactions: List<WalletTransaction>
)

data class WalletTransaction(
    val id: String,
    val type: String, // credit, debit
    val amount: Double,
    val title: String,
    val date: String,
    val referenceId: String?
)

data class ModuleApiDoc(
    val moduleNumber: Int,
    val name: String,
    val description: String,
    val totalEndpoints: Int,
    val status: String,
    val keyTables: List<String>,
    val endpointsSummary: List<String>
)
