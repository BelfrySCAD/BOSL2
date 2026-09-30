//////////////////////////////////////////////////////////////////////
// LibFile: color.scad
//   In OpenSCAD the `color()` module sets the color immutably for its geometry subtree:
//   nested `color()` calls cannot override it. In BOSL2, {{recolor()}} provides mutable
//   coloring for attachable objects, so that descendants can change their colors.
//   Use `mutable=false` when an immutable color is needed, including for geometry
//   that is not attachable. The {{color_this()}} module changes color at just one
//   level, with descendants reverting to the previous color and alpha.
//   .
//   The {{rainbow()}} module assigns different colors to items in a list, for example
//   for debugging. This file also provides HSL, HSV, and D65 CIE LCh conversions.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: HSL, HSV, and LCh conversion; mutable colors and object modifiers.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

_BOSL2_COLOR = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: color.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;


use <builtins.scad>

/// Validate the color/alpha pair and canonicalize the default-color sentinel.
/// There is no explicit RGB value to which alpha can be applied for the default color.
function _color_pair(c, a) =
    assert(is_undef(c) || is_string(c) || is_vector(c,3) || is_vector(c,4),
           "\nc must be a color name, an RGB or RGBA vector, or undef.")
    assert(is_undef(a) || (is_finite(a) && a>=0 && a<=1),
           "\na must be a finite number between 0 and 1.")
    let(c=default(c,"default"))
    [c, c=="default" ? undef : a];

// Section: Coloring Objects

// Module: recolor()
// Synopsis: Sets the color for attachable children and their descendants.
// SynTags: Trans
// Topics: Attachments, Colors
// See Also: color_this(), hsl(), hsv(), lch()
// Usage:
//   recolor([c], [a], [mutable=]) CHILDREN;
// Description:
//   This is the BOSL2 replacement for `color()`.  Unlike `color()` it enables children
//   to change their color even when a parent has set a color.  
//   With `mutable=true` (the default) it sets the color for attachable children and their descendants
//   until another {{recolor()}} or {{color_this()}} changes it. This sets the special
//   `$color` variable, which attachable objects use to apply the color. 
//   .
//   With `mutable=false` it behaves like the native module and applies an immutable color to all of the children and descendants.  
//   No operation performed by a child can override that color.  
//   .
//   A separate `a` specifies alpha and overrides alpha given in an RGBA vector. 
//   Each call replaces the alpha rather than multiplying alpha values.
//   Omitting `c`, or giving `c="default"` sets the color to the default for your color scheme.
//   .
//   The color can be an RGB vector with values between 0 and 1, or an RGBA vector that includes an alpha component.
//   You can also give the name (as a string) for a standard
//   web [color name](https://htmlpreview.github.io/?https://github.com/BelfrySCAD/BOSL2/blob/master/scripts/openscad_colors.html), and
//   in development snapshots after July 2026 you
//   can use [xkcd colors](https://xkcd.com/color/rgb/) with the format `"xkcd:<name>"`.  
// Arguments:
//   c = Color name, RGB vector, or RGBA vector. Default: the default color in your color scheme.
//   a = Alpha from 0 (transparent) to 1 (opaque), overriding embedded alpha when supplied. Default: preserve embedded alpha, otherwise opaque. Ignored for the default color.
//   ---
//   mutable = If true, use mutable attachable coloring. If false, apply immutable coloring to the complete child geometry. Default: true
// Side Effects:
//   Sets `$color` to the color/alpha pair used by attachable objects.
// Example:
//   cuboid([10,10,5])
//     recolor("green")attach(TOP,BOT) cuboid([9,9,4.5])
//       attach(TOP,BOT) cuboid([8,8,4])
//         recolor("purple") attach(TOP,BOT) cuboid([7,7,3.5])
//           attach(TOP,BOT) cuboid([6,6,3])
//             recolor("cyan")attach(TOP,BOT) cuboid([5,5,2.5])
//               attach(TOP,BOT) cuboid([4,4,2]);
module recolor(c="default", a=undef, mutable=true)
{
    req_children($children);
    assert(is_bool(mutable), "\nmutable must be a boolean.");
    $color = _color_pair(c,a);
    if (mutable) children();
    else _color($color[0],$color[1]) children();
}


