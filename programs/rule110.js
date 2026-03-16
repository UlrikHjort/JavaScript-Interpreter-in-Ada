// Rule 110 - Elementary Cellular Automaton
// One of Stephen Wolfram's elementary cellular automata
// Proven to be Turing complete!

// Rule 110 lookup table:
// Pattern: 111 110 101 100 011 010 001 000
// Result:   0   1   1   0   1   1   1   0
// Binary: 01101110 = 110 in decimal

function applyRule110(left, center, right) {
    // Convert pattern to index (0-7)
    let pattern = left * 4 + center * 2 + right;
    
    // Rule 110: 01101110 in binary
    // Index:    76543210
    if (pattern == 7) return 0;  // 111 -> 0
    if (pattern == 6) return 1;  // 110 -> 1
    if (pattern == 5) return 1;  // 101 -> 1
    if (pattern == 4) return 0;  // 100 -> 0
    if (pattern == 3) return 1;  // 011 -> 1
    if (pattern == 2) return 1;  // 010 -> 1
    if (pattern == 1) return 1;  // 001 -> 1
    if (pattern == 0) return 0;  // 000 -> 0
    return 0;
}

function displayRow(cells) {
    let line = "";
    for (let i = 0; i < cells.length; i++) {
        if (cells[i] == 1) {
            line = line + "#";
        } else {
            line = line + " ";
        }
    }
    console.log(line);
}

function evolve(cells) {
    let len = cells.length;
    let newCells = [];
    
    for (let i = 0; i < len; i++) {
        // Get neighbors (use 0 for edges)
        let left = 0;
        let right = 0;
        
        if (i > 0) left = cells[i - 1];
        if (i < len - 1) right = cells[i + 1];
        
        let center = cells[i];
        newCells[i] = applyRule110(left, center, right);
    }
    
    return newCells;
}

// Configuration
let width = 79;      // Width of the cellular automaton
let generations = 40; // Number of generations to simulate

// Initialize cells - single cell on the right edge
let cells = [];
for (let i = 0; i < width; i++) cells[i] = 0;
cells[width - 1] = 1;  // Start with single cell on the right

// Display header
console.log("=== Rule 110 - Elementary Cellular Automaton ===");
console.log("Width: " + width + " cells, Generations: " + generations);
console.log("");

// Run simulation
for (let gen = 0; gen < generations; gen++) {
    displayRow(cells);
    cells = evolve(cells);
}

console.log("");
console.log("Rule 110 is Turing complete - it can simulate any computation!");
console.log("This simple pattern can perform universal computation.");
