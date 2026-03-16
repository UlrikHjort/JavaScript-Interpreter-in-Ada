// String Methods Test Suite

// Test 1: split() with separator
var str1 = "hello,world,test";
var arr1 = str1.split(",");
print(arr1[0]);  // "hello"
print(arr1[1]);  // "world"
print(arr1[2]);  // "test"

// Test 2: split() into characters (empty separator)
var str2 = "abc";
var arr2 = str2.split("");
print(arr2[0]);  // "a"
print(arr2[1]);  // "b"
print(arr2[2]);  // "c"

// Test 3: substring()
var str3 = "JavaScript";
print(str3.substring(0, 4));   // "Java"
print(str3.substring(4, 10));  // "Script"
print(str3.substring(4));      // "Script" (to end)

// Test 4: charAt()
var str4 = "Hello";
print(str4.charAt(0));   // "H"
print(str4.charAt(1));   // "e"
print(str4.charAt(4));   // "o"
print(str4.charAt(10));  // "" (out of bounds)

// Test 5: toUpperCase()
var str5 = "hello world";
print(str5.toUpperCase());  // "HELLO WORLD"

// Test 6: toLowerCase()
var str6 = "HELLO WORLD";
print(str6.toLowerCase());  // "hello world"

// Test 7: trim()
var str7 = "  hello  ";
print(str7.trim());  // "hello"

var str8 = "\thello\n";
print(str8.trim());  // "hello"

// Test 8: Method chaining
var str9 = "  Hello World  ";
print(str9.trim().toLowerCase());  // "hello world"

// Test 9: split and join (inverse operations)
var str10 = "a-b-c";
var parts = str10.split("-");
var joined = parts.join("-");
print(joined);  // "a-b-c"

// Test 10: substring edge cases
var str11 = "test";
print(str11.substring(0, 0));  // "" (empty)
print(str11.substring(0, 100));  // "test" (clamp to length)

print("All string method tests complete!");
