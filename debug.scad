//////////////////////////////////////////////////////////////////////
// LibFile: debug.scad
//   Helpers to make debugging OpenScad code easier.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////



// Function: standard_anchors()
// Usage:
//   anchs = standard_anchors([two_d]);
// Description:
//   Return the vectors for all standard anchors.
// Arguments:
//   two_d = If true, returns only the anchors where the Z component is 0.  Default: false
function standard_anchors(two_d=false) = [
    for (
        zv = [
            if (!two_d) TOP,
            CENTER,
            if (!two_d) BOTTOM
        ],
        yv = [FRONT, CENTER, BACK],
        xv = [LEFT, CENTER, RIGHT]
    ) xv+yv+zv
];



// Module: anchor_arrow()
// Usage:
//   anchor_arrow([s], [color], [flag]);
// Description:
//   Show an anchor orientation arrow.  By default, tagged with the name "anchor-arrow".
// Arguments:
//   s = Length of the arrows.  Default: `10`
//   color = Color of the arrow.  Default: `[0.333, 0.333, 1]`
//   flag = If true, draw the orientation flag on the arrowhead.  Default: true
// Example:
//   anchor_arrow(s=20);
module anchor_arrow(s=10, color=[0.333,0.333,1], flag=true, $tags="anchor-arrow") {
    $fn=12;
    recolor("gray") spheroid(d=s/6) {
        attach(CENTER,BOT) recolor(color) cyl(h=s*2/3, d=s/15) {
            attach(TOP,BOT) cyl(h=s/3, d1=s/5, d2=0) {
                if(flag) {
                    position(BOT)
                        recolor([1,0.5,0.5])
                            cuboid([s/100, s/6, s/4], anchor=FRONT+BOT);
                }
                children();
            }
        }
    }
}



// Module: anchor_arrow2d()
// Usage:
//   anchor_arrow2d([s], [color], [flag]);
// Description:
//   Show an anchor orientation arrow.
// Arguments:
//   s = Length of the arrows.
//   color = Color of the arrow.
// Example:
//   anchor_arrow2d(s=20);
module anchor_arrow2d(s=15, color=[0.333,0.333,1], $tags="anchor-arrow") {
    noop() color(color) stroke([[0,0],[0,s]], width=s/10, endcap1="butt", endcap2="arrow2");
}



// Module: expose_anchors()
// Usage:
//   expose_anchors(opacity) {...}
// Description:
//   Makes the children transparent gray, while showing any anchor arrows that may exist.
// Arguments:
//   opacity = The opacity of the arrow.  0.0 is invisible, 1.0 is opaque.  Default: 0.2
// Example(FlatSpin,VPD=333):
//   expose_anchors() cube(50, center=true) show_anchors();
module expose_anchors(opacity=0.2) {
    show("anchor-arrow")
        children();
    hide("anchor-arrow")
        color(is_undef($color)? [0,0,0] :
              is_string($color)? $color :
                                 point3d($color), opacity)
            children();
}


// Module: show_anchors()
// Usage:
//   ... show_anchors([s], [std=], [custom=]);
// Description:
//   Show all standard anchors for the parent object.
// Arguments:
//   s = Length of anchor arrows.
//   ---
//   std = If true (default), show standard anchors.
//   custom = If true (default), show custom anchors.
// Example(FlatSpin,VPD=333):
//   cube(50, center=true) show_anchors();
module show_anchors(s=10, std=true, custom=true) {
    check = assert($parent_geom != undef) 1;
    two_d = _attach_geom_2d($parent_geom);
    if (std) {
        for (anchor=standard_anchors(two_d=two_d)) {
            if(two_d) {
                attach(anchor) anchor_arrow2d(s);
            } else {
                attach(anchor) anchor_arrow(s);
            }
        }
    }
    if (custom) {
        for (anchor=last($parent_geom)) {
            attach(anchor[0]) {
                if(two_d) {
                    anchor_arrow2d(s, color="cyan");
                } else {
                    anchor_arrow(s, color="cyan");
                }
                color("black")
                noop($tags="anchor-arrow") {
                    xrot(two_d? 0 : 90) {
                        back(s/3) {
                            yrot_copies(n=2)
                            up(s/30) {
                                linear_extrude(height=0.01, convexity=12, center=true) {
                                    text(text=anchor[0], size=s/4, halign="center", valign="center");
                                }
                            }
                        }
                    }
                }
                color([1, 1, 1, 0.4])
                noop($tags="anchor-arrow") {
                    xrot(two_d? 0 : 90) {
                        back(s/3) {
                            zcopies(s/21) cube([s/4.5*len(anchor[0]), s/3, 0.01], center=true);
                        }
                    }
                }
            }
        }
    }
    children();
}