// Module: color_this()
// Synopsis: Sets the color for attachable children at the current level only.
// SynTags: Trans
// Topics: Attachments, Colors
// See Also: recolor(), hsl(), hsv(), lch()
// Usage:
//   color_this([c], [a]) CHILDREN;
// Description:
//   Sets the color for attachable children at one level, reverting to the previous
//   color and alpha for their descendants. This uses `$color` and
//   `$save_color`, which attachable objects interpret. An enclosing native `color()`
//   or immutable {{recolor()}} cannot be overridden.
//   .
//   As with {{recolor()}}, a separate `a` overrides alpha embedded in `c`.  
//   Omitting the color or giving `c="default"` selects the default color for your OpenSCAD color scheme.  
// Arguments:
//   c = Color name, RGB vector, or RGBA vector. Default: the default color in your color scheme.
//   a = Alpha from 0 (transparent) to 1 (opaque), overriding any alpha specified in the `c` vector
// Side Effects:
//   Sets `$color` and saves the previous color/alpha pair in `$save_color`.
// Example:
//   cuboid([10,10,5])
//     color_this("green")attach(TOP,BOT) cuboid([9,9,4.5])
//       attach(TOP,BOT) cuboid([8,8,4])
//         color_this("purple") attach(TOP,BOT) cuboid([7,7,3.5])
//           attach(TOP,BOT) cuboid([6,6,3])
//             color_this("cyan")attach(TOP,BOT) cuboid([5,5,2.5])
//               attach(TOP,BOT) cuboid([4,4,2]);
module color_this(c="default", a=undef)
{
    req_children($children);
    $save_color=default($color,["default",undef]);
    $color=_color_pair(c,a);
    children();
}


// Module: rainbow()
// Synopsis: Iterates through a list, displaying children in different colors.
// SynTags: Trans
// Topics: Colors, List Handling, Debugging
// See Also: hsl(), hsv(), recolor(), color_this()
// Usage:
//   rainbow(list, [stride], [maxhues], [shuffle=], [seed=], [mutable=]) CHILDREN;
// Description:
//   Iterates over a list or string, invoking the children once per item. Use `$item`
//   for the current item and `$idx` for its index. An empty input generates no children.
//   Assigns color to each child using {{recolor()}} with `mutable=true` by default.
//   .
//   Colors use uniformly spaced HSV hues at full saturation and value. The `maxhues` parameter
//   specifies the number hues to use and defaults to the number of items in `list`;
//   colors repeat when there are more items than hues.
//   The integer `stride` controls the step through those hues. A stride of 1 selects
//   adjacent hues; a negative stride reverses traversal, and 0 repeats one hue.
//   The default stride is a number near `maxhues` divided by the golden ratio and also
//   coprime with `maxhues`.  This is meant to separate nearby colors while visiting
//   every hue.  If you give a stride that has common factors with `maxhue` then
//   some hues will be skipped.
//   .  
//   Set `shuffle=true` to shuffle the resulting color assignments.
// Arguments:
//   list = List of items, or a string to iterate character by character.
//   stride = Integer step through the available hues. Default: see description.
//   maxhues = Positive integer number of available hues. Default: the input length, or 1 for empty input.
//   ---
//   shuffle = If true, shuffle the color assignments. Default: false
//   seed = Optional finite numeric random seed passed to {{shuffle()}}.
//   mutable = If true, use mutable attachable coloring. If false, color complete child geometry immutably. Default: true
// Side Effects:
//   Sets the color of each item using recolor().
//   Sets `$idx` to the index of the current item.
//   Sets `$item` to the current item.
// Example(2D,NoAxes):
//   rainbow(["Foo","Bar","Baz","Big","Bam"])
//     fwd($idx*10)
//       text(text=$item,size=8,halign="center",
//            valign="center");
// Example(2D,NoAxes,Med):
//   rgn = [circle(d=45,$fn=3),
//          circle(d=75,$fn=4),
//          circle(d=50)];
//   rainbow(rgn) stroke($item, closed=true);
// Example(2D,NoAxes,Med):
//   rainbow(lerpn(0,360,30,endpoint=false))
//     zrot($item)
//       stroke([[10,0],[50,0]],width=3);
// Example(2D,NoAxes,Med): Setting maxhues to a small value
//   rainbow(lerpn(0,360,30,endpoint=false),maxhues=3)
//     zrot($item)
//       stroke([[10,0],[50,0]],width=3);
// Example(2D,NoAxes,Med): Changing stride to 1
//   rainbow(lerpn(0,360,30,endpoint=false),stride=1)
//     zrot($item)
//       stroke([[7,0],[50,0]],width=3);

