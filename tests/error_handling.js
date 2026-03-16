// Test error handling with try/catch/throw

print("=== Error Handling Tests ===");
print("");

// Test 1: Basic try/catch
print("Test 1: Basic try/catch");
try {
    print("In try block");
    throw "Error message";
    print("This should not print");
} catch (e) {
    print("Caught error: " + e);
}
print("");

// Test 2: Try/finally without catch
print("Test 2: Try/finally");
let finallyExecuted = false;
try {
    print("In try block");
    finallyExecuted = true;
} finally {
    print("Finally block executed");
}
print("Finally was executed: " + finallyExecuted);
print("");

// Test 3: Try/catch/finally
print("Test 3: Try/catch/finally");
try {
    print("In try block");
    throw "Another error";
} catch (e) {
    print("Caught: " + e);
} finally {
    print("Finally always runs");
}
print("");

// Test 4: Throwing numbers
print("Test 4: Throw number");
try {
    throw 42;
} catch (e) {
    print("Caught number: " + e);
}
print("");

// Test 5: Throwing booleans
print("Test 5: Throw boolean");
try {
    throw true;
} catch (e) {
    print("Caught boolean: " + e);
}
print("");

// Test 6: Nested try/catch
print("Test 6: Nested try/catch");
try {
    print("Outer try");
    try {
        print("Inner try");
        throw "Inner error";
    } catch (e) {
        print("Inner catch: " + e);
        throw "Outer error";
    }
} catch (e) {
    print("Outer catch: " + e);
}
print("");

// Test 7: Try/catch in function
print("Test 7: Try/catch in function");
function riskyOperation(shouldFail) {
    try {
        if (shouldFail) {
            throw "Operation failed";
        }
        return "Success";
    } catch (e) {
        return "Failed: " + e;
    }
}
print(riskyOperation(false));
print(riskyOperation(true));
print("");

// Test 8: Try/catch in loop
print("Test 8: Try/catch in loop");
for (let i = 0; i < 3; i++) {
    try {
        if (i == 1) {
            throw "Error at iteration " + i;
        }
        print("Iteration " + i + " succeeded");
    } catch (e) {
        print("Caught: " + e);
    }
}
print("");

// Test 9: Finally with return
print("Test 9: Finally with early return");
function testFinally() {
    try {
        print("Before return");
        return "From try";
    } finally {
        print("Finally executes before return");
    }
}
let result = testFinally();
print("Result: " + result);
print("");

// Test 10: No error - catch not executed
print("Test 10: No error thrown");
try {
    print("No error here");
    let x = 10 + 5;
    print("x = " + x);
} catch (e) {
    print("This should not print");
}
print("After try/catch");
print("");

// Test 11: Error object with properties
print("Test 11: Throw object");
try {
    let errorObj = { message: "Something went wrong", code: 500 };
    throw errorObj;
} catch (e) {
    print("Caught object - message: " + e.message);
    print("Caught object - code: " + e.code);
}
print("");

// Test 12: Division by zero handling
print("Test 12: Custom error for invalid operation");
function divide(a, b) {
    if (b == 0) {
        throw "Division by zero";
    }
    return a / b;
}
try {
    let result1 = divide(10, 2);
    print("10 / 2 = " + result1);
    let result2 = divide(10, 0);
    print("This should not print");
} catch (e) {
    print("Error: " + e);
}
print("");

print("=== All Error Handling Tests Complete ===");
