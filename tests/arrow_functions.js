// Arrow Function Test Suite

print("=== Arrow Function Tests ===");

// Test 1: Expression body - single parameter
var double = (x) => x * 2;
print("Test 1: double(5) = " + double(5));

// Test 2: Expression body - two parameters
var add = (a, b) => a + b;
print("Test 2: add(3, 7) = " + add(3, 7));

// Test 3: Expression body - no parameters
var getFortyTwo = () => 42;
print("Test 3: getFortyTwo() = " + getFortyTwo());

// Test 4: Block body with return
var multiply = (x, y) => {
   var result = x * y;
   return result;
};
print("Test 4: multiply(6, 7) = " + multiply(6, 7));

// Test 5: Block body with conditional
var max = (a, b) => {
   if (a > b) {
      return a;
   } else {
      return b;
   }
};
print("Test 5: max(15, 8) = " + max(15, 8));

// Test 6: typeof arrow function
print("Test 6: typeof double = " + typeof double);

// Test 7: Arrow function in variable assignment
var square = (n) => n * n;
var result = square(9);
print("Test 7: square(9) = " + result);

// Test 8: Arrow function with boolean logic
var isEven = (n) => n % 2 == 0;
print("Test 8: isEven(4) = " + isEven(4));
print("Test 8: isEven(5) = " + isEven(5));

// Test 9: Arrow functions can call other functions
function increment(x) {
   return x + 1;
}
var doubleAndIncrement = (x) => increment(double(x));
print("Test 9: doubleAndIncrement(5) = " + doubleAndIncrement(5));

// Test 10: Multiple arrow functions
var subtract = (a, b) => a - b;
var divide = (a, b) => a / b;
print("Test 10: subtract(10, 3) = " + subtract(10, 3));
print("Test 10: divide(20, 4) = " + divide(20, 4));

print("All arrow function tests complete!");