module rainbow(list, stride, maxhues, shuffle=false, seed, mutable=true)
{
    req_children($children);
    assert(is_bool(shuffle), "\nshuffle must be a boolean.");
    assert(is_bool(mutable), "\nmutable must be a boolean.");
    assert(is_undef(seed) || is_finite(seed), "\nseed must be a finite number.");
    listlen = assert(is_list(list) || is_string(list), "\nlist must be a list or string.") len(list);
    maxhues = assert(is_undef(maxhues) || (is_int(maxhues) && maxhues>0),
                     "\nmaxhues must be a positive integer.")
              default(maxhues,max(1,listlen));
    stride = assert(is_undef(stride) || is_int(stride), "\nstride must be an integer.")
             default(stride,_golden_stride(maxhues));
    huestep = 360 / maxhues;
    huelist = [for (i=[0:1:listlen-1]) posmod(i*posmod(stride,maxhues),maxhues)*huestep];
    hues = listlen==0 ? [] : shuffle ? shuffle(huelist, seed=seed) : huelist;
    for($idx=idx(list)) {
        $item = list[$idx];
        hsv(h=hues[$idx],mutable=mutable) children();
    }
}


function _golden_stride(n) =
    n<=2 ? 1 :
    let(
        target = round(n*(sqrt(5)-1)/2)   // n/phi
    )
    _nearest_coprime(n, target, 0);


function _nearest_coprime(n, target, d) =
    let(lo=target-d, hi=target+d)
    (lo>=1 && gcd(lo,n)==1) ? lo
  : (hi<=n-1 && gcd(hi,n)==1) ? hi
  : d>n ? 1
  : _nearest_coprime(n, target, d+1);



// Module: color_overlaps()
// Synopsis: Shows ghostly children, with overlaps highlighted in color.
// SynTags: Trans
// Topics: Debugging
// See Also: rainbow(), debug_vnf()
// Usage:
//   color_overlaps([color]) CHILDREN;
// Description:
//   Displays the given children in ghostly transparent gray, while the places where
//   they overlap are highlighted with the given color. Uses immutable coloring.
// Arguments:
//   color = The color to highlight overlaps with.  Default: "red"
// Example(2D): 2D Overlaps
//   color_overlaps() {
//       circle(d=50);
//       left(20) circle(d=50);
//       right(20) circle(d=50);
//   }
// Example(3D): 3D Overlaps
//   color_overlaps() {
//       cuboid(50);
//       left(30) sphere(d=50);
//       right(30) sphere(d=50);
//       xcyl(d=10,l=120);
//   }
module color_overlaps(color="red") {
    pairs = [for (i=[0:1:$children-1], j=[i+1:1:$children-1]) [i,j]];
    for (p = pairs) {
        color(color) {
            intersection() {
                children(p.x);
                children(p.y);
            }
        }
    }
    %children();
}

// Section: Setting Object Modifiers




