// Data structures: Stack and Queue implementations

print("=== Data Structures ===");
print("");

print("--- Stack (LIFO - Last In First Out) ---");
let stack = [];
print("Push: 10, 20, 30");
stack.push(10);
stack.push(20);
stack.push(30);
print("Stack size: " + stack.length);
print("Top element: " + stack[stack.length - 1]);
print("Pop: " + stack.pop());
print("Pop: " + stack.pop());
print("Top element: " + stack[stack.length - 1]);
print("Stack size: " + stack.length);
print("");

print("--- Queue (FIFO - First In First Out) ---");
let queue = [];
print("Enqueue: A, B, C");
queue.push("A");
queue.push("B");
queue.push("C");
print("Queue size: " + queue.length);
print("Front element: " + queue[0]);
print("Dequeue: " + queue.shift());
print("Dequeue: " + queue.shift());
print("Front element: " + queue[0]);
print("Queue size: " + queue.length);
print("");

print("--- Practical Example: Reverse String with Stack ---");
function reverseWithStack(str) {
    let stack = [];
    let i = 0;
    while (i < str.length) {
        stack.push(str[i]);
        i++;
    }
    
    let result = "";
    while (stack.length > 0) {
        result = result + stack.pop();
    }
    return result;
}

print("Original: 'hello'");
print("Reversed: '" + reverseWithStack("hello") + "'");
print("");

print("Original: 'JavaScript'");
print("Reversed: '" + reverseWithStack("JavaScript") + "'");
print("");

print("--- Practical Example: Palindrome Checker ---");
function isPalindromeStack(str) {
    let stack = [];
    let i = 0;
    while (i < str.length) {
        stack.push(str[i]);
        i++;
    }
    
    i = 0;
    while (i < str.length) {
        if (str[i] != stack.pop()) {
            return false;
        }
        i++;
    }
    return true;
}

print("'racecar' is palindrome? " + isPalindromeStack("racecar"));
print("'hello' is palindrome? " + isPalindromeStack("hello"));
print("'level' is palindrome? " + isPalindromeStack("level"));