// Module: frame_ref()
// Usage:
//   frame_ref(s, opacity);
// Description:
//   Displays X,Y,Z axis arrows in red, green, and blue respectively.
// Arguments:
//   s = Length of the arrows.
//   opacity = The opacity of the arrows.  0.0 is invisible, 1.0 is opaque.  Default: 1.0
// Examples:
//   frame_ref(25);
//   frame_ref(30, opacity=0.5);
module frame_ref(s=15, opacity=1) {
    cube(0.01, center=true) {
        attach([1,0,0]) anchor_arrow(s=s, flag=false, color=[1.0, 0.3, 0.3, opacity]);
        attach([0,1,0]) anchor_arrow(s=s, flag=false, color=[0.3, 1.0, 0.3, opacity]);
        attach([0,0,1]) anchor_arrow(s=s, flag=false, color=[0.3, 0.3, 1.0, opacity]);
        children();
    }
}


// Module: ruler()
// Usage:
//   ruler(length, width, [thickness=], [depth=], [labels=], [pipscale=], [maxscale=], [colors=], [alpha=], [unit=], [inch=]);
// Description:
//   Creates a ruler for checking dimensions of the model
// Arguments:
//   length = length of the ruler.  Default 100
//   width = width of the ruler.  Default: size of the largest unit division
//   ---
//   thickness = thickness of the ruler. Default: 1
//   depth = the depth of mark subdivisions. Default: 3
//   labels = draw numeric labels for depths where labels are larger than 1.  Default: false
//   pipscale = width scale of the pips relative to the next size up.  Default: 1/3
//   maxscale = log10 of the maximum width divisions to display.  Default: based on input length
//   colors = colors to use for the ruler, a list of two values.  Default: `["black","white"]`
//   alpha = transparency value.  Default: 1.0
//   unit = unit to mark.  Scales the ruler marks to a different length.  Default: 1
//   inch = set to true for a ruler scaled to inches (assuming base dimension is mm).  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `LEFT+BACK+TOP`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples(2D,Big):
//   ruler(100,depth=3);
//   ruler(100,depth=3,labels=true);
//   ruler(27);
//   ruler(27,maxscale=0);
//   ruler(100,pipscale=3/4,depth=2);
//   ruler(100,width=2,depth=2);
// Example(2D,Big):  Metric vs Imperial
//   ruler(12,width=50,inch=true,labels=true,maxscale=0);
//   fwd(50)ruler(300,width=50,labels=true);
module ruler(length=100, width, thickness=1, depth=3, labels=false, pipscale=1/3, maxscale, colors=["black","white"], alpha=1.0, unit=1, inch=false, anchor=LEFT+BACK+TOP, spin=0, orient=UP)
{
    inchfactor = 25.4;
    assert(depth<=5, "Cannot render scales smaller than depth=5");
    assert(len(colors)==2, "colors must contain a list of exactly two colors.");
    length = inch ? inchfactor * length : length;
    unit = inch ? inchfactor*unit : unit;
    maxscale = is_def(maxscale)? maxscale : floor(log(length/unit-EPSILON));
    scales = unit * [for(logsize = [maxscale:-1:maxscale-depth+1]) pow(10,logsize)];
    widthfactor = (1-pipscale) / (1-pow(pipscale,depth));
    width = default(width, scales[0]);
    widths = width * widthfactor * [for(logsize = [0:-1:-depth+1]) pow(pipscale,-logsize)];
    offsets = concat([0],cumsum(widths));
    attachable(anchor,spin,orient, size=[length,width,thickness]) {
        translate([-length/2, -width/2, 0]) 
        for(i=[0:1:len(scales)-1]) {
            count = ceil(length/scales[i]);
            fontsize = 0.5*min(widths[i], scales[i]/ceil(log(count*scales[i]/unit)));
            back(offsets[i]) {
                xcopies(scales[i], n=count, sp=[0,0,0]) union() {
                    actlen = ($idx<count-1) || approx(length%scales[i],0) ? scales[i] : length % scales[i];
                    color(colors[$idx%2], alpha=alpha) {
                        w = i>0 ? quantup(widths[i],1/1024) : widths[i];    // What is the i>0 test supposed to do here? 
                        cube([quantup(actlen,1/1024),quantup(w,1/1024),thickness], anchor=FRONT+LEFT);
                    }
                    mark =
                        i == 0 && $idx % 10 == 0 && $idx != 0 ? 0 :
                        i == 0 && $idx % 10 == 9 && $idx != count-1 ? 1 :
                        $idx % 10 == 4 ? 1 :
                        $idx % 10 == 5 ? 0 : -1;
                    flip = 1-mark*2;
                    if (mark >= 0) {
                        marklength = min(widths[i]/2, scales[i]*2);
                        markwidth = marklength*0.4;
                        translate([mark*scales[i], widths[i], 0]) {
                            color(colors[1-$idx%2], alpha=alpha) {
                                linear_extrude(height=thickness+scales[i]/100, convexity=2, center=true) {
                                    polygon(scale([flip*markwidth, marklength],p=[[0,0], [1, -1], [0,-0.9]]));
                                }
                            }
                        }
                    }
                    if (labels && scales[i]/unit+EPSILON >= 1) {
                        color(colors[($idx+1)%2], alpha=alpha) {
                            linear_extrude(height=thickness+scales[i]/100, convexity=2, center=true) {
                                back(scales[i]*.02) {
                                    text(text=str( $idx * scales[i] / unit), size=fontsize, halign="left", valign="baseline");
                                }
                            }
                        }
                    }

                }
            }
        }
        children();
    }
}


