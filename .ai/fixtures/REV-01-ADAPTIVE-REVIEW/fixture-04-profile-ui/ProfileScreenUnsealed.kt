package com.example.fixture

import androidx.compose.runtime.*
import androidx.compose.material3.*

@Composable
fun ProfileScreenUnsealed(userId: String) {
    // VIOLATION: Loose mutable state variables instead of a sealed UiState
    var name by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    // Missing Error and Empty state handling completely!

    if (isLoading) {
        CircularProgressIndicator()
    } else {
        Text("User: $name")
    }
}
