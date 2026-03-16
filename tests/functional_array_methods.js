// Functional Array Methods Test Suite

// Test 1: map() - transform each element
function double(x) {
   return x * 2;
}

var arr1 = [1, 2, 3, 4, 5];
var doubled = arr1.map(double);
print("Doubled:");
print(doubled[0]);  // 2
print(doubled[1]);  // 4
print(doubled[2]);  // 6

// Test 2: filter() - select elements
function isEven(x) {
   return x % 2 == 0;
}

var arr2 = [1, 2, 3, 4, 5, 6];
var evens = arr2.filter(isEven);
print("Evens:");
print(evens[0]);  // 2
print(evens[1]);  // 4
print(evens[2]);  // 6

// Test 3: forEach() - iterate
var sum = 0;
function addToSum(x) {
   sum = sum + x;
}

var arr3 = [1, 2, 3, 4, 5];
arr3.forEach(addToSum);
print("Sum via forEach:");
print(sum);  // 15

// Test 4: find() - first matching element
function isGreaterThan3(x) {
   return x > 3;
}

var arr4 = [1, 2, 3, 4, 5];
var found = arr4.find(isGreaterThan3);
print("First > 3:");
print(found);  // 4

// Test 5: reduce() - reduce to single value
function add(acc, x) {
   return acc + x;
}

var arr5 = [1, 2, 3, 4, 5];
var total = arr5.reduce(add, 0);
print("Reduce sum:");
print(total);  // 15

// Test 6: reduce() without initial value
var arr6 = [10, 20, 30];
var product = arr6.reduce(add);
print("Reduce without initial:");
print(product);  // 60

print("All functional array method tests complete!");
