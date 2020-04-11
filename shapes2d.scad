//////////////////////////////////////////////////////////////////////
// LibFile: shapes2d.scad
//   Common useful 2D shapes.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: 2D Drawing Helpers

// Module: stroke()
// Usage:
//   stroke(path, [width], [closed], [endcaps], [endcap_width], [endcap_length], [endcap_extent], [trim]);
//   stroke(path, [width], [closed], [endcap1], [endcap2], [endcap_width1], [endcap_width2], [endcap_length1], [endcap_length2], [endcap_extent1], [endcap_extent2], [trim1], [trim2]);
// Description:
//   Draws a 2D or 3D path with a given line width.  Endcaps can be specified for each end individually.
// Figure(2D,Big): Endcap Types
//   endcaps = [
//       ["butt", "square", "round", "chisel", "tail", "tail2"],
//       ["line", "cross", "dot", "diamond", "x", "arrow", "arrow2"]
//   ];
//   for (x=idx(endcaps), y=idx(endcaps[x])) {
//       cap = endcaps[x][y];
//       right(x*60-60+5) fwd(y*10+15) {
//           right(28) color("black") text(text=cap, size=5, halign="left", valign="center");
//           stroke([[0,0], [20,0]], width=3, endcap_width=3, endcap1=false, endcap2=cap);
//           color("black") stroke([[0,0], [20,0]], width=0.25, endcaps=false);
//       }
//   }
// Arguments:
//   path = The 2D path to draw along.
//   width = The width of the line to draw.  If given as a list of widths, (one for each path point), draws the line with varying thickness to each point.
//   closed = If true, draw an additional line from the end of the path to the start.
//   endcaps = Specifies the endcap type for both ends of the line.  If a 2D path is given, use that to draw custom endcaps.
//   endcap1 = Specifies the endcap type for the start of the line.  If a 2D path is given, use that to draw a custom endcap.
//   endcap2 = Specifies the endcap type for the end of the line.  If a 2D path is given, use that to draw a custom endcap.
//   endcap_width = Some endcap types are wider than the line.  This specifies the size of endcaps, in multiples of the line width.  Default: 3.5
//   endcap_width1 = This specifies the size of starting endcap, in multiples of the line width.  Default: 3.5
//   endcap_width2 = This specifies the size of ending endcap, in multiples of the line width.  Default: 3.5
//   endcap_length = Length of endcaps, in multiples of the line width.  Default: `endcap_width*0.5`
//   endcap_length1 = Length of starting endcap, in multiples of the line width.  Default: `endcap_width1*0.5`
//   endcap_length2 = Length of ending endcap, in multiples of the line width.  Default: `endcap_width2*0.5`
//   endcap_extent = Extents length of endcaps, in multiples of the line width.  Default: `endcap_width*0.5`
//   endcap_extent1 = Extents length of starting endcap, in multiples of the line width.  Default: `endcap_width1*0.5`
//   endcap_extent2 = Extents length of ending endcap, in multiples of the line width.  Default: `endcap_width2*0.5`
//   endcap_angle = Extra axial rotation given to flat endcaps for 3D paths, in degrees.  If not given, the endcaps are fully spun.  Default: `undef` (Fully spun cap)
//   endcap_angle1 = Extra axial rotation given to a flat starting endcap for 3D paths, in degrees.  If not given, the endcap is fully spun.  Default: `undef` (Fully spun cap)
//   endcap_angle2 = Extra axial rotation given to a flat ending endcap for 3D paths, in degrees.  If not given, the endcap is fully spun.  Default: `undef` (Fully spun cap)
//   trim = Trim the the start and end line segments by this much, to keep them from interfering with custom endcaps.
//   trim1 = Trim the the starting line segment by this much, to keep it from interfering with a custom endcap.
//   trim2 = Trim the the ending line segment by this much, to keep it from interfering with a custom endcap.
//   convexity = Max number of times a line could intersect a wall of an endcap.
// Example(2D): Drawing a Path
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=20);
// Example(2D): Closing a Path
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=20, endcaps=true, closed=true);
// Example(2D): Fancy Arrow Endcaps
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=10, endcaps="arrow2");
// Example(2D): Modified Fancy Arrow Endcaps
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=10, endcaps="arrow2", endcap_width=6, endcap_length=3, endcap_extent=2);
// Example(2D): Mixed Endcaps
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=10, endcap1="tail2", endcap2="arrow2");
// Example(2D): Custom Endcap Shapes
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   arrow = [[0,0], [2,-3], [0.5,-2.3], [2,-4], [0.5,-3.5], [-0.5,-3.5], [-2,-4], [-0.5,-2.3], [-2,-3]];
//   stroke(path, width=10, trim=3.5, endcaps=arrow);
// Example(2D): Variable Line Width
//   path = circle(d=50,$fn=18);
//   widths = [for (i=idx(path)) 10*i/len(path)+2];
//   stroke(path,width=widths,$fa=1,$fs=1);
// Example: 3D Path with Endcaps
//   path = rot([15,30,0], p=path3d(pentagon(d=50)));
//   stroke(path, width=2, endcaps="arrow2", $fn=18);
// Example: 3D Path with Flat Endcaps
//   path = rot([15,30,0], p=path3d(pentagon(d=50)));
//   stroke(path, width=2, endcaps="arrow2", endcap_angle=0, $fn=18);
// Example: 3D Path with Mixed Endcaps
//   path = rot([15,30,0], p=path3d(pentagon(d=50)));
//   stroke(path, width=2, endcap1="arrow2", endcap2="tail", endcap_angle2=0, $fn=18);
module stroke(
	path, width=1, closed=false,
	endcaps, endcap1, endcap2,
	trim, trim1, trim2,
	endcap_width, endcap_width1, endcap_width2,
	endcap_length, endcap_length1, endcap_length2,
	endcap_extent, endcap_extent1, endcap_extent2,
	endcap_angle, endcap_angle1, endcap_angle2,
	convexity=10
) {
	function _endcap_shape(cap,linewidth,w,l,l2) = (
		let(sq2=sqrt(2), l3=l-l2)
		(cap=="round" || cap==true)? circle(d=1, $fn=max(8, segs(w/2))) :
		cap=="chisel"? [[-0.5,0], [0,0.5], [0.5,0], [0,-0.5]] :
		cap=="square"? [[-0.5,-0.5], [-0.5,0.5], [0.5,0.5], [0.5,-0.5]] :
		cap=="diamond"? [[0,w/2], [w/2,0], [0,-w/2], [-w/2,0]] :
		cap=="dot"?    circle(d=3, $fn=max(12, segs(w*3/2))) :
		cap=="x"?      [for (a=[0:90:270]) each rot(a,p=[[w+sq2/2,w-sq2/2]/2, [w-sq2/2,w+sq2/2]/2, [0,sq2/2]]) ] :
		cap=="cross"?  [for (a=[0:90:270]) each rot(a,p=[[1,w]/2, [-1,w]/2, [-1,1]/2]) ] :
		cap=="line"?   [[w/2,0.5], [w/2,-0.5], [-w/2,-0.5], [-w/2,0.5]] :
		cap=="arrow"?  [[0,0], [w/2,-l2], [w/2,-l2-l], [0,-l], [-w/2,-l2-l], [-w/2,-l2]] :
		cap=="arrow2"? [[0,0], [w/2,-l2-l], [0,-l], [-w/2,-l2-l]] :
		cap=="tail"?   [[0,0], [w/2,l2], [w/2,l2-l], [0,-l], [-w/2,l2-l], [-w/2,l2]] :
		cap=="tail2"?  [[w/2,0], [w/2,-l], [0,-l-l2], [-w/2,-l], [-w/2,0]] :
		is_path(cap)? cap :
		[]
	) * linewidth;

	assert(is_bool(closed));
	assert(is_path(path,[2,3]), "The path argument must be a list of 2D or 3D points.");
	path = deduplicate( closed? close_path(path) : path );

	assert(is_num(width) || (is_vector(width) && len(width)==len(path)));
	width = is_num(width)? [for (x=path) width] : width;

	endcap1 = first_defined([endcap1, endcaps, "round"]);
	endcap2 = first_defined([endcap2, endcaps, "round"]);
	assert(is_bool(endcap1) || is_string(endcap1));
	assert(is_bool(endcap2) || is_string(endcap2));

	endcap_width1 = first_defined([endcap_width1, endcap_width, 3.5]);
	endcap_width2 = first_defined([endcap_width2, endcap_width, 3.5]);
	assert(is_num(endcap_width1));
	assert(is_num(endcap_width2));

	endcap_length1 = first_defined([endcap_length1, endcap_length, endcap_width1*0.5]);
	endcap_length2 = first_defined([endcap_length2, endcap_length, endcap_width2*0.5]);
	assert(is_num(endcap_length1));
	assert(is_num(endcap_length2));

	endcap_extent1 = first_defined([endcap_extent1, endcap_extent, endcap_width1*0.5]);
	endcap_extent2 = first_defined([endcap_extent2, endcap_extent, endcap_width2*0.5]);
	assert(is_num(endcap_extent1));
	assert(is_num(endcap_extent2));

	endcap_angle1 = first_defined([endcap_angle1, endcap_angle]);
	endcap_angle2 = first_defined([endcap_angle2, endcap_angle]);
	assert(is_undef(endcap_angle1)||is_num(endcap_angle1));
	assert(is_undef(endcap_angle2)||is_num(endcap_angle2));

	endcap_shape1 = _endcap_shape(endcap1, select(width,0), endcap_width1, endcap_length1, endcap_extent1);
	endcap_shape2 = _endcap_shape(endcap2, select(width,-1), endcap_width2, endcap_length2, endcap_extent2);

	segments = pair(path);

	trim1 = select(width,0) * first_defined([
		trim1, trim,
		(endcap1=="arrow")? endcap_length1-0.01 :
		(endcap1=="arrow2")? endcap_length1*3/4 :
		0
	]);
	assert(is_num(trim1));

	trim2 = select(width,-1) * first_defined([
		trim2, trim,
		(endcap2=="arrow")? endcap_length2-0.01 :
		(endcap2=="arrow2")? endcap_length2*3/4 :
		0
	]);
	assert(is_num(trim2));

	spos = path_pos_from_start(path,trim1,closed=false);
	epos = path_pos_from_end(path,trim2,closed=false);
	path2 = path_subselect(path, spos[0], spos[1], epos[0], epos[1]);
	widths = concat(
		[lerp(width[spos[0]], width[(spos[0]+1)%len(width)], spos[1])],
		[for (i = [spos[0]+1:1:epos[0]]) width[i]],
		[lerp(width[epos[0]], width[(epos[0]+1)%len(width)], epos[1])]
	);

	start_vec = select(path,0) - select(path,1);
	end_vec = select(path,-1) - select(path,-2);
	if (len(path[0]) == 2) {
		// Straight segments
		for (i = idx(path2,end=-2)) {
			seg = select(path2,i,i+1);
			delt = seg[1] - seg[0];
			translate(seg[0]) {
				rot(from=BACK,to=delt) {
					trapezoid(w1=widths[i], w2=widths[i+1], h=norm(delt), anchor=FRONT);
				}
			}
		}

		// Joints
		for (i = [1:1:len(path2)-2]) {
			$fn = quantup(segs(widths[i]/2),4);
			hull() {
				translate(path2[i]) {
					rot(from=BACK, to=path2[i]-path2[i-1])
						circle(d=widths[i]);
					rot(from=BACK, to=path2[i+1]-path2[i])
						circle(d=widths[i]);
				}
			}
		}

		// Endcap1
		translate(path[0]) {
			start_vec = select(path,0) - select(path,1);
			rot(from=BACK, to=start_vec) {
				polygon(endcap_shape1);
			}
		}

		// Endcap2
		translate(select(path,-1)) {
			rot(from=BACK, to=end_vec) {
				polygon(endcap_shape2);
			}
		}
	} else {
		// Straight segments
		for (i = idx(path2,end=-2)) {
			seg = select(path2,i,i+1);
			delt = seg[1] - seg[0];
			translate(seg[0]) {
				rot(from=UP,to=delt) {
					cylinder(r1=widths[i]/2, r2=widths[i+1]/2, h=norm(delt), center=false);
				}
			}
		}

		// Joints
		for (i = [1:1:len(path2)-2]) {
			$fn = quantup(segs(widths[i]/2),4);
			translate(path2[i]) {
				rot(from=UP, to=path2[i]-path2[i-1]) {
					sphere(d=widths[i]);
				}
			}
		}

		// Endcap1
		translate(path[0]) {
			rot(from=UP, to=start_vec) {
				if (is_undef(endcap_angle1)) {
					rotate_extrude(convexity=convexity) {
						right_half(planar=true) {
							polygon(endcap_shape1);
						}
					}
				} else {
					rotate([90,0,endcap_angle1]) {
						linear_extrude(height=widths[0], center=true, convexity=convexity) {
							polygon(endcap_shape1);
						}
					}
				}
			}
		}

		// Endcap2
		translate(select(path,-1)) {
			rot(from=UP, to=end_vec) {
				if (is_undef(endcap_angle2)) {
					rotate_extrude(convexity=convexity) {
						right_half(planar=true) {
							polygon(endcap_shape2);
						}
					}
				} else {
					rotate([90,0,endcap_angle2]) {
						linear_extrude(height=select(widths,-1), center=true, convexity=convexity) {
							polygon(endcap_shape2);
						}
					}
				}
			}
		}
	}
}


