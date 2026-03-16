// Prime number calculator and generator

// Check if a number is prime
function isPrime(n) {
    if (n <= 1) {
        return false;
    }
    if (n <= 3) {
        return true;
    }
    if (n % 2 == 0 || n % 3 == 0) {
        return false;
    }
    
    let i = 5;
    while (i * i <= n) {
        if (n % i == 0 || n % (i + 2) == 0) {
            return false;
        }
        i = i + 6;
    }
    return true;
}

// Find all primes up to N
function primesUpTo(max) {
    let primes = [];
    let n = 2;
    while (n <= max) {
        if (isPrime(n)) {
            primes.push(n);
        }
        n++;
    }
    return primes;
}

print("=== Prime Numbers ===");
print("");

print("Is 17 prime? " + isPrime(17));
print("Is 20 prime? " + isPrime(20));
print("Is 97 prime? " + isPrime(97));
print("");

print("Primes up to 50:");
let primes50 = primesUpTo(50);
print(primes50.join(", "));
print("Count: " + primes50.length);

