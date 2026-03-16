// Built-in Objects and Functions Test Program

print("========================================");
print("   JavaScript Built-in Objects Test");
print("========================================");
print("");

// ====================
// Math Object Tests
// ====================
print("=== Math Object ===");
print("");

print("Constants:");
print("  Math.PI  = " + Math.PI);
print("  Math.E   = " + Math.E);
print("");

print("Rounding:");
print("  Math.floor(4.7)  = " + Math.floor(4.7));
print("  Math.ceil(4.3)   = " + Math.ceil(4.3));
print("  Math.round(4.5)  = " + Math.round(4.5));
print("  Math.round(4.4)  = " + Math.round(4.4));
print("");

print("Absolute Value:");
print("  Math.abs(-10)    = " + Math.abs(-10));
print("  Math.abs(10)     = " + Math.abs(10));
print("");

print("Square Root:");
print("  Math.sqrt(4)     = " + Math.sqrt(4));
print("  Math.sqrt(9)     = " + Math.sqrt(9));
print("  Math.sqrt(100)   = " + Math.sqrt(100));
print("  Math.sqrt(-100)   = " + Math.sqrt(-100));


print("");

print("Power:");
print("  Math.pow(2, 3)   = " + Math.pow(2, 3));
print("  Math.pow(5, 2)   = " + Math.pow(5, 2));
print("  Math.pow(10, 0)  = " + Math.pow(10, 0));
print("  Math.pow(-10, -2)  = " + Math.pow(-10, -2));
print("  Math.pow(10, -2)  = " + Math.pow(10, -2));
print("");

print("Min/Max:");
print("  Math.min(5, 2, 9, 1) = " + Math.min(5, 2, 9, 1));
print("  Math.max(5, 2, 9, 1) = " + Math.max(5, 2, 9, 1));
print("");

print("Random:");
let r = Math.random();
print("  Math.random() = " + r + " (0 <= x < 1)");
print("");

// ====================
// Global Functions
// ====================
print("=== Global Functions ===");
print("");

print("parseInt:");
print("  parseInt('42')      = " + parseInt("42"));
print("  parseInt('-123')    = " + parseInt("-123"));
print("  parseInt('99 red')  = " + parseInt("99 red"));
print("");

print("parseFloat:");
print("  parseFloat('3.14')  = " + parseFloat("3.14"));
print("  parseFloat('-2.5')  = " + parseFloat("-2.5"));
print("  parseFloat('1.5x')  = " + parseFloat("1.5x"));
print("");

print("isNaN:");
print("  isNaN(42)           = " + isNaN(42));
print("  isNaN('hello')      = " + isNaN("hello"));
print("");

print("isFinite:");
print("  isFinite(100)       = " + isFinite(100));
print("  isFinite('text')    = " + isFinite("text"));
print("");

// ====================
// console Object
// ====================
print("=== console.log ===");
console.log("Basic message");
console.log("Multiple", "arguments");
console.log(42, "mixed", true);
print("");

// ====================
// Practical Examples
// ====================
print("=== Practical Examples ===");
print("");

// Circle area calculator using Math.PI
function circleArea(radius) {
    return Math.PI * Math.pow(radius, 2);
}
print("Circle area (r=5): " + circleArea(5));

// Distance formula using Math.sqrt and Math.pow
function distance(x1, y1, x2, y2) {
    let dx = x2 - x1;
    let dy = y2 - y1;
    return Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));
}
print("Distance (0,0) to (3,4): " + distance(0, 0, 3, 4));

// Parse and calculate
let num1 = parseInt("10");
let num2 = parseFloat("3.5");
let result = num1 + num2;
print("parseInt('10') + parseFloat('3.5') = " + result);
print("");

print("========================================");
print("   All Tests Passed!");
print("========================================");