// Function&Module: arc()
// Usage: 2D arc from 0º to `angle` degrees.
//   arc(N, r|d, angle);
// Usage: 2D arc from START to END degrees.
//   arc(N, r|d, angle=[START,END])
// Usage: 2D arc from `start` to `start+angle` degrees.
//   arc(N, r|d, start, angle)
// Usage: 2D circle segment by `width` and `thickness`, starting and ending on the X axis.
//   arc(N, width, thickness)
// Usage: Shortest 2D or 3D arc around centerpoint `cp`, starting at P0 and ending on the vector pointing from `cp` to `P1`.
//   arc(N, cp, points=[P0,P1])
// Usage: 2D or 3D arc, starting at `P0`, passing through `P1` and ending at `P2`.
//   arc(N, points=[P0,P1,P2])
// Description:
//   If called as a function, returns a 2D or 3D path forming an arc.
//   If called as a module, creates a 2D arc polygon or pie slice shape.
// Arguments:
//   N = Number of vertices to form the arc curve from.
//   r = Radius of the arc.
//   d = Diameter of the arc.
//   angle = If a scalar, specifies the end angle in degrees.  If a vector of two scalars, specifies start and end angles.
//   cp = Centerpoint of arc.
//   points = Points on the arc.
//   width = If given with `thickness`, arc starts and ends on X axis, to make a circle segment.
//   thickness = If given with `width`, arc starts and ends on X axis, to make a circle segment.
//   start = Start angle of arc.
//   wedge = If true, include centerpoint `cp` in output to form pie slice shape.
// Examples(2D):
//   arc(N=4, r=30, angle=30, wedge=true);
//   arc(r=30, angle=30, wedge=true);
//   arc(d=60, angle=30, wedge=true);
//   arc(d=60, angle=120);
//   arc(d=60, angle=120, wedge=true);
//   arc(r=30, angle=[75,135], wedge=true);
//   arc(r=30, start=45, angle=75, wedge=true);
//   arc(width=60, thickness=20);
//   arc(cp=[-10,5], points=[[20,10],[0,35]], wedge=true);
//   arc(points=[[30,-5],[20,10],[-10,20]], wedge=true);
//   arc(points=[[5,30],[-10,-10],[30,5]], wedge=true);
// Example(2D):
//   path = arc(points=[[5,30],[-10,-10],[30,5]], wedge=true);
//   stroke(closed=true, path);
// Example(FlatSpin):
//   path = arc(points=[[0,30,0],[0,0,30],[30,0,0]]);
//   trace_polyline(path, showpts=true, color="cyan");
function arc(N, r, angle, d, cp, points, width, thickness, start, wedge=false) =
	// First try for 2D arc specified by angles
	is_def(width) && is_def(thickness)? (
		arc(N,points=[[width/2,0], [0,thickness], [-width/2,0]],wedge=wedge)
	) : is_def(angle)? (
		let(
			parmok = is_undef(points) && is_undef(width) && is_undef(thickness) &&
				((is_vector(angle) && len(angle)==2 && is_undef(start)) || is_num(angle))
		)
		assert(parmok,"Invalid parameters in arc")
		let(
			cp = is_def(cp) ? cp : [0,0],
			start = is_def(start)? start : is_vector(angle) ? angle[0] : 0,
			angle = is_vector(angle)? angle[1]-angle[0] : angle,
			r = get_radius(r=r, d=d),
			N = max(3, is_undef(N)? ceil(segs(r)*abs(angle)/360) : N),
			arcpoints = [for(i=[0:N-1]) let(theta = start + i*angle/(N-1)) r*[cos(theta),sin(theta)]+cp],
			extra = wedge? [cp] : []
		)
		concat(extra,arcpoints)
	) :
	assert(is_list(points),"Invalid parameters")
	// Arc is 3D, so transform points to 2D and make a recursive call, then remap back to 3D
	len(points[0])==3? (
		let(
			thirdpoint = is_def(cp) ? cp : points[2],
			center2d = is_def(cp) ? project_plane(cp,thirdpoint,points[0],points[1]) : undef,
			points2d = project_plane(points,thirdpoint,points[0],points[1])
		)
		lift_plane(arc(N,cp=center2d,points=points2d,wedge=wedge),thirdpoint,points[0],points[1])
	) : is_def(cp)? (
		// Arc defined by center plus two points, will have radius defined by center and points[0]
		// and extent defined by direction of point[1] from the center
		let(
			angle = vector_angle(points[0], cp, points[1]),
			v1 = points[0]-cp,
			v2 = points[1]-cp,
			dir = sign(det2([v1,v2])),   // z component of cross product
			r=norm(v1)
		)
		assert(dir!=0,"Collinear inputs don't define a unique arc")
		arc(N,cp=cp,r=r,start=atan2(v1.y,v1.x),angle=dir*angle,wedge=wedge)
	) : (
		// Final case is arc passing through three points, starting at point[0] and ending at point[3]
		let(col = collinear(points[0],points[1],points[2]))
		assert(!col, "Collinear inputs do not define an arc")
		let(
			cp = line_intersection(_normal_segment(points[0],points[1]),_normal_segment(points[1],points[2])),
			// select order to be counterclockwise
			dir = det2([points[1]-points[0],points[2]-points[1]]) > 0,
			points = dir? select(points,[0,2]) : select(points,[2,0]),
			r = norm(points[0]-cp),
			theta_start = atan2(points[0].y-cp.y, points[0].x-cp.x),
			theta_end = atan2(points[1].y-cp.y, points[1].x-cp.x),
			angle = posmod(theta_end-theta_start, 360),
			arcpts = arc(N,cp=cp,r=r,start=theta_start,angle=angle,wedge=wedge)
		)
		dir ? arcpts : reverse(arcpts)
	);


