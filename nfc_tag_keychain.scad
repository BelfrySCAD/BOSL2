/*
 * NFC Tag Keychain with Custom Logo - Parametric Design
 *
 * This OpenSCAD file creates a custom keychain designed to hold an NFC tag
 * with support for adding custom logos/images on one or both sides.
 *
 * AVAILABLE VERSIONS:
 * - Set keychain_shape = "oval" for classic teardrop design
 * - Set keychain_shape = "square" for rectangular design with rounded corners
 * - Set nfc_tag_hole = true/false to include/exclude NFC tag recess
 *
 * To use your own photo/logo:
 * 1. Save your image file in the same directory as this .scad file
 * 2. Update the svgFile1, pngFile1, or stlFile1 parameter below with your filename
 * 3. Adjust logo1Width and logo1Height to resize as needed
 * 4. Set logo1Type to match your file type (svg, png, or stl)
 *
 * For best results with photos:
 * - Convert photos to SVG or PNG format
 * - Resize images to approximately 200-500px for faster rendering
 * - High contrast images work best for 3D printing
 */

/* [Basic Parameters] */
// Keychain base color
tag_color = "#FFFFFF";  // color

// Keychain shape style
keychain_shape = "oval"; // [oval, square]

// Create a recessed hole for embedding NFC tag
nfc_tag_hole = true;

/* [Logo 1 Options - Front Side] */
// Logo file type: svg (recommended), png, or stl
logo1Type = "svg"; // [svg,png,stl]

// SVG logo file (place your .svg file in the same directory)
// Example: "my_logo.svg" or "photo.svg"
svgFile1 = "default.svg";

// PNG logo file (if using PNG instead of SVG)
// Example: "my_photo.png"
pngFile1 = "default.png";

// STL logo file (if using 3D model as logo)
stlFile1 = "default.stl";

// Logo raised height above surface (in mm)
logo1Thickness = 0.5;

// Logo color (for multi-color printing)
logo1Color = "#00FF00";  // color

// Logo width (warps/scales the image)
logo1Width = 22;

// Logo height (warps/scales the image)
logo1Height = 22;

// Horizontal offset of logo from center
logo1OffsetX = 0;

// Vertical offset of logo from center
logo1OffsetY = 0;

/* [Logo 2 Options - Back Side] */
// Enable second logo on back side
logo2Enabled = false;

// Logo file type for back side
logo2Type = "svg"; // [svg,png,stl]

svgFile2 = "default.svg";
pngFile2 = "default.png";
stlFile2 = "default.stl";

// Logo raised height above surface (in mm)
logo2Thickness = 0.5;

// Logo color for back side
logo2Color = "#00FF00";  // color

// Logo dimensions for back side
logo2Width = 22;
logo2Height = 22;
logo2OffsetX = 0;
logo2OffsetY = 0;

/* [Advanced Keychain Dimensions] */
// Angle for the tapered sides (in degrees)
angle = 30;

// Radius for the beveled (rounded) edges
bevel_radius = 1.5;

// Distance from center to hanging hole
distance_hole = 18.7;

// Diameter of the bottom (main) circle
diameter1 = 30;

// Diameter of the top (hanging) circle
diameter2 = 15;

// Distance between the centers of the two circles
distance_centers = 15;

// Base thickness of the keychain (before beveling)
keychain_thickness = 1;

// Diameter of the pill-shaped hanging hole
hole_diameter = 7;

// Length of the pill-shaped hanging hole
hole_length = 3;

/* [NFC Tag Specifications] */
// NFC tag diameter (NTAG216 is typically 25mm)
nfc_tag_diameter = 26;

// NFC tag recess depth
nfc_tag_height = 1.25;

/* [Square Shape Dimensions] */
// Width of square keychain body (only used if keychain_shape = "square")
square_width = 35;

// Height of square keychain body (only used if keychain_shape = "square")
square_height = 50;

// Corner radius for rounded corners (only used if keychain_shape = "square")
square_corner_radius = 3;

// Distance from bottom to center of hanging hole (only used if keychain_shape = "square")
square_hole_distance = 43;


// ============================================================
// MODULES - Main Construction Code
// ============================================================

