// Error Handling Example - User Input Validator

print("=== User Input Validator ===");
print("");

// Validate email format
function validateEmail(email) {
    try {
        // Check for @ symbol
        let hasAt = false;
        for (let i = 0; i < email.length; i++) {
            if (email[i] == "@") {
                hasAt = true;
                break;
            }
        }
        
        if (!hasAt) {
            throw { type: "ValidationError", message: "Email must contain @ symbol" };
        }
        
        // Check minimum length
        if (email.length < 5) {
            throw { type: "ValidationError", message: "Email too short" };
        }
        
        return { valid: true, email: email };
    } catch (error) {
        return { valid: false, error: error.message };
    }
}

// Validate age
function validateAge(age) {
    try {
        if (age < 0) {
            throw "Age cannot be negative";
        }
        if (age > 150) {
            throw "Age is unrealistic";
        }
        return { valid: true, age: age };
    } catch (error) {
        return { valid: false, error: error };
    }
}

// Safe division
function safeDivide(a, b) {
    try {
        if (b == 0) {
            throw "Cannot divide by zero";
        }
        return { success: true, result: a / b };
    } catch (error) {
        return { success: false, error: error };
    }
}

// Array access with bounds checking
function safeArrayAccess(arr, index) {
    try {
        if (index < 0 || index >= arr.length) {
            throw "Index out of bounds: " + index;
        }
        return { success: true, value: arr[index] };
    } catch (error) {
        return { success: false, error: error };
    }
}

// Test email validation
print("--- Email Validation ---");
let emails = ["user@example.com", "invalid", "a@b.c", "test@domain.org"];
for (let i = 0; i < emails.length; i++) {
    let result = validateEmail(emails[i]);
    if (result.valid) {
        print(" Valid email: " + result.email);
    } else {
        print(" Invalid email: " + emails[i] + " - " + result.error);
    }
}
print("");

// Test age validation
print("--- Age Validation ---");
let ages = [25, -5, 150, 200, 0];
for (let i = 0; i < ages.length; i++) {
    let result = validateAge(ages[i]);
    if (result.valid) {
        print(" Valid age: " + result.age);
    } else {
        print(" Invalid age: " + ages[i] + " - " + result.error);
    }
}
print("");

// Test safe division
print("--- Safe Division ---");
let divisions = [
    { a: 10, b: 2 },
    { a: 15, b: 3 },
    { a: 100, b: 0 },
    { a: 7, b: 0 }
];
for (let i = 0; i < divisions.length; i++) {
    let op = divisions[i];
    let result = safeDivide(op.a, op.b);
    if (result.success) {
        print(" " + op.a + " / " + op.b + " = " + result.result);
    } else {
        print(" " + op.a + " / " + op.b + " - " + result.error);
    }
}
print("");

// Test safe array access
print("--- Safe Array Access ---");
let numbers = [10, 20, 30, 40, 50];
let indices = [0, 2, 4, 5, -1, 10];
for (let i = 0; i < indices.length; i++) {
    let idx = indices[i];
    let result = safeArrayAccess(numbers, idx);
    if (result.success) {
        print(" numbers[" + idx + "] = " + result.value);
    } else {
        print(" numbers[" + idx + "] - " + result.error);
    }
}
print("");

// Complex example: Process data with error recovery
print("--- Data Processing with Error Recovery ---");
function processUserData(users) {
    let processed = 0;
    let errors = 0;
    
    for (let i = 0; i < users.length; i++) {
        try {
            let user = users[i];
            
            // Validate required fields
            if (!user.name) {
                throw "Missing name";
            }
            if (!user.age) {
                throw "Missing age";
            }
            
            // Process user
            print("Processing: " + user.name + ", age " + user.age);
            processed++;
            
        } catch (error) {
            print("Error processing user " + i + ": " + error);
            errors++;
        } finally {
            // This always runs, good for cleanup/logging
            if (i == users.length - 1) {
                print("Finished processing all users");
            }
        }
    }
    
    return { processed: processed, errors: errors };
}

let users = [
    { name: "Alice", age: 30 },
    { name: "Bob" },
    { age: 25 },
    { name: "Charlie", age: 35 }
];

let summary = processUserData(users);
print("Summary: " + summary.processed + " processed, " + summary.errors + " errors");
