// Control Flow Enhancements Test Suite

print("=== Ternary Operator Tests ===");

// Test 1: Basic ternary
var x = 5;
var y = 10;
var max = x > y ? x : y;
print("max(5, 10) = " + max);  // 10

// Test 2: String results
var age = 20;
var status = age >= 18 ? "adult" : "minor";
print("Age " + age + " is " + status);  // adult

// Test 3: Nested ternary
var score = 85;
var grade = score >= 90 ? "A" : score >= 80 ? "B" : score >= 70 ? "C" : "D";
print("Score " + score + " gets grade " + grade);  // B

// Test 4: Ternary in expressions
print("5 > 3 ? " + (5 > 3 ? "yes" : "no"));  // yes
print("2 > 7 ? " + (2 > 7 ? "yes" : "no"));  // no

// Test 5: Ternary with different types
var val = true ? 42 : "string";
print("true ? 42 : string = " + val);  // 42

var val2 = false ? 99 : "fallback";
print("false ? 99 : fallback = " + val2);  // fallback

// Test 6: Nested deeply
var n = 3;
var result = n > 5 ? "big" : n > 3 ? "medium" : n > 1 ? "small" : "tiny";
print("n=3: " + result);  // small

print("All ternary tests complete!");