/*
 * Main keychain body with oval shape and rounded edges
 */
module keychain_oval_with_ends() {
    radius1 = diameter1 / 2;
    radius2 = diameter2 / 2;

    // Apply minkowski to create smooth, beveled edges
    minkowski() {
        difference() {
            // Main body union
            union() {
                // Bottom circular end (main body for NFC tag)
                translate([0, 0, 0])
                    cylinder(h = keychain_thickness, r = radius1, $fn=200);

                // Top circular end (hanging hole area)
                translate([0, distance_centers, 0])
                    cylinder(h = keychain_thickness, r = radius2, $fn=100);

                // Connecting walls between the two circles
                linear_extrude(height = keychain_thickness)
                    polygon(points=[
                        [radius1 * cos(angle), radius1 * sin(angle)],
                        [radius2 * cos(angle), distance_centers + radius2 * sin(angle)],
                        [-radius2 * cos(angle), distance_centers + radius2 * sin(angle)],
                        [-radius1 * cos(angle), radius1 * sin(angle)]
                    ]);
            }

            // Cut out the hanging hole
            pill_hole();
        }

        // Sphere used for rounding/beveling all edges
        sphere(r = bevel_radius, $fn=50);
    }
}

/*
 * Main keychain body with square/rectangular shape and rounded corners
 */
module keychain_square() {
    // Apply minkowski to create smooth, beveled edges
    minkowski() {
        difference() {
            // Main square body with rounded corners
            translate([-square_width/2, 0, 0])
                hull() {
                    // Four corners with rounded edges
                    translate([square_corner_radius, square_corner_radius, 0])
                        cylinder(h = keychain_thickness, r = square_corner_radius, $fn=50);

                    translate([square_width - square_corner_radius, square_corner_radius, 0])
                        cylinder(h = keychain_thickness, r = square_corner_radius, $fn=50);

                    translate([square_corner_radius, square_height - square_corner_radius, 0])
                        cylinder(h = keychain_thickness, r = square_corner_radius, $fn=50);

                    translate([square_width - square_corner_radius, square_height - square_corner_radius, 0])
                        cylinder(h = keychain_thickness, r = square_corner_radius, $fn=50);
                }

            // Cut out the hanging hole at top
            pill_hole_square();
        }

        // Sphere used for rounding/beveling all edges
        sphere(r = bevel_radius, $fn=50);
    }
}

/*
 * Creates a pill-shaped (obround) hole for hanging the keychain (oval version)
 */
module pill_hole() {
    translate([0, distance_hole, -0.1]) {
        union() {
            // Left rounded end
            translate([-hole_length / 2, 0, 0])
                cylinder(h = keychain_thickness + 3, r = hole_diameter / 2, $fn=50);

            // Right rounded end
            translate([hole_length / 2, 0, 0])
                cylinder(h = keychain_thickness + 3, r = hole_diameter / 2, $fn=50);

            // Connecting rectangle
            translate([-hole_length / 2, -hole_diameter / 2, 0])
                cube([hole_length, hole_diameter, keychain_thickness + 3]);
        }
    }
}

/*
 * Creates a pill-shaped (obround) hole for hanging the keychain (square version)
 */
module pill_hole_square() {
    translate([0, square_hole_distance, -0.1]) {
        union() {
            // Left rounded end
            translate([-hole_length / 2, 0, 0])
                cylinder(h = keychain_thickness + 3, r = hole_diameter / 2, $fn=50);

            // Right rounded end
            translate([hole_length / 2, 0, 0])
                cylinder(h = keychain_thickness + 3, r = hole_diameter / 2, $fn=50);

            // Connecting rectangle
            translate([-hole_length / 2, -hole_diameter / 2, 0])
                cube([hole_length, hole_diameter, keychain_thickness + 3]);
        }
    }
}

/*
 * Generic logo module that handles SVG, PNG, or STL files
 */
