// Colored Mandelbrot Set - WIDE VERSION with 2048-char limit!

const WIDTH = 80;
const HEIGHT = 30;
const MAX_ITER = 100;

const ESC = "";
const RESET = ESC + "[0m";

function getColor(iter, maxIter) {
    if (iter == maxIter) {
        return ESC + "[38;5;17m";
    }
    let ratio = iter / maxIter;
    let colorIndex = 16 + Math.floor(ratio * 215);
    if (colorIndex > 231) {
        colorIndex = 231;
    }
    return ESC + "[38;5;" + colorIndex + "m";
}

function mandelbrot(cx, cy, maxIter) {
    let x = 0;
    let y = 0;
    let iter = 0;
    while (iter < maxIter) {
        let x2 = x * x;
        let y2 = y * y;
        if (x2 + y2 > 4) {
            break;
        }
        let temp = x2 - y2 + cx;
        y = 2 * x * y + cy;
        x = temp;
        iter++;
    }
    return iter;
}

function renderMandelbrot(centerX, centerY, zoom, title) {
    console.log("");
    console.log(RESET + title);
    console.log("================================================================================");
    
    for (let py = 0; py < HEIGHT; py++) {
        let line = "";
        for (let px = 0; px < WIDTH; px++) {
            let x = centerX + (px - WIDTH / 2) / (WIDTH / 4) / zoom;
            let y = centerY + (py - HEIGHT / 2) / (HEIGHT / 2) / zoom;
            let iter = mandelbrot(x, y, MAX_ITER);
            let color = getColor(iter, MAX_ITER);
            line = line + color + "█" + RESET;
        }
        console.log(line);
    }
}

console.log(RESET);
console.log("MANDELBROT SET - Full Width Colored Visualization");
console.log("==================================================");

renderMandelbrot(-0.5, 0, 1, "Full Mandelbrot Set (80x30)");
renderMandelbrot(-0.7, 0, 2, "Spiral Region Detail");
renderMandelbrot(-0.75, 0.1, 4, "Seahorse Valley Detail");

console.log("");
console.log(RESET + "Rendering complete!");
