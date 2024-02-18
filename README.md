# BOSL2
![BOSL2 Logo](images/BOSL2logo.png)

**The Belfry OpenScad Library, v2**

A library for OpenSCAD, filled with useful tools, shapes, masks, math and manipulators, designed to make OpenSCAD easier to use.

Requires OpenSCAD 2021.01 or later.

- **NOTE:** BOSL2 IS BETA CODE.  THE CODE IS STILL BEING REORGANIZED.
- **NOTE2:** CODE WRITTEN FOR BOSLv1 PROBABLY WON'T WORK WITH BOSL2!

[![Join the chat at https://gitter.im/revarbat/BOSL2](https://badges.gitter.im/revarbat/BOSL2.svg)](https://gitter.im/revarbat/BOSL2?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


## Documentation

You can find the full BOSL2 library documentation at: https://github.com/BelfrySCAD/BOSL2/wiki


## Installation

1. Download the .zip or .tar.gz release file for this library.  Currently you should be able to find this at https://github.com/BelfrySCAD/BOSL2/archive/refs/heads/master.zip
2. Unpack it. Make sure that you unpack the whole file structure. Some zipfile unpackers call this option "Use folder names". It should create either a `BOSL-v2.0` or `BOSL2-master` directory with the library files within it.  You should see "examples", "scripts", "tests", and other subdirectories.
3. Rename the unpacked main directory to `BOSL2`.
4. Move the `BOSL2` directory into the apropriate OpenSCAD library directory.  The library directory may be on the list below, but for SNAP or other prepackaged installations, it is probably somewhere else.  To find it, run OpenSCAD and select Help&rarr;Library Info, and look for the entry that says "User Library Path".  This is your default library directory.  You may choose to change it to something more convenient by setting the environment variable OPENSCADPATH.  Using this variable also means that all versions of OpenSCAD you install will look for libraries in the same location.  
    - Windows: `My Documents\OpenSCAD\libraries\`
    - Linux: `$HOME/.local/share/OpenSCAD/libraries/`
    - Mac OS X: `$HOME/Documents/OpenSCAD/libraries/`
5. Restart OpenSCAD.


## Examples
A lot of the features of this library are to allow shorter, easier-to-read, intent-based coding.  For example:

[`BOSL2/transforms.scad`](https://github.com/BelfrySCAD/BOSL2/wiki/transforms.scad) Examples | Raw OpenSCAD Equivalent
------------------------------- | -------------------------------
`up(5)`                         | `translate([0,0,5])`
`xrot(30,cp=[0,10,20])`         | `translate([0,10,20]) rotate([30,0,0]) translate([0,-10,-20])`
`xcopies(20,n=3)`               | `for (dx=[-20,0,20]) translate([dx,0,0])`
`zrot_copies(n=6,r=20)`         | `for (zr=[0:5]) rotate([0,0,zr*60]) translate([20,0,0])`
`skew(sxz=0.5,syz=0.333)`       | `multmatrix([[1,0,0.5,0],[0,1,0.333,0],[0,0,1,0],[0,0,0,1]])`

[`BOSL2/shapes.scad`](https://github.com/BelfrySCAD/BOSL2/wiki/shapes.scad) Examples | Raw OpenSCAD Equivalent
---------------------------------- | -------------------------------
`cube([10,20,30], anchor=BOTTOM);` | `translate([0,0,15]) cube([10,20,30], center=true);`
`cuboid([20,20,30], rounding=5);`  | `minkowski() {cube([10,10,20], center=true); sphere(r=5, $fn=32);}`
`prismoid([30,40],[20,30],h=10);`  | `hull() {translate([0,0,0.005]) cube([30,40,0.01], center=true); translate([0,0,9.995]) cube([20,30,0.01],center=true);}`
`xcyl(l=20,d=4);`                  | `rotate([0,90,0]) cylinder(h=20, d=4, center=true);`
`cyl(l=100, d=40, rounding=5);`    | `minkowski() {cylinder(h=90, d=30, center=true); sphere(r=5);}`
`tube(od=40,wall=5,h=30);`         | `difference() {cylinder(d=40,h=30,center=true); cylinder(d=30,h=31,center=true);}`
`torus(d_maj=100, d_min=30);`      | `rotate_extrude() translate([50,0,0]) circle(d=30);`


