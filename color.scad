//////////////////////////////////////////////////////////////////////
// LibFile: color.scad
//   In OpenSCAD the `color()` module sets the color immutably for all children:
//   any `color()` modules appearing below are ignored.  This is both inflexible
//   and somewhat unintuitive. In BOSL2 {{recolor()}} replaces `color()` for
//   use with attachable objects.  
//   If you need to impose immutable color, it has an option to do that, but
//   by default it colors objects in such a way that you can change the colors
//   of children when desired.  The {{color_this()}} module can 
//   change the color at just one level, which children switching back to
//   the previous color.  
//   .
//   The `rainbow()` module for gives its children each a different color (e.g.
//   for debugging), and also provided are conversions from HSV, HSL and LCh. 
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: HSV and HSL conversion, color multiple objects, change color of objects
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

_BOSL2_COLOR = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: color.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;


use <builtins.scad>

// Section: Coloring Objects

// Module: recolor()
// Synopsis:  Sets the color for attachable children and their descendants.
// SynTags: Trans
// Topics: Attachments
// See Also: color_this(), hsl(), hsv()
// Usage:
//   recolor([c],[a],[mutable=]) CHILDREN;
// Description:
//   Sets the color for attachable children and their descendants, down until another {{recolor()}}
//   or {{color_this()}}.  This only works with attachables and you cannot have any color() modules
//   above it in any parents, only other {{recolor()}} or {{color_this()}} modules.  This works by
//   setting the special `$color` variable, which attachable objects make use of to set the color.
//   As with `color()`, if you specify the alpha value with `a` that overrides any alpha given in the `c` vector.                                    
// Arguments:
//   c = Color name or RGBA vector.  Default: The default color in your color scheme.
//   a = Alpha value. Overrides any alpha specified in `c`.  Default: 1
//   ---
//   mutable = If false set color using `color()` so that the color can never change again for any child.  Default: False                                    
// Side Effects:
//   Changes the value of `$color`.
//   Sets the color of child attachments.
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
    if (mutable){
      $color=[c,a];
      children();
    } else color(c,a)children();
}


// Module: color_this()
// Synopsis: Sets the color for children at the current level only.
// SynTags: Trans
// Topics: Attachments
// See Also: recolor(), hsl(), hsv()
// Usage:
//   color_this([c]) CHILDREN;
// Description:
//   Sets the color for children at one level, reverting to the previous color for further descendants.
//   This works only with attachables and you cannot have any color() modules above it in any parents,
//   only recolor() or other color_this() modules.  This works using the `$color` and `$save_color` variables,
//   which attachable objects make use of to set the color. 
// Arguments:
//   c = Color name or RGBA vector.  Default: the default color in your color scheme
// Side Effects:
//   Changes the value of `$color` and `$save_color`.
//   Sets the color of child attachments.
// Example:
//   cuboid([10,10,5])
//     color_this("green")attach(TOP,BOT) cuboid([9,9,4.5])
//       attach(TOP,BOT) cuboid([8,8,4])
//         color_this("purple") attach(TOP,BOT) cuboid([7,7,3.5])
//           attach(TOP,BOT) cuboid([6,6,3])
//             color_this("cyan")attach(TOP,BOT) cuboid([5,5,2.5])
//               attach(TOP,BOT) cuboid([4,4,2]);
module color_this(c="default")
{
  req_children($children);  
  $save_color=default($color,"default");
  $color=c;
  children();
}


