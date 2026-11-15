package com.example.fixture

data class UserProfile(
    val id: String,
    val name: String // strictly non-nullable in Kotlin type system
) {
    fun formatGreeting(): String {
        return "Hello, $name"
    }

    fun findIndex(users: List<String>): Int {
        val idx = users.indexOf(name) // style nit: naming
        return idx
    }
}
