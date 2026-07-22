package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.data.model.WalletInfo

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WalletPaymentsScreen(
    walletInfo: WalletInfo,
    onAddMoneyClick: (Double) -> Unit
) {
    var showTopupDialog by remember { mutableStateOf(false) }
    var topupAmountText by remember { mutableStateOf("1000") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("OneCall Wallet & Receipts", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = Color.White
                )
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(MaterialTheme.colorScheme.background)
        ) {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Wallet Balance Card
                item {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("wallet_balance_card"),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primary),
                        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
                    ) {
                        Column(modifier = Modifier.padding(20.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(
                                        text = "ONECALL WALLET BALANCE",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White.copy(alpha = 0.8f)
                                    )
                                    Text(
                                        text = "₹${walletInfo.balance.toInt()}.00",
                                        style = MaterialTheme.typography.headlineLarge,
                                        fontWeight = FontWeight.ExtraBold,
                                        color = Color.White
                                    )
                                }

                                Button(
                                    onClick = { showTopupDialog = true },
                                    colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = MaterialTheme.colorScheme.primary),
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.testTag("add_money_button")
                                ) {
                                    Icon(Icons.Default.Add, contentDescription = null)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("TOP UP", fontWeight = FontWeight.Bold)
                                }
                            }

                            Spacer(modifier = Modifier.height(16.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column {
                                    Text("Total Credited", style = MaterialTheme.typography.labelSmall, color = Color.White.copy(alpha = 0.7f))
                                    Text("₹${walletInfo.totalCredited.toInt()}", style = MaterialTheme.typography.bodyMedium, color = Color.White, fontWeight = FontWeight.Bold)
                                }
                                Column {
                                    Text("Total Debited", style = MaterialTheme.typography.labelSmall, color = Color.White.copy(alpha = 0.7f))
                                    Text("₹${walletInfo.totalDebited.toInt()}", style = MaterialTheme.typography.bodyMedium, color = Color.White, fontWeight = FontWeight.Bold)
                                }
                                Column {
                                    Text("Cashback Earned", style = MaterialTheme.typography.labelSmall, color = Color.White.copy(alpha = 0.7f))
                                    Text("₹500", style = MaterialTheme.typography.bodyMedium, color = Color(0xFF10B981), fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }

                // Recent Transactions Header
                item {
                    Text(
                        text = "Recent Wallet Transactions",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }

                items(walletInfo.transactions) { tx ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    imageVector = if (tx.type == "credit") Icons.Default.ArrowDownward else Icons.Default.ArrowUpward,
                                    contentDescription = null,
                                    tint = if (tx.type == "credit") Color(0xFF059669) else Color(0xFFE11D48)
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text(text = tx.title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                                    Text(text = "${tx.date} • ${tx.referenceId ?: ""}", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }

                            Text(
                                text = "${if (tx.type == "credit") "+" else "-"}₹${tx.amount.toInt()}",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = if (tx.type == "credit") Color(0xFF059669) else Color(0xFFE11D48)
                            )
                        }
                    }
                }
            }
        }
    }

    if (showTopupDialog) {
        AlertDialog(
            onDismissRequest = { showTopupDialog = false },
            title = { Text("Top Up OneCall Wallet", fontWeight = FontWeight.Bold) },
            text = {
                Column {
                    Text("Select or enter amount to add via Instant UPI / Net Banking:")
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = topupAmountText,
                        onValueChange = { topupAmountText = it },
                        label = { Text("Amount (₹)") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf(500.0, 1000.0, 2000.0).forEach { amt ->
                            OutlinedButton(
                                onClick = { topupAmountText = amt.toInt().toString() },
                                modifier = Modifier.weight(1f)
                            ) {
                                Text("+₹${amt.toInt()}")
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val amt = topupAmountText.toDoubleOrNull() ?: 500.0
                        onAddMoneyClick(amt)
                        showTopupDialog = false
                    }
                ) {
                    Text("PROCEED TO PAY")
                }
            },
            dismissButton = {
                TextButton(onClick = { showTopupDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
