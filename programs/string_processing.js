// String processing and text analysis

function wordCount(str) {
    let trimmed = str.trim();
    if (trimmed.length == 0) {
        return 0;
    }
    function notEmpty(word) {
        return word.length > 0;
    }
    let words = trimmed.split(" ");
    return words.filter(notEmpty).length;
}

function reverseString(str) {
    let result = "";
    let i = str.length - 1;
    while (i >= 0) {
        result = result + str[i];
        i--;
    }
    return result;
}

function isPalindrome(str) {
    let cleaned = str.toLowerCase().trim();
    return cleaned == reverseString(cleaned);
}

function countVowels(str) {
    let vowels = "aeiouAEIOU";
    let count = 0;
    let i = 0;
    while (i < str.length) {
        if (vowels.indexOf(str[i]) >= 0) {
            count++;
        }
        i++;
    }
    return count;
}

function titleCase(str) {
    function capitalize(word) {
        if (word.length == 0) {
            return word;
        }
        let first = word[0].toUpperCase();
        let rest = word.substring(1).toLowerCase();
        return first + rest;
    }
    let words = str.split(" ");
    let capitalized = words.map(capitalize);
    return capitalized.join(" ");
}

print("=== String Processing ===");
print("");

let text = "hello world from javascript";
print("Text: '" + text + "'");
print("");

print("Analysis:");
print("Length: " + text.length);
print("Word count: " + wordCount(text));
print("Vowel count: " + countVowels(text));
print("");

print("Transformations:");
print("Uppercase: " + text.toUpperCase());
print("Title case: " + titleCase(text));
print("Reversed: " + reverseString(text));
print("");

print("Palindrome tests:");
print("'racecar' is palindrome? " + isPalindrome("racecar"));
print("'hello' is palindrome? " + isPalindrome("hello"));
print("'madam' is palindrome? " + isPalindrome("madam"));
