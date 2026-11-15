package com.example.fixture

class UserSessionBugFix {
    private var token: String? = null

    // Fixes NPE by returning empty string instead of throwing, but added zero tests
    fun getAuthorizationHeader(): String {
        return token?.let { "Bearer $it" } ?: ""
    }
}
