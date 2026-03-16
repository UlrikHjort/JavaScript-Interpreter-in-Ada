// Factorial calculator - multiple approaches

// Recursive factorial
function factorialRecursive(n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorialRecursive(n - 1);
}

// Iterative factorial
function factorialIterative(n) {
    let result = 1;
    let i = 2;
    while (i <= n) {
        result = result * i;
        i++;
    }
    return result;
}

// Factorial using reduce
function factorialFunctional(n) {
    if (n <= 1) {
        return 1;
    }
    let numbers = [];
    let i = 1;
    while (i <= n) {
        numbers.push(i);
        i++;
    }
    return numbers.reduce((acc, val) => acc * val, 1);
}

print("=== Factorial Calculator ===");
print("");

print("Recursive:");
print("5! = " + factorialRecursive(5));
print("10! = " + factorialRecursive(10));
print("");

print("Iterative:");
print("5! = " + factorialIterative(5));
print("10! = " + factorialIterative(10));
print("");

print("Functional (using reduce):");
print("5! = " + factorialFunctional(5));
print("10! = " + factorialFunctional(10));
print("");

print("Factorials from 0 to 12:");
let i = 0;
while (i <= 12) {
    print(i + "! = " + factorialIterative(i));
    i++;
}
