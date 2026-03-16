// Do-While Loop Test Suite

print("=== Do-While Loop Tests ===");

// Test 1: Basic do-while
print("Test 1: Basic counting");
var i = 0;
do {
   print("i = " + i);
   i = i + 1;
} while (i < 3);
print("Final i: " + i);

// Test 2: Do-while executes at least once
print("Test 2: Executes at least once (condition false from start)");
var j = 10;
do {
   print("j = " + j);
   j = j + 1;
} while (j < 5);
print("Final j: " + j);

// Test 3: Do-while with break
print("Test 3: With break");
var k = 0;
do {
   print("k = " + k);
   if (k >= 2) {
      break;
   }
   k = k + 1;
} while (k < 10);
print("Final k: " + k);

// Test 4: Do-while with continue
print("Test 4: With continue");
var m = 0;
do {
   m = m + 1;
   if (m == 2) {
      continue;
   }
   print("m = " + m);
} while (m < 4);

// Test 5: Nested do-while
print("Test 5: Nested loops");
var outer = 0;
do {
   var inner = 0;
   do {
      print("outer=" + outer + ", inner=" + inner);
      inner = inner + 1;
   } while (inner < 2);
   outer = outer + 1;
} while (outer < 2);

// Test 6: Do-while with complex condition
print("Test 6: Complex condition");
var sum = 0;
var count = 0;
do {
   sum = sum + count;
   count = count + 1;
} while (count < 5 && sum < 20);
print("Sum: " + sum + ", Count: " + count);

print("All do-while tests complete!");
