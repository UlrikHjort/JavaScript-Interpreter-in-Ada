// Sorting algorithms demonstration

// Bubble Sort
function bubbleSort(arr) {
    let n = arr.length;
    let i = 0;
    while (i < n) {
        let j = 0;
        while (j < n - i - 1) {
            if (arr[j] > arr[j + 1]) {
                let temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
            j++;
        }
        i++;
    }
    return arr;
}

// Selection Sort
function selectionSort(arr) {
    let n = arr.length;
    let i = 0;
    while (i < n - 1) {
        let minIdx = i;
        let j = i + 1;
        while (j < n) {
            if (arr[j] < arr[minIdx]) {
                minIdx = j;
            }
            j++;
        }
        if (minIdx != i) {
            let temp = arr[i];
            arr[i] = arr[minIdx];
            arr[minIdx] = temp;
        }
        i++;
    }
    return arr;
}

// Insertion Sort
function insertionSort(arr) {
    let i = 1;
    while (i < arr.length) {
        let key = arr[i];
        let j = i - 1;
        while (j >= 0 && arr[j] > key) {
            arr[j + 1] = arr[j];
            j--;
        }
        arr[j + 1] = key;
        i++;
    }
    return arr;
}

print("=== Sorting Algorithms ===");
print("");

let unsorted = [64, 34, 25, 12, 22, 11, 90, 88, 45, 50, 33, 17];
print("Original array:");
print(unsorted.join(", "));
print("");

let arr1 = [64, 34, 25, 12, 22, 11, 90, 88, 45, 50, 33, 17];
bubbleSort(arr1);
print("Bubble Sort:");
print(arr1.join(", "));
print("");

let arr2 = [64, 34, 25, 12, 22, 11, 90, 88, 45, 50, 33, 17];
selectionSort(arr2);
print("Selection Sort:");
print(arr2.join(", "));
print("");

let arr3 = [64, 34, 25, 12, 22, 11, 90, 88, 45, 50, 33, 17];
insertionSort(arr3);
print("Insertion Sort:");
print(arr3.join(", "));
