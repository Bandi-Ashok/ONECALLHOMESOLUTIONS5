package com.example.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "categories")
data class CategoryEntity(
    @PrimaryKey val id: String,
    val name: String,
    val slug: String,
    val description: String,
    val iconName: String,
    val serviceCount: Int,
    val rating: Double
)

@Entity(tableName = "services")
data class ServiceEntity(
    @PrimaryKey val id: String,
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

@Entity(tableName = "bookings")
data class BookingEntity(
    @PrimaryKey val id: String,
    val bookingNumber: String,
    val serviceName: String,
    val categoryName: String,
    val status: String,
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

@Entity(tableName = "properties")
data class PropertyEntity(
    @PrimaryKey val id: String,
    val name: String,
    val propertyType: String,
    val address: String,
    val city: String,
    val pincode: String,
    val appliancesCount: Int
)
