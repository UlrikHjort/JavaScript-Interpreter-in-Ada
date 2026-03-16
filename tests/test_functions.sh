#!/bin/bash

echo "Testing JavaScript Functions..."
echo "================================"
echo ""

cd "$(dirname "$0")/.."

echo "Test 1: Basic function declaration and call"
cat << 'EOF' | ./bin/jsinterp
function greet() {
    print("Hello!")
}
greet()
EOF
echo ""

echo "Test 2: Function with parameters and return"
cat << 'EOF' | ./bin/jsinterp
function add(a, b) {
    return a + b
}
print(add(5, 7))
EOF
echo ""

echo "Test 3: Recursive factorial"
cat << 'EOF' | ./bin/jsinterp
function factorial(n) {
    if (n <= 1) {
        return 1
    }
    return n * factorial(n - 1)
}
print(factorial(6))
EOF
echo ""

echo "Test 4: Nested function calls"
cat << 'EOF' | ./bin/jsinterp
function double(x) {
    return x * 2
}
function square(x) {
    return x * x
}
function process(x) {
    return square(double(x))
}
print(process(3))
EOF
echo ""

echo "Test 5: Function with local variables"
cat << 'EOF' | ./bin/jsinterp
function calculate(n) {
    let x = n * 2
    let y = x + 10
    return y
}
print(calculate(5))
EOF
echo ""

echo "Test 6: Fibonacci (recursive)"
cat << 'EOF' | ./bin/jsinterp
function fib(n) {
    if (n <= 1) {
        return n
    }
    return fib(n - 1) + fib(n - 2)
}
print(fib(8))
EOF
echo ""

echo "All function tests completed!"
