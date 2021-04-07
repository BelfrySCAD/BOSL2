//////////////////////////////////////////////////////////////////////
// LibFile: debug.scad
//   Helpers to make debugging OpenScad code easier.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Debugging Paths and Polygons

// Module: trace_path()
// Usage:
//   trace_path(path, <closed=>, <showpts=>, <N=>, <size=>, <color=>);
// Description:
//   Renders lines between each point of a path.
//   Can also optionally show the individual vertex points.
// Arguments:
//   path = The list of points in the path.
//   ---
//   closed = If true, draw the segment from the last vertex to the first.  Default: false
//   showpts = If true, draw vertices and control points.
//   N = Mark the first and every Nth vertex after in a different color and shape.
//   size = Diameter of the lines drawn.
//   color = Color to draw the lines (but not vertices) in.
// Example(FlatSpin,VPD=44.4):
//   path = [for (a=[0:30:210]) 10*[cos(a), sin(a), sin(a)]];
//   trace_path(path, showpts=true, size=0.5, color="lightgreen");
module trace_path(path, closed=false, showpts=false, N=1, size=1, color="yellow") {
    assert(is_path(path),"Invalid path argument");
    sides = segs(size/2);
    path = closed? close_path(path) : path;
    if (showpts) {
        for (i = [0:1:len(path)-1]) {
            translate(path[i]) {
                if (i % N == 0) {
                    color("blue") sphere(d=size*2.5, $fn=8);
                } else {
                    color("red") {
                        cylinder(d=size/2, h=size*3, center=true, $fn=8);
                        xrot(90) cylinder(d=size/2, h=size*3, center=true, $fn=8);
                        yrot(90) cylinder(d=size/2, h=size*3, center=true, $fn=8);
                    }
                }
            }
        }
    }
    if (N!=3) {
        color(color) stroke(path3d(path), width=size, $fn=8);
    } else {
        for (i = [0:1:len(path)-2]) {
            if (N != 3 || (i % N) != 1) {
                color(color) extrude_from_to(path[i], path[i+1]) circle(d=size, $fn=sides);
            }
        }
    }
}


// Module: debug_polygon()
// Usage:
//   debug_polygon(points, paths, <convexity=>, <size=>);
// Description:
//   A drop-in replacement for `polygon()` that renders and labels the path points.
// Arguments:
//   points = The array of 2D polygon vertices.
//   paths = The path connections between the vertices.
//   ---
//   convexity = The max number of walls a ray can pass through the given polygon paths.
//   size = The base size of the line and labels.
// Example(Big2D):
//   debug_polygon(
//       points=concat(
//           regular_ngon(or=10, n=8),
//           regular_ngon(or=8, n=8)
//       ),
//       paths=[
//           [for (i=[0:7]) i],
//           [for (i=[15:-1:8]) i]
//       ]
//   );
module debug_polygon(points, paths, convexity=2, size=1)
{
    paths = is_undef(paths)? [[for (i=[0:1:len(points)-1]) i]] :
        is_num(paths[0])? [paths] :
        paths;
    echo(points=points);
    echo(paths=paths);
    linear_extrude(height=0.01, convexity=convexity, center=true) {
        polygon(points=points, paths=paths, convexity=convexity);
    }
    for (i = [0:1:len(points)-1]) {
        color("red") {
            up(0.2) {
                translate(points[i]) {
                    linear_extrude(height=0.1, convexity=10, center=true) {
                        text(text=str(i), size=size, halign="center", valign="center");
                    }
                }
            }
        }
    }
    for (j = [0:1:len(paths)-1]) {
        path = paths[j];
        translate(points[path[0]]) {
            color("cyan") up(0.1) cylinder(d=size*1.5, h=0.01, center=false, $fn=12);
        }
        translate(points[path[len(path)-1]]) {
            color("pink") up(0.11) cylinder(d=size*1.5, h=0.01, center=false, $fn=4);
        }
        for (i = [0:1:len(path)-1]) {
            midpt = (points[path[i]] + points[path[(i+1)%len(path)]])/2;
            color("blue") {
                up(0.2) {
                    translate(midpt) {
                        linear_extrude(height=0.1, convexity=10, center=true) {
                            text(text=str(chr(65+j),i), size=size/2, halign="center", valign="center");
                        }
                    }
                }
            }
        }
    }
}



// Section: Debugging Polyhedrons


// Module: debug_vertices()
// Usage:
//   debug_vertices(vertices, <size>, <disabled=>);
// Description:
//   Draws all the vertices in an array, at their 3D position, numbered by their
//   position in the vertex array.  Also draws any children of this module with
//   transparency.
// Arguments:
//   vertices = Array of point vertices.
//   size = The size of the text used to label the vertices.  Default: 1
//   ---
//   disabled = If true, don't draw numbers, and draw children without transparency.  Default = false.
// Example:
//   verts = [for (z=[-10,10], y=[-10,10], x=[-10,10]) [x,y,z]];
//   faces = [[0,1,2], [1,3,2], [0,4,5], [0,5,1], [1,5,7], [1,7,3], [3,7,6], [3,6,2], [2,6,4], [2,4,0], [4,6,7], [4,7,5]];
//   debug_vertices(vertices=verts, size=2) {
//       polyhedron(points=verts, faces=faces);
//   }
module debug_vertices(vertices, size=1, disabled=false) {
    if (!disabled) {
        echo(vertices=vertices);
        color("blue") {
            for (i = [0:1:len(vertices)-1]) {
                v = vertices[i];
                translate(v) {
                    up(size/8) zrot($vpr[2]) xrot(90) {
                        linear_extrude(height=size/10, center=true, convexity=10) {
                            text(text=str(i), size=size, halign="center");
                        }
                    }
                    sphere(size/10);
                }
            }
        }
    }
    if ($children > 0) {
        if (!disabled) {
            color([0.2, 1.0, 0, 0.5]) children();
        } else {
            children();
        }
    }
}



