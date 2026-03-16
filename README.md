# JavaScript Interpreter in Ada

An JavaScript interpreter written in Ada, that implements a **subset of JavaScript ES6+  [ECMAScript 2015](https://262.ecma-international.org/6.0/)** This interpreter was implemented recreationally to get an idea how to  implement object-oriented programming features in a language interpreter. 

- **Not a complete JavaScript implementation** - Missing template literals, async/await, modules, etc.
- **Not optimized for performance** 
- **Not standards-compliant** - Implements ES6+ subset, not full ECMA-262 spec



## Building

```bash
make build
```

## Running

### Interactive REPL Mode

Start the REPL by running without arguments:

```bash
make run
# or
./bin/jsinterp
```

#### REPL Features

The REPL supports full line editing with:
- **↑/↓ Arrow Keys** - Navigate command history
- **←/→ Arrow Keys** - Move cursor left/right within the line
- **Backspace** - Delete character before cursor
- **Delete** - Delete character at cursor
- **Home** - Move cursor to beginning of line
- **End** - Move cursor to end of line
- **Insert Mode** - Type anywhere in the line to insert characters

Example session:
```
js> 2 + 3
5.00000E+00
js> 10 * 5 + 2
5.20000E+01
js> ↑ (recalls previous command)
js> 10 * 5 + 2
    ← ← (move cursor left)
js> 10 * 5█+ 2
    (type to insert)
js> 10 * 5 / 2 + 2
1.70000E+01
js> quit
Goodbye!
```

### Script Mode

Run JavaScript expressions from files:

```bash
./bin/jsinterp < script.js
# or
cat script.js | ./bin/jsinterp
```

Example:
```bash
echo "2 + 3 * 4" > test.js
./bin/jsinterp < test.js
# Output: 1.40000E+01
```


## Requirements

- GNAT Ada compiler (gnatmake)
- GNU make








### Currently Implemented

- **Lexer** - Tokenizes JavaScript source code
- **Parser** - Builds Abstract Syntax Tree (AST) with proper operator precedence
- **Evaluator** - Executes expressions with variables and functions
- **REPL** - Interactive Read-Eval-Print Loop with advanced features:
  - Command history (up to 100 commands)
  - Arrow key navigation (↑/↓ for history, ←/→ for cursor)
  - Full line editing with insert/delete
  - Home/End key support
- **Script Mode** - Execute JavaScript from files

### Supported Operations

#### Variable Declarations
- `let` - Declare a variable
- `const` - Declare a constant
- `var` - Declare a variable (var scope)
- Assignment: `x = value`

#### Functions
- `function name(params) { body }` - Function declarations
- `name(args)` - Function calls
- `return value` - Return from functions
- Recursive functions supported
- Local scope for parameters
- **Arrow Functions** (ES6 style):
  - Expression body: `(x) => x * 2` - Implicit return
  - Block body: `(x) => { return x * 2; }` - Explicit return
  - Multiple parameters: `(a, b) => a + b`
  - No parameters: `() => 42`
  - Single parameter (parentheses required): `(x) => x * 2`
- **First-class functions**: Functions can be stored in variables and passed as arguments
- **Closures** (partial support): Functions can read outer scope variables but mutations don't persist
  - Reading captured variables works
  - Mutating captured variables doesn't persist 
- `typeof function` returns `"function"`

#### Control Flow
- `if (condition) { ... } else { ... }` - Conditional execution
- `while (condition) { ... }` - While loops
- `do { ... } while (condition);` - Do-while loops (executes at least once)
- `for (init; condition; update) { ... }` - For loops
- `break` - Exit loop or switch statement
- `continue` - Skip to next iteration of loop
- `condition ? true_val : false_val` - Ternary operator
- `switch (expr) { case val: ...; break; default: ... }` - Switch/case statements
- `{ }` - Block statements

#### Output Functions
- `print(value)` - Print value to output (global function)
- `console.log(...args)` - Print multiple values to console

#### Arithmetic Operators
- `+` (addition)
- `-` (subtraction)
- `*` (multiplication)
- `/` (division)
- `%` (modulo)

#### Comparison Operators
- `<` (less than)
- `<=` (less than or equal)
- `>` (greater than)
- `>=` (greater than or equal)
- `==` (equality)
- `!=` (inequality)
- `===` (strict equality)
- `!==` (strict inequality)

#### Logical Operators
- `&&` (logical AND)
- `||` (logical OR)
- `!` (logical NOT)

#### Unary Operators
- `-x` (negation)
- `!x` (logical NOT)
- `typeof x` (type checking)

#### Increment/Decrement Operators
- `x++` - Postfix increment (returns old value, then increments)
- `++x` - Prefix increment (increments, then returns new value)
- `x--` - Postfix decrement (returns old value, then decrements)
- `--x` - Prefix decrement (decrements, then returns new value)
- Works on variables and array elements: `arr[i]++`

#### Arrays
- Array literals: `[1, 2, 3]`
- Array indexing: `arr[0]`, `arr[i]`
- Array length: `arr.length`
- Array assignment: `arr[0] = 5`
- **Basic Array Methods**:
  - `arr.push(value)` - Add element to end, returns new length
  - `arr.pop()` - Remove and return last element
  - `arr.shift()` - Remove and return first element
  - `arr.unshift(value)` - Add element to beginning, returns new length
  - `arr.slice(start, end)` - Extract subarray without modifying original
  - `arr.join(separator)` - Convert array to string with separator (default: comma)
  - `arr.indexOf(value)` - Find index of element, returns -1 if not found
  - `arr.includes(value)` - Check if array contains value, returns boolean
- **Functional Array Methods** (with callbacks):
  - `arr.map(callback)` - Transform each element: `[1,2,3].map(x => x * 2)` -> `[2,4,6]`
  - `arr.filter(callback)` - Select matching elements: `[1,2,3,4,5].filter(x => x % 2 == 0)` -> `[2,4]`
  - `arr.forEach(callback)` - Iterate with side effects: `arr.forEach(x => print(x))`
  - `arr.find(callback)` - Find first match: `[1,2,3,4,5].find(x => x > 3)` -> `4`
  - `arr.reduce(callback, initial)` - Reduce to single value: `[1,2,3,4,5].reduce((a,b) => a+b, 0)` -> `15`

#### String Operations
- String concatenation: `"Hello" + " " + "World"`
- String comparison: `==`, `!=`, `<`, `>`, `<=`, `>=`
- String length: `str.length`
- String indexing: `str[0]`, `str[i]`
- String methods: `split()`, `substring()`, `charAt()`, `toUpperCase()`, `toLowerCase()`, `trim()`, `replace()`, `repeat()`, `startsWith()`, `endsWith()`, `indexOf()`, `lastIndexOf()`
  - `str.split(separator)` - Split string into array (empty separator splits each char)
  - `str.substring(start, end)` - Extract substring from start to end (end optional)
  - `str.charAt(index)` - Get character at index, returns empty string if out of bounds
  - `str.toUpperCase()` - Convert to uppercase
  - `str.toLowerCase()` - Convert to lowercase
  - `str.trim()` - Remove whitespace from both ends
  - `str.replace(search, replacement)` - Replace first occurrence of search string
  - `str.repeat(count)` - Repeat string N times
  - `str.startsWith(prefix)` - Check if string starts with prefix
  - `str.endsWith(suffix)` - Check if string ends with suffix
  - `str.indexOf(substring)` - Find first position of substring (0-indexed, -1 if not found)
  - `str.lastIndexOf(substring)` - Find last position of substring

#### Objects
- Object literals: `{key: value, key2: value2}`
- Property access (dot notation): `obj.property`
- Property access (bracket notation): `obj["property"]`
- Property assignment: `obj.property = value`, `obj["key"] = value`
- Adding new properties: properties are created if they don't exist
- Accessing undefined properties returns `undefined`

#### Classes and OOP
- `class Name { ... }` - Class declarations
- `constructor(params) { ... }` - Constructor methods
- `this.property` - Instance properties
- `this.method()` - Instance methods
- `new ClassName(args)` - Create instances
- `class Child extends Parent { ... }` - Inheritance
- `super(args)` - Call parent constructor
- Method overriding in child classes
- Multi-level inheritance supported
- `typeof instance` returns `"object"`
- `typeof class` returns `"function"`

**How Classes and Inheritance Are Implemented:**


1. **Class Representation**: Classes are stored as `Val_Class` values containing:
   - Constructor function (executed when creating instances)
   - Method map (all instance methods)
   - Parent class reference (for inheritance chains)

2. **Object Instances**: When `new ClassName()` is called:
   - A new object (`Val_Object`) is created
   - The constructor is executed with `this` bound to the new object
   - Instance properties are set via `this.property = value`
   - The object gets a reference to its class (for method lookup)

3. **Method Dispatch**: When calling `obj.method()`:
   - First checks the object's own properties
   - Then searches the class's method map
   - If not found and class has a parent, searches up the inheritance chain
   - Methods are executed with `this` bound to the calling object

4. **The `this` Keyword**: 
   - Implemented as a special variable in the environment
   - Automatically bound when entering constructor or method
   - Allows methods to access and modify instance state

5. **The `super` Keyword**:
   - Used in constructors to call parent constructor: `super(args)`
   - Implemented by looking up parent class and calling its constructor
   - Ensures proper initialization of inherited properties

6. **Inheritance Chain**: 
   - Child classes store reference to parent class
   - Method lookup traverses the chain until method is found
   - Allows multi-level inheritance (GrandChild -> Child -> Parent)

#### Built-in Objects and Functions

**Math Object:**
- `Math.PI` - Pi constant (3.14159...)
- `Math.E` - Euler's number (2.71828...)
- `Math.floor(x)` - Round down to integer
- `Math.ceil(x)` - Round up to integer
- `Math.round(x)` - Round to nearest integer
- `Math.abs(x)` - Absolute value
- `Math.sqrt(x)` - Square root
- `Math.pow(base, exp)` - Raise to power
- `Math.min(a, b, ...)` - Find minimum value
- `Math.max(a, b, ...)` - Find maximum value
- `Math.random()` - Random number between 0 and 1

**Global Functions:**
- `print(value)` - Print value to console (REPL compatibility)
- `parseInt(string)` - Parse string to integer
- `parseFloat(string)` - Parse string to float
- `isNaN(value)` - Check if value is not a number
- `isFinite(value)` - Check if value is a finite number
- `console.log(...args)` - Print values to console (same as print)

#### Error Handling

**Try/Catch/Finally:**
- `try { ... } catch (e) { ... }` - Catch and handle exceptions
- `try { ... } finally { ... }` - Always execute finally block
- `try { ... } catch (e) { ... } finally { ... }` - Catch errors and run cleanup
- `throw value` - Throw an exception (can throw any value: string, number, object, etc.)
- Finally block executes even if there's a return, break, or continue
- Catch parameter binds the thrown value to a variable

**Features:**
- Throw any JavaScript value (strings, numbers, objects)
- Nested try/catch blocks
- Exception propagation through function calls
- Finally block always executes for cleanup
- Try/catch in loops and functions

#### Literals
- Numbers: `42`, `3.14`
- Strings: `"hello"`, `'world'`
- Booleans: `true`, `false`
- `null`, `undefined`
- Arrays: `[1, 2, 3]`, `[]`
- Objects: `{name: "John", age: 30}`, `{}`

### Examples

```javascript
// Variables
let x = 10
let y = 20
print(x + y)         // 30

// Assignment
x = 15
print(x)             // 15

// Constants
const PI = 3.14
print(PI)            // 3.14

// Functions
function add(a, b) {
    return a + b
}
print(add(5, 3))     // 8

// Recursive functions
function factorial(n) {
    if (n <= 1) {
        return 1
    }
    return n * factorial(n - 1)
}
print(factorial(5))  // 120

// Control flow
let x = 10
if (x > 5) {
    print("big")
} else {
    print("small")
}

// Loops
for (let i = 0; i < 5; i = i + 1) {
    print(i)
}

while (x > 0) {
    x = x - 1
}

do {
    print("At least once")
} while (false)

// Switch/case
switch (x) {
    case 1:
        print("One")
        break
    case 2:
        print("Two")
        break
    default:
        print("Other")
}

// Ternary operator
let status = x > 5 ? "big" : "small"

// Arrow functions
let double = (x) => x * 2
print(double(5))        // 10

let add = (a, b) => a + b
print(add(3, 7))        // 10

// Arrow functions with blocks
let max = (a, b) => {
    if (a > b) {
        return a
    } else {
        return b
    }
}
print(max(10, 20))      // 20

// Functional array methods
let numbers = [1, 2, 3, 4, 5]

// map - transform elements
let doubled = numbers.map((x) => x * 2)
print(doubled)          // [2, 4, 6, 8, 10]

// filter - select elements
let evens = numbers.filter((x) => x % 2 == 0)
print(evens)            // [2, 4]

// find - find first match
let firstBig = numbers.find((x) => x > 3)
print(firstBig)         // 4

// reduce - accumulate to single value
let sum = numbers.reduce((acc, x) => acc + x, 0)
print(sum)              // 15

// forEach - iterate with side effects
numbers.forEach((x) => print(x))

// Chaining operations
let result = [1, 2, 3, 4, 5, 6]
    .filter((x) => x % 2 == 0)  // [2, 4, 6]
    .map((x) => x * 10)          // [20, 40, 60]
    .reduce((a, b) => a + b, 0)  // 120
print(result)
}

// While loops
let sum = 0
let i = 1
while (i <= 5) {
    sum = sum + i
    i = i + 1
}
print(sum)           // 15

// For loops
for (let i = 0; i < 5; i = i + 1) {
    print(i)
}                    // 0, 1, 2, 3, 4

// Complex expressions with variables
let a = 5
let b = 10
print(a * b + 20)    // 70

// Arithmetic
2 + 3 * 4           // 14
100 / 4             // 25
10 % 3              // 1

// Comparisons
5 > 3               // true
10 == 10            // true
7 <= 5              // false

// Logical operations
true && false       // false
true || false       // true
5 > 3 && 10 < 20    // true

// Complex expressions
10 + 5 > 12         // true
(5 + 3) * 2         // 16

// Unary operators
print(-5)           // -5
print(!true)        // false
print(typeof 42)    // "number"

// Increment/Decrement
let x = 5
print(x++)          // 5 (returns old value)
print(x)            // 6
print(++x)          // 7 (returns new value)
print(x)            // 7
for (let i = 0; i < 3; i++) {
    print(i)        // 0, 1, 2
}

// Arrays
let arr = [1, 2, 3]
print(arr)          // [1, 2, 3]
print(arr[0])       // 1
print(arr.length)   // 3
arr[0] = 99
print(arr)          // [99, 2, 3]

// Array methods
arr.push(4)
print(arr)          // [99, 2, 3, 4]
let last = arr.pop()
print(last)         // 4
let first = arr.shift()
print(first)        // 99
arr.unshift(0)
print(arr)          // [0, 2, 3]

// More array methods
let nums = [1, 2, 3, 4, 5]
print(nums.slice(1, 3))    // [2, 3]
print(nums.join(" - "))     // "1 - 2 - 3 - 4 - 5"
print(nums.indexOf(3))      // 2
print(nums.includes(10))    // false

// String operations
print("Hello" + " " + "World")  // "Hello World"
let str = "Hello"
print(str.length)   // 5
print(str[0])       // "H"
print("abc" < "xyz") // true

// Objects
let person = {name: "John", age: 30, city: "Boston"}
print(person)       // {name: John, age: 30, city: Boston}
print(person.name)  // John
print(person["age"]) // 30
person.age = 31
print(person.age)   // 31
person.country = "USA"  // Add new property
print(person)       // {name: John, age: 31, city: Boston, country: USA}

// Classes and OOP
class Animal {
    constructor(name) {
        this.name = name
    }
    
    speak() {
        print(this.name + " makes a sound")
    }
}

class Dog extends Animal {
    constructor(name, breed) {
        super(name)
        this.breed = breed
    }
    
    speak() {
        print(this.name + " barks!")
    }
}

let dog = new Dog("Rex", "Golden Retriever")
dog.speak()         // "Rex barks!"
print(dog.name)     // "Rex"
print(dog.breed)    // "Golden Retriever"

// Built-in objects and functions
print(Math.PI)              // 3.141593
print(Math.sqrt(16))        // 4
print(Math.pow(2, 8))       // 256
print(Math.max(5, 3, 8))    // 8

let num = parseInt("42")
let pi = parseFloat("3.14")
print(num + pi)             // 45.14

console.log("Hello", "World", 123)  // Hello World 123

// Error handling
try {
    throw "Something went wrong"
} catch (e) {
    print("Caught error: " + e)
}

function divide(a, b) {
    if (b == 0) {
        throw "Division by zero"
    }
    return a / b
}

try {
    print(divide(10, 2))   // 5
    print(divide(10, 0))   // Throws error
} catch (error) {
    print("Error: " + error)
} finally {
    print("Cleanup runs always")
}
```


### Syntax Limitations

1. **Anonymous Function Expressions Not Supported**
   ```javascript
   // Doesn't work:
   return function(x) { return x * 2; };
   
   // Use arrow functions instead:
   return (x) => { return x * 2; };
   // or
   return (x) => x * 2;
   ```

2. **For Loop Update Expression**
   ```javascript
   // Doesn't work:
   for (let i = 0; i < 10; i = i + 1) { }
   
   // Use increment operators:
   for (let i = 0; i < 10; i++) { }
   ```

3. **Block Statement Limit**
   - Maximum 500 statements per block
   - Very large programs may need to be split into functions

### Language Feature Limitations

1. **Closures - Partial Support** 
   
   **What Works:**
   ```javascript
   // Reading outer variables
   function makeGreeter(greeting) {
       return (name) => {
           return greeting + ', ' + name;  // Can read 'greeting'
       };
   }
   var sayHello = makeGreeter('Hello');
   sayHello('Alice');  // "Hello, Alice" - Works!
   
   // Higher-order functions
   function add(fn) {
       return (s) => {
           fn(s + ' is Best');  // Can call 'fn'
       };
   }
   ```
   
   **What Doesn't Work:**
   ```javascript
   // Mutating captured variables
   function makeCounter() {
       var count = 0;
       return () => {
           count = count + 1;  // Doesn't persist!
           return count;
       };
   }
   var c = makeCounter();
   c();  // Returns 1
   c();  // Returns 1 (not 2!) - mutation lost
   ```
   
   **Why:** Captured variables are copied, not referenced. Each call gets a fresh copy.
   
   **Workaround:** Use object properties for mutable state:
   ```javascript
   function makeCounter() {
       var state = { count: 0 };
       return () => {
           state.count = state.count + 1;
           return state.count;
       };
   }
   ```

2. **Function-Level Scope Only**
   - `let` and `const` use function scope, not block scope
   - Variables declared in blocks are accessible outside the block
   ```javascript
   {
       let x = 1;
   }
   console.log(x);  // Works (should error in strict JS)
   ```

3. **String Length Limit**
   - Maximum string length: 1000 characters
   - Longer strings will be truncated

4. **Math.random() Precision**
   - Limited by system clock resolution
   - May not be cryptographically secure

5. **No Object Reference Equality**
   ```javascript
   var obj1 = {a: 1};
   var obj2 = {a: 1};
   console.log(obj1 == obj2);  // Returns false (correct)
   
   var obj3 = obj1;
   console.log(obj1 == obj3);  // Returns false (should be true)
   ```

### Features Not Implemented

By design, these JavaScript features are not implemented:

- Regular expressions (`/pattern/`)
- Template literals (backticks)
- Spread operator (`...`)
- Destructuring assignment
- `async`/`await` and Promises
- Generators (`function*` and `yield`)
- ES6 modules (`import`/`export`)
- Proxy and Reflect
- Symbol type
- WeakMap/WeakSet
- Browser APIs (`document`, `window`, `setTimeout`, `fetch`, etc.)



## References for the object and class implementation
**Sebesta: Concepts Of Programming Languages**

**Gabbrielli, Martini: Programming languages: Principles and Paradigms (Ch. 10 The Object-Oriented Paradigm)**

