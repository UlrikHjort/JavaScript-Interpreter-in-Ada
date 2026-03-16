// Test unary operators
print("Testing unary operators:");
print(-5);
print(-(-5));
print(!true);
print(!false);
print(!0);
print(!1);
print(typeof 42);
print(typeof "hello");
print(typeof true);
print(typeof null);
print(typeof undefined);

// Test arrays
print("\nTesting arrays:");
let arr = [1, 2, 3];
print(arr);
print(arr[0]);
print(arr[1]);
print(arr[2]);
print(arr.length);

let empty = [];
print(empty);
print(empty.length);

// Test string operations
print("\nTesting string operations:");
print("Hello" + " " + "World");
print("Number: " + 42);
print("abc" == "abc");
print("abc" == "xyz");
print("abc" < "xyz");

let str = "Hello";
print(str.length);
print(str[0]);
print(str[4]);

// Test typeof with arrays
print("\nTesting typeof with arrays:");
print(typeof [1, 2, 3]);
print(typeof arr);
