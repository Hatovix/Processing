import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

// Canvas dimensions
int canvasWidth = 800;
int canvasHeight = 800;

// Rendering settings
int[] possiblePixelSize = {1, 2, 4};

// Running settings
boolean saveAllImages = false;
boolean loopOnPixelSize = true;
boolean changeOnPixelSize = true;
String imagesFolder = "Images/";
int delayMS; // Will be set automatically if left undefined

ColorProportion[] colors = {
    // Black to MidnightBlue mix (https://www.w3schools.com/colors/colors_mixer.asp?colorbottom=191970&colortop=000000)
    // Fibonacci proportions
    new ColorProportion(#000000, 10946),
    new ColorProportion(#010106, 6765),
    new ColorProportion(#02020b, 4181),
    new ColorProportion(#040411, 2584),
    new ColorProportion(#050516, 1597),
    new ColorProportion(#06061c, 987),
    new ColorProportion(#080822, 610),
    new ColorProportion(#090927, 377),
    new ColorProportion(#0a0a2d, 233),
    new ColorProportion(#0b0b32, 144),
    new ColorProportion(#0c0c38, 89),
    new ColorProportion(#0e0e3e, 55),
    new ColorProportion(#0f0f43, 34),
    new ColorProportion(#101049, 21),
    new ColorProportion(#12124e, 13),
    new ColorProportion(#131354, 8),
    new ColorProportion(#14145a, 5),
    new ColorProportion(#15155f, 3),
    new ColorProportion(#161665, 2),
    new ColorProportion(#18186a, 1),
    new ColorProportion(#191970, 1),
    
    // Harvard spectral classification
    new ColorProportion(#9CBDFF, 0.0000021), // O-type star, real proportion: 0.0000021
    new ColorProportion(#A6C3FF, 0.0084), // B-type star, real proportion: 0.0084
    new ColorProportion(#D9E3FF, 0.0427), // A-type star, real proportion: 0.0427
    new ColorProportion(#FFF8FF, 0.21), // F-type star, real proportion: 0.21
    new ColorProportion(#FFEEE4, 0.532), // G-type star, real proportion: 0.532
    new ColorProportion(#FFDDBE, 0.84), // K-type star, real proportion: 0.84
    new ColorProportion(#FFB873, 5.32), // M-type star, real proportion: 5.32
};


// Automatic settings
ColorOdds odds = new ColorOdds(colors);
int pixelSizeIndex;
int pixelSize;
int rows;
int columns;

void setup() {
    // size(1584, 396); // Size function can't deal with declared variables...
    windowResize(canvasWidth, canvasHeight);
    noStroke(); // Shapes without borders
    initPixelSize();
    initDelay();
    odds.debug();
}

void draw() {
    for (int row = 0; row < rows; row++) {
        int y = row * pixelSize;
        for (int column = 0; column < columns; column++) {
            int x = column * pixelSize;
            Pixel p = new Pixel(x, y);
            p.displayRandomColor();
        }
    }

    if (saveAllImages) {
        saveImage();
    } 
    
    delay(delayMS);

    nextPixelSize();
}

void saveImage() {
    DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HHmmss");
    Date d = new Date();
    String filename = dateFormat.format(d) + " pixelSize " + pixelSize + ".png";
    save(imagesFolder + filename);
    println("Image saved as " + filename);
}

void mouseClicked() {
    saveImage();
}

void initDelay() {
    if (delayMS != 0) {
        return; // Custom timer already set
    }

    if (!saveAllImages) {
        delayMS = 2000; // Timer for human to perform save
        return;
    }

    if (loopOnPixelSize) {
        delayMS = 1000 / possiblePixelSize.length;
    }
}

void initPixelSize() {
    pixelSizeIndex = 0;
    setPixelSize();
}

void setPixelSize() {
    pixelSize = possiblePixelSize[pixelSizeIndex];
    rows = canvasHeight / pixelSize;
    columns = canvasWidth / pixelSize;
}

void nextPixelSize() {
    if (!changeOnPixelSize) {
        return;
    }
    
    pixelSizeIndex++;

    if (pixelSizeIndex == possiblePixelSize.length) {
        if (loopOnPixelSize) {
            pixelSizeIndex = 0;
        } else {
            exit(); // Will finish execution of current draw() call before stopping the program
            return;
        }
    }

    setPixelSize();
}

class Pixel {
    int x, y;

    Pixel(int x, int y) {
        this.x = x;
        this.y = y;
    }

    void displayRandomColor() {
        fill(odds.getRandomColor());
        square(x, y, pixelSize);
    }
}

class ColorProportion {
    float proportion; // Initial odd proportion
    float min, max; // Random number generation matching range, min inclusive / max exclusive
    color c;

    ColorProportion(color hexColor, float proportion) {
        this.c = hexColor;
        this.proportion = proportion;
    }

    float getProportion() {
        return proportion;
    }

    color getColor() {
        return c;
    }

    void setMin(float value) {
        min = value;
    }

    void setMax(float value) {
        max = value;
    }

    boolean isInRange(float value) {
        return min <= value && value < max;
    }

    void debug() {
        String colorText = "Color code #" + hex(c, 6);
        String proportionText = "Proportion of " + proportion;
        String rangeText = "Applied range => [" + min + ", " + max + "[";
        println(colorText + "; " + proportionText + "; " + rangeText);
    }
}

class ColorOdds {
    ColorProportion[] colors;

    ColorOdds(ColorProportion[] colors) {
        this.colors = colors;
        fillOddRanges();
    }

    void fillOddRanges() {
        float oddSum = 0;
        float min = 0;
        float max = 0;
        for (ColorProportion c: colors) {
            oddSum += c.getProportion();
        }
        if (oddSum == 0) {
            exit();
            return;
        }
        for (ColorProportion c: colors) {
            max = min + c.getProportion() / oddSum;
            c.setMin(min);
            c.setMax(max);
            min = max;
        }
    }

    color getRandomColor() {
        float r = random(0, 1);
        for (ColorProportion c: colors) {
            if (c.isInRange(r)) {
                return c.getColor();
            }
        }

        // Should be unreachable
        // However, an error can accumulate, making the last range not reaching 1
        // and so having no match, requiring another random generation
        println("r => ", r);
        return getRandomColor();
    }

    void debug() {
        for (ColorProportion c: colors) {
            c.debug();
        }
    }
}