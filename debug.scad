//////////////////////////////////////////////////////////////////////
// LibFile: debug.scad
//   Helpers to make debugging OpenScad code easier.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/debug.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Debugging Polyhedrons


// Module: debug_vertices()
// Description:
//   Draws all the vertices in an array, at their 3D position, numbered by their
//   position in the vertex array.  Also draws any children of this module with
//   transparency.
// Arguments:
//   vertices = Array of point vertices.
//   size     = The size of the text used to label the vertices.
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
// Description:
//   Draws all the vertices at their 3D position, numbered in blue by their
//   position in the vertex array.  Each face will have their face number drawn
//   in red, aligned with the center of face.  All children of this module are drawn
//   with transparency.
// Arguments:
//   vertices = Array of point vertices.
//   faces    = Array of faces by vertex numbers.
//   size     = The size of the text used to label the faces and vertices.
//   disabled = If true, don't draw numbers, and draw children without transparency.  Default = false.
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
					v0 = vertices[face[0]];
					v1 = vertices[face[1]];
					v2 = vertices[face[2]];
					c = (v0 + v1 + v2) / 3;
					dv0 = normalize(v1 - v0);
					dv1 = normalize(v2 - v0);
					nrm0 = normalize(cross(dv0, dv1));
					nrm1 = [0, 0, 1];
					axis = normalize(cross(nrm0, nrm1));
					ang = vector_angle(nrm0,  nrm1);
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
// Description:
//   A drop-in module to replace `polyhedron()` and help debug vertices and faces.
//   Draws all the vertices at their 3D position, numbered in blue by their
//   position in the vertex array.  Each face will have their face number drawn
//   in red, aligned with the center of face.  All given faces are drawn with
//   transparency. All children of this module are drawn with transparency.
//   Works best with Thrown-Together preview mode, to see reversed faces.
// Arguments:
//   vertices = Array of point vertices.
//   faces = Array of faces by vertex numbers.
//   txtsize = The size of the text used to label the faces and vertices.
//   disabled = If true, act exactly like `polyhedron()`.  Default = false.
// Example(EdgesMed):
//   verts = [for (z=[-10,10], a=[0:120:359.9]) [10*cos(a),10*sin(a),z]];
//   faces = [[0,1,2], [5,4,3], [0,3,4], [0,4,1], [1,4,5], [1,5,2], [2,5,3], [2,3,0]];
//   debug_polyhedron(points=verts, faces=faces, txtsize=1);
module debug_polyhedron(points, faces, convexity=10, txtsize=1, disabled=false) {
	debug_faces(vertices=points, faces=faces, size=txtsize, disabled=disabled) {
		polyhedron(points=points, faces=faces, convexity=convexity);
	}
}



// Function: standard_anchors()
// Description:
//   Return the vectors for all standard anchors.
function standard_anchors() = [
	for (
		zv = [TOP, CENTER, BOTTOM],
		yv = [FRONT, CENTER, BACK],
		xv = [LEFT, CENTER, RIGHT]
	) xv+yv+zv
];



// Module: anchor_arrow()
// Usage:
//   anchor_arrow([s], [color], [flag]);
// Description:
//   Show an anchor orientation arrow.
// Arguments:
//   s = Length of the arrows.
//   color = Color of the arrow.
//   flag = If true, draw the orientation flag on the arrowhead.
// Example:
//   anchor_arrow(s=20);
module anchor_arrow(s=10, color=[0.333,0.333,1], flag=true, $tags="anchor-arrow") {
	$fn=12;
	recolor("gray") spheroid(d=s/6)
	attach(CENTER,BOT) recolor(color) cyl(h=s*2/3, d=s/15, anchor=BOT)
	attach(TOP) cyl(h=s/3, d1=s/5, d2=0, anchor=BOT) {
		if(flag) {
			attach(BOTTOM) recolor([1,0.5,0.5]) cuboid([s/50, s/6, s/4], anchor=FRONT+TOP);
		}
		children();
	}
}



// Module: show_internal_anchors()
// Usage:
//   show_internal_anchors() ...
// Description:
//   Makes the children transparent gray, while showing any
//   anchor arrows that may exist.
// Example(FlatSpin):
//   show_internal_anchors() cube(50, center=true) show_anchors();
module show_internal_anchors(opacity=0.2) {
	show("anchor-arrow") children() show_anchors();
	hide("anchor-arrow") recolor(list_pad(point3d($color),4,fill=opacity)) children();
}


