// Mathematical calculator with various operations

// Power function (base^exponent)
function power(base, exponent) {
    if (exponent == 0) {
        return 1;
    }
    if (exponent < 0) {
        return 1 / power(base, -exponent);
    }
    let result = 1;
    let i = 0;
    while (i < exponent) {
        result = result * base;
        i++;
    }
    return result;
}

// Greatest Common Divisor (Euclidean algorithm)
function gcd(a, b) {
    while (b != 0) {
        let temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

// Least Common Multiple
function lcm(a, b) {
    return (a * b) / gcd(a, b);
}

// Square root (Newton's method approximation)
function sqrt(n) {
    if (n < 0) {
        return undefined;
    }
    if (n == 0) {
        return 0;
    }
    
    let x = n;
    let prev = 0;
    let iterations = 0;
    
    while (iterations < 20) {
        prev = x;
        x = (x + n / x) / 2;
        iterations++;
        
        // Check convergence
        let diff = x - prev;
        if (diff < 0) {
            diff = -diff;
        }
        if (diff < 0.000001) {
            return x;
        }
    }
    return x;
}

// Absolute value
function abs(n) {
    return n < 0 ? -n : n;
}

// Check if number is even
function isEven(n) {
    return n % 2 == 0;
}

// Check if number is odd
function isOdd(n) {
    return n % 2 != 0;
}

// Sum of digits
function sumOfDigits(n) {
    let num = abs(n);
    let sum = 0;
    while (num > 0) {
        sum = sum + (num % 10);
        num = (num - (num % 10)) / 10;
    }
    return sum;
}

print("=== Mathematical Calculator ===");
print("");

print("Power calculations:");
print("2^8 = " + power(2, 8));
print("5^3 = " + power(5, 3));
print("10^4 = " + power(10, 4));
print("");

print("GCD and LCM:");
print("gcd(48, 18) = " + gcd(48, 18));
print("gcd(100, 35) = " + gcd(100, 35));
print("lcm(12, 18) = " + lcm(12, 18));
print("lcm(21, 14) = " + lcm(21, 14));
print("");

print("Square roots:");
print("sqrt(16) = " + sqrt(16));
print("sqrt(25) = " + sqrt(25));
print("sqrt(2) = " + sqrt(2));
print("sqrt(100) = " + sqrt(100));
print("");

print("Number properties:");
print("Is 42 even? " + isEven(42));
print("Is 17 odd? " + isOdd(17));
print("abs(-25) = " + abs(-25));
print("abs(25) = " + abs(25));
print("");

print("Sum of digits:");
print("sumOfDigits(123) = " + sumOfDigits(123));
print("sumOfDigits(9876) = " + sumOfDigits(9876));
print("sumOfDigits(100) = " + sumOfDigits(100));
