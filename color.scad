//////////////////////////////////////////////////////////////////////
// LibFile: color.scad
//   HSV and HSL conversion, and raindow module for coloring multiple objects.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: HSV and HSL conversion, color multiple objects
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


use <builtins.scad>


// Section: Coloring Objects

// Module: rainbow()
// Usage:
//   rainbow(list) ...
// Description:
//   Iterates the list, displaying children in different colors for each list item.
//   This is useful for debugging lists of paths and such.
// Arguments:
//   list = The list of items to iterate through.
//   stride = Consecutive colors stride around the color wheel divided into this many parts.
//   maxhues = max number of hues to use (to prevent lots of indistinguishable hues)
//   shuffle = if true then shuffle the hues in a random order.  Default: false
//   seed = seed to use for shuffle
// Side Effects:
//   Sets the color to progressive values along the ROYGBIV spectrum for each item.
//   Sets `$idx` to the index of the current item in `list` that we want to show.
//   Sets `$item` to the current item in `list` that we want to show.
// Example(2D):
//   rainbow(["Foo","Bar","Baz"]) fwd($idx*10) text(text=$item,size=8,halign="center",valign="center");
// Example(2D):
//   rgn = [circle(d=45,$fn=3), circle(d=75,$fn=4), circle(d=50)];
//   rainbow(rgn) stroke($item, closed=true);
module rainbow(list, stride=1, maxhues, shuffle=false, seed)
{
    ll = len(list);
    maxhues = first_defined([maxhues,ll]);
    huestep = 360 / maxhues;
    huelist = [for (i=[0:1:ll-1]) posmod(i*huestep+i*360/stride,360)];
    hues = shuffle ? shuffle(huelist, seed=seed) : huelist;
    for($idx=idx(list)) {
        $item = list[$idx];
        HSV(h=hues[$idx]) children();
    }
}


// Section: Colorspace Conversion

// Function&Module: HSL()
// Usage:
//   HSL(h,[s],[l],[a]) ...
//   rgb = HSL(h,[s],[l]);
// Description:
//   When called as a function, returns the [R,G,B] color for the given hue `h`, saturation `s`, and lightness `l` from the HSL colorspace.
//   When called as a module, sets the color to the given hue `h`, saturation `s`, and lightness `l` from the HSL colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   l = The lightness, between 0 and 1.  0 = black, 0.5 = bright colors, 1 = white.  Default: 0.5
//   a = When called as a module, specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
// Example:
//   HSL(h=120,s=1,l=0.5) sphere(d=60);
// Example:
//   rgb = HSL(h=270,s=0.75,l=0.6);
//   color(rgb) cube(60, center=true);
function HSL(h,s=1,l=0.5) =
    let(
        h=posmod(h,360)
    ) [
        for (n=[0,8,4]) let(
            k=(n+h/30)%12
        ) l - s*min(l,1-l)*max(min(k-3,9-k,1),-1)
    ];

module HSL(h,s=1,l=0.5,a=1) color(HSL(h,s,l),a) children();


// Function&Module: HSV()
// Usage:
//   HSV(h,[s],[v],[a]) ...
//   rgb = HSV(h,[s],[v]);
// Description:
//   When called as a function, returns the [R,G,B] color for the given hue `h`, saturation `s`, and value `v` from the HSV colorspace.
//   When called as a module, sets the color to the given hue `h`, saturation `s`, and value `v` from the HSV colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   v = The value, between 0 and 1.  0 = darkest black, 1 = bright.  Default: 1
//   a = When called as a module, specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
// Example:
//   HSV(h=120,s=1,v=1) sphere(d=60);
// Example:
//   rgb = HSV(h=270,s=0.75,v=0.9);
//   color(rgb) cube(60, center=true);
function HSV(h,s=1,v=1) =
    assert(s>=0 && s<=1)
    assert(v>=0 && v<=1)
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
    rgbprime+[m,m,m];

module HSV(h,s=1,v=1,a=1) color(HSV(h,s,v),a) children();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
