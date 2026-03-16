// Demo: New Control Flow Features

print("=== JAVASCRIPT INTERPRETER: CONTROL FLOW DEMO ===");
print("");

// 1. TERNARY OPERATOR
print("1. Ternary Operator:");
var age = 25;
var status = age >= 18 ? "Adult" : "Minor";
print("  Age: " + age + " -> Status: " + status);

var score = 85;
var grade = score >= 90 ? "A" : score >= 80 ? "B" : score >= 70 ? "C" : "F";
print("  Score: " + score + " -> Grade: " + grade);
print("");

// 2. DO-WHILE LOOPS
print("2. Do-While Loop (always runs once):");
var countdown = 3;
print("  Countdown:");
do {
   print("    " + countdown + "...");
   countdown = countdown - 1;
} while (countdown > 0);
print("  Blast off!");
print("");

// 3. SWITCH/CASE
print("3. Switch/Case Statement:");
var day = 5;
print("  Day " + day + " is: ");
switch (day) {
   case 1:
      print("    Monday");
      break;
   case 2:
      print("    Tuesday");
      break;
   case 3:
      print("    Wednesday");
      break;
   case 4:
      print("    Thursday");
      break;
   case 5:
      print("    Friday!");
      break;
   case 6:
   case 7:
      print("    Weekend!");
      break;
   default:
      print("    Invalid day");
}
print("");

// 4. COMBINING ALL THREE
print("4. Combined Example: Grade Calculator");
var scores = [95, 82, 78, 65, 91];
var i = 0;
print("  Processing " + scores.length + " scores:");
do {
   var currentScore = scores[i];
   var letterGrade = currentScore >= 90 ? "A" : 
                     currentScore >= 80 ? "B" : 
                     currentScore >= 70 ? "C" : 
                     currentScore >= 60 ? "D" : "F";
   
   var comment = "";
   switch (letterGrade) {
      case "A":
         comment = "Excellent!";
         break;
      case "B":
         comment = "Good job!";
         break;
      case "C":
         comment = "Passing";
         break;
      default:
         comment = "Needs improvement";
   }
   
   print("    Score " + (i + 1) + ": " + currentScore + " -> " + 
         letterGrade + " (" + comment + ")");
   i = i + 1;
} while (i < scores.length);
print("");

// 5. PRACTICAL: MENU SYSTEM
print("5. Menu System Example:");
var menuOption = "list";
print("  Selected: " + menuOption);
switch (menuOption) {
   case "list":
      print("    Displaying items:");
      var items = ["Apple", "Banana", "Cherry"];
      var j = 0;
      do {
         print("      " + (j + 1) + ". " + items[j]);
         j = j + 1;
      } while (j < items.length);
      break;
   case "add":
      print("    Adding new item...");
      break;
   case "delete":
      print("    Deleting item...");
      break;
   default:
      print("    Unknown command");
}
print("");

print("=== DEMO COMPLETE ===");
print("");
print("Features Demonstrated:");
print("  Ternary operator (? :)");
print("  Do-while loops");
print("  Switch/case with fall-through");
print("  Combined usage in real scenarios");