module arc(N, r, angle, d, cp, points, width, thickness, start, wedge=false)
{
	path = arc(N=N, r=r, angle=angle, d=d, cp=cp, points=points, width=width, thickness=thickness, start=start, wedge=wedge);
	polygon(path);
}


function _normal_segment(p1,p2) =
	let(center = (p1+p2)/2)
	[center, center + norm(p1-p2)/2 * line_normal(p1,p2)];


// Function: turtle()
// Usage:
//   turtle(commands, [state], [return_state])
// Description:
//   Use a sequence of turtle graphics commands to generate a path.  The parameter `commands` is a list of
//   turtle commands and optional parameters for each command.  The turtle state has a position, movement direction,
//   movement distance, and default turn angle.  If you do not give `state` as input then the turtle starts at the
//   origin, pointed along the positive x axis with a movement distance of 1.  By default, `turtle` returns just
//   the computed turtle path.  If you set `full_state` to true then it instead returns the full turtle state.
//   You can invoke `turtle` again with this full state to continue the turtle path where you left off.
//   
//   The turtle state is a list with three entries: the path constructed so far, the current step as a 2-vector, and the current default angle.
//   
//   For the list below, `dist` is the current movement distance.
//   
//   Commands     | Arguments          | What it does
//   ------------ | ------------------ | -------------------------------
//   "move"       | [dist]             | Move turtle scale*dist units in the turtle direction.  Default dist=1.  
//   "xmove"      | [dist]             | Move turtle scale*dist units in the x direction. Default dist=1.  Does not change turtle direction.
//   "ymove"      | [dist]             | Move turtle scale*dist units in the y direction. Default dist=1.  Does not change turtle direction.
//   "xymove"     | vector             | Move turtle by the specified vector.  Does not change turtle direction. 
//   "untilx"     | xtarget            | Move turtle in turtle direction until x==xtarget.  Produces an error if xtarget is not reachable.
//   "untily"     | ytarget            | Move turtle in turtle direction until y==ytarget.  Produces an error if xtarget is not reachable.
//   "jump"       | point              | Move the turtle to the specified point
//   "xjump"      | x                  | Move the turtle's x position to the specified value
//   "yjump       | y                  | Move the turtle's y position to the specified value
//   "turn"       | [angle]            | Turn turtle direction by specified angle, or the turtle's default turn angle.  The default angle starts at 90.
//   "left"       | [angle]            | Same as "turn"
//   "right"      | [angle]            | Same as "turn", -angle
//   "angle"      | angle              | Set the default turn angle.
//   "setdir"     | dir                | Set turtle direction.  The parameter `dir` can be an angle or a vector.
//   "length"     | length             | Change the turtle move distance to `length`
//   "scale"      | factor             | Multiply turtle move distance by `factor`
//   "addlength"  | length             | Add `length` to the turtle move distance
//   "repeat"     | count, commands    | Repeats a list of commands `count` times.
//   "arcleft"    | radius, [angle]    | Draw an arc from the current position toward the left at the specified radius and angle.  The turtle turns by `angle`.  A negative angle draws the arc to the right instead of the left, and leaves the turtle facing right.  A negative radius draws the arc to the right but leaves the turtle facing left.  
//   "arcright"   | radius, [angle]    | Draw an arc from the current position toward the right at the specified radius and angle
//   "arcleftto"  | radius, angle      | Draw an arc at the given radius turning toward the left until reaching the specified absolute angle.  
//   "arcrightto" | radius, angle      | Draw an arc at the given radius turning toward the right until reaching the specified absolute angle.  
//   "arcsteps"   | count              | Specifies the number of segments to use for drawing arcs.  If you set it to zero then the standard `$fn`, `$fa` and `$fs` variables define the number of segments.  
//
// Arguments:
//   commands = list of turtle commands
//   state = starting turtle state (from previous call) or starting point.  Default: start at the origin
//   full_state = if true return the full turtle state for continuing the path in subsequent turtle calls.  Default: false
//   repeat = number of times to repeat the command list.  Default: 1
//
// Example(2D): Simple rectangle
//   path = turtle(["xmove",3, "ymove", "xmove",-3, "ymove",-1]);
//   stroke(path,width=.1);
// Example(2D): Pentagon
//   path=turtle(["angle",360/5,"move","turn","move","turn","move","turn","move"]);
//   stroke(path,width=.1,closed=true);
// Example(2D): Pentagon using the repeat argument
//   path=turtle(["move","turn",360/5],repeat=5);
//   stroke(path,width=.1,closed=true);
// Example(2D): Pentagon using the repeat turtle command, setting the turn angle
//   path=turtle(["angle",360/5,"repeat",5,["move","turn"]]);
//   stroke(path,width=.1,closed=true);
// Example(2D): Pentagram
//   path = turtle(["move","left",144], repeat=4);
//   stroke(path,width=.05,closed=true);
// Example(2D): Sawtooth path
//   path = turtle([
//       "turn", 55,
//       "untily", 2,
//       "turn", -55-90,
//       "untily", 0,
//       "turn", 55+90,
//       "untily", 2.5,
//       "turn", -55-90,
//       "untily", 0,
//       "turn", 55+90,
//       "untily", 3,
//       "turn", -55-90,
//       "untily", 0
//   ]);
//   stroke(path, width=.1);
// Example(2D): Simpler way to draw the sawtooth.  The direction of the turtle is preserved when executing "yjump".
//   path = turtle([
//       "turn", 55,
//       "untily", 2,
//       "yjump", 0,
//       "untily", 2.5,
//       "yjump", 0,
//       "untily", 3,
//       "yjump", 0,
//   ]);
//   stroke(path, width=.1);
// Example(2DMed): square spiral
//   path = turtle(["move","left","addlength",1],repeat=50);
//   stroke(path,width=.2);
// Example(2DMed): pentagonal spiral
//   path = turtle(["move","left",360/5,"addlength",1],repeat=50);
//   stroke(path,width=.2);
// Example(2DMed): yet another spiral, without using `repeat`
//   path = turtle(concat(["angle",71],flatten(repeat(["move","left","addlength",1],50))));
//   stroke(path,width=.2);
// Example(2DMed): The previous spiral grows linearly and eventually intersects itself.  This one grows geometrically and does not.
//   path = turtle(["move","left",71,"scale",1.05],repeat=50);
//   stroke(path,width=.05);
// Example(2D): Koch Snowflake
//   function koch_unit(depth) =
//       depth==0 ? ["move"] :
//       concat(
//           koch_unit(depth-1),
//           ["right"],
//           koch_unit(depth-1),
//           ["left","left"],
//           koch_unit(depth-1),
//           ["right"],
//           koch_unit(depth-1)
//       );
//   koch=concat(["angle",60,"repeat",3],[concat(koch_unit(3),["left","left"])]);
//   polygon(turtle(koch));
function turtle(commands, state=[[[0,0]],[1,0],90,0], full_state=false, repeat=1) =
	let( state = is_vector(state) ? [[state],[1,0],90,0] : state )
		repeat == 1?
			_turtle(commands,state,full_state) :
			_turtle_repeat(commands, state, full_state, repeat);

