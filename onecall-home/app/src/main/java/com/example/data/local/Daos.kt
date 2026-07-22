package com.example.data.local

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface CategoryDao {
    @Query("SELECT * FROM categories ORDER BY name ASC")
    fun getAllCategories(): Flow<List<CategoryEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCategories(categories: List<CategoryEntity>)
}

@Dao
interface ServiceDao {
    @Query("SELECT * FROM services WHERE categoryId = :categoryId ORDER BY name ASC")
    fun getServicesByCategory(categoryId: String): Flow<List<ServiceEntity>>

    @Query("SELECT * FROM services WHERE isPopular = 1")
    fun getPopularServices(): Flow<List<ServiceEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertServices(services: List<ServiceEntity>)
}

@Dao
interface BookingDao {
    @Query("SELECT * FROM bookings ORDER BY scheduledDate DESC, scheduledTime DESC")
    fun getAllBookings(): Flow<List<BookingEntity>>

    @Query("SELECT * FROM bookings WHERE status IN ('confirmed', 'assigned', 'en_route', 'in_progress') ORDER BY scheduledDate ASC LIMIT 1")
    fun getActiveBooking(): Flow<BookingEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBooking(booking: BookingEntity)

    @Query("UPDATE bookings SET status = :status WHERE id = :bookingId")
    suspend fun updateBookingStatus(bookingId: String, status: String)
}

@Dao
interface PropertyDao {
    @Query("SELECT * FROM properties")
    fun getAllProperties(): Flow<List<PropertyEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProperty(property: PropertyEntity)
}
