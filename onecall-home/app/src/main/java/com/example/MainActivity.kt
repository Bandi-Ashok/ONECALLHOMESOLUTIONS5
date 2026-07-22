package com.example

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.model.BookingItem
import com.example.data.model.ServiceCategory
import com.example.data.model.ServiceItem
import com.example.data.repository.OneCallRepository
import com.example.ui.screens.*
import com.example.ui.theme.MyApplicationTheme
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MyApplicationTheme {
                MainAppScreen()
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainAppScreen() {
    val context = LocalContext.current
    val repository = remember { OneCallRepository(context) }
    val scope = rememberCoroutineScope()

    val categories by repository.getCategories().collectAsStateWithLifecycle(initialValue = emptyList())
    val popularServices by repository.getPopularServices().collectAsStateWithLifecycle(initialValue = emptyList())
    val activeBooking by repository.getActiveBooking().collectAsStateWithLifecycle(initialValue = null)
    val bookings by repository.getAllBookings().collectAsStateWithLifecycle(initialValue = emptyList())
    val properties by repository.getProperties().collectAsStateWithLifecycle(initialValue = emptyList())
    val walletInfo by repository.walletState.collectAsStateWithLifecycle()
    val activeCity by repository.activeCity.collectAsStateWithLifecycle()
    val userMode by repository.userMode.collectAsStateWithLifecycle()

    var currentScreen by remember { mutableStateOf("home") } // "home", "catalog", "tracking", "properties", "portal", "wallet", "apidocs"
    var selectedCategory by remember { mutableStateOf<ServiceCategory?>(null) }
    var selectedCategoryServices by remember { mutableStateOf<List<ServiceItem>>(emptyList()) }
    var trackedBooking by remember { mutableStateOf<BookingItem?>(null) }

    val snackbarHostState = remember { SnackbarHostState() }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 8.dp
            ) {
                NavigationBarItem(
                    selected = currentScreen == "home" || currentScreen == "catalog",
                    onClick = { currentScreen = "home" },
                    icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                    label = { Text("Home") },
                    modifier = Modifier.testTag("nav_home")
                )
                NavigationBarItem(
                    selected = currentScreen == "properties",
                    onClick = { currentScreen = "properties" },
                    icon = { Icon(Icons.Default.HomeWork, contentDescription = "Properties") },
                    label = { Text("Properties") },
                    modifier = Modifier.testTag("nav_properties")
                )
                NavigationBarItem(
                    selected = currentScreen == "portal",
                    onClick = { currentScreen = "portal" },
                    icon = { Icon(Icons.Default.Engineering, contentDescription = "Provider") },
                    label = { Text(if (userMode == "technician") "Tech" else "Vendor") },
                    modifier = Modifier.testTag("nav_portal")
                )
                NavigationBarItem(
                    selected = currentScreen == "wallet",
                    onClick = { currentScreen = "wallet" },
                    icon = { Icon(Icons.Default.AccountBalanceWallet, contentDescription = "Wallet") },
                    label = { Text("Wallet") },
                    modifier = Modifier.testTag("nav_wallet")
                )
                NavigationBarItem(
                    selected = currentScreen == "apidocs",
                    onClick = { currentScreen = "apidocs" },
                    icon = { Icon(Icons.Default.Code, contentDescription = "API Docs") },
                    label = { Text("Backend Docs") },
                    modifier = Modifier.testTag("nav_apidocs")
                )
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.padding(innerPadding)) {
            when (currentScreen) {
                "home" -> {
                    HomeScreen(
                        categories = categories,
                        popularServices = popularServices,
                        activeBooking = activeBooking,
                        activeCity = activeCity,
                        onCitySelected = { repository.setCity(it) },
                        onCategoryClick = { category ->
                            selectedCategory = category
                            scope.launch {
                                repository.getServicesByCategory(category.id).collect {
                                    selectedCategoryServices = it
                                }
                            }
                            currentScreen = "catalog"
                        },
                        onServiceClick = { service ->
                            selectedCategoryServices = listOf(service)
                            selectedCategory = categories.find { it.id == service.categoryId }
                            currentScreen = "catalog"
                        },
                        onActiveBookingClick = { booking ->
                            trackedBooking = booking
                            currentScreen = "tracking"
                        },
                        onEmergencyCallClick = {
                            Toast.makeText(context, "Initiating Emergency Dispatch Call to OneCall Helpline 1800-ONECALL", Toast.LENGTH_LONG).show()
                        }
                    )
                }

                "catalog" -> {
                    ServiceCatalogScreen(
                        categoryName = selectedCategory?.name ?: "All Services",
                        services = selectedCategoryServices.ifEmpty { popularServices },
                        walletBalance = walletInfo.balance,
                        onBackClick = { currentScreen = "home" },
                        onBookService = { service, date, address, totalAmount ->
                            scope.launch {
                                val bookingNumber = repository.createBooking(
                                    serviceName = service.name,
                                    categoryName = selectedCategory?.name ?: "Home Services",
                                    scheduledDate = date,
                                    scheduledTime = "11:00 AM",
                                    address = address,
                                    totalAmount = totalAmount
                                )
                                snackbarHostState.showSnackbar("Booking Confirmed: $bookingNumber! Technician Suresh Patel dispatched.")
                                currentScreen = "home"
                            }
                        }
                    )
                }

                "tracking" -> {
                    val bookingToTrack = trackedBooking ?: activeBooking ?: bookings.firstOrNull()
                    if (bookingToTrack != null) {
                        BookingTrackingScreen(
                            booking = bookingToTrack,
                            onBackClick = { currentScreen = "home" },
                            onCallTechnician = { phone ->
                                Toast.makeText(context, "Calling Technician Suresh Patel at $phone", Toast.LENGTH_SHORT).show()
                            }
                        )
                    } else {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) {
                            Text("No active booking found.")
                        }
                    }
                }

                "properties" -> {
                    PropertiesScreen(
                        properties = properties,
                        onAddPropertyClick = {
                            Toast.makeText(context, "New property registration workflow opened.", Toast.LENGTH_SHORT).show()
                        }
                    )
                }

                "portal" -> {
                    TechnicianVendorPortalScreen(
                        bookings = bookings,
                        userMode = userMode,
                        onModeChange = { newMode ->
                            repository.setUserMode(newMode)
                        }
                    )
                }

                "wallet" -> {
                    WalletPaymentsScreen(
                        walletInfo = walletInfo,
                        onAddMoneyClick = { amount ->
                            scope.launch {
                                repository.addWalletBalance(amount)
                                snackbarHostState.showSnackbar("Added ₹${amount.toInt()} to OneCall Wallet via UPI!")
                            }
                        }
                    )
                }

                "apidocs" -> {
                    BackendApiSchemaDocScreen(
                        modules = repository.getModuleApiDocs()
                    )
                }
            }
        }
    }
}