function _turtle_repeat(commands, state, full_state, repeat) =
	repeat==1?
		_turtle(commands,state,full_state) :
		_turtle_repeat(commands, _turtle(commands, state, true), full_state, repeat-1);

function _turtle_command_len(commands, index) =
	let( one_or_two_arg = ["arcleft","arcright", "arcleftto", "arcrightto"] )
	commands[index] == "repeat"? 3 :   // Repeat command requires 2 args
	// For these, the first arg is required, second arg is present if it is not a string
	in_list(commands[index], one_or_two_arg) && len(commands)>index+2 && !is_string(commands[index+2]) ? 3 :  
	is_string(commands[index+1])? 1 :  // If 2nd item is a string it's must be a new command
	2;                                 // Otherwise we have command and arg

function _turtle(commands, state, full_state, index=0) =
	index < len(commands) ?
	_turtle(commands,
			_turtle_command(commands[index],commands[index+1],commands[index+2],state,index),
			full_state,
			index+_turtle_command_len(commands,index)
		) :
		( full_state ? state : state[0] );

// Turtle state: state = [path, step_vector, default angle]

function _turtle_command(command, parm, parm2, state, index) =
	command == "repeat"?
		assert(is_num(parm),str("\"repeat\" command requires a numeric repeat count at index ",index))
		assert(is_list(parm2),str("\"repeat\" command requires a command list parameter at index ",index))
		_turtle_repeat(parm2, state, true, parm) :
	let(
		path = 0,
		step=1,
		angle=2,
		arcsteps=3,
		parm = !is_string(parm) ? parm : undef,
		parm2 = !is_string(parm2) ? parm2 : undef,
		needvec = ["jump", "xymove"],
		neednum = ["untilx","untily","xjump","yjump","angle","length","scale","addlength"],
		needeither = ["setdir"],
		chvec = !in_list(command,needvec) || is_vector(parm,2),
		chnum = !in_list(command,neednum) || is_num(parm),
		vec_or_num = !in_list(command,needeither) || (is_num(parm) || is_vector(parm,2)),
		lastpt = select(state[path],-1)
	)
	assert(chvec,str("\"",command,"\" requires a vector parameter at index ",index))
	assert(chnum,str("\"",command,"\" requires a numeric parameter at index ",index))
	assert(vec_or_num,str("\"",command,"\" requires a vector or numeric parameter at index ",index))

	command=="move" ? list_set(state, path, concat(state[path],[default(parm,1)*state[step]+lastpt])) :
	command=="untilx" ? (
		let(
			int = line_intersection([lastpt,lastpt+state[step]], [[parm,0],[parm,1]]),
			xgood = sign(state[step].x) == sign(int.x-lastpt.x)
		)
		assert(xgood,str("\"untilx\" never reaches desired goal at index ",index))
		list_set(state,path,concat(state[path],[int]))
	) :
	command=="untily" ? (
		let(
			int = line_intersection([lastpt,lastpt+state[step]], [[0,parm],[1,parm]]),
			ygood = is_def(int) && sign(state[step].y) == sign(int.y-lastpt.y)
		)
		assert(ygood,str("\"untily\" never reaches desired goal at index ",index))
		list_set(state,path,concat(state[path],[int]))
	) :
	command=="xmove" ? list_set(state, path, concat(state[path],[default(parm,1)*norm(state[step])*[1,0]+lastpt])):
	command=="ymove" ? list_set(state, path, concat(state[path],[default(parm,1)*norm(state[step])*[0,1]+lastpt])):
        command=="xymove" ? list_set(state, path, concat(state[path], [lastpt+parm])):
	command=="jump" ?  list_set(state, path, concat(state[path],[parm])):
	command=="xjump" ? list_set(state, path, concat(state[path],[[parm,lastpt.y]])):
	command=="yjump" ? list_set(state, path, concat(state[path],[[lastpt.x,parm]])):
	command=="turn" || command=="left" ? list_set(state, step, rot(default(parm,state[angle]),p=state[step],planar=true)) :
	command=="right" ? list_set(state, step, rot(-default(parm,state[angle]),p=state[step],planar=true)) :
	command=="angle" ? list_set(state, angle, parm) :
	command=="setdir" ? (
		is_vector(parm) ?
			list_set(state, step, norm(state[step]) * unit(parm)) :
			list_set(state, step, norm(state[step]) * [cos(parm),sin(parm)])
	) :
	command=="length" ? list_set(state, step, parm*unit(state[step])) :
	command=="scale" ?  list_set(state, step, parm*state[step]) :
	command=="addlength" ?  list_set(state, step, state[step]+unit(state[step])*parm) :
	command=="arcsteps" ? list_set(state, arcsteps, parm) :
	command=="arcleft" || command=="arcright" ?
		assert(is_num(parm),str("\"",command,"\" command requires a numeric radius value at index ",index))  
		let(
			myangle = default(parm2,state[angle]),
			lrsign = command=="arcleft" ? 1 : -1,
			radius = parm*sign(myangle),
			center = lastpt + lrsign*radius*line_normal([0,0],state[step]),
			steps = state[arcsteps]==0 ? segs(abs(radius)) : state[arcsteps], 
			arcpath = myangle == 0 || radius == 0 ? [] : arc(
				steps,
				points = [
					lastpt,
					rot(cp=center, p=lastpt, a=sign(parm)*lrsign*myangle/2),
					rot(cp=center, p=lastpt, a=sign(parm)*lrsign*myangle)
				]
			)
		)
		list_set(
			state, [path,step], [
				concat(state[path], slice(arcpath,1,-1)),
				rot(lrsign * myangle,p=state[step],planar=true)
			]
		) :
	command=="arcleftto" || command=="arcrightto" ?
		assert(is_num(parm),str("\"",command,"\" command requires a numeric radius value at index ",index))
		assert(is_num(parm2),str("\"",command,"\" command requires a numeric angle value at index ",index))
		let(
			radius = parm,
			lrsign = command=="arcleftto" ? 1 : -1,
			center = lastpt + lrsign*radius*line_normal([0,0],state[step]),
			steps = state[arcsteps]==0 ? segs(abs(radius)) : state[arcsteps],
			start_angle = posmod(atan2(state[step].y, state[step].x),360),
			end_angle = posmod(parm2,360),
			delta_angle =  -start_angle + (lrsign * end_angle < lrsign*start_angle ? end_angle+lrsign*360 : end_angle),
			arcpath = delta_angle == 0 || radius==0 ? [] : arc(
				steps,
				points = [
					lastpt,
					rot(cp=center, p=lastpt, a=sign(radius)*delta_angle/2),
					rot(cp=center, p=lastpt, a=sign(radius)*delta_angle)
				]
			)
		)
		list_set(
			state, [path,step], [
				concat(state[path], slice(arcpath,1,-1)),
				rot(delta_angle,p=state[step],planar=true)
			]
		) :
	assert(false,str("Unknown turtle command \"",command,"\" at index",index))
	[];



// Section: 2D N-Gons

