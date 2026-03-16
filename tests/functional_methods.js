// Functional Array Methods Test Suite
print("=== Functional Array Methods Tests ===");
var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
print("Original: " + numbers);

// Test 1: map()
print("\n1. map():");
function double(x) { return x * 2; }
print("Doubled: " + numbers.map(double));
var square = (x) => x * x;
print("Squared: " + numbers.map(square));

// Test 2: filter()
print("\n2. filter():");
function isEven(x) { return x % 2 == 0; }
print("Evens: " + numbers.filter(isEven));
var greaterThan5 = (x) => x > 5;
print(">5: " + numbers.filter(greaterThan5));

// Test 3: forEach()
print("\n3. forEach():");
function printItem(x) { print("  " + x); }
[1, 2, 3].forEach(printItem);

// Test 4: find()
print("\n4. find():");
function isGT7(x) { return x > 7; }
print("First >7: " + numbers.find(isGT7));

// Test 5: reduce()
print("\n5. reduce():");
function add(a, x) { return a + x; }
print("Sum: " + numbers.reduce(add, 0));
function mult(a, x) { return a * x; }
print("Product 1-5: " + [1,2,3,4,5].reduce(mult, 1));

print("\nAll tests complete!");
