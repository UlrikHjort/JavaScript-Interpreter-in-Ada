#!/bin/bash
# Test variables and print functionality

echo "=== Variables and Print Test Suite ==="
echo ""

cd "$(dirname "$0")/.."

echo "Test 1: Variable declaration and print"
cat << 'EOF' | ./bin/jsinterp
let x = 42
print(x)
EOF
echo ""

echo "Test 2: Multiple variables and arithmetic"
cat << 'EOF' | ./bin/jsinterp
let a = 10
let b = 20
print(a + b)
print(a * b)
EOF
echo ""

echo "Test 3: Variable assignment"
cat << 'EOF' | ./bin/jsinterp
let x = 5
print(x)
x = 10
print(x)
x = x + 5
print(x)
EOF
echo ""

echo "Test 4: Const declaration"
cat << 'EOF' | ./bin/jsinterp
const PI = 3.14
let radius = 10
print(PI * radius * radius)
EOF
echo ""

echo "Test 5: Complex expression with variables"
cat << 'EOF' | ./bin/jsinterp
let x = 5
let y = 10
let z = 15
print(x * y + z)
print((x + y) * z)
EOF
echo ""

echo "Test 6: Boolean variables"
cat << 'EOF' | ./bin/jsinterp
let isTrue = true
print(isTrue)
let result = 10 > 5
print(result)
EOF
echo ""

echo "=== All tests complete ==="