// Function&Module: regular_ngon()
// Usage:
//   regular_ngon(n, r|d|or|od, [realign]);
//   regular_ngon(n, ir|id, [realign]);
//   regular_ngon(n, side, [realign]);
// Description:
//   When called as a function, returns a 2D path for a regular N-sided polygon.
//   When called as a module, creates a 2D regular N-sided polygon.
// Arguments:
//   n = The number of sides.
//   or = Outside radius, at points.
//   r = Same as or
//   od = Outside diameter, at points.
//   d = Same as od
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): by Outer Size
//   regular_ngon(n=5, or=30);
//   regular_ngon(n=5, od=60);
// Example(2D): by Inner Size
//   regular_ngon(n=5, ir=30);
//   regular_ngon(n=5, id=60);
// Example(2D): by Side Length
//   regular_ngon(n=8, side=20);
// Example(2D): Realigned
//   regular_ngon(n=8, side=20, realign=true);
// Example(2D): Rounded
//   regular_ngon(n=5, od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, regular_ngon(n=6, or=30));
function regular_ngon(n=6, r, d, or, od, ir, id, side, rounding=0, realign=false, anchor=CENTER, spin=0) =
	let(
		sc = 1/cos(180/n),
		r = get_radius(r1=ir*sc, r2=or, r=r, d1=id*sc, d2=od, d=d, dflt=side/2/sin(180/n))
	)
	assert(!is_undef(r), "regular_ngon(): need to specify one of r, d, or, od, ir, id, side.")
	let(
		path = rounding==0? circle(r=r, realign=realign, spin=90, $fn=n) :
			let(
				steps = floor(segs(r)/n),
				step = 360/n/steps
			) [
				for (i=[0:1:n-1], j=[0:1:steps]) let(
					a = 90 - (realign? 180/n : 0) - i*360/n,
					b = a + 180/n - j*step
				)
				(r-rounding*sc)*[cos(a),sin(a)] +
				rounding*[cos(b),sin(b)]
			]
	) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


module regular_ngon(n=6, r, d, or, od, ir, id, side, rounding=0, realign=false, anchor=CENTER, spin=0) {
	sc = 1/cos(180/n);
	r = get_radius(r1=ir*sc, r2=or, r=r, d1=id*sc, d2=od, d=d, dflt=side/2/sin(180/n));
	assert(!is_undef(r), "regular_ngon(): need to specify one of r, d, or, od, ir, id, side.");
	path = regular_ngon(n=n, r=r, rounding=rounding, realign=realign);
	attachable(anchor,spin, two_d=true, path=path, extent=false) {
		polygon(path);
		children();
	}
}


// Function&Module: pentagon()
// Usage:
//   pentagon(or|od, [realign]);
//   pentagon(ir|id, [realign]);
//   pentagon(side, [realign]);
// Description:
//   When called as a function, returns a 2D path for a regular pentagon.
//   When called as a module, creates a 2D regular pentagon.
// Arguments:
//   or = Outside radius, at points.
//   r = Same as or.
//   od = Outside diameter, at points.
//   d = Same as od.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): by Outer Size
//   pentagon(or=30);
//   pentagon(od=60);
// Example(2D): by Inner Size
//   pentagon(ir=30);
//   pentagon(id=60);
// Example(2D): by Side Length
//   pentagon(side=20);
// Example(2D): Realigned
//   pentagon(side=20, realign=true);
// Example(2D): Rounded
//   pentagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, pentagon(or=30));
function pentagon(r, d, or, od, ir, id, side, rounding=0, realign=false, anchor=CENTER, spin=0) =
	regular_ngon(n=5, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, anchor=anchor, spin=spin);


module pentagon(r, d, or, od, ir, id, side, rounding=0, realign=false, anchor=CENTER, spin=0)
	regular_ngon(n=5, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, anchor=anchor, spin=spin) children();


// Function&Module: hexagon()
// Usage:
//   hexagon(or, od, ir, id, side);
// Description:
//   When called as a function, returns a 2D path for a regular hexagon.
//   When called as a module, creates a 2D regular hexagon.
// Arguments:
//   or = Outside radius, at points.
//   r = Same as or
//   od = Outside diameter, at points.
//   d = Same as od
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): by Outer Size
//   hexagon(or=30);
//   hexagon(od=60);
// Example(2D): by Inner Size
//   hexagon(ir=30);
//   hexagon(id=60);
// Example(2D): by Side Length
//   hexagon(side=20);
// Example(2D): Realigned
//   hexagon(side=20, realign=true);
// Example(2D): Rounded
//   hexagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, hexagon(or=30));
function hexagon(r, d, or, od, ir, id, side, rounding=0, realign=false, anchor=CENTER, spin=0) =
	regular_ngon(n=6, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, anchor=anchor, spin=spin);


module hexagon(r, d, or, od, ir, id, side, rounding=0, realign=false, anchor=CENTER, spin=0)
	regular_ngon(n=6, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, anchor=anchor, spin=spin) children();


// Function&Module: octagon()
// Usage:
//   octagon(or, od, ir, id, side);
// Description:
//   When called as a function, returns a 2D path for a regular octagon.
//   When called as a module, creates a 2D regular octagon.
// Arguments:
//   or = Outside radius, at points.
//   r = Same as or
//   od = Outside diameter, at points.
//   d = Same as od
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): by Outer Size
//   octagon(or=30);
//   octagon(od=60);
// Example(2D): by Inner Size
//   octagon(ir=30);
//   octagon(id=60);
// Example(2D): by Side Length
//   octagon(side=20);
// Example(2D): Realigned
//   octagon(side=20, realign=true);
// Example(2D): Rounded
//   octagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, octagon(or=30));
function octagon(r, d, or, od, ir, id, side, rounding=0, realign=false, anchor=CENTER, spin=0) =
	regular_ngon(n=8, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, anchor=anchor, spin=spin);


module octagon(r, d, or, od, ir, id, side, rounding=0, realign=false, anchor=CENTER, spin=0)
	regular_ngon(n=8, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, anchor=anchor, spin=spin) children();



// Section: Other 2D Shapes


// Function&Module: trapezoid()
// Usage:
//   trapezoid(h, w1, w2);
// Description:
//   When called as a function, returns a 2D path for a trapezoid with parallel front and back sides.
//   When called as a module, creates a 2D trapezoid with parallel front and back sides.
// Arguments:
//   h = The Y axis height of the trapezoid.
//   w1 = The X axis width of the front end of the trapezoid.
//   w2 = The X axis width of the back end of the trapezoid.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Examples(2D):
//   trapezoid(h=30, w1=40, w2=20);
//   trapezoid(h=25, w1=20, w2=35);
//   trapezoid(h=20, w1=40, w2=0);
// Example(2D): Called as Function
//   stroke(closed=true, trapezoid(h=30, w1=40, w2=20));
function trapezoid(h, w1, w2, anchor=CENTER, spin=0) =
	let(
		path = [[w1/2,-h/2], [-w1/2,-h/2], [-w2/2,h/2], [w2/2,h/2]]
	) reorient(anchor,spin, two_d=true, size=[w1,h], size2=w2, p=path);



module trapezoid(h, w1, w2, anchor=CENTER, spin=0) {
	path = [[w1/2,-h/2], [-w1/2,-h/2], [-w2/2,h/2], [w2/2,h/2]];
	attachable(anchor,spin, two_d=true, size=[w1,h], size2=w2) {
		polygon(path);
		children();
	}
}


// Function&Module: teardrop2d()
//
// Description:
//   Makes a 2D teardrop shape. Useful for extruding into 3D printable holes.
//
// Usage:
//   teardrop2d(r|d, [ang], [cap_h]);
//
// Arguments:
//   r = radius of circular part of teardrop.  (Default: 1)
//   d = diameter of spherical portion of bottom. (Use instead of r)
//   ang = angle of hat walls from the Y axis.  (Default: 45 degrees)
//   cap_h = if given, height above center where the shape will be truncated.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//
// Example(2D): Typical Shape
//   teardrop2d(r=30, ang=30);
// Example(2D): Crop Cap
//   teardrop2d(r=30, ang=30, cap_h=40);
// Example(2D): Close Crop
//   teardrop2d(r=30, ang=30, cap_h=20);
module teardrop2d(r, d, ang=45, cap_h, anchor=CENTER, spin=0)
{
	path = teardrop2d(r=r, d=d, ang=ang, cap_h=cap_h);
	attachable(anchor,spin, two_d=true, path=path) {
		polygon(path);
		children();
	}
}


