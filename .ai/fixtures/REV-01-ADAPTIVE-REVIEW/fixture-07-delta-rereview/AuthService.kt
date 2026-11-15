package com.example.fixture

class AuthService {
    // REMEDIATED IN ITERATION 2:
    fun fetchUserSafely(userId: String): Result<String> {
        return runCatching {
            // Safe network call wrapped in Result
            "User-$userId"
        }
    }

    // UNTOUCHED CODE FROM ITERATION 1:
    fun legacyHelperSync(): String {
        return "legacy"
    }
}
