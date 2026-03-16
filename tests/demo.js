// ========================================
// JavaScript Interpreter Demo
// Showcasing: Unary Operators, Arrays, and String Operations
// ========================================

print("=== UNARY OPERATORS ===");
print("Negation: -42 = " + -42);
print("Logical NOT: !true = " + !true);
print("Logical NOT: !false = " + !false);
print("typeof 42 = " + typeof 42);
print("typeof 'hello' = " + typeof "hello");
print("typeof true = " + typeof true);
print("typeof [1,2,3] = " + typeof [1, 2, 3]);

print("=== ARRAYS ===");
let numbers = [5, 10, 15, 20, 25];
print("Array: " + numbers);
print("numbers[0] = " + numbers[0]);
print("numbers[4] = " + numbers[4]);
print("numbers.length = " + numbers.length);

let empty = [];
print("Empty array: " + empty);
print("empty.length = " + empty.length);

print("=== STRING OPERATIONS ===");
let greeting = "Hello" + " " + "World";
print("Concatenation: " + greeting);
print("greeting.length = " + greeting.length);
print("greeting[0] = " + greeting[0]);
print("greeting[6] = " + greeting[6]);

print("String comparison:");
print("'abc' == 'abc' = " + ("abc" == "abc"));
print("'abc' < 'xyz' = " + ("abc" < "xyz"));
print("'xyz' > 'abc' = " + ("xyz" > "abc"));

print("=== FUNCTIONS WITH ARRAYS ===");
function sum(arr) {
    let total = 0;
    for (let i = 0; i < arr.length; i = i + 1) {
        total = total + arr[i];
    }
    return total;
}

print("sum([1,2,3,4,5]) = " + sum([1, 2, 3, 4, 5]));

function getFirst(arr) {
    if (arr.length > 0) {
        return arr[0];
    }
    return undefined;
}

function getLast(arr) {
    if (arr.length > 0) {
        return arr[arr.length - 1];
    }
    return undefined;
}

print("getFirst([10,20,30]) = " + getFirst([10, 20, 30]));
print("getLast([10,20,30]) = " + getLast([10, 20, 30]));

print("=== COMBINING ALL FEATURES ===");
let words = ["JavaScript", "interpreter", "in", "Ada"];
let sentence = words[0] + " " + words[1] + " " + words[2] + " " + words[3];
print("Array of words: " + words);
print("Combined sentence: " + sentence);
print("Sentence length: " + sentence.length);
print("First character: " + sentence[0]);
print("Type of words: " + typeof words);
print("Type of sentence: " + typeof sentence);

print("=== RECURSIVE FUNCTIONS WITH ARRAYS ===");
function fibonacci(n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

// Build fibonacci array
let fib = [fibonacci(0), fibonacci(1), fibonacci(2), fibonacci(3), fibonacci(4), fibonacci(5)];
print("Fibonacci sequence: " + fib);
print("Sum of fibonacci: " + sum(fib));

print("=== ALL DONE ===");
