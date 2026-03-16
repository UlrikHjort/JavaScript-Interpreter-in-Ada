// ASCII Mandelbrot Set - Zoomed Views
// Multiple views of the Mandelbrot fractal

let width = 60;
let height = 30;
let maxIterations = 60;
let chars = " .:-=+*#%@";

function mandelbrot(cx, cy) {
    let x = 0;
    let y = 0;
    let iteration = 0;
    
    while (iteration < maxIterations) {
        let x2 = x * x;
        let y2 = y * y;
        
        if (x2 + y2 > 4) {
            return iteration;
        }
        
        let xTemp = x2 - y2 + cx;
        y = 2 * x * y + cy;
        x = xTemp;
        
        iteration = iteration + 1;
    }
    
    return maxIterations;
}

function getChar(iterations) {
    if (iterations == maxIterations) {
        return " ";
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

function render(xMin, xMax, yMin, yMax, title) {
    print("=== " + title + " ===");
    print("");
    
    let row = 0;
    while (row < height) {
        let line = "";
        let col = 0;
        
        while (col < width) {
            let cx = xMin + (col / width) * (xMax - xMin);
            let cy = yMin + (row / height) * (yMax - yMin);
            let iterations = mandelbrot(cx, cy);
            line = line + getChar(iterations);
            col = col + 1;
        }
        
        print(line);
        row = row + 1;
    }
    print("");
}

// View 1: Full overview
render(-2.5, 1.0, -1.0, 1.0, "Full Mandelbrot Set");

// View 2: Zoom on the "tail" (seahorse valley)
render(-0.8, -0.4, -0.2, 0.2, "Seahorse Valley");

// View 3: Zoom on spiral
render(-0.9, -0.6, 0.2, 0.5, "Spiral Region");
