#!/bin/bash
# Demonstration of JavaScript Interpreter Features

echo "------------------------------------------------------------"
echo "  JavaScript Interpreter in Ada - Feature Demonstration     "
echo "------------------------------------------------------------"
echo ""

cd "$(dirname "$0")/.."

echo "Arithmetic Operations"
echo "----------------------------"
echo -n "2 + 3 * 4 = "
echo "2 + 3 * 4" | ./bin/jsinterp
echo -n "(2 + 3) * 4 = "
echo "(2 + 3) * 4" | ./bin/jsinterp
echo -n "100 / 4 = "
echo "100 / 4" | ./bin/jsinterp
echo -n "17 % 5 = "
echo "17 % 5" | ./bin/jsinterp
echo ""

echo "Comparison Operations"
echo "----------------------------"
echo -n "5 > 3: "
echo "5 > 3" | ./bin/jsinterp
echo -n "10 <= 10: "
echo "10 <= 10" | ./bin/jsinterp
echo -n "7 == 7: "
echo "7 == 7" | ./bin/jsinterp
echo -n "7 != 5: "
echo "7 != 5" | ./bin/jsinterp
echo ""

echo "Logical Operations"
echo "----------------------------"
echo -n "true && true: "
echo "true && true" | ./bin/jsinterp
echo -n "true && false: "
echo "true && false" | ./bin/jsinterp
echo -n "true || false: "
echo "true || false" | ./bin/jsinterp
echo -n "false || false: "
echo "false || false" | ./bin/jsinterp
echo ""

echo "Complex Expressions"
echo "----------------------------"
echo -n "10 + 5 > 12: "
echo "10 + 5 > 12" | ./bin/jsinterp
echo -n "5 > 3 && 10 < 20: "
echo "5 > 3 && 10 < 20" | ./bin/jsinterp
echo -n "(5 + 3) * 2 > 15 && true: "
echo "(5 + 3) * 2 > 15 && true" | ./bin/jsinterp
echo -n "100 / 4 == 25 || false: "
echo "100 / 4 == 25 || false" | ./bin/jsinterp
echo ""

echo "Operator Precedence"
echo "----------------------------"
echo -n "2 + 3 * 4 (multiplication first) = "
echo "2 + 3 * 4" | ./bin/jsinterp
echo -n "10 - 6 / 2 (division first) = "
echo "10 - 6 / 2" | ./bin/jsinterp
echo -n "5 + 3 > 7 && true (comparison before logical) = "
echo "5 + 3 > 7 && true" | ./bin/jsinterp
echo ""
echo "-----------------------------------------------------------"
echo "All demonstrations complete!"
echo ""
echo "Try the REPL for interactive mode with line editing:"
echo "   ./bin/jsinterp"
echo ""
