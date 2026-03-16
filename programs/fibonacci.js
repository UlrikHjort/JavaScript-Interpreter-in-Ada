// Fibonacci sequence generator - multiple implementations

// Recursive version (classic but slower)
function fibRecursive(n) {
    if (n <= 1) {
        return n;
    }
    return fibRecursive(n - 1) + fibRecursive(n - 2);
}

// Iterative version (efficient)
function fibIterative(n) {
    if (n <= 1) {
        return n;
    }
    let a = 0;
    let b = 1;
    let i = 2;
    while (i <= n) {
        let temp = a + b;
        a = b;
        b = temp;
        i++;
    }
    return b;
}

print("=== Fibonacci Numbers ===");
print("");

print("Recursive fibonacci(10): " + fibRecursive(10));
print("Iterative fibonacci(10): " + fibIterative(10));
print("");

print("First 15 Fibonacci numbers:");
let i = 0;
while (i < 15) {
    print(fibIterative(i));
    i++;
}

