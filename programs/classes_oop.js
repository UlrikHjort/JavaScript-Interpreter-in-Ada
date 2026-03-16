// Object-Oriented Programming with Classes

class Shape {
    constructor(name) {
        this.name = name;
    }
}

class Rectangle extends Shape {
    constructor(width, height) {
        super("Rectangle");
        this.width = width;
        this.height = height;
    }
    
    area() {
        return this.width * this.height;
    }
    
    perimeter() {
        return 2 * (this.width + this.height);
    }
}

class Circle extends Shape {
    constructor(radius) {
        super("Circle");
        this.radius = radius;
    }
    
    area() {
        return 3.14159 * this.radius * this.radius;
    }
    
    perimeter() {
        return 2 * 3.14159 * this.radius;
    }
}

class BankAccount {
    constructor(owner, balance) {
        this.owner = owner;
        this.balance = balance;
    }
    
    deposit(amount) {
        this.balance = this.balance + amount;
        return this.balance;
    }
    
    withdraw(amount) {
        if (amount <= this.balance) {
            this.balance = this.balance - amount;
        }
        return this.balance;
    }
    
    getBalance() {
        return this.balance;
    }
}

print("=== Object-Oriented Programming ===");
print("");

print("--- Shapes ---");
let rect = new Rectangle(10, 5);
print("Rectangle: " + rect.name);
print("Width: " + rect.width + ", Height: " + rect.height);
print("Area: " + rect.area());
print("Perimeter: " + rect.perimeter());
print("");

let circle = new Circle(7);
print("Circle: " + circle.name);
print("Radius: " + circle.radius);
print("Area: " + circle.area());
print("Perimeter: " + circle.perimeter());
print("");

print("--- Bank Accounts ---");
let account1 = new BankAccount("Alice", 1000);
print("Account owner: " + account1.owner);
print("Initial balance: " + account1.getBalance());

account1.deposit(500);
print("After deposit 500: " + account1.getBalance());

account1.withdraw(200);
print("After withdraw 200: " + account1.getBalance());
print("");

let account2 = new BankAccount("Bob", 500);
let account3 = new BankAccount("Charlie", 2000);

print("All accounts:");
print("Alice: " + account1.getBalance());
print("Bob: " + account2.getBalance());
print("Charlie: " + account3.getBalance());