function teardrop2d(r, d, ang=45, cap_h, anchor=CENTER, spin=0) =
	let(
		r = get_radius(r=r, d=d, dflt=1),
		cord = 2 * r * cos(ang),
		cord_h = r * sin(ang),
		tip_y = (cord/2)/tan(ang),
		cap_h = min((!is_undef(cap_h)? cap_h : tip_y+cord_h), tip_y+cord_h),
		cap_w = cord * (1 - (cap_h - cord_h)/tip_y),
		ang = min(ang,asin(cap_h/r)),
		sa = 180 - ang,
		ea = 360 + ang,
		steps = segs(r)*(ea-sa)/360,
		step = (ea-sa)/steps,
		path = deduplicate(
			[
				[ cap_w/2,cap_h],
				for (i=[0:1:steps]) let(a=ea-i*step) r*[cos(a),sin(a)],
				[-cap_w/2,cap_h]
			], closed=true
		)
	) reorient(anchor,spin, two_d=true, path=path, p=path);



// Function&Module: glued_circles()
// Usage:
//   glued_circles(r|d, spread, tangent);
// Description:
//   When called as a function, returns a 2D path forming a shape of two circles joined by curved waist.
//   When called as a module, creates a 2D shape of two circles joined by curved waist.
// Arguments:
//   r = The radius of the end circles.
//   d = The diameter of the end circles.
//   spread = The distance between the centers of the end circles.
//   tangent = The angle in degrees of the tangent point for the joining arcs, measured away from the Y axis.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Examples(2D):
//   glued_circles(r=15, spread=40, tangent=45);
//   glued_circles(d=30, spread=30, tangent=30);
//   glued_circles(d=30, spread=30, tangent=15);
//   glued_circles(d=30, spread=30, tangent=-30);
// Example(2D): Called as Function
//   stroke(closed=true, glued_circles(r=15, spread=40, tangent=45));
function glued_circles(r, d, spread=10, tangent=30, anchor=CENTER, spin=0) =
	let(
		r = get_radius(r=r, d=d, dflt=10),
		r2 = (spread/2 / sin(tangent)) - r,
		cp1 = [spread/2, 0],
		cp2 = [0, (r+r2)*cos(tangent)],
		sa1 = 90-tangent,
		ea1 = 270+tangent,
		lobearc = ea1-sa1,
		lobesegs = floor(segs(r)*lobearc/360),
		lobestep = lobearc / lobesegs,
		sa2 = 270-tangent,
		ea2 = 270+tangent,
		subarc = ea2-sa2,
		arcsegs = ceil(segs(r2)*abs(subarc)/360),
		arcstep = subarc / arcsegs,
		path = concat(
			[for (i=[0:1:lobesegs]) let(a=sa1+i*lobestep)     r  * [cos(a),sin(a)] - cp1],
			tangent==0? [] : [for (i=[0:1:arcsegs])  let(a=ea2-i*arcstep+180)  r2 * [cos(a),sin(a)] - cp2],
			[for (i=[0:1:lobesegs]) let(a=sa1+i*lobestep+180) r  * [cos(a),sin(a)] + cp1],
			tangent==0? [] : [for (i=[0:1:arcsegs])  let(a=ea2-i*arcstep)      r2 * [cos(a),sin(a)] + cp2]
		)
	) reorient(anchor,spin, two_d=true, path=path, extent=true, p=path);


module glued_circles(r, d, spread=10, tangent=30, anchor=CENTER, spin=0) {
	path = glued_circles(r=r, d=d, spread=spread, tangent=tangent);
	attachable(anchor,spin, two_d=true, path=path, extent=true) {
		polygon(path);
		children();
	}
}


// Function&Module: star()
// Usage:
//   star(n, r|d|or|od, ir|id|step, [realign]);
// Description:
//   When called as a function, returns the path needed to create a star polygon with N points.
//   When called as a module, creates a star polygon with N points.
// Arguments:
//   n = The number of stellate tips on the star.
//   r = The radius to the tips of the star.
//   or = Same as r
//   d = The diameter to the tips of the star.
//   od = Same as d
//   ir = The radius to the inner corners of the star.
//   id = The diameter to the inner corners of the star.
//   step = Calculates the radius of the inner star corners by virtually drawing a straight line `step` tips around the star.  2 <= step < n/2
//   realign = If false, a tip is aligned with the Y+ axis.  If true, an inner corner is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Examples(2D):
//   star(n=5, r=50, ir=25);
//   star(n=5, r=50, step=2);
//   star(n=7, r=50, step=2);
//   star(n=7, r=50, step=3);
// Example(2D): Realigned
//   star(n=7, r=50, step=3, realign=true);
// Example(2D): Called as Function
//   stroke(closed=true, star(n=5, r=50, ir=25));
function star(n, r, d, or, od, ir, id, step, realign=false, anchor=CENTER, spin=0) =
	let(
		r = get_radius(r1=or, d1=od, r=r, d=d),
		count = num_defined([ir,id,step]),
		stepOK = is_undef(step) || (step>1 && step<n/2)
	)
	assert(is_def(n), "Must specify number of points, n")
	assert(count==1, "Must specify exactly one of ir, id, step")
	assert(stepOK, str("Parameter 'step' must be between 2 and ",floor(n/2)," for ",n," point star"))
	let(
		stepr = is_undef(step)? r : r*cos(180*step/n)/cos(180*(step-1)/n),
		ir = get_radius(r=ir, d=id, dflt=stepr),
		offset = 90+(realign? 180/n : 0),
		path = [for(i=[0:1:2*n-1]) let(theta=180*i/n+offset, radius=(i%2)?ir:r) radius*[cos(theta), sin(theta)]]
	) reorient(anchor,spin, two_d=true, path=path, p=path);


module star(n, r, d, or, od, ir, id, step, realign=false, anchor=CENTER, spin=0) {
	path = star(n=n, r=r, d=d, od=od, or=or, ir=ir, id=id, step=step, realign=realign);
	attachable(anchor,spin, two_d=true, path=path) {
		polygon(path);
		children();
	}
}


function _superformula(theta,m1,m2,n1,n2=1,n3=1,a=1,b=1) =
	pow(pow(abs(cos(m1*theta/4)/a),n2)+pow(abs(sin(m2*theta/4)/b),n3),-1/n1);

// Function&Module: supershape()
// Usage:
//   supershape(step,[m1],[m2],[n1],[n2],[n3],[a],[b],[r|d]);
// Description:
//   When called as a function, returns a 2D path for the outline of the [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
//   When called as a module, creates a 2D [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
// Arguments:
//   step = The angle step size for sampling the superformula shape.  Smaller steps are slower but more accurate.
//   m1 = The m1 argument for the superformula. Default: 4.
//   m2 = The m2 argument for the superformula. Default: m1.
//   n1 = The n1 argument for the superformula. Default: 1.
//   n2 = The n2 argument for the superformula. Default: n1.
//   n3 = The n3 argument for the superformula. Default: n2.
//   a = The a argument for the superformula.  Default: 1.
//   b = The b argument for the superformula.  Default: a.
//   r = Radius of the shape.  Scale shape to fit in a circle of radius r.
//   d = Diameter of the shape.  Scale shape to fit in a circle of diameter d.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D):
//   supershape(step=0.5,m1=16,m2=16,n1=0.5,n2=0.5,n3=16,r=50);
// Example(2D): Called as Function
//   stroke(closed=true, supershape(step=0.5,m1=16,m2=16,n1=0.5,n2=0.5,n3=16,d=100));
// Examples(2D,Med):
//   for(n=[2:5]) right(2.5*(n-2)) supershape(m1=4,m2=4,n1=n,a=1,b=2);  // Superellipses
//   m=[2,3,5,7]; for(i=[0:3]) right(2.5*i) supershape(.5,m1=m[i],n1=1);
//   m=[6,8,10,12]; for(i=[0:3]) right(2.7*i) supershape(.5,m1=m[i],n1=1,b=1.5);  // m should be even
//   m=[1,2,3,5]; for(i=[0:3]) fwd(1.5*i) supershape(m1=m[i],n1=0.4);
//   supershape(m1=5, n1=4, n2=1); right(2.5) supershape(m1=5, n1=40, n2=10);
//   m=[2,3,5,7]; for(i=[0:3]) right(2.5*i) supershape(m1=m[i], n1=60, n2=55, n3=30);
//   n=[0.5,0.2,0.1,0.02]; for(i=[0:3]) right(2.5*i) supershape(m1=5,n1=n[i], n2=1.7);
//   supershape(m1=2, n1=1, n2=4, n3=8);
//   supershape(m1=7, n1=2, n2=8, n3=4);
//   supershape(m1=7, n1=3, n2=4, n3=17);
//   supershape(m1=4, n1=1/2, n2=1/2, n3=4);
//   supershape(m1=4, n1=4.0,n2=16, n3=1.5, a=0.9, b=9);
//   for(i=[1:4]) right(3*i) supershape(m1=i, m2=3*i, n1=2);
//   m=[4,6,10]; for(i=[0:2]) right(i*5) supershape(m1=m[i], n1=12, n2=8, n3=5, a=2.7);
//   for(i=[-1.5:3:1.5]) right(i*1.5) supershape(m1=2,m2=10,n1=i,n2=1);
//   for(i=[1:3],j=[-1,1]) translate([3.5*i,1.5*j])supershape(m1=4,m2=6,n1=i*j,n2=1);
//   for(i=[1:3]) right(2.5*i)supershape(step=.5,m1=88, m2=64, n1=-i*i,n2=1,r=1);
// Examples:
//   linear_extrude(height=0.3, scale=0) supershape(step=1, m1=6, n1=0.4, n2=0, n3=6);
//   linear_extrude(height=5, scale=0) supershape(step=1, b=3, m1=6, n1=3.8, n2=16, n3=10);
function supershape(step=0.5,m1=4,m2=undef,n1=1,n2=undef,n3=undef,a=1,b=undef,r=undef,d=undef,anchor=CENTER, spin=0) =
	let(
		r = get_radius(r=r, d=d, dflt=undef),
		m2 = is_def(m2) ? m2 : m1,
		n2 = is_def(n2) ? n2 : n1,
		n3 = is_def(n3) ? n3 : n2,
		b = is_def(b) ? b : a,
		steps = ceil(360/step),
		step = 360/steps,
		angs = [for (i = [0:steps-1]) step*i],
		rads = [for (theta = angs) _superformula(theta=theta,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b)],
		scale = is_def(r) ? r/max(rads) : 1,
		path = [for (i = [0:steps-1]) let(a=angs[i]) scale*rads[i]*[cos(a), sin(a)]]
	) reorient(anchor,spin, two_d=true, path=path, p=path);