// Module: show_anchors()
// Description:
//   Show all standard anchors for the parent object.
// Arguments:
//   s = Length of anchor arrows.
//   std = If true (default), show standard anchors.
//   custom = If true (default), show custom anchors.
// Example(FlatSpin):
//   cube(50, center=true) show_anchors();
module show_anchors(s=10, std=true, custom=true) {
	if (std) {
		for (anchor=standard_anchors()) {
			attach(anchor) anchor_arrow(s);
		}
	}
	if (custom) {
		for (anchor=$parent_anchors) {
			attach(anchor[0]) {
				anchor_arrow(s, color="cyan");
				recolor("black")
				noop($tags="anchor-arrow") {
					xrot(90) {
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
// Description:
//   Displays X,Y,Z axis arrows in red, green, and blue respectively.
// Arguments:
//   s = Length of the arrows.
// Examples:
//   frame_ref(25);
module frame_ref(s=15) {
	cube(0.01, center=true) {
		attach(RIGHT) anchor_arrow(s=s, flag=false, color="red");
		attach(BACK)  anchor_arrow(s=s, flag=false, color="green");
		attach(TOP)   anchor_arrow(s=s, flag=false, color="blue");
		children();
	}
}


// Module: ruler()
// Description:
//   Creates a ruler for checking dimensions of the model
// Arguments:
//   length = length of the ruler.  Default 100
//   width = width of the ruler.  Default: size of the largest unit division
//   thickness = thickness of the ruler. Default: 1
//   depth = the depth of mark subdivisions. Default: 3
//   labels = draw numeric labels for depths where labels are larger than 1.  Default: false
//   pipscale = width scale of the pips relative to the next size up.  Default: 1/3
//   maxscale = log10 of the maximum width divisions to display.  Default: based on input length
//   colors = colors to use for the ruler, a list of two values.  Default: `["black","white"]`
//   alpha = transparency value.  Default: 1.0
//   unit = unit to mark.  Scales the ruler marks to a different length.  Default: 1
//   inch = set to true for a ruler scaled to inches (assuming base dimension is mm).  Default: false
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
module ruler(length=100, width=undef, thickness=1, depth=3, labels=false, pipscale=1/3, maxscale=undef, colors=["black","white"], alpha=1.0, unit=1, inch=false, anchor=ALLNEG, spin=0, orient=UP)
{
    inchfactor = 25.4;
    assert(depth<=5, "Cannot render scales smaller than depth=5");
    assert(len(colors)==2, "colors must contain a list of exactly two colors.");
    length = inch ? inchfactor * length : length;
    unit = inch ? inchfactor*unit : unit;
    maxscale = is_def(maxscale)? maxscale : floor(log(length/unit-EPSILON));
    scales = unit * [for(logsize = [maxscale:-1:maxscale-depth+1]) pow(10,logsize)];
    echo(scales=scales);
    widthfactor = (1-pipscale) / (1-pow(pipscale,depth));
    width = default(width, scales[0]);
    widths = width * widthfactor * [for(logsize = [0:-1:-depth+1]) pow(pipscale,-logsize)];
    offsets = concat([0],cumsum(widths));
    orient_and_anchor([length,width,thickness], anchor=anchor, spin=spin, orient=orient, chain=true) {
      translate([-length/2, -width/2, 0]) 
        for(i=[0:1:len(scales)-1]){
          count = ceil(length/scales[i]);
          fontsize = 0.5*min(widths[i], scales[i]/ceil(log(count*scales[i]/unit)));
          back(offsets[i])
            xspread(scales[i], n=count, sp=[0,0,0]) 
            union(){
              actlen = ($idx<count-1) || approx(length%scales[i],0) ? scales[i] : length % scales[i];
              color(colors[$idx%2], alpha=alpha) {
                w = i>0 ? quantup(widths[i],1/1024) : widths[i];    // What is the i>0 test supposed to do here? 
                cube([quantup(actlen,1/1024),quantup(w,1/1024),thickness], anchor=FRONT+LEFT);
              }
              mark = i == 0 && $idx % 10 == 0 && $idx != 0 ? 0 :
                     i == 0 && $idx % 10 == 9 && $idx != count-1 ? 1 :
                     $idx % 10 == 4 ? 1 :
                     $idx % 10 == 5 ? 0 :
                                      -1;
              flip = 1-mark*2;
              if (mark >= 0){
                marklength = min(widths[i]/2, scales[i]*2);
                markwidth = marklength*0.4;
                translate([mark*scales[i],widths[i]])
                  color(colors[1-$idx%2], alpha=alpha) 
                  linear_extrude(height=thickness+scales[i]/100, convexity=2, center=true)
                  polygon(scale([flip*markwidth, marklength],p=[[0,0], [1, -1], [0,-0.9]]));
              }
              if (labels && scales[i]/unit+EPSILON >= 1)
                color(colors[($idx+1)%2], alpha=alpha)
                  linear_extrude(height=thickness+scales[i]/100, convexity=2, center=true)
                  back(scales[i]*.02)
                  text(text=str( $idx * scales[i] / unit), size=fontsize, halign="left", valign="baseline");
            }
          }
        children();
    }
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
