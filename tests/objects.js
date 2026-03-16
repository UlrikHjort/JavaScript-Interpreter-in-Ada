// Test objects

print("=== Object Tests ===");

// Test object literals
print("\n--- Object Literals ---");
let person = {name: "John", age: 30, city: "Boston"};
print(person);

let empty = {};
print("Empty object: " + empty);

// Test property access (dot notation)
print("\n--- Property Access (Dot Notation) ---");
print("person.name = " + person.name);
print("person.age = " + person.age);
print("person.city = " + person.city);

// Test property access (bracket notation)
print("\n--- Property Access (Bracket Notation) ---");
print('person["name"] = ' + person["name"]);
print('person["age"] = ' + person["age"]);
print('person["city"] = ' + person["city"]);

// Test property assignment (dot notation)
print("\n--- Property Assignment (Dot Notation) ---");
person.age = 31;
print("After person.age = 31: " + person);

person.city = "New York";
print("After person.city = 'New York': " + person);

// Test property assignment (bracket notation)
print("\n--- Property Assignment (Bracket Notation) ---");
person["age"] = 32;
print('After person["age"] = 32: ' + person);

person["city"] = "Chicago";
print('After person["city"] = "Chicago": ' + person);

// Test adding new properties
print("\n--- Adding New Properties ---");
person.country = "USA";
print("After person.country = 'USA': " + person);

person["state"] = "IL";
print('After person["state"] = "IL": ' + person);

// Test objects with different value types
print("\n--- Different Value Types ---");
let mixed = {
    num: 42,
    str: "hello",
    bool: true
};
print(mixed);
print("mixed.num = " + mixed.num);
print("mixed.str = " + mixed.str);
print("mixed.bool = " + mixed.bool);

// Test objects in expressions
print("\n--- Objects in Expressions ---");
let point = {x: 10, y: 20};
print("point = " + point);
let sum = point.x + point.y;
print("point.x + point.y = " + sum);

// Test modifying properties in expressions
point.x = point.x + 5;
print("After point.x = point.x + 5: " + point);

// Test undefined properties
print("\n--- Undefined Properties ---");
print("person.nonexistent = " + person.nonexistent);
print("empty.foo = " + empty.foo);

// Test typeof with objects
print("\n--- typeof Objects ---");
print("typeof person = " + typeof person);
print("typeof empty = " + typeof empty);
print("typeof mixed = " + typeof mixed);

// Test objects in conditionals
print("\n--- Objects in Conditionals ---");
if (person) {
    print("person is truthy");
}
if (empty) {
    print("empty object is truthy");
}

// Test objects with arrays
print("\n--- Objects with Array Values ---");
let student = {
    name: "Alice",
    grades: [90, 85, 92]
};
print(student);
print("student.name = " + student.name);
print("student.grades = " + student.grades);
print("student.grades[0] = " + student.grades[0]);

// Modify array in object
student.grades[1] = 95;
print("After modifying grades[1]: " + student);

// Test multiple objects
print("\n--- Multiple Objects ---");
let car1 = {brand: "Toyota", year: 2020};
let car2 = {brand: "Honda", year: 2021};
print("car1: " + car1);
print("car2: " + car2);

car1.year = 2022;
print("After updating car1.year: " + car1);
print("car2 unchanged: " + car2);

print("\n=== All Object Tests Complete ===");