// Function: mod_indent()
// Usage:
//   str = mod_indent([indent]);
// Description:
//   Returns a string that is the total indentation for the module level you are at.
// Arguments:
//   indent = The string to indent each level by.  Default: "  " (Two spaces)
// Example:
//   x = echo(str(mod_indent(), parent_module(0)));
function mod_indent(indent="  ") =
    str_join([for (i=[1:1:$parent_modules-1]) indent]);


// Function: mod_trace()
// Usage:
//   str = mod_trace([levs], [indent=], [modsep=]);
// Description:
//   Returns a string that shows the current module and its parents, indented for each unprinted parent module.
// Arguments:
//   levs = This is the number of levels to print the names of.  Prints the N most nested module names.  Default: 2
//   ---
//   indent = The string to indent each level by.  Default: "  " (Two spaces)
//   modsep = Multiple module names will be separated by this string.  Default: "->"
// Example:
//   x = echo(mod_trace());
function mod_trace(levs=2, indent="  ", modsep="->") =
    str(
        str_join([for (i=[1:1:$parent_modules+1-levs]) indent]),
        str_join([for (i=[min(levs-1,$parent_modules-1):-1:0]) parent_module(i)], modsep)
    );


// Function&Module: echo_matrix()
// Usage:
//    echo_matrix(M, [description=], [sig=], [eps=]);
//    dummy = echo_matrix(M, [description=], [sig=], [eps=]),
// Description:
//    Display a numerical matrix in a readable columnar format with `sig` significant
//    digits.  Values smaller than eps display as zero.  If you give a description
//    it is displayed at the top.  
function echo_matrix(M,description,sig=4,eps=1e-9) =
  let(
      horiz_line = chr(8213),
      matstr = matrix_strings(M,sig=sig,eps=eps),
      separator = str_join(repeat(horiz_line,10)),
      dummy=echo(str(separator,"  ",is_def(description) ? description : ""))
            [for(row=matstr) echo(row)]
  )
  echo(separator);

module echo_matrix(M,description,sig=4,eps=1e-9)
{
  dummy = echo_matrix(M,description,sig,eps);
}

// Function: random_polygon()
// Usage:
//    points = random_polygon(n, size, [seed]);
// See Also: random_points(), gaussian_random_points(), spherical_random_points()
// Topics: Random, Polygon
// Description:
//    Generate the `n` vertices of a random counter-clockwise simple 2d polygon 
//    inside a circle centered at the origin with radius `size`.
// Arguments:
//    n = number of vertices of the polygon. Default: 3
//    size = the radius of a circle centered at the origin containing the polygon. Default: 1
//    seed = an optional seed for the random generation.
function random_polygon(n=3,size=1, seed) =
    assert( is_int(n) && n>2, "Improper number of polygon vertices.")
    assert( is_num(size) && size>0, "Improper size.")
    let( 
        seed = is_undef(seed) ? rands(0,1,1)[0] : seed,
        cumm = cumsum(rands(0.1,10,n+1,seed)),
        angs = 360*cumm/cumm[n-1],
        rads = rands(.01,size,n,seed+cumm[0])
      )
    [for(i=count(n)) rads[i]*[cos(angs[i]), sin(angs[i])] ];




// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
