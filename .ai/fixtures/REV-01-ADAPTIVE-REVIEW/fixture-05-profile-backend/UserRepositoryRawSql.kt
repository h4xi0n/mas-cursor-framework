package com.example.fixture

import java.sql.Connection

class UserRepositoryRawSql(private val connection: Connection) {
    fun findUserByEmail(email: String): String? {
        // VIOLATION: SQL Injection vulnerability via raw string interpolation
        val query = "SELECT id, name FROM users WHERE email = '$email'"
        val statement = connection.createStatement()
        val resultSet = statement.executeQuery(query)
        return if (resultSet.next()) resultSet.getString("name") else null
    }
}
