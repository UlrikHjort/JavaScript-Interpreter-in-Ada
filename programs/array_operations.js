// Array operations and statistics

function sum(arr) {
    function add(acc, val) {
        return acc + val;
    }
    return arr.reduce(add, 0);
}

function average(arr) {
    if (arr.length == 0) {
        return 0;
    }
    return sum(arr) / arr.length;
}

function max(arr) {
    if (arr.length == 0) {
        return undefined;
    }
    function maxFunc(acc, val) {
        return val > acc ? val : acc;
    }
    return arr.reduce(maxFunc, arr[0]);
}

function min(arr) {
    if (arr.length == 0) {
        return undefined;
    }
    function minFunc(acc, val) {
        return val < acc ? val : acc;
    }
    return arr.reduce(minFunc, arr[0]);
}

function count(arr, value) {
    function matchValue(x) {
        return x == value;
    }
    return arr.filter(matchValue).length;
}

print("=== Array Operations ===");
print("");

let numbers = [5, 2, 8, 2, 9, 1, 5, 5, 7, 3, 2];
print("Array: " + numbers.join(", "));
print("");

print("Statistics:");
print("Sum: " + sum(numbers));
print("Average: " + average(numbers));
print("Maximum: " + max(numbers));
print("Minimum: " + min(numbers));
print("Count of 5: " + count(numbers, 5));
print("Count of 2: " + count(numbers, 2));
print("");

print("Filtered operations:");
function isEven(x) {
    return x % 2 == 0;
}
let evens = numbers.filter(isEven);
print("Even numbers: " + evens.join(", "));

function isOdd(x) {
    return x % 2 == 1;
}
let odds = numbers.filter(isOdd);
print("Odd numbers: " + odds.join(", "));

function gt5(x) {
    return x > 5;
}
let greater = numbers.filter(gt5);
print("Numbers > 5: " + greater.join(", "));
print("");

print("Mapped operations:");
function double(x) {
    return x * 2;
}
let doubled = numbers.map(double);
print("Doubled: " + doubled.join(", "));

function square(x) {
    return x * x;
}
let squared = numbers.map(square);
print("Squared: " + squared.join(", "));
