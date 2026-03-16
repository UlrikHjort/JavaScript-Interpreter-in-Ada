// Test more array methods: slice, join, indexOf, includes

print("=== More Array Methods Test ===");

// Test slice
print("\n--- slice() Method ---");
let arr = [1, 2, 3, 4, 5];
print("Original array: " + arr);

print("slice(1, 3): " + arr.slice(1, 3));  // [2, 3]
print("slice(2): " + arr.slice(2));        // [3, 4, 5]
print("slice(0, 2): " + arr.slice(0, 2));  // [1, 2]
print("slice(): " + arr.slice());          // [1, 2, 3, 4, 5]

// Negative indices
print("\nNegative indices:");
print("slice(-2): " + arr.slice(-2));      // [4, 5]
print("slice(-3, -1): " + arr.slice(-3, -1));  // [3, 4]
print("slice(1, -1): " + arr.slice(1, -1));    // [2, 3, 4]

// Original array unchanged
print("Original after slicing: " + arr);

// Edge cases
print("\nEdge cases:");
let empty = [];
print("Empty array slice: " + empty.slice());
print("slice(5, 10): " + arr.slice(5, 10));  // []
print("slice(10, 20): " + arr.slice(10, 20)); // []

// Test join
print("\n--- join() Method ---");
let numbers = [1, 2, 3, 4, 5];
print("Array: " + numbers);

print("join(): " + numbers.join());              // "1,2,3,4,5"
print("join('-'): " + numbers.join("-"));        // "1-2-3-4-5"
print("join(' '): " + numbers.join(" "));        // "1 2 3 4 5"
print("join(' and '): " + numbers.join(" and ")); // "1 and 2 and ..."

let words = ["Hello", "World", "from", "JavaScript"];
print("\nWords: " + words);
print("join(' '): " + words.join(" "));
print("join(', '): " + words.join(", "));

// Empty array join
print("\nEmpty array join: " + empty.join());
print("Empty array join('-'): " + empty.join("-"));

// Single element
let single = [42];
print("Single element join: " + single.join());
print("Single element join('-'): " + single.join("-"));

// Test indexOf
print("\n--- indexOf() Method ---");
let values = [10, 20, 30, 40, 50, 30];
print("Array: " + values);

print("indexOf(30): " + values.indexOf(30));    // 2 (first occurrence)
print("indexOf(10): " + values.indexOf(10));    // 0
print("indexOf(50): " + values.indexOf(50));    // 4
print("indexOf(99): " + values.indexOf(99));    // -1 (not found)
print("indexOf(20): " + values.indexOf(20));    // 1

// String array
let fruits = ["apple", "banana", "cherry", "banana"];
print("\nFruits: " + fruits);
print('indexOf("banana"): ' + fruits.indexOf("banana"));  // 1
print('indexOf("cherry"): ' + fruits.indexOf("cherry"));  // 2
print('indexOf("grape"): ' + fruits.indexOf("grape"));    // -1

// Boolean array
let flags = [true, false, true];
print("\nFlags: " + flags);
print("indexOf(true): " + flags.indexOf(true));   // 0
print("indexOf(false): " + flags.indexOf(false)); // 1

// Empty array
print("\nEmpty indexOf: " + empty.indexOf(1));    // -1

// Test includes
print("\n--- includes() Method ---");
let nums = [1, 2, 3, 4, 5];
print("Array: " + nums);

print("includes(3): " + nums.includes(3));       // true
print("includes(1): " + nums.includes(1));       // true
print("includes(5): " + nums.includes(5));       // true
print("includes(10): " + nums.includes(10));     // false
print("includes(0): " + nums.includes(0));       // false

// String array
let colors = ["red", "green", "blue"];
print("\nColors: " + colors);
print('includes("green"): ' + colors.includes("green"));   // true
print('includes("yellow"): ' + colors.includes("yellow")); // false

// Boolean array
let bools = [true, false, true];
print("\nBooleans: " + bools);
print("includes(true): " + bools.includes(true));   // true
print("includes(false): " + bools.includes(false)); // true

// Empty array
print("\nEmpty includes: " + empty.includes(1));    // false

// Combining methods
print("\n--- Combining Methods ---");
let data = [1, 2, 3, 4, 5];
print("Original: " + data);

let sliced = data.slice(1, 4);
print("Sliced (1, 4): " + sliced);
print("Sliced joined: " + sliced.join(" - "));

if (data.includes(3)) {
    print("Array contains 3 at index: " + data.indexOf(3));
}

// Using in conditionals
print("\n--- In Conditionals ---");
let search = 30;
let list = [10, 20, 30, 40];
if (list.includes(search)) {
    print(search + " found at index " + list.indexOf(search));
} else {
    print(search + " not found");
}

search = 99;
if (list.includes(search)) {
    print(search + " found at index " + list.indexOf(search));
} else {
    print(search + " not found");
}

// Method chaining potential
print("\n--- Method Results ---");
let original = [1, 2, 3, 4, 5];
print("Original: " + original);

let middle = original.slice(1, 4);
print("Middle slice: " + middle);

let joined = middle.join(" * ");
print("Joined: " + joined);

print("\n=== All More Array Methods Tests Complete ===");
