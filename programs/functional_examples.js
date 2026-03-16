// Functional programming examples

print("=== Functional Programming Examples ===");
print("");

let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

print("--- Map Examples ---");
function double(x) {
    return x * 2;
}
let doubled = numbers.map(double);
print("Doubled: " + doubled.join(", "));

function square(x) {
    return x * x;
}
let squared = numbers.map(square);
print("Squared: " + squared.join(", "));
print("");

print("--- Filter Examples ---");
function isEven(x) {
    return x % 2 == 0;
}
let evens = numbers.filter(isEven);
print("Evens: " + evens.join(", "));

function greaterThan5(x) {
    return x > 5;
}
let gt5 = numbers.filter(greaterThan5);
print("Greater than 5: " + gt5.join(", "));
print("");

print("--- Reduce Examples ---");
function sum(acc, val) {
    return acc + val;
}
let total = numbers.reduce(sum, 0);
print("Sum: " + total);

function product(acc, val) {
    return acc * val;
}
let prod = numbers.reduce(product, 1);
print("Product: " + prod);
print("");

print("--- Find Example ---");
function gt7(x) {
    return x > 7;
}
let first = numbers.find(gt7);
print("First > 7: " + first);
print("");

print("--- ForEach Example ---");
print("Squares:");
function printSquare(n) {
    print(n + "^2 = " + (n * n));
}
let small = [1, 2, 3, 4, 5];
small.forEach(printSquare);
