package com.example.fixture

import java.util.NonExistentClass

class LinterViolation {
    fun doSomething(): NonExistentClass {
        return NonExistentClass()
    }
}
