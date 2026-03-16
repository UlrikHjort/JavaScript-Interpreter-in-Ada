// Test array methods: push, pop, shift, unshift

print("=== Array Methods Test ===");

// Test push
print("\n--- Push Test ---");
let arr1 = [1, 2];
print("Initial: " + arr1);
let len = arr1.push(3);
print("After push(3): " + arr1);
print("Returned length: " + len);
arr1.push(4);
arr1.push(5);
print("After push(4), push(5): " + arr1);

// Test pop
print("\n--- Pop Test ---");
let arr2 = [10, 20, 30];
print("Initial: " + arr2);
let val = arr2.pop();
print("Popped value: " + val);
print("After pop: " + arr2);
val = arr2.pop();
print("Popped value: " + val);
print("After pop: " + arr2);

// Test shift
print("\n--- Shift Test ---");
let arr3 = [100, 200, 300];
print("Initial: " + arr3);
let first = arr3.shift();
print("Shifted value: " + first);
print("After shift: " + arr3);
first = arr3.shift();
print("Shifted value: " + first);
print("After shift: " + arr3);

// Test unshift
print("\n--- Unshift Test ---");
let arr4 = [5, 6];
print("Initial: " + arr4);
let newLen = arr4.unshift(4);
print("After unshift(4): " + arr4);
print("Returned length: " + newLen);
arr4.unshift(3);
arr4.unshift(2);
print("After unshift(3), unshift(2): " + arr4);

// Test combined operations
print("\n--- Combined Operations ---");
let arr5 = [1, 2, 3];
print("Start: " + arr5);
arr5.push(4);
arr5.unshift(0);
print("After push(4), unshift(0): " + arr5);
arr5.pop();
arr5.shift();
print("After pop(), shift(): " + arr5);

// Test edge cases
print("\n--- Edge Cases ---");
let empty = [];
print("Empty array: " + empty);
let popEmpty = empty.pop();
print("Pop from empty: " + popEmpty);
let shiftEmpty = empty.shift();
print("Shift from empty: " + shiftEmpty);
empty.push(1);
print("After push(1): " + empty);
empty.unshift(0);
print("After unshift(0): " + empty);

// Test with different types
print("\n--- Different Types ---");
let mixed = [1, 2];
mixed.push("hello");
print("After push('hello'): " + mixed);
mixed.unshift(true);
print("After unshift(true): " + mixed);

print("\n=== All Array Method Tests Complete ===");