module supershape(step=0.5,m1=4,m2=undef,n1,n2=undef,n3=undef,a=1,b=undef, r=undef, d=undef, anchor=CENTER, spin=0) {
	path = supershape(step=step,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b,r=r,d=d);
	attachable(anchor,spin, two_d=true, path=path) {
		polygon(path);
		children();
	}
}


// Section: 2D Masking Shapes

// Function&Module: mask2d_roundover()
// Usage:
//   mask2d_roundover(r|d, [inset], [excess]);
// Description:
//   Creates a 2D roundover/bead mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   r = Radius of the roundover.
//   d = Diameter of the roundover.
//   inset = Optional bead inset size.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.
// Example(2D): 2D Roundover Mask
//   mask2d_roundover(r=10);
// Example(2D): 2D Bead Mask
//   mask2d_roundover(r=10,inset=2);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_roundover(r=10, inset=2);
module mask2d_roundover(r, d, excess, inset=0, anchor=CENTER,spin=0) {
	path = mask2d_roundover(r=r,d=d,excess=excess,inset=inset);
	attachable(anchor,spin, two_d=true, path=path, p=path) {
		polygon(path);
		children();
	}
}

function mask2d_roundover(r, d, excess, inset=0, anchor=CENTER,spin=0) =
	assert(is_num(r)||is_num(d))
	assert(is_undef(excess)||is_num(excess))
	assert(is_num(inset)||(is_vector(inset)&&len(inset)==2))
	let(
		inset = is_list(inset)? inset : [inset,inset],
		excess = default(excess,$overlap),
		r = get_radius(r=r,d=d,dflt=1),
		steps = quantup(segs(r),4)/4,
		step = 90/steps,
		path = [
			[-excess,-excess], [-excess, r+inset.y],
			for (i=[0:1:steps]) [r,r] + inset + polar_to_xy(r,180+i*step),
			[r+inset.x,-excess]
		]
	) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


// Function&Module: mask2d_cove()
// Usage:
//   mask2d_cove(r|d, [inset], [excess]);
// Description:
//   Creates a 2D cove mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   r = Radius of the cove.
//   d = Diameter of the cove.
//   inset = Optional amount to inset code from corner.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.
// Example(2D): 2D Cove Mask
//   mask2d_cove(r=10);
// Example(2D): 2D Inset Cove Mask
//   mask2d_cove(r=10,inset=3);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_cove(r=10, inset=2);
module mask2d_cove(r, d, inset=0, excess, anchor=CENTER,spin=0) {
	path = mask2d_cove(r=r,d=d,excess=excess,inset=inset);
	attachable(anchor,spin, two_d=true, path=path) {
		polygon(path);
		children();
	}
}

function mask2d_cove(r, d, inset=0, excess, anchor=CENTER,spin=0) =
	assert(is_num(r)||is_num(d))
	assert(is_undef(excess)||is_num(excess))
	assert(is_num(inset)||(is_vector(inset)&&len(inset)==2))
	let(
		inset = is_list(inset)? inset : [inset,inset],
		excess = default(excess,$overlap),
		r = get_radius(r=r,d=d,dflt=1),
		steps = quantup(segs(r),4)/4,
		step = 90/steps,
		path = [
			[-excess,-excess], [-excess, r+inset.y],
			for (i=[0:1:steps]) inset + polar_to_xy(r,90-i*step),
			[r+inset.x,-excess]
		]
	) reorient(anchor,spin, two_d=true, path=path, p=path);


// Function&Module: mask2d_chamfer()
// Usage:
//   mask2d_chamfer(x|y|edge, [angle], [inset], [excess]);
// Description:
//   Creates a 2D chamfer mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   x = The width of the chamfer.
//   y = The height of the chamfer.
//   edge = The length of the edge of the chamfer.
//   angle = The angle of the chamfer edge, away from vertical.  Default: 45.
//   inset = Optional amount to inset code from corner.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.
// Example(2D): 2D Chamfer Mask
//   mask2d_chamfer(x=10);
// Example(2D): 2D Chamfer Mask by Width.
//   mask2d_chamfer(x=10, angle=30);
// Example(2D): 2D Chamfer Mask by Height.
//   mask2d_chamfer(y=10, angle=30);
// Example(2D): 2D Inset Chamfer Mask
//   mask2d_chamfer(x=10, inset=2);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_chamfer(x=10, inset=2);
module mask2d_chamfer(x, y, edge, angle=45, excess, inset=0, anchor=CENTER,spin=0) {
	path = mask2d_chamfer(x=x, y=y, edge=edge, angle=angle, excess=excess, inset=inset);
	attachable(anchor,spin, two_d=true, path=path, extent=true) {
		polygon(path);
		children();
	}
}

function mask2d_chamfer(x, y, edge, angle=45, excess, inset=0, anchor=CENTER,spin=0) =
	assert(num_defined([x,y,edge])==1)
	assert(is_num(first_defined([x,y,edge])))
	assert(is_num(angle))
	assert(is_undef(excess)||is_num(excess))
	assert(is_num(inset)||(is_vector(inset)&&len(inset)==2))
	let(
		inset = is_list(inset)? inset : [inset,inset],
		excess = default(excess,$overlap),
		x = !is_undef(x)? x :
			!is_undef(y)? adj_ang_to_opp(adj=y,ang=angle) :
			hyp_ang_to_opp(hyp=edge,ang=angle),
		y = opp_ang_to_adj(opp=x,ang=angle),
		path = [
			[-excess, -excess], [-excess, y+inset.y],
			[inset.x, y+inset.y], [x+inset.x, inset.y],
			[x+inset.x, -excess]
		]
	) reorient(anchor,spin, two_d=true, path=path, extent=true, p=path);


// Function&Module: mask2d_rabbet()
// Usage:
//   mask2d_rabbet(size, [excess]);
// Description:
//   Creates a 2D rabbet mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   size = The size of the rabbet, either as a scalar or an [X,Y] list.
//   inset = Optional amount to inset code from corner.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.
// Example(2D): 2D Rabbet Mask
//   mask2d_rabbet(size=10);
// Example(2D): 2D Asymmetrical Rabbet Mask
//   mask2d_rabbet(size=[5,10]);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_rabbet(size=10);
module mask2d_rabbet(size, excess, anchor=CENTER,spin=0) {
	path = mask2d_rabbet(size=size, excess=excess);
	attachable(anchor,spin, two_d=true, path=path, extent=false, p=path) {
		polygon(path);
		children();
	}
}

