//////////////////////////////////////////////////////////////////////
/// Undocumented LibFile: builtins.scad
//   This file has indirect calls to OpenSCAD's builtin functions and modules.
/// Includes:
//   use <BOSL2/builtins.scad>
//////////////////////////////////////////////////////////////////////

/// Section: Builtin Functions

/// Section: Builtin Modules
module _square(size,center=false) square(size,center=center);

module _circle(r,d) circle(r=r,d=d);

module _text(t,size,font,halign,valign,spacing,direction,language,script)
    text(t, size=size, font=font,
        halign=halign, valign=valign,
        spacing=spacing, direction=direction,
        language=language, script=script
    );

module _cube(size,center) cube(size,center=center);

module _cylinder(h,r1,r2,center,r,d,d1,d2) cylinder(h,r=r,d=d,r1=r1,r2=r2,d1=d1,d2=d2,center=center);

module _sphere(r,center,d) sphere(r=r,d=d,center=center);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