// Module: rainbow()
// Synopsis: Iterates through a list, displaying children in different colors.
// SynTags: Trans
// Topics: Colors, List Handling, Debugging
// See Also: hsl(), hsv()
// Usage:
//   rainbow(list,[stride],[maxhues],[shuffle],[seed]) CHILDREN;
// Description:
//   Iterates over the list, invoking the children with different colors for each list item.  The color
//   is set using the color() module, so this module is not compatible with {{recolor()}} or
//   {{color_this()}}.  You use the `$item` variable to control the display of different children.
//   By default the colors are chosen as mathematically uniform hue steps in HSV using a different hue
//   for every item in the list.  The `stride` specifies how big of a step to take between two adjacent
//   items.  If `stride=1` then the step gives the next adjacent color, which may be very similar.  By
//   default a stride that is coprime with the list length is chosen to maximize the used and distinguishability
//   of nearby the available colors.  
// Arguments:
//   list = The list of items to iterate through.
//   stride = How big of a step to take through the available hue list between two adjacent items.  Default: see description
//   maxhues = max number of hues to use (to prevent lots of indistinguishable hues)
//   ---
//   shuffle = if true then shuffle the hues in a random order.  Default: false
//   seed = seed to use for shuffle
//   mutable = If false set color using `color()` so that the color can never change again for any child.  Default: False                                    
// Side Effects:
//   Sets the color to progressive values along the ROYGBIV spectrum for each item.
//   Sets `$idx` to the index of the current item in `list` that we want to show.
//   Sets `$item` to the current item in `list` that we want to show.
// Example(2D):
//   rainbow(["Foo","Bar","Baz","Big","Bam"]) fwd($idx*10) text(text=$item,size=8,halign="center",valign="center");
// Example(2D):
//   rgn = [circle(d=45,$fn=3), circle(d=75,$fn=4), circle(d=50)];
//   rainbow(rgn) stroke($item, closed=true);
// Example(2D):
//   rainbow(lerpn(0,360,30,endpoint=false))
//     zrot($item)
//       stroke([[0,0],[50,0]]);
// Example(2D): Setting maxhues to a small value
//   rainbow(lerpn(0,360,30,endpoint=false),maxhues=3)
//      zrot($item)stroke([[0,0],[50,0]]);
// Example(2D): Changing stride to 1
//   rainbow(lerpn(0,360,30,endpoint=false),stride=1)
//     zrot($item)stroke([[0,0],[50,0]]);

