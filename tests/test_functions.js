function greet() {
    print("Hello from function!")
}

greet()

function add(a, b) {
    return a + b
}

let result = add(5, 3)
print(result)

function calculate(x) {
    let doubled = x * 2
    let squared = doubled * doubled
    return squared
}

print(calculate(3))

function factorial(n) {
    if (n <= 1) {
        return 1
    } else {
        return n * factorial(n - 1)
    }
}

print(factorial(5))

function noReturn() {
    print("No return value")
}

let nothing = noReturn()

function double(x) {
    return x * 2
}

function triple(x) {
    return x * 3
}

function process(x) {
    return double(x) + triple(x)
}

print(process(4))

function fibonacci(n) {
    if (n <= 1) {
        return n
    }
    return fibonacci(n - 1) + fibonacci(n - 2)
}

print(fibonacci(10))
