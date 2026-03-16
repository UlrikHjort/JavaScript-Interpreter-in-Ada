// Control Flow - Complete Feature Test

print("=== CONTROL FLOW COMPREHENSIVE TEST ===");

// 1. TERNARY OPERATOR
print("\n1. Ternary Operator:");
var age = 25;
var canVote = age >= 18 ? "yes" : "no";
print("Can vote: " + canVote);

var max = 10 > 5 ? 10 : 5;
print("Max: " + max);

// Nested ternary
var score = 85;
var grade = score >= 90 ? "A" : score >= 80 ? "B" : score >= 70 ? "C" : "F";
print("Grade for " + score + ": " + grade);

// 2. DO-WHILE LOOPS
print("\n2. Do-While Loops:");
var count = 0;
do {
   print("Count: " + count);
   count = count + 1;
} while (count < 3);

// Always executes once
var x = 100;
do {
   print("Executed with x=" + x);
   x = x + 1;
} while (x < 50);

// 3. SWITCH/CASE
print("\n3. Switch/Case:");
var dayNum = 5;
switch (dayNum) {
   case 1:
      print("Monday");
      break;
   case 2:
      print("Tuesday");
      break;
   case 3:
      print("Wednesday");
      break;
   case 4:
      print("Thursday");
      break;
   case 5:
      print("Friday");
      break;
   case 6:
   case 7:
      print("Weekend!");
      break;
   default:
      print("Invalid day");
}

// Switch with strings
var command = "start";
switch (command) {
   case "start":
      print("Starting...");
      break;
   case "stop":
      print("Stopping...");
      break;
   case "pause":
      print("Pausing...");
      break;
   default:
      print("Unknown command");
}

// 4. COMBINING CONTROL FLOW
print("\n4. Combined Control Flow:");

// Ternary in switch
var value = 15;
var category = value > 10 ? "high" : "low";
switch (category) {
   case "high":
      print("Value is high");
      break;
   case "low":
      print("Value is low");
      break;
}

// Do-while with ternary
var i = 0;
do {
   var msg = i % 2 == 0 ? "even" : "odd";
   print(i + " is " + msg);
   i = i + 1;
} while (i < 4);

// Switch with do-while
var option = 2;
switch (option) {
   case 1:
      print("Option 1 loop:");
      var j = 0;
      do {
         print("  " + j);
         j = j + 1;
      } while (j < 2);
      break;
   case 2:
      print("Option 2 loop:");
      var k = 0;
      do {
         print("  " + k);
         k = k + 1;
      } while (k < 3);
      break;
}

// 5. PRACTICAL EXAMPLES
print("\n5. Practical Examples:");

// Menu system with switch
var menuChoice = "save";
switch (menuChoice) {
   case "new":
      print("Creating new file...");
      break;
   case "open":
      print("Opening file...");
      break;
   case "save":
      print("Saving file...");
      break;
   case "exit":
      print("Exiting...");
      break;
   default:
      print("Invalid choice");
}

// Input validation with do-while and ternary
var attempts = 0;
var maxAttempts = 3;
do {
   var status = attempts < maxAttempts ? "trying" : "failed";
   print("Attempt " + attempts + ": " + status);
   attempts = attempts + 1;
} while (attempts < maxAttempts);

print("\n=== ALL CONTROL FLOW TESTS COMPLETE ===");
