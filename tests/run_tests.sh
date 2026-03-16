#!/bin/bash
# Test script for JavaScript interpreter

echo "=== JavaScript Interpreter Test Suite ==="
echo ""

echo "Test 1: Basic arithmetic"
echo "2 + 3 * 4" | ./bin/jsinterp
echo ""

echo "Test 2: Division and modulo"
echo "100 / 4" | ./bin/jsinterp
echo "10 % 3" | ./bin/jsinterp
echo ""

echo "Test 3: Comparisons"
echo "5 > 3" | ./bin/jsinterp
echo "10 == 10" | ./bin/jsinterp
echo "7 <= 5" | ./bin/jsinterp
echo ""

echo "Test 4: Logical operators"
echo "true && false" | ./bin/jsinterp
echo "true || false" | ./bin/jsinterp
echo ""

echo "Test 5: Complex expressions"
echo "10 + 5 > 12" | ./bin/jsinterp
echo "5 > 3 && 10 < 20" | ./bin/jsinterp
echo "10 + 5 * 2 > 15 && true" | ./bin/jsinterp
echo ""

echo "Test 6: Operator precedence"
echo "(5 + 3) * 2" | ./bin/jsinterp
echo "5 + 3 * 2" | ./bin/jsinterp
echo ""

echo "=== All tests complete ==="