module logo(logoType, logoOffsetX, logoOffsetY, logoWidth, logoHeight, logoThickness, svgFile, pngFile, stlFile) {
    if(logoType == "svg") {
        if (svgFile != "default.svg") {
            translate([logoOffsetX, logoOffsetY, 0])
                resize([logoWidth, logoHeight, logoThickness], auto=true)
                    linear_extrude(height = logoThickness, center = true)
                        import(file = svgFile, center = true);
        }
    } else if(logoType == "png") {
        if (pngFile != "default.png") {
            translate([logoOffsetX, logoOffsetY, 0])
                resize([logoWidth, logoHeight, logoThickness], auto=true)
                    surface(file = pngFile, center = true);
        }
    } else if(logoType == "stl") {
        if (stlFile != "default.stl") {
            translate([logoOffsetX, logoOffsetY, 0])
                resize([logoWidth, logoHeight, logoThickness], auto=true)
                    import(file = stlFile, center = true);
        }
    }
}

/*
 * Creates a recessed hole for embedding the NFC tag
 */
module nfc_hole() {
    if(nfc_tag_hole) {
        translate([0, 0, 0])
            cylinder(h = nfc_tag_height, r = nfc_tag_diameter / 2, $fn=100);
    }
}

// ============================================================
// RENDERING - Final Assembly
// ============================================================

// Main keychain body with NFC tag recess
color(tag_color)
    difference() {
        // Render selected shape
        if (keychain_shape == "oval") {
            keychain_oval_with_ends();
        } else if (keychain_shape == "square") {
            keychain_square();
        }
        nfc_hole();
    }

// Front side logo (Logo 1)
logo1ZOffset = logo1Type == "svg"
    ? keychain_thickness + bevel_radius - logo1Thickness/2
    : keychain_thickness + bevel_radius - logo1Thickness + 0.01;

color(logo1Color)
    translate([0, 0, logo1ZOffset])
        logo(logo1Type, logo1OffsetX, logo1OffsetY, logo1Width, logo1Height,
             logo1Thickness, svgFile1, pngFile1, stlFile1);

// Back side logo (Logo 2) - Optional
if(logo2Enabled) {
    logo2ZOffset = logo2Type == "svg"
        ? -bevel_radius + logo2Thickness/2
        : -bevel_radius - 0.01 + logo2Thickness;

    color(logo2Color)
        translate([0, 0, logo2ZOffset])
            rotate([0, 180, 0])
                logo(logo2Type, logo2OffsetX, logo2OffsetY, logo2Width, logo2Height,
                     logo2Thickness, svgFile2, pngFile2, stlFile2);
}

// ============================================================
// USAGE NOTES
// ============================================================
/*
 * QUICK START GUIDE:
 *
 * SELECT YOUR VERSION:
 *    Version 1 - Oval with NFC recess:
 *       keychain_shape = "oval"
 *       nfc_tag_hole = true
 *
 *    Version 2 - Oval without NFC recess:
 *       keychain_shape = "oval"
 *       nfc_tag_hole = false
 *
 *    Version 3 - Square with NFC recess:
 *       keychain_shape = "square"
 *       nfc_tag_hole = true
 *
 *    Version 4 - Square without NFC recess:
 *       keychain_shape = "square"
 *       nfc_tag_hole = false
 *
 * 1. PREPARE YOUR IMAGE:
 *    - For photos: Convert to SVG using online tools like:
 *      * vectorizer.io
 *      * convertio.co/jpg-svg/
 *    - Or use PNG directly (may need post-processing)
 *
 * 2. ADD YOUR IMAGE:
 *    - Save image file in the same folder as this .scad file
 *    - Set logo1Type to match your file type
 *    - Update svgFile1 (or pngFile1) with your filename
 *
 * 3. ADJUST SIZE:
 *    - Modify logo1Width and logo1Height to fit
 *    - Oval: Default 22mm x 22mm fits well on 30mm diameter
 *    - Square: Default 22mm x 22mm fits well on 35mm width
 *
 * 4. PRINT SETTINGS:
 *    - Layer height: 0.1-0.2mm recommended
 *    - Enable supports if needed for hanging hole
 *    - Consider pause at layer for multi-color printing
 *    - Insert NFC tag into recess before final layers (if desired)
 *
 * NFC TAG COMPATIBILITY:
 *    - NTAG213/215/216 tags typically 25mm diameter, 0.5mm thick
 *    - Adjust nfc_tag_diameter and nfc_tag_height if needed
 */
