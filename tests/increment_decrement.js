// Test increment and decrement operators

print("=== Increment/Decrement Operators Test ===");

// Test postfix increment
print("\n--- Postfix Increment (x++) ---");
let a = 10;
print("a = " + a);
print("a++ returns: " + a++);
print("a after a++: " + a);

// Test prefix increment
print("\n--- Prefix Increment (++x) ---");
let b = 10;
print("b = " + b);
print("++b returns: " + ++b);
print("b after ++b: " + b);

// Test postfix decrement
print("\n--- Postfix Decrement (x--) ---");
let c = 10;
print("c = " + c);
print("c-- returns: " + c--);
print("c after c--: " + c);

// Test prefix decrement
print("\n--- Prefix Decrement (--x) ---");
let d = 10;
print("d = " + d);
print("--d returns: " + --d);
print("d after --d: " + d);

// Test in expressions
print("\n--- In Expressions ---");
let x = 5;
let y = 10;
let result = x++ + ++y;
print("x=5, y=10: x++ + ++y = " + result);
print("x after: " + x);
print("y after: " + y);

// Test in loops
print("\n--- In For Loops ---");
for (let i = 0; i < 5; i++) {
    print("i = " + i);
}

print("\nCountdown:");
for (let j = 5; j > 0; j--) {
    print("j = " + j);
}

// Test with arrays
print("\n--- With Arrays ---");
let arr = [1, 2, 3, 4, 5];
print("Initial array: " + arr);

// Increment array elements
arr[0]++;
print("After arr[0]++: " + arr);

++arr[1];
print("After ++arr[1]: " + arr);

// Use in expressions
let val = arr[2]++;
print("arr[2]++ returns: " + val);
print("Array after arr[2]++: " + arr);

val = ++arr[3];
print("++arr[3] returns: " + val);
print("Array after ++arr[3]: " + arr);

// Decrement
arr[4]--;
print("After arr[4]--: " + arr);

--arr[0];
print("After --arr[0]: " + arr);

// Test in while loop
print("\n--- In While Loop ---");
let count = 3;
while (count > 0) {
    print("count = " + count);
    count--;
}
print("Final count: " + count);

// Test multiple operations
print("\n--- Multiple Operations ---");
let m = 5;
m++;
m++;
++m;
print("After m++, m++, ++m (started at 5): " + m);

m--;
--m;
m--;
print("After m--, --m, m--: " + m);

// Test as standalone statements
print("\n--- As Statements ---");
let n = 10;
print("n = " + n);
n++;
print("After 'n++' statement: " + n);
++n;
print("After '++n' statement: " + n);
n--;
print("After 'n--' statement: " + n);
--n;
print("After '--n' statement: " + n);

print("\n=== All Increment/Decrement Tests Complete ===");
