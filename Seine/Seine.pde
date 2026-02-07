import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.HashSet;

// Canvas dimensions
int canvasWidth = 1584; // Adaptative to add some column and have perfect match
int canvasHeight = 396;

// Rendering settings
int pixelSize = 12;
int leftColumnOffset = 0;
int rightColumnOffset = 0;

// Running settings
boolean saveAllImages = false;
boolean autoFitWidth = true;
String imagesFolder = "Images/";
int delayMS; // Will be set automatically if left undefined

color[] colors = {
    // Seine (Kelly Ellsworth, 1951)
    #FFFFFF,
    #000000,
    #FFFFFF,

    // French flag
    // #000091, // French flag Blue
    // #FFFFFF, // French flag White
    // #E1000F, // French flag Red

    // Visible spectrum
    // Norme française AFNOR X080-10 « Classification méthodique générale des couleurs »
    // #27005B, // Violet 445 nm (380 - 449 nm)
    // #2A007B, // Violet-bleu 455 nm (449 - 466 nm)
    // #002F83, // Bleu-violet 470 nm (466 - 478 nm)
    // #004769, // Bleu 480 nm (478 - 483 nm)
    // #005162, // Bleu-vert 485 nm (483 - 490 nm)
    // #00725F, // Vert-bleu 500 nm (490 - 510 nm)
    // #00AF6C, // Vert 525 nm (510 - 541 nm)
    // #59C000, // Vert-jaune 555 nm (541 - 573 nm)
    // #CAB300, // Jaune-vert 574 nm (573 - 575 nm)
    // #D2A900, // Jaune 577 nm (575 - 579 nm)
    // #D79300, // Jaune-orangé 582 nm (579 - 584 nm)
    // #DE8400, // Orangé-jaune 586 nm (584 - 588 nm)
    // #E77700, // Orangé 590 nm (588 - 593 nm)
    // #F55000, // Orangé-rouge 600 nm (593 - 605 nm)
    // #EA0021, // Rouge-orangé 615 nm (605 - 622 nm)
    // #7A0022, // Rouge 650 nm (622 - 780 nm)
};

// Automatic settings
int rows;
int columns;
int colorCycleLength;
float step; // Float type on purpose

void setup() {
    // size(1584, 396); // Size function can't deal with declared variables...
    noStroke(); // Shapes without borders
    applyPixelSize();
    initDelay();
}

void draw() {
    for (int column = 0; column < columns; column++) {
        int x = column * pixelSize;
        ColumnComposition composition = computeColumnComposition(column);
        PixelColumn pc = new PixelColumn(x, composition);
        pc.displayRandomColour();
    }

    if (saveAllImages) {
        saveImage();
    } 

    delay(delayMS);
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
}

void applyPixelSize() {
    rows = canvasHeight / pixelSize;
    columns = canvasWidth / pixelSize;
    setTransientArea();
}

void setTransientArea() {
    int cycles = (colors.length - 1);
    int minTransientColumns = cycles * rows + 1;
    int transientColumns = columns - leftColumnOffset - rightColumnOffset;
    int overCycle = transientColumns % minTransientColumns;

    if (autoFitWidth && overCycle != 0) {
        int missingColumns = minTransientColumns - overCycle;
        canvasWidth += missingColumns * pixelSize;
        applyPixelSize();
        return;
    }

    step = transientColumns / float(minTransientColumns);
    colorCycleLength = autoFitWidth ? rows * int(step) : transientColumns / cycles;
    windowResize(canvasWidth, canvasHeight);
}

ColumnComposition computeColumnComposition(int columnIndex) {
    if (columnIndex < leftColumnOffset) {
        return new ColumnComposition(colors[0], colors[1], 0); // Inside left offset
    }
    if (columnIndex >= columns - rightColumnOffset) {
        return new ColumnComposition(colors[colors.length - 2], colors[colors.length - 1], rows); // Inside right offset
    }

    int transientColumnIndex = columnIndex - leftColumnOffset;
    int cycleColumnIndex = transientColumnIndex % colorCycleLength;
    int rightColoredPixels = floor(cycleColumnIndex / step);

    int leftColorIndex = transientColumnIndex / colorCycleLength;
    int rightColorIndex = (leftColorIndex + 1) % (colors.length);

    return new ColumnComposition(colors[leftColorIndex], colors[rightColorIndex], rightColoredPixels);
}

/**
    Fill a Set with k distinct random integers in the range [0, n[
    by generating random integers until Set size threshold is reached
    For performance concerns, pointless to use with k greater than half of n
*/
HashSet<Integer> randomPick(int k, int n) {
    HashSet<Integer> picks = new HashSet<Integer>();
    int count = 0;

    while (count < k) {
        int r = int(random(0, n));
        if (!picks.contains(r)) {
            picks.add(r);
            count++;
        }
    }

    return picks;
}

class ColumnComposition {
    color left, right;
    int rightColoredPixels;

    ColumnComposition(color left, color right, int rightColoredPixels) {
        this.left = left;
        this.right = right;
        this.rightColoredPixels = rightColoredPixels;
    }

    color getLeftColor() {
        return left;
    }

    color getRightColor() {
        return right;
    }

    int getRightColoredPixels() {
        return rightColoredPixels;
    }
}

class PixelColumn {
    int x;
    int k; // Selection to perform, max half of number of right color pixels
    color selectedColor;
    color unselectedColor;

    PixelColumn(int x, ColumnComposition composition) {
        this.x = x;
        this.k = min(composition.getRightColoredPixels(), rows - composition.getRightColoredPixels());
        if (k == composition.getRightColoredPixels()) {
            this.selectedColor = composition.getRightColor();
            this.unselectedColor = composition.getLeftColor();
        } else {
            this.selectedColor = composition.getLeftColor();
            this.unselectedColor = composition.getRightColor();
        }
    }

    void displayRandomColour() {
        HashSet<Integer> selected = randomPick(this.k, rows);
        for (int row = 0; row < rows; row++) {
            if (selected.contains(row)) {
                fill(this.selectedColor);
            } else {
                fill(this.unselectedColor);
            }
            square(this.x, row * pixelSize, pixelSize);
        }
    }
}