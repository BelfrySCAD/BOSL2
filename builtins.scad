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

module _text(text,size,font,halign,valign,spacing,direction,language,script,em)
    if (version_num() >= 20260314)
        text(text, size=size, font=font,
            halign=halign, valign=valign,
            spacing=spacing, direction=direction,
            language=language, script=script, em=em
        );
    else
        text(text, size=size, font=font,
            halign=halign, valign=valign,
            spacing=spacing, direction=direction,
            language=language, script=script
        );

module _color(color,a) if (color==undef || color=="default") children(); else color(color,a) children();

module _cube(size,center) cube(size,center=center);

module _cylinder(h,r1,r2,center,r,d,d1,d2) cylinder(h,r=r,d=d,r1=r1,r2=r2,d1=d1,d2=d2,center=center);

module _sphere(r,d) sphere(r=r,d=d);

module _multmatrix(m) multmatrix(m) children();
module _translate(v) translate(v) children();
module _rotate(a,v) rotate(a=a,v=v) children();
module _scale(v) scale(v) children();
module _mirror(v) mirror(v) children();                        

module _linear_extrude(height, v, scale, center, twist, slices, segments, convexity, h) {
    if (is_undef(h)) {
        if (is_undef(v) && is_undef(segments))
            linear_extrude(height=height, center=center, convexity=convexity, twist=twist, slices=slices, scale=scale) children();
        else if (is_undef(v))
            linear_extrude(height=height, center=center, convexity=convexity, twist=twist, slices=slices, segments=segments, scale=scale) children();
        else if (is_undef(segments))
            linear_extrude(height=height, v=v, center=center, convexity=convexity, twist=twist, slices=slices, scale=scale) children();
        else
            linear_extrude(height=height, v=v, center=center, convexity=convexity, twist=twist, slices=slices, segments=segments, scale=scale) children();
    } else {
        if (is_undef(v) && is_undef(segments))
            linear_extrude(height=height, h=h, center=center, convexity=convexity, twist=twist, slices=slices, scale=scale) children();
        else if (is_undef(v))
            linear_extrude(height=height, h=h, center=center, convexity=convexity, twist=twist, slices=slices, segments=segments, scale=scale) children();
        else if (is_undef(segments))
            linear_extrude(height=height, h=h, v=v, center=center, convexity=convexity, twist=twist, slices=slices, scale=scale) children();
        else
            linear_extrude(height=height, h=h, v=v, center=center, convexity=convexity, twist=twist, slices=slices, segments=segments, scale=scale) children();
    }
}       

module _hull() hull() children();

module _rotate_extrude(angle, start, convexity, a) {
    if (is_undef(start) && is_undef(a))
        rotate_extrude(angle=angle, convexity=convexity) children();
    else if (is_undef(a))
        rotate_extrude(angle=angle, convexity=convexity,
                       start=start) children();
    else if (is_undef(start))
        rotate_extrude(angle=angle, convexity=convexity,
                       a=a) children();
    else
        rotate_extrude(angle=angle, convexity=convexity,
                       start=start, a=a) children();
}

module _polygon(points, paths, convexity)
  if ($children>0) polygon(points=points, paths=paths, convexity=convexity) children();
  else polygon(points=points, paths=paths, convexity=convexity);

module _polyhedron(points, faces, convexity)
  if ($children>0) polyhedron(points=points, faces=faces, convexity=convexity) children();
  else polyhedron(points=points, faces=faces, convexity=convexity);
  
module _surface(file,center,convexity,invert)
  if ($children>0) surface(file=file,center=center,convexity=convexity,invert=invert) children();
  else surface(file=file,center=center,convexity=convexity,invert=invert);
  
module _projection(cut,convexity)
  if ($children>0) projection(cut=cut,convexity=convexity) children();
  else projection(cut=cut,convexity=convexity);                                
                                  
// import?                                  
// resize?
                                  
// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