// Module: highlight()
// Synopsis: Sets # modifier for attachable children and their descendants.
// SynTags: Trans
// Topics: Attachments, Modifiers, Debugging
// See Also: highlight_this(), ghost(), ghost_this(), recolor(), color_this()
// Usage:
//   highlight([highlight]) CHILDREN;
// Description:
//   Sets the `#` modifier for the attachable children and their descendents until another {{highlight()}} or {{highlight_this()}}.
//   By default, turns `#` on, which makes the children transparent pink and displays them even if they are subtracted from the model.
//   Give the `false` parameter to disable the modifier and restore children to normal.  
//   Do not mix this with user supplied `#` modifiers anywhere in the geometry tree.  
// Arguments:
//   highlight = If true set the descendants to use `#`; if false, disable `#` for descendants.  Default: true
// Example(3D):
//   highlight() cuboid(10)
//     highlight(false) attach(RIGHT,BOT)cuboid(5);
function highlight(highlight) = no_function("highlight");
module highlight(highlight=true)
{
   $highlight=highlight;
   children();
}


// Module: highlight_this()
// Synopsis: Apply # modifier to children at a single level.
// SynTags: Trans
// Topics: Attachments, Modifiers, Debugging
// See Also: highlight(), ghost(), ghost_this(), recolor(), color_this()
// Usage:
//   highlight_this() CHILDREN;
// Description:
//   Applies the `#` modifier to the children at a single level, reverting to the previous highlight state for further descendants.  
//   This works only with attachables and you cannot give the `#` operator anywhere in the geometry tree.  
// Example(3D):
//   highlight_this()
//   cuboid(10)
//      attach(TOP,BOT)cuboid(5);
function highlight_this() = no_function("highlight_this");
module highlight_this()
{
   $highlight_this=true;
   children();
}




// Module: ghost()
// Synopsis: Sets % modifier for attachable children and their descendants.
// SynTags: Trans
// Topics: Attachments, Modifiers, Debugging
// See Also: ghost_this(), recolor(), color_this()
// Usage:
//   ghost([ghost]) CHILDREN;
// Description:
//   Sets the `%` modifier for the attachable children and their descendents until another {{ghost()}} or {{ghost_this()}}.
//   By default, turns `%` on, which makes the children gray and also removes them from interaction with the model.
//   Give the `false` parameter to disable the modifier and restore children to normal.  
//   Do not mix this with user supplied `%` modifiers anywhere in the geometry tree.  
// Arguments:
//   ghost = If true set the descendants to use `%`; if false, disable `%` for descendants.  Default: true
// Example(3D):
//   ghost() cuboid(10)
//     ghost(false) cuboid(5);
function ghost(ghost) = no_function("ghost");
module ghost(ghost=true)
{
   $ghost=ghost;
   children();
}


// Module: ghost_this()
// Synopsis: Apply % modifier to children at a single level.
// SynTags: Trans
// Topics: Attachments, Modifiers, Debugging
// See Also: ghost(), recolor(), color_this()
// Usage:
//   ghost_this() CHILDREN;
// Description:
//   Applies the `%` modifier to the children at a single level, reverting to the previous ghost state for further descendants.  
//   This works only with attachables and you cannot give the `%` operator anywhere in the geometry tree.  
// Example(3D):
//   ghost_this() cuboid(10)
//      cuboid(5);
function ghost_this() = no_function("ghost_this");
module ghost_this()
{
   $ghost_this=true;
   children();
}


// Section: Colorspace Conversion

