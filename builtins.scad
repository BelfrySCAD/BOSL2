//////////////////////////////////////////////////////////////////////
/// Undocumented LibFile: builtins.scad
///   This file has indirect calls to OpenSCAD's builtin functions and modules.
/// Includes:
///   use <BOSL2/builtins.scad>
//////////////////////////////////////////////////////////////////////

/// Section: Builtin Functions

/// Section: Builtin Modules
module _square(size,center=false) square(size,center=center);

module _circle(r,d) circle(r=r,d=d);

module _text(text,size,font,halign,valign,spacing,direction,language,script)
    text(text, size=size, font=font,
        halign=halign, valign=valign,
        spacing=spacing, direction=direction,
        language=language, script=script
    );

module _color(color) if (color==undef || color=="default") children(); else color(color) children();

module _cube(size,center) cube(size,center=center);

module _cylinder(h,r1,r2,center,r,d,d1,d2) cylinder(h,r=r,d=d,r1=r1,r2=r2,d1=d1,d2=d2,center=center);

module _sphere(r,d) sphere(r=r,d=d);

module _multmatrix(m) multmatrix(m) children();
module _translate(v) translate(v) children();
module _rotate(a,v) rotate(a=a,v=v) children();
module _scale(v) scale(v) children();

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
