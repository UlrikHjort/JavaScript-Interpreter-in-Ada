// Test 1: Basic inheritance
print("=== Test 1: Basic Inheritance ===");
class Animal {
   constructor(name) {
      this.name = name;
   }
   
   speak() {
      print(this.name + " makes a sound");
   }
}

class Dog extends Animal {
   constructor(name, breed) {
      super(name);
      this.breed = breed;
   }
   
   bark() {
      print(this.name + " barks!");
   }
}

let dog = new Dog("Rex", "Labrador");
dog.speak();  // Inherited method
dog.bark();   // Own method
print("Breed: " + dog.breed);
print("");

// Test 2: Method overriding
print("=== Test 2: Method Overriding ===");
class Cat extends Animal {
   constructor(name, color) {
      super(name);
      this.color = color;
   }
   
   speak() {
      print(this.name + " meows!");
   }
}

let cat = new Cat("Whiskers", "orange");
cat.speak();  // Overridden method
print("Color: " + cat.color);
print("");

// Test 3: Multi-level inheritance
print("=== Test 3: Multi-level Inheritance ===");
class Vehicle {
   constructor(brand) {
      this.brand = brand;
   }
   
   honk() {
      print(this.brand + " goes beep!");
   }
}

class Car extends Vehicle {
   constructor(brand, model) {
      super(brand);
      this.model = model;
   }
   
   drive() {
      print("Driving " + this.brand + " " + this.model);
   }
}

class ElectricCar extends Car {
   constructor(brand, model, battery) {
      super(brand, model);
      this.battery = battery;
   }
   
   charge() {
      print("Charging " + this.battery + "kWh battery");
   }
}

let tesla = new ElectricCar("Tesla", "Model 3", 75);
tesla.honk();    // From Vehicle (grandparent)
tesla.drive();   // From Car (parent)
tesla.charge();  // Own method
print("");

// Test 4: Access to properties set by parent
print("=== Test 4: Parent Properties ===");
class Person {
   constructor(name, age) {
      this.name = name;
      this.age = age;
   }
   
   introduce() {
      print("I'm " + this.name);
   }
}

class Student extends Person {
   constructor(name, age, grade) {
      super(name, age);
      this.grade = grade;
   }
   
   study() {
      print(this.name + " is studying for grade " + this.grade);
   }
}

let student = new Student("Alice", 15, 10);
student.introduce();  // Calls parent method using this.name set by parent
student.study();
print("Age: " + student.age);  // Property from parent
print("");

print("=== All Inheritance Tests Complete! ===");
