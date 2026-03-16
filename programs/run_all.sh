#!/bin/bash
# Run all example programs

echo "================================"
echo "JavaScript Interpreter - Programs"
echo "================================"
echo ""

for prog in programs/*.js; do
    name=$(basename "$prog")
    echo "-> Running $name..."
    echo "---"
    ./bin/jsinterp < "$prog"
    echo ""
    echo "---"
    echo ""
done

echo "All programs completed!"
