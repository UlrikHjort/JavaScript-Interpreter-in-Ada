// Switch/Case Statement Test Suite

print("=== Switch/Case Tests ===");

// Test 1: Basic switch with numbers
var day = 3;
switch (day) {
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
   default:
      print("Weekend!");
      break;
}

// Test 2: Fall-through behavior (no break)
print("Fall-through test:");
var x = 2;
switch (x) {
   case 1:
   case 2:
   case 3:
      print("x is 1, 2, or 3");
      break;
   case 4:
      print("x is 4");
      break;
   default:
      print("x is something else");
}

// Test 3: Switch with strings
print("String switch:");
var color = "red";
switch (color) {
   case "red":
      print("Stop");
      break;
   case "yellow":
      print("Caution");
      break;
   case "green":
      print("Go");
      break;
   default:
      print("Unknown color");
}

// Test 4: Switch with default
print("Default case:");
var value = 99;
switch (value) {
   case 1:
      print("One");
      break;
   case 2:
      print("Two");
      break;
   default:
      print("Something else: " + value);
}

// Test 5: Switch with expressions in cases
print("Boolean switch:");
var flag = true;
switch (flag) {
   case true:
      print("Flag is true");
      break;
   case false:
      print("Flag is false");
      break;
}

// Test 6: Empty cases (fall-through)
print("Empty case fall-through:");
var grade = "B";
switch (grade) {
   case "A":
   case "B":
      print("Good grade!");
      break;
   case "C":
      print("Average");
      break;
   case "D":
   case "F":
      print("Needs improvement");
      break;
}

print("All switch/case tests complete!");
