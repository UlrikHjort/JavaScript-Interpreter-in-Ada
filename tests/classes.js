// Test 1: Simple class declaration and instantiation
print("Test 1: Simple class");
class Person {
   constructor(name, age) {
      this.name = name;
      this.age = age;
   }
   
   greet() {
      print("Hello, I'm " + this.name);
   }
   
   getAge() {
      return this.age;
   }
}

let p = new Person("Alice", 30);
p.greet();
print("Age: " + p.getAge());
print("Name: " + p.name);

// Test 2: Multiple instances
print("\nTest 2: Multiple instances");
let p2 = new Person("Bob", 25);
p2.greet();
print("Bob's age: " + p2.getAge());

// Test 3: Method that modifies properties
print("\nTest 3: Modify properties");
class Counter {
   constructor() {
      this.count = 0;
   }
   
   increment() {
      this.count = this.count + 1;
   }
   
   getCount() {
      return this.count;
   }
}

let c = new Counter();
print("Initial: " + c.getCount());
c.increment();
print("After increment: " + c.getCount());
c.increment();
c.increment();
print("After 2 more: " + c.getCount());

// Test 4: typeof
print("\nTest 4: typeof");
print("typeof Person: " + typeof Person);
print("typeof p: " + typeof p);

print("\nAll class tests complete!");
