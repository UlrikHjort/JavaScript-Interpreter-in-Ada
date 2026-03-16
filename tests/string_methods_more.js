// Additional String Methods Test Suite

print("=== String Methods Tests ===");

// Test 1: replace() - replace first occurrence
var str1 = "hello world hello";
print("Original: " + str1);
print("Replace 'hello' with 'hi': " + str1.replace("hello", "hi"));  // "hi world hello"
print("Replace 'world' with 'universe': " + str1.replace("world", "universe"));  // "hello universe hello"

// Test 2: repeat() - repeat string N times
var str2 = "abc";
print("Repeat 'abc' 3 times: " + str2.repeat(3));  // "abcabcabc"
print("Repeat 'x' 5 times: " + "x".repeat(5));  // "xxxxx"

// Test 3: startsWith() - check prefix
var str3 = "Hello World";
print("Starts with 'Hello': " + str3.startsWith("Hello"));  // true
print("Starts with 'World': " + str3.startsWith("World"));  // false
print("Starts with 'H': " + str3.startsWith("H"));  // true

// Test 4: endsWith() - check suffix
var str4 = "test.js";
print("Ends with '.js': " + str4.endsWith(".js"));  // true
print("Ends with '.txt': " + str4.endsWith(".txt"));  // false
print("Ends with 's': " + str4.endsWith("s"));  // true

// Test 5: indexOf() - find position
var str5 = "hello world";
print("indexOf 'world': " + str5.indexOf("world"));  // 6
print("indexOf 'o': " + str5.indexOf("o"));  // 4 (first o)
print("indexOf 'xyz': " + str5.indexOf("xyz"));  // -1 (not found)

// Test 6: lastIndexOf() - find last position
var str6 = "hello world hello";
print("lastIndexOf 'hello': " + str6.lastIndexOf("hello"));  // 12
print("lastIndexOf 'o': " + str6.lastIndexOf("o"));  // 13
print("lastIndexOf 'xyz': " + str6.lastIndexOf("xyz"));  // -1

// Test 7: Chaining methods
var str7 = "  hello  ";
var result = str7.trim().toUpperCase().repeat(2);
print("Chained (trim + upper + repeat): " + result);  // "HELLOHELLO"

// Test 8: Edge cases
print("Empty string replace: " + "".replace("a", "b"));  // ""
print("Replace not found: " + "abc".replace("x", "y"));  // "abc"
print("Repeat 0 times: " + "test".repeat(0));  // ""
print("startsWith empty: " + "test".startsWith(""));  // false
print("indexOf empty: " + "test".indexOf(""));  // 0

print("All additional string method tests complete!");
