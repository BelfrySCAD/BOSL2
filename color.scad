//////////////////////////////////////////////////////////////////////
// LibFile: color.scad
//   HSV and HSL conversion, rainbow() module for coloring multiple objects. 
//   The recolor() and color_this() modules allow you to change the color
//   of previously colored attachable objects.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: HSV and HSL conversion, color multiple objects, change color of objects
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


use <builtins.scad>

// Section: Coloring Objects

// Module: recolor()
// Synopsis:  Sets the color for attachable children and their descendants.
// SynTags: Trans
// Topics: Attachments
// See Also: color_this(), hsl(), hsv()
// Usage:
//   recolor([c]) CHILDREN;
// Description:
//   Sets the color for attachable children and their descendants, down until another {{recolor()}}
//   or {{color_this()}}.  This only works with attachables and you cannot have any color() modules
//   above it in any parents, only other {{recolor()}} or {{color_this()}} modules.  This works by
//   setting the special `$color` variable, which attachable objects make use of to set the color. 
// Arguments:
//   c = Color name or RGBA vector.  Default: The default color in your color scheme. 
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
module recolor(c="default")
{
    req_children($children);  
    $color=c;
    children();
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
// Topics: List Handling
// See Also: hsl(), hsv()
// Usage:
//   rainbow(list,[stride],[maxhues],[shuffle],[seed]) CHILDREN;
// Description:
//   Iterates the list, displaying children in different colors for each list item.  The color
//   is set using the color() module, so this module is not compatible with {{recolor()}} or
//   {{color_this()}}.  This is useful for debugging regions or lists of paths. 
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
    req_children($children);  
    ll = len(list);
    maxhues = first_defined([maxhues,ll]);
    huestep = 360 / maxhues;
    huelist = [for (i=[0:1:ll-1]) posmod(i*huestep+i*360/stride,360)];
    hues = shuffle ? shuffle(huelist, seed=seed) : huelist;
    for($idx=idx(list)) {
        $item = list[$idx];
        hsv(h=hues[$idx]) children();
    }
}


// Module: color_overlaps()
// Synopsis: Shows ghostly children, with overlaps highlighted in color.
// SynTags: Trans
// Topics: Debugging
// See Also: rainbow(), debug_vnf()
// Usage:
//   color_overlaps([color]) CHILDREN;
// Description:
//   Displays the given children in ghostly transparent gray, while the places where the
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
// Topics: Attachments, Modifiers
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
// Topics: Attachments, Modifiers
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
// Topics: Attachments, Modifiers
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
// Topics: Attachments, Modifiers
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
//   lightness `l` from the HSL colorspace.  If you supply the `a` value then you'll get a length 4
//   list `[R,G,B,A]`.  When called as a module, sets the color using the color() module to the given
//   hue `h`, saturation `s`, and lightness `l` from the HSL colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   l = The lightness, between 0 and 1.  0 = black, 0.5 = bright colors, 1 = white.  Default: 0.5
//   a = Specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
// Side Effects:
//   When called as a module, sets the color of all children.
// Example:
//   hsl(h=120,s=1,l=0.5) sphere(d=60);
// Example:
//   rgb = hsl(h=270,s=0.75,l=0.6);
//   color(rgb) cube(60, center=true);
function hsl(h,s=1,l=0.5,a) =
    let(
        h=posmod(h,360)
    ) [
        for (n=[0,8,4])
          let(k=(n+h/30)%12)
          l - s*min(l,1-l)*max(min(k-3,9-k,1),-1),
        if (is_def(a)) a
    ];

module hsl(h,s=1,l=0.5,a=1)
{
  req_children($children);  
  color(hsl(h,s,l),a) children();
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
//   value `v` from the HSV colorspace.  If you supply the `a` value then you'll get a length 4 list
//   `[R,G,B,A]`.  When called as a module, sets the color using the color() module to the given hue
//   `h`, saturation `s`, and value `v` from the HSV colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   v = The value, between 0 and 1.  0 = darkest black, 1 = bright.  Default: 1
//   a = Specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
// Side Effects:
//   When called as a module, sets the color of all children.
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

module hsv(h,s=1,v=1,a=1)
{
    req_children($children);
    color(hsv(h,s,v),a) children();
}    



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
