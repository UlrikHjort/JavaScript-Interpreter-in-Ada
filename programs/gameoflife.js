// Conway's Game of Life
// A cellular automaton where cells evolve based on simple rules

const WIDTH = 50;
const HEIGHT = 25;
const GENERATIONS = 50;

// Initialize grid with random pattern (~20% density)
function createGrid() {
    let grid = [];
    for (let y = 0; y < HEIGHT; y++) {
        let row = [];
        for (let x = 0; x < WIDTH; x++) {
            // Use position-based pseudo-randomness
            let seed = (y * WIDTH + x) * 7919;
            let r = Math.random();
            let val = (r * seed) - Math.floor(r * seed);
            row[x] = (val < 0.20) ? 1 : 0;
        }
        grid[y] = row;
    }
    return grid;
}

// Create glider pattern (simple oscillator/spaceship)
function createGlider() {
    let grid = [];
    for (let y = 0; y < HEIGHT; y++) {
        let row = [];
        for (let x = 0; x < WIDTH; x++) {
            row[x] = 0;
        }
        grid[y] = row;
    }
    
    // Classic glider pattern
    grid[1][2] = 1;
    grid[2][3] = 1;
    grid[3][1] = 1;
    grid[3][2] = 1;
    grid[3][3] = 1;
    
    // Blinker
    grid[10][10] = 1;
    grid[10][11] = 1;
    grid[10][12] = 1;
    
    // Block (stable)
    grid[15][15] = 1;
    grid[15][16] = 1;
    grid[16][15] = 1;
    grid[16][16] = 1;
    
    return grid;
}

// Count living neighbors
function countNeighbors(grid, x, y) {
    let count = 0;
    for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) {
                continue;
            }
            let ny = y + dy;
            let nx = x + dx;
            if (ny >= 0 && ny < HEIGHT && nx >= 0 && nx < WIDTH) {
                if (grid[ny][nx] == 1) {
                    count++;
                }
            }
        }
    }
    return count;
}

// Apply Game of Life rules
function nextGeneration(grid) {
    let newGrid = [];
    
    for (let y = 0; y < HEIGHT; y++) {
        let row = [];
        for (let x = 0; x < WIDTH; x++) {
            let neighbors = countNeighbors(grid, x, y);
            let cell = grid[y][x];
            
            if (cell == 1) {
                // Living cell
                if (neighbors < 2 || neighbors > 3) {
                    row[x] = 0; // Dies
                } else {
                    row[x] = 1; // Survives
                }
            } else {
                // Dead cell
                if (neighbors == 3) {
                    row[x] = 1; // Birth
                } else {
                    row[x] = 0; // Stays dead
                }
            }
        }
        newGrid[y] = row;
    }
    
    return newGrid;
}

// Display the grid
function displayGrid(grid, generation) {
    console.log("Generation " + generation);
    console.log("+" + repeat("-", WIDTH) + "+");
    
    for (let y = 0; y < HEIGHT; y++) {
        let line = "|";
        for (let x = 0; x < WIDTH; x++) {
            if (grid[y][x] == 1) {
                line = line + "#";
            } else {
                line = line + " ";
            }
        }
        line = line + "|";
        console.log(line);
    }
    
    console.log("+" + repeat("-", WIDTH) + "+");
    console.log("");
}

// Helper: repeat character n times
function repeat(char, n) {
    let result = "";
    for (let i = 0; i < n; i++) {
        result = result + char;
    }
    return result;
}

// Count living cells
function countLiving(grid) {
    let count = 0;
    for (let y = 0; y < HEIGHT; y++) {
        for (let x = 0; x < WIDTH; x++) {
            if (grid[y][x] == 1) {
                count++;
            }
        }
    }
    return count;
}

// Run the simulation
console.log("Conway's Game of Life");
console.log("====================");
console.log("");

let grid = createGrid();
displayGrid(grid, 0);

for (let gen = 1; gen <= GENERATIONS; gen++) {
    grid = nextGeneration(grid);
    
    // Show every 5th generation
    if (gen % 5 == 0) {
        displayGrid(grid, gen);
        let living = countLiving(grid);
        console.log("Living cells: " + living);
        console.log("");
    }
}

console.log("Simulation complete!");
