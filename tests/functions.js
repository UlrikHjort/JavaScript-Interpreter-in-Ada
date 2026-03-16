// Test basic function declaration and call
function greet() {
    print("Hello from function!")
}

greet()

// Test function with parameters
function add(a, b) {
    return a + b
}

let result = add(5, 3)
print(result)

// Test function with multiple statements
function calculate(x) {
    let doubled = x * 2
    let squared = doubled * doubled
    return squared
}

print(calculate(3))

// Test recursive function (factorial)
function factorial(n) {
    if (n <= 1) {
        return 1
    } else {
        return n * factorial(n - 1)
    }
}

print(factorial(5))

// Test function returning nothing (undefined)
function noReturn() {
    print("No return value")
}

let nothing = noReturn()
print(nothing)

// Test nested function calls
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