// Function&Module: hsl()
// Synopsis: Converts HSL to RGB or colors children with an HSL color.
// SynTags: Trans
// See Also: hsv(), lch(), recolor(), color_this()
// Topics: Colors, Colorspace
// Usage: As a function
//   rgb = hsl(h, [s], [l], [a]);
// Usage: As a module
//   hsl(h, [s], [l], [a], [mutable=]) CHILDREN;
// Description:
// Description:
//   When called as a function, returns the `[R,G,B]` color for the given hue `h`, saturation `s`, and
//   lightness `l` from the [HSL colorspace](https://en.wikipedia.org/wiki/HSL_and_HSV).  If you supply the `a` value then you'll get a length 4
//   list `[R,G,B,A]`.  When called as a module, sets the color using {{recolor()}} with `mutable=true` by default.
// Arguments:
//   h = Hue angle in degrees, wrapped mod 360. 0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = Saturation from 0 (grayscale) to 1 (vivid colors). Default: 1
//   l = Lightness from 0 (black) to 1 (white); 0.5 gives bright colors. Default: 0.5
//   a = Alpha from 0 (transparent) to 1 (opaque). Default: 1 (opaque)
//   ---
//   mutable = Module only. Specifies whether color applies to children mutably or immutably.  Default: true
// Side Effects:
//   The module sets `$color` through recolor().
// Example:
//   hsl(h=120,s=1,l=0.5) sphere(d=60);
// Example:
//   rgb = hsl(h=270,s=0.75,l=0.6);
//   recolor(rgb) cuboid(60);
function hsl(h,s=1,l=0.5,a) =
    assert(is_finite(h), "\nh must be a finite hue angle.")
    assert(is_finite(s) && s>=0 && s<=1, "\ns must be a finite number between 0 and 1.")
    assert(is_finite(l) && l>=0 && l<=1, "\nl must be a finite number between 0 and 1.")
    assert(is_undef(a) || (is_finite(a) && a>=0 && a<=1), "\na must be a finite number between 0 and 1.")
    let(
        h=posmod(h,360)
    ) [
        for (n=[0,8,4])
          let(k=(n+h/30)%12)
          l - s*min(l,1-l)*max(min(k-3,9-k,1),-1),
        if (is_def(a)) a
    ];

module hsl(h,s=1,l=0.5,a=1, mutable=true)
{
  req_children($children);  
  recolor(hsl(h,s,l,a),mutable=mutable) children();
}


// Function&Module: hsv()
// Synopsis: Converts HSV to RGB or colors children with an HSV color.
// SynTags: Trans
// See Also: hsl(), lch(), recolor(), color_this()
// Topics: Colors, Colorspace
// Usage: As a function
//   rgb = hsv(h, [s], [v], [a]);
// Usage: As a module
//   hsv(h, [s], [v], [a], [mutable=]) CHILDREN;
// Description:
//   When called as a function, returns the `[R,G,B]` color for the given hue `h`, saturation `s`, and
//   value `v` from the [HSV colorspace](https://en.wikipedia.org/wiki/HSL_and_HSV).
//   If you supply the `a` value then you'll get a length 4 list
//   `[R,G,B,A]`.  When called as a module, sets the color using the color() module to the given hue
//   `h`, saturation `s`, and value `v` from the HSV colorspace.
//   When called as a module, sets the color using {{recolor()}} with `mutable=true` by default.
// Arguments:
//   h = Hue angle in degrees, wrapped mod 360. 0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = Saturation from 0 (grayscale) to 1 (vivid colors). Default: 1
//   v = Value from 0 (black) to 1 (full brightness). Default: 1
//   a = Alpha from 0 (transparent) to 1 (opaque). Default: 1 (opaque)
//   ---
//   mutable = Module only. Specifies whether color applies to children mutably or immutably.  Default: true
// Side Effects:
//   The module sets `$color` through {{recolor()}}.
// Example:
//   hsv(h=120,s=1,v=1) sphere(d=60);
// Example:
//   rgb = hsv(h=270,s=0.75,v=0.9);
//   recolor(rgb) cube(60, center=true);
function hsv(h,s=1,v=1,a) =
    assert(is_finite(h), "\nh must be a finite hue angle.")
    assert(is_finite(s) && s>=0 && s<=1, "\ns must be a finite number between 0 and 1.")
    assert(is_finite(v) && v>=0 && v<=1, "\nv must be a finite number between 0 and 1.")
    assert(is_undef(a) || (is_finite(a) && a>=0 && a<=1), "\na must be a finite number between 0 and 1.")
    let(
        h = posmod(h,360),
        c = v * s,
        hprime = h/60,
        x = c * (1- abs(hprime % 2 - 1)),
        rgbprime = hprime <=1 ? [c,x,0]
                 : hprime <=2 ? [x,c,0]
                 : hprime <=3 ? [0,c,x]
                 : hprime <=4 ? [0,x,c]
                 : hprime <=5 ? [x,0,c]
                 : hprime <=6 ? [c,0,x]
                 : [0,0,0],
        m=v-c
    )
    is_def(a) ? point4d(add_scalar(rgbprime,m),a)
              : add_scalar(rgbprime,m);