function mask2d_rabbet(size, excess, anchor=CENTER,spin=0) =
	assert(is_num(size)||(is_vector(size)&&len(size)==2))
	assert(is_undef(excess)||is_num(excess))
	let(
		excess = default(excess,$overlap),
		size = is_list(size)? size : [size,size],
		path = [
			[-excess, -excess], [-excess, size.y],
			size, [size.x, -excess]
		]
	) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


// Function&Module: mask2d_dovetail()
// Usage:
//   mask2d_dovetail(x|y|edge, [angle], [inset], [shelf], [excess]);
// Description:
//   Creates a 2D dovetail mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   x = The width of the dovetail.
//   y = The height of the dovetail.
//   edge = The length of the edge of the dovetail.
//   angle = The angle of the chamfer edge, away from vertical.  Default: 30.
//   inset = Optional amount to inset code from corner.  Default: 0
//   shelf = The extra height to add to the inside corner of the dovetail.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.
// Example(2D): 2D Dovetail Mask
//   mask2d_dovetail(x=10);
// Example(2D): 2D Dovetail Mask by Width.
//   mask2d_dovetail(x=10, angle=30);
// Example(2D): 2D Dovetail Mask by Height.
//   mask2d_dovetail(y=10, angle=30);
// Example(2D): 2D Inset Dovetail Mask
//   mask2d_dovetail(x=10, inset=2);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_dovetail(x=10, inset=2);
module mask2d_dovetail(x, y, edge, angle=30, inset=0, shelf=0, excess, anchor=CENTER, spin=0) {
	path = mask2d_dovetail(x=x, y=y, edge=edge, angle=angle, inset=inset, shelf=shelf, excess=excess);
	attachable(anchor,spin, two_d=true, path=path) {
		polygon(path);
		children();
	}
}

function mask2d_dovetail(x, y, edge, angle=30, inset=0, shelf=0, excess, anchor=CENTER, spin=0) =
	assert(num_defined([x,y,edge])==1)
	assert(is_num(first_defined([x,y,edge])))
	assert(is_num(angle))
	assert(is_undef(excess)||is_num(excess))
	assert(is_num(inset)||(is_vector(inset)&&len(inset)==2))
	let(
		inset = is_list(inset)? inset : [inset,inset],
		excess = default(excess,$overlap),
		x = !is_undef(x)? x :
			!is_undef(y)? adj_ang_to_opp(adj=y,ang=angle) :
			hyp_ang_to_opp(hyp=edge,ang=angle),
		y = opp_ang_to_adj(opp=x,ang=angle),
		path = [
			[-excess, 0], [-excess, y+inset.y+shelf],
			inset+[x,y+shelf], inset+[x,y], inset, [inset.x,0]
		]
	) reorient(anchor,spin, two_d=true, path=path, p=path);


// Function&Module: mask2d_teardrop()
// Usage:
//   mask2d_teardrop(r|d, [angle], [excess]);
// Description:
//   Creates a 2D teardrop mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   This is particularly useful to make partially rounded bottoms, that don't need support to print.
// Arguments:
//   r = Radius of the rounding.
//   d = Diameter of the rounding.
//   angle = The maximum angle from vertical.
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.
// Example(2D): 2D Teardrop Mask
//   mask2d_teardrop(r=10);
// Example(2D): Using a Custom Angle
//   mask2d_teardrop(r=10,angle=30);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile(BOT)
//           mask2d_teardrop(r=10, angle=40);
function mask2d_teardrop(r,d,angle=45,excess=0.1,anchor=CENTER,spin=0) =  
	assert(is_num(angle))
	assert(angle>0 && angle<90)
	assert(is_num(excess))
	let(
		r = get_radius(r=r, d=d, dflt=1),
		n = ceil(segs(r) * angle/360),
		cp = [r,r],
		tp = cp + polar_to_xy(r,180+angle),
		bp = [tp.x+adj_ang_to_opp(tp.y,angle), 0],
		step = angle/n,
		path = [
			bp, bp-[0,excess], [-excess,-excess], [-excess,r],
			for (i=[0:1:n]) cp+polar_to_xy(r,180+i*step)
		]
	) reorient(anchor,spin, two_d=true, path=path, p=path);

module mask2d_teardrop(r,d,angle=45,excess=0.1,anchor=CENTER,spin=0) {
	path = mask2d_teardrop(r=r, d=d, angle=angle, excess=excess);
	attachable(anchor,spin, two_d=true, path=path) {
		polygon(path);
		children();
	}
}

// Function&Module: mask2d_ogee()
// Usage:
//   mask2d_ogee(pattern, [excess]);
//
// Description:
//   Creates a 2D Ogee mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be `difference()`d  away from the edge of a shape that is in the first (X+Y+) quadrant.
//   Since there are a number of shapes that fall under the name ogee, the shape of this mask is given as a pattern.
//   Patterns are given as TYPE, VALUE pairs.  ie: `["fillet",10, "xstep",2, "step",[5,5], ...]`.  See Patterns below.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   
//   ### Patterns
//   
//   Type     | Argument  | Description
//   -------- | --------- | ----------------
//   "step"   | [x,y]     | Makes a line to a point `x` right and `y` down.
//   "xstep"  | dist      | Makes a `dist` length line towards X+.
//   "ystep"  | dist      | Makes a `dist` length line towards Y-.
//   "round"  | radius    | Makes an arc that will mask a roundover.
//   "fillet" | radius    | Makes an arc that will mask a fillet.
//
// Arguments:
//   pattern = A list of pattern pieces to describe the Ogee.
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.
//
// Example(2D): 2D Ogee Mask
//   mask2d_ogee([
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,  "xstep",1   // Ending shoulder.
//   ]);
module mask2d_ogee(pattern, excess, anchor=CENTER,spin=0) {
	path = mask2d_ogee(pattern, excess=excess);
	attachable(anchor,spin, two_d=true, path=path) {
		polygon(path);
		children();
	}
}

function mask2d_ogee(pattern, excess, anchor=CENTER, spin=0) =
	assert(is_list(pattern))
	assert(len(pattern)>0)
	assert(len(pattern)%2==0,"pattern must be a list of TYPE, VAL pairs.")
	assert(all([for (i = idx(pattern,step=2)) in_list(pattern[i],["step","xstep","ystep","round","fillet"])]))
	let(
		excess = default(excess,$overlap),
		x = concat([0], cumsum([
			for (i=idx(pattern,step=2)) let(
				type = pattern[i],
				val = pattern[i+1]
			) (
				type=="step"?   val.x :
				type=="xstep"?  val :
				type=="round"?  val :
				type=="fillet"? val :
				0
			)
		])),
		y = concat([0], cumsum([
			for (i=idx(pattern,step=2)) let(
				type = pattern[i],
				val = pattern[i+1]
			) (
				type=="step"?   val.y :
				type=="ystep"?  val :
				type=="round"?  val :
				type=="fillet"? val :
				0
			)
		])),
		tot_x = select(x,-1),
		tot_y = select(y,-1),
		data = [
			for (i=idx(pattern,step=2)) let(
				type = pattern[i],
				val = pattern[i+1],
				pt = [x[i/2], tot_y-y[i/2]] + (
					type=="step"?   [val.x,-val.y] :
					type=="xstep"?  [val,0] :
					type=="ystep"?  [0,-val] :
					type=="round"?  [val,0] :
					type=="fillet"? [0,-val] :
					[0,0]
				)
			) [type, val, pt]
		],
		path = [
			[tot_x,-excess],
			[-excess,-excess],
			[-excess,tot_y],
			for (pat = data) each
				pat[0]=="step"?  [pat[2]] :
				pat[0]=="xstep"? [pat[2]] :
				pat[0]=="ystep"? [pat[2]] :
				let(
					r = pat[1],
					steps = segs(abs(r)),
					step = 90/steps
				) [
					for (i=[0:1:steps]) let(
						a = pat[0]=="round"? (180+i*step) : (90-i*step)
					) pat[2] + abs(r)*[cos(a),sin(a)]
				]
		],
		path2 = deduplicate(path)
	) reorient(anchor,spin, two_d=true, path=path2, p=path2);



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
