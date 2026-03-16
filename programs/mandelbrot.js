// ASCII Mandelbrot Set Generator
// Renders the famous Mandelbrot fractal using ASCII characters

// Configuration
let width = 80;          // Width in characters
let height = 40;         // Height in characters
let maxIterations = 50;  // Max iterations to test

// Viewport in complex plane
let xMin = -2.5;
let xMax = 1.0;
let yMin = -1.0;
let yMax = 1.0;

// ASCII gradient from dark to light (representing iteration count)
let chars = " .:-=+*#%@";

// Calculate if a point is in the Mandelbrot set
function mandelbrot(cx, cy) {
    let x = 0;
    let y = 0;
    let iteration = 0;
    
    while (iteration < maxIterations) {
        // Complex number squaring: (x + yi)^2 = (x^2 - y^2) + (2xy)i
        let x2 = x * x;
        let y2 = y * y;
        
        // Check if escaped (magnitude > 2)
        if (x2 + y2 > 4) {
            return iteration;
        }
        
        // z = z^2 + c
        let xTemp = x2 - y2 + cx;
        y = 2 * x * y + cy;
        x = xTemp;
        
        iteration = iteration + 1;
    }
    
    return maxIterations;
}

// Map iteration count to ASCII character
function getChar(iterations) {
    if (iterations == maxIterations) {
        return " ";  // Inside the set
    }
    
    let index = (iterations * chars.length) / maxIterations;
    
    // Convert to integer by truncating
    let intIndex = 0;
    while (intIndex < index && intIndex < chars.length - 1) {
        intIndex = intIndex + 1;
    }
    
    if (intIndex >= chars.length) {
        intIndex = chars.length - 1;
    }
    return chars[intIndex];
}

print("=== Mandelbrot Set ===");
print("");
print("Rendering " + width + "x" + height + " fractal...");
print("");

// Render the Mandelbrot set
let row = 0;
while (row < height) {
    let line = "";
    let col = 0;
    
    while (col < width) {
        // Map pixel coordinates to complex plane
        let cx = xMin + (col / width) * (xMax - xMin);
        let cy = yMin + (row / height) * (yMax - yMin);
        
        // Calculate iterations for this point
        let iterations = mandelbrot(cx, cy);
        
        // Convert to ASCII character
        let char = getChar(iterations);
        line = line + char;
        
        col = col + 1;
    }
    
    print(line);
    row = row + 1;
}

print("");
print("Legend: ' ' = inside set, '.:-=+*#%@' = escaped (darker = more iterations)");
print("Center of main bulb: approximately (-0.5, 0)");