module hsv(h,s=1,v=1,a=1,mutable=true)
{
    req_children($children);
    recolor(hsv(h,s,v,a),mutable=mutable) children();
}    


/// sRGB <-> CIE XYZ <-> CIE Lab/LCh conversions.
/// D65 reference white, standard sRGB primaries and transfer function.

function _srgb_to_linear(c) =
    c <= 0.04045 ? c/12.92 : pow((c+0.055)/1.055, 2.4);

function _linear_to_srgb(c) =
    c <= 0.0031308 ? c*12.92 : 1.055*pow(c,1/2.4) - 0.055;

function _lab_f(t) =
    t > pow(6/29,3) ? pow(t,1/3) : t/(3*pow(6/29,2)) + 4/29;

function _lab_finv(t) =
    t > 6/29 ? pow(t,3) : 3*pow(6/29,2)*(t-4/29);

_LAB_XN = 0.95047;  _LAB_YN = 1.0;  _LAB_ZN = 1.08883;   // D65 white point

function _rgb_to_xyz(rgb) =
    let(
        r=_srgb_to_linear(rgb[0]), g=_srgb_to_linear(rgb[1]), b=_srgb_to_linear(rgb[2])
    ) [
        0.4124564*r + 0.3575761*g + 0.1804375*b,
        0.2126729*r + 0.7151522*g + 0.0721750*b,
        0.0193339*r + 0.1191920*g + 0.9503041*b
    ];

function _xyz_to_rgb(xyz) =
    let(
        r= 3.2404542*xyz[0] - 1.5371385*xyz[1] - 0.4985314*xyz[2],
        g=-0.9692660*xyz[0] + 1.8760108*xyz[1] + 0.0415560*xyz[2],
        b= 0.0556434*xyz[0] - 0.2040259*xyz[1] + 1.0572252*xyz[2]
    ) [_linear_to_srgb(r), _linear_to_srgb(g), _linear_to_srgb(b)];

function _xyz_to_lab(xyz) =
    let(fx=_lab_f(xyz[0]/_LAB_XN), fy=_lab_f(xyz[1]/_LAB_YN), fz=_lab_f(xyz[2]/_LAB_ZN))
    [116*fy-16, 500*(fx-fy), 200*(fy-fz)];

function _lab_to_xyz(lab) =
    let(fy=(lab[0]+16)/116, fx=fy+lab[1]/500, fz=fy-lab[2]/200)
    [_LAB_XN*_lab_finv(fx), _LAB_YN*_lab_finv(fy), _LAB_ZN*_lab_finv(fz)];