// Module: debug_faces()
// Usage:
//   debug_faces(vertices, faces, <size=>, <disabled=>);
// Description:
//   Draws all the vertices at their 3D position, numbered in blue by their
//   position in the vertex array.  Each face will have their face number drawn
//   in red, aligned with the center of face.  All children of this module are drawn
//   with transparency.
// Arguments:
//   vertices = Array of point vertices.
//   faces = Array of faces by vertex numbers.
//   ---
//   size = The size of the text used to label the faces and vertices.  Default: 1
//   disabled = If true, don't draw numbers, and draw children without transparency.  Default: false.
// Example(EdgesMed):
//   verts = [for (z=[-10,10], y=[-10,10], x=[-10,10]) [x,y,z]];
//   faces = [[0,1,2], [1,3,2], [0,4,5], [0,5,1], [1,5,7], [1,7,3], [3,7,6], [3,6,2], [2,6,4], [2,4,0], [4,6,7], [4,7,5]];
//   debug_faces(vertices=verts, faces=faces, size=2) {
//       polyhedron(points=verts, faces=faces);
//   }
module debug_faces(vertices, faces, size=1, disabled=false) {
    if (!disabled) {
        vlen = len(vertices);
        color("red") {
            for (i = [0:1:len(faces)-1]) {
                face = faces[i];
                if (face[0] < 0 || face[1] < 0 || face[2] < 0 || face[0] >= vlen || face[1] >= vlen || face[2] >= vlen) {
                    echo("BAD FACE: ", vlen=vlen, face=face);
                } else {
                    verts = select(vertices,face);
                    c = mean(verts);
                    v0 = verts[0];
                    v1 = verts[1];
                    v2 = verts[2];
                    dv0 = unit(v1 - v0);
                    dv1 = unit(v2 - v0);
                    nrm0 = cross(dv0, dv1);
                    nrm1 = UP;
                    axis = vector_axis(nrm0, nrm1);
                    ang = vector_angle(nrm0, nrm1);
                    theta = atan2(nrm0[1], nrm0[0]);
                    translate(c) {
                        rotate(a=180-ang, v=axis) {
                            zrot(theta-90)
                            linear_extrude(height=size/10, center=true, convexity=10) {
                                union() {
                                    text(text=str(i), size=size, halign="center");
                                    text(text=str("_"), size=size, halign="center");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    debug_vertices(vertices, size=size, disabled=disabled) {
        children();
    }
    if (!disabled) {
        echo(faces=faces);
    }
}



// Module: debug_polyhedron()
// Usage:
//   debug_polyhedron(points, faces, <convexity=>, <txtsize=>, <disabled=>);
// Description:
//   A drop-in module to replace `polyhedron()` and help debug vertices and faces.
//   Draws all the vertices at their 3D position, numbered in blue by their
//   position in the vertex array.  Each face will have their face number drawn
//   in red, aligned with the center of face.  All given faces are drawn with
//   transparency. All children of this module are drawn with transparency.
//   Works best with Thrown-Together preview mode, to see reversed faces.
// Arguments:
//   points = Array of point vertices.
//   faces = Array of faces by vertex numbers.
//   ---
//   convexity = The max number of walls a ray can pass through the given polygon paths.
//   txtsize = The size of the text used to label the faces and vertices.
//   disabled = If true, act exactly like `polyhedron()`.  Default = false.
// Example(EdgesMed):
//   verts = [for (z=[-10,10], a=[0:120:359.9]) [10*cos(a),10*sin(a),z]];
//   faces = [[0,1,2], [5,4,3], [0,3,4], [0,4,1], [1,4,5], [1,5,2], [2,5,3], [2,3,0]];
//   debug_polyhedron(points=verts, faces=faces, txtsize=1);
module debug_polyhedron(points, faces, convexity=6, txtsize=1, disabled=false) {
    debug_faces(vertices=points, faces=faces, size=txtsize, disabled=disabled) {
        polyhedron(points=points, faces=faces, convexity=convexity);
    }
}



// Function: standard_anchors()
// Usage:
//   anchs = standard_anchors(<two_d>);
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
//   anchor_arrow(<s>, <color>, <flag>);
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
//   anchor_arrow2d(<s>, <color>, <flag>);
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
        color(is_string($color)? $color : point3d($color), opacity)
            children();
}


// Module: show_anchors()
// Usage:
//   ... show_anchors(<s>, <std=>, <custom=>);
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
    two_d = attach_geom_2d($parent_geom);
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
                        up(s/10) {
                            linear_extrude(height=0.01, convexity=12, center=true) {
                                text(text=anchor[0], size=s/4, halign="center", valign="center");
                            }
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
//   ruler(length, width, <thickness=>, <depth=>, <labels=>, <pipscale=>, <maxscale=>, <colors=>, <alpha=>, <unit=>, <inch=>);
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
//   str = mod_indent(<indent>);
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
//   str = mod_trace(<levs>, <indent=>, <modsep=>);
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
//    echo_matrix(M, <description=>, <sig=>, <eps=>);
//    dummy = echo_matrix(M, <description=>, <sig=>, <eps=>),
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


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