module rainbow(list, stride, maxhues, shuffle=false, seed, mutable=true)
{
    req_children($children);
    listlen = len(list);
    maxhues = first_defined([maxhues,listlen]);
    stride = default(stride,_golden_stride(maxhues));
    huestep = 360 / maxhues;
    huelist = [for (i=[0:1:listlen-1]) posmod(i*stride*huestep,360)];
    hues = shuffle ? shuffle(huelist, seed=seed) : huelist;
    for($idx=idx(list)) {
        echo($idx,floor($idx/maxhues));
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
//   they overlap are highlighted with the given color.
// Arguments:
//   color = The color to highlight overlaps with.  Default: "red"
// Example(2D): 2D Overlaps
//   color_overlaps() {
//       circle(d=50);
//       left(20) circle(d=50);
//       right(20) circle(d=50);
//   }
// Example(): 3D Overlaps
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
// Synopsis: Sets # modifier for attachable children and their descendents.
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
//   highlight = If true set the descendents to use `#`; if false, disable `#` for descendents.  Default: true
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
//   Applies the `#` modifier to the children at a single level, reverting to the previous highlight state for further descendents.  
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
// Synopsis: Sets % modifier for attachable children and their descendents.
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
//   ghost = If true set the descendents to use `%`; if false, disable `%` for descendents.  Default: true
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
//   Applies the `%` modifier to the children at a single level, reverting to the previous ghost state for further descendents.  
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
// Synopsis: Sets the color of children to a specified hue, saturation, lightness and optional alpha channel value.
// SynTags: Trans
// See Also: hsv(), recolor(), color_this()
// Topics: Colors, Colorspace
// Usage:
//   hsl(h,[s],[l],[a]) CHILDREN;
//   rgb = hsl(h,[s],[l],[a]);
// Description:
//   When called as a function, returns the `[R,G,B]` color for the given hue `h`, saturation `s`, and
//   lightness `l` from the [HSL colorspace](https://en.wikipedia.org/wiki/HSL_and_HSV).  If you supply the `a` value then you'll get a length 4
//   list `[R,G,B,A]`.  When called as a module, sets the color using the color() module to the given
//   hue `h`, saturation `s`, and lightness `l` from the HSL colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   l = The lightness, between 0 and 1.  0 = black, 0.5 = bright colors, 1 = white.  Default: 0.5
//   a = Specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
//   ---
//   mutable = If false set color using `color()` so that the color can never change again for any child.  Default: False                                    
// Side Effects:
//   When called as a module, sets the color of the children.
// Example:
//   hsl(h=120,s=1,l=0.5) sphere(d=60);
// Example:
//   rgb = hsl(h=270,s=0.75,l=0.6);
//   color(rgb) cube(60, center=true);
function hsl(h,s=1,l=0.5,a) =
    assert(is_finite(s) && s>=0 && s<=1)
    assert(is_finite(l) && l>=0 && l<=1,str(l))
    assert(is_finite(h))
    assert(is_undef(a) || a>=0 && a<=1)
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
// Synopsis: Sets the color of children to a hue, saturation, value and optional alpha channel value.
// SynTags: Trans
// See Also: hsl(), recolor(), color_this()
// Topics: Colors, Colorspace
// Usage:
//   hsv(h,[s],[v],[a]) CHILDREN;
//   rgb = hsv(h,[s],[v],[a]);
// Description:
//   When called as a function, returns the `[R,G,B]` color for the given hue `h`, saturation `s`, and
//   value `v` from the [HSV colorspace](https://en.wikipedia.org/wiki/HSL_and_HSV).
//   If you supply the `a` value then you'll get a length 4 list
//   `[R,G,B,A]`.  When called as a module, sets the color using the color() module to the given hue
//   `h`, saturation `s`, and value `v` from the HSV colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   v = The value, between 0 and 1.  0 = darkest black, 1 = bright.  Default: 1
//   a = Specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
//   ---
//   mutable = If false set color using `color()` so that the color can never change again for any child.  Default: False                                    
// Side Effects:
//   When called as a module, sets the color of the children.
// Example:
//   hsv(h=120,s=1,v=1) sphere(d=60);
// Example:
//   rgb = hsv(h=270,s=0.75,v=0.9);
//   color(rgb) cube(60, center=true);
function hsv(h,s=1,v=1,a) =
    assert(s>=0 && s<=1)
    assert(v>=0 && v<=1)
    assert(is_undef(a) || a>=0 && a<=1)
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


// ---- sRGB <-> CIE XYZ <-> CIE Lab/LCh ----
// D65 reference white, standard sRGB primaries/gamma.

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

/// >0 means outside the RGB cube, <0 inside, 0 exactly on the boundary.
/// Monotonic increasing in chroma along a fixed hue/lightness ray, so it
/// has exactly one root -- safe input for root_find().
function _gamut_violation(h,c,l) =
    let(rgb = _xyz_to_rgb(_lab_to_xyz([l*100, c*cos(h), c*sin(h)])))
    max(max(rgb)-1, -min(rgb));

// Function&Module: lch()
// Synopsis: Sets the color of children to a lightness, chroma and hue with optional alpha channel value. 
// SynTags: Trans
// See Also: max_chroma(), hsl(), hsv(), recolor(), color_this()
// Topics: Colors, Colorspace
// Usage:
//   lch(l, c, h, [a], [sat=]) CHILDREN;
//   rgb = lch(l, c, h, [a], [sat=])
// Description:
//   When called as a function, returns the `[R,G,B]` color for the given lightness `l`, chroma `c`,
//   and hue `h` from the CIE LCh colorspace.  If you supply the `a` value then you'll get a length 4
//   list `[R,G,B,A]`.  When called as a module, sets the color using the color() module to the given
//   lightness `l`, chroma `c`, and hue `h` from the CIE LCh colorspace.  Unlike HSL/HSV, equal steps in
//   `l` and `h` correspond much more closely to equal steps in perceived lightness and hue, which makes
//   LCh a better basis for generating sets of colors that need to look evenly distinguishable.
//   The tradeoff is that `c` has no fixed maximum: the highest chroma displayable in
//   sRGB depends on both `l` and `h`, so a chroma that looks vivid for one hue may be out of gamut for
//   another.  If you give an out of bounds value for chroma then you'll get an error with the
//   unrealizable RGB value shown.  If you'd rather work in a 0-1 dial similar to HSL/HSV's `s`,
//   you can specify `sat=` and the chroma will be calculated as that fraction of the available
//   maximum chroma at the given `l` and `h`.  
// Arguments:
//   l = lightness, 0 (black) to 1 (white)
//   c = chroma in absolute CIE Lab units.  0 = gray.  The max value (0-150 depending on hue and lightness) is the most vivid or saturated color
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   a = Specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
//   ---
//   sat = Value between 0 and 1 specifying chroma as a fraction of the maximum chroma available at this lightness and hue.
//   mutable = If false set color using `color()` so that the color can never change again for any child.  Default: False                                    
// Side Effects:
//   When called as a module, sets the color of the children.
// Example:
//   lch(l=0.6,c=45,h=120) sphere(d=60);
// Example:
//   rgb = lch(l=0.7,sat=0.9,h=270);
//   recolor(rgb) cube(60, center=true);

function lch(l, c, h, a, sat) =
    assert(num_defined([c,sat])==1, "Must give exactly one of 'c' and 'sta'")
    assert(is_finite(h))
    assert(is_finite(l) && l>=0 && l<=1)
    let(
        calc_rgb = function(l,c,h)
                      let(lab = [l*100, c*cos(h), c*sin(h)])
                      _xyz_to_rgb(_lab_to_xyz(lab)),            
        h = posmod(h,360),
        rgb = is_def(sat) ? constrain(calc_rgb(l,sat*max_chroma(l,h),h),0,1)
            : let(
                  val = calc_rgb(l,c,h),
                  ok = [for(v=val) if (v<-1e-6 || v >1+1e-6) 1]==[]
              )
              assert(ok,str("\nChroma ",c," is out of gamut at l=",l,", h=",h,": RGB=",val,", max c=",max_chroma(l,h)))
              constrain(val,0,1)
    )
    is_def(a) ? point4d(rgb,a) : rgb;


module lch(l, c, h, a, sat, mutable=true) 
{
    req_children($children);
    recolor(lch(h=h,c=c,sat=sat,l=l,a=a), mutable=mutable) children();
}


// Function: max_chroma()
// Synopsis: Compute maximum chroma value for lightness and hue values in lch()
// Topics: Colors, Colorspace
// See Also: lch()
// Usage:
//   max_c = max_chroma(l,h)
// Description:
//   Returns the maximum chroma (absolute CIE Lab units) achievable in sRGB
//   at the given hue and lightness, before the color goes outside gamut.
//   Useful for building custom palettes, or for gamut-boundary visualization.
//   Note: this runs a root-find internally so if you need it for many (h,l)
//   pairs it may be worth storing values. 
function max_chroma(l,h) =
    l==0 || l==1 ? 0
                 : root_find(function(c) _gamut_violation(h,c,l), 0, 150);


/// This version produces uniform lightness hues but actually this seems bad because
/// they are less distinctive.  
/// // Module: rainbow_lch()
/// // Like rainbow(), but hues are perceptually-spaced via CIE LCh instead of
/// // HSV, and chroma is auto-maximized per hue at the given lightness.
/// // l   = lightness for every color, 0-1. Default: 0.6
/// // sat = fraction of each hue's max available chroma, 0-1. Default: 0.9
/// module rainbow_lch(list, stride, maxhues, l=0.7, sat=.8, shuffle=false, seed)
/// {
///     req_children($children);
///     ll = len(list);
///     maxhues = first_defined([maxhues, ll]);
///     stride = first_defined([stride, _golden_stride(maxhues)]);
///     huestep = 360/maxhues;
///     bucket_cmax = [for (b=[0:1:maxhues-1]) max_chroma(b*huestep, l)];  // once per bucket, not per item
///     huelist = [for (i=[0:1:ll-1]) posmod(i*stride*huestep,360)];
///     hues = shuffle ? shuffle(huelist, seed=seed) : huelist;
///     for ($idx = idx(list)) {
///         $item = list[$idx];
///         h = hues[$idx];
///         b = round(h/huestep) % maxhues;
///         color(lch(h=h, c=sat*bucket_cmax[b], l=l)) children();
///     }
/// }
/// 

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