// Function&Module: lch()
// Synopsis: Converts D65 CIE LCh to sRGB or colors children with an LCh color.
// SynTags: Trans
// See Also: hsl(), hsv(), recolor(), color_this()
// Topics: Colors, Colorspace
// Usage: As a function
//   rgb = lch(l, c, h, [a], [clip=]);
// Usage: As a module
//   lch(l, c, h, [a], [clip=], [mutable=]) CHILDREN;
// Description:
//   As a function, converts D65-referenced CIE LCh coordinates to sRGB `[R,G,B]`.
//   If you give `a` it returns `[R,G,B,A]`. Lightness `l` uses the range 0-100,
//   corresponding to CIE Lab lightness 0-100. Chroma `c` uses absolute CIE Lab
//   units. Hue is an angle in the Lab a*-b* plane, not the HSL/HSV hue wheel.
//   .
//   As a rough guide to hue, the fully saturated sRGB primaries are approximately
//   | Color   | approx. h |
//   |---------|-----------|
//   | red     | 40°       |
//   | yellow  | 103°      |
//   | green   | 136°      |
//   | cyan    | 196°      |
//   | blue    | 306°      |
//   | magenta | 328°      |
//   .
//   Unlike HSL/HSV, these are not exact or fixed: which hue angle looks like a given
//   named color shifts with `l` and `c`.  Unlike the {{hsl()}} and {{hsv()}} functions,
//   this function follows the CIE Lab convention with values ranging from 0 to 100, not 0 to 1.
//   .
//   For a given lightness and hue only some chroma values result in colors
//   that can be represented in sRGB.  There is no simple way to identify which
//   chroma values are valid, and it is not even a simple range of continuous
//   values.  Your requested color is tested after conversion.  By default, if it
//   is out of gamut you will get an error showing its RGB components.  If you set
//   `clip=true` then the converted RGB values will be clipped into the valid range.
//   Clipping can change the requested lightness and hue.  
//   .
//   When called as a module, sets the color using {{recolor()}} with `mutable=true` by default.
// Arguments:
//   l = Lightness, CIE Lab L* from 0 (black) to 100 (white)
//   c = Chroma in CIE Lab units. 0 is gray. There is no fixed upper limit; representability is tested in sRGB.
//   h = Hue angle in degrees, wrapped modulo 360. 0 is the +a* axis, 90 is +b*, 180 is -a*, and 270 is -b*.
//   a = Optional alpha from 0 (transparent) to 1 (opaque). Omitted by default from the function result; the module is opaque when omitted.
//   ---
//   clip = If true, clamp out-of-gamut RGB components to [0,1]. Otherwise, assert an error for out-of-gamut colors beyond the roundoff tolerance. Default: false
//   mutable = Module only. If true, use mutable attachable coloring; if false, color complete child geometry immutably. Default: true
// Side Effects:
//   The module sets `$color` through recolor().
// Example:
//   lch(l=60,c=45,h=120) sphere(d=60);
// Example:
//   rgb = lch(l=70,c=30,h=270);
//   recolor(rgb) cube(60, center=true);
// Example: Clip an out-of-gamut color to displayable RGB.
//   lch(l=50,c=150,h=0,clip=true) sphere(d=60);
// Example: Apply alpha to the converted color.
//   lch(l=60,c=45,h=20,a=0.4) cuboid(40);
function lch(l, c, h, a, clip=false) =
    assert(is_finite(l) && l>=0 && l<=100, "\nl must be a finite number between 0 and 100.")
    assert(is_finite(c) && c>=0, "\nc must be a finite nonnegative chroma.")
    assert(is_finite(h), "\nh must be a finite hue angle.")
    assert(is_undef(a) || (is_finite(a) && a>=0 && a<=1), "\na must be a finite number between 0 and 1.")
    assert(is_bool(clip), "\nclip must be a boolean.")
    let(
        h = posmod(h,360),
        rgb = _xyz_to_rgb(_lab_to_xyz([l,c*cos(h),c*sin(h)])),
        eps = 1e-6
    )
    assert(is_vector(rgb,3), str("\nLCh conversion produced nonfinite RGB components: ",rgb))
    assert(clip || (min(rgb)>=-eps && max(rgb)<=1+eps),
           str("\nRequested LCh color is outside the sRGB gamut: RGB=",rgb,
               ". Use clip=true to clamp the RGB components."))
    let(rgb=constrain(rgb,0,1))
    is_def(a) ? point4d(rgb,a) : rgb;

module lch(l, c, h, a, clip=false, mutable=true)
{
    req_children($children);
    recolor(lch(l=l,c=c,h=h,a=a,clip=clip), mutable=mutable) children();
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
