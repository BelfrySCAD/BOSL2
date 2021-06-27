//////////////////////////////////////////////////////////////////////
// LibFile: shapes2d.scad
//   Common useful 2D shapes.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////

// Section: 2D Drawing Helpers

// Module: stroke()
// Usage:
//   stroke(path, [width], [closed], [endcaps], [endcap_width], [endcap_length], [endcap_extent], [trim]);
//   stroke(path, [width], [closed], [endcap1], [endcap2], [endcap_width1], [endcap_width2], [endcap_length1], [endcap_length2], [endcap_extent1], [endcap_extent2], [trim1], [trim2]);
// Topics: Paths (2D), Paths (3D), Drawing Tools
// Description:
//   Draws a 2D or 3D path with a given line width.  Endcaps can be specified for each end individually.
// Figure(Med,NoAxes,2D,VPR=[0,0,0],VPD=250): Endcap Types
//   cap_pairs = [
//       ["butt",  "chisel" ],
//       ["round", "square" ],
//       ["line",  "cross"  ],
//       ["x",     "diamond"],
//       ["dot",   "block"  ],
//       ["tail",  "arrow"  ],
//       ["tail2", "arrow2" ]
//   ];
//   for (i = idx(cap_pairs)) {
//       fwd((i-len(cap_pairs)/2+0.5)*13) {
//           stroke([[-20,0], [20,0]], width=3, endcap1=cap_pairs[i][0], endcap2=cap_pairs[i][1]);
//           color("black") {
//               stroke([[-20,0], [20,0]], width=0.25, endcaps=false);
//               left(28) text(text=cap_pairs[i][0], size=5, halign="right", valign="center");
//               right(28) text(text=cap_pairs[i][1], size=5, halign="left", valign="center");
//           }
//       }
//   }
// Arguments:
//   path = The path to draw along.
//   width = The width of the line to draw.  If given as a list of widths, (one for each path point), draws the line with varying thickness to each point.
//   closed = If true, draw an additional line from the end of the path to the start.
//   plots = Specifies the plot point shape for every point of the line.  If a 2D path is given, use that to draw custom plot points.
//   joints  = Specifies the joint shape for each joint of the line.  If a 2D path is given, use that to draw custom joints.
//   endcaps = Specifies the endcap type for both ends of the line.  If a 2D path is given, use that to draw custom endcaps.
//   endcap1 = Specifies the endcap type for the start of the line.  If a 2D path is given, use that to draw a custom endcap.
//   endcap2 = Specifies the endcap type for the end of the line.  If a 2D path is given, use that to draw a custom endcap.
//   plot_width = Some plot point shapes are wider than the line.  This specifies the width of the shape, in multiples of the line width.
//   joint_width = Some joint shapes are wider than the line.  This specifies the width of the shape, in multiples of the line width.
//   endcap_width = Some endcap types are wider than the line.  This specifies the size of endcaps, in multiples of the line width.
//   endcap_width1 = This specifies the size of starting endcap, in multiples of the line width.
//   endcap_width2 = This specifies the size of ending endcap, in multiples of the line width.
//   plot_length = Length of plot point shape, in multiples of the line width.
//   joint_length = Length of joint shape, in multiples of the line width.
//   endcap_length = Length of endcaps, in multiples of the line width.
//   endcap_length1 = Length of starting endcap, in multiples of the line width.
//   endcap_length2 = Length of ending endcap, in multiples of the line width.
//   plot_extent = Extents length of plot point shape, in multiples of the line width.
//   joint_extent = Extents length of joint shape, in multiples of the line width.
//   endcap_extent = Extents length of endcaps, in multiples of the line width.
//   endcap_extent1 = Extents length of starting endcap, in multiples of the line width.
//   endcap_extent2 = Extents length of ending endcap, in multiples of the line width.
//   plot_angle = Extra rotation given to plot point shapes, in degrees.  If not given, the shapes are fully spun.
//   joint_angle = Extra rotation given to joint shapes, in degrees.  If not given, the shapes are fully spun.
//   endcap_angle = Extra rotation given to endcaps, in degrees.  If not given, the endcaps are fully spun.
//   endcap_angle1 = Extra rotation given to a starting endcap, in degrees.  If not given, the endcap is fully spun.
//   endcap_angle2 = Extra rotation given to a ending endcap, in degrees.  If not given, the endcap is fully spun.
//   trim = Trim the the start and end line segments by this much, to keep them from interfering with custom endcaps.
//   trim1 = Trim the the starting line segment by this much, to keep it from interfering with a custom endcap.
//   trim2 = Trim the the ending line segment by this much, to keep it from interfering with a custom endcap.
//   convexity = Max number of times a line could intersect a wall of an endcap.
//   hull = If true, use `hull()` to make higher quality joints between segments, at the cost of being much slower.  Default: true
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
// Example(2D): Plotting Points
//   path = [for (a=[0:30:360]) [a-180, 60*sin(a)]];
//   stroke(path, width=3, joints="diamond", endcaps="arrow2", plot_angle=0, plot_width=5);
// Example(2D): Joints and Endcaps
//   path = [for (a=[0:30:360]) [a-180, 60*sin(a)]];
//   stroke(path, width=3, joints="dot", endcaps="arrow2", joint_angle=0);
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
// Example: 3D Path with Joints and Endcaps
//   path = [for (i=[0:10:360]) [(i-180)/2,20*cos(3*i),20*sin(3*i)]];
//   stroke(path, width=2, joints="dot", endcap1="round", endcap2="arrow2", joint_width=2.0, endcap_width2=3, $fn=18);
module stroke(
    path, width=1, closed=false,
    endcaps,       endcap1,        endcap2,        joints,       plots,
    endcap_width,  endcap_width1,  endcap_width2,  joint_width,  plot_width,
    endcap_length, endcap_length1, endcap_length2, joint_length, plot_length,
    endcap_extent, endcap_extent1, endcap_extent2, joint_extent, plot_extent,
    endcap_angle,  endcap_angle1,  endcap_angle2,  joint_angle,  plot_angle,
    trim, trim1, trim2,
    convexity=10, hull=true
) {
    function _shape_defaults(cap) =
        cap==undef?     [1.00, 0.00, 0.00] :
        cap==false?     [1.00, 0.00, 0.00] :
        cap==true?      [1.00, 1.00, 0.00] :
        cap=="butt"?    [1.00, 0.00, 0.00] :
        cap=="round"?   [1.00, 1.00, 0.00] :
        cap=="chisel"?  [1.00, 1.00, 0.00] :
        cap=="square"?  [1.00, 1.00, 0.00] :
        cap=="block"?   [3.00, 1.00, 0.00] :
        cap=="diamond"? [3.50, 1.00, 0.00] :
        cap=="dot"?     [3.00, 1.00, 0.00] :
        cap=="x"?       [3.50, 0.40, 0.00] :
        cap=="cross"?   [4.50, 0.22, 0.00] :
        cap=="line"?    [4.50, 0.22, 0.00] :
        cap=="arrow"?   [3.50, 0.40, 0.50] :
        cap=="arrow2"?  [3.50, 1.00, 0.14] :
        cap=="tail"?    [3.50, 0.47, 0.50] :
        cap=="tail2"?   [3.50, 0.28, 0.50] :
        is_path(cap)?   [0.00, 0.00, 0.00] :
        assert(false, str("Invalid cap or joint: ",cap));

    function _shape_path(cap,linewidth,w,l,l2) = (
        (cap=="butt" || cap==false || cap==undef)? [] : 
        (cap=="round" || cap==true)? scale([w,l], p=circle(d=1, $fn=max(8, segs(w/2)))) :
        cap=="chisel"?  scale([w,l], p=circle(d=1,$fn=4)) :
        cap=="diamond"? circle(d=w,$fn=4) :
        cap=="square"?  scale([w,l], p=square(1,center=true)) :
        cap=="block"?   scale([w,l], p=square(1,center=true)) :
        cap=="dot"?     circle(d=w, $fn=max(12, segs(w*3/2))) :
        cap=="x"?       [for (a=[0:90:270]) each rot(a,p=[[w+l/2,w-l/2]/2, [w-l/2,w+l/2]/2, [0,l/2]]) ] :
        cap=="cross"?   [for (a=[0:90:270]) each rot(a,p=[[l,w]/2, [-l,w]/2, [-l,l]/2]) ] :
        cap=="line"?    scale([w,l], p=square(1,center=true)) :
        cap=="arrow"?   [[0,0], [w/2,-l2], [w/2,-l2-l], [0,-l], [-w/2,-l2-l], [-w/2,-l2]] :
        cap=="arrow2"?  [[0,0], [w/2,-l2-l], [0,-l], [-w/2,-l2-l]] :
        cap=="tail"?    [[0,0], [w/2,l2], [w/2,l2-l], [0,-l], [-w/2,l2-l], [-w/2,l2]] :
        cap=="tail2"?   [[w/2,0], [w/2,-l], [0,-l-l2], [-w/2,-l], [-w/2,0]] :
        is_path(cap)? cap :
        assert(false, str("Invalid endcap: ",cap))
    ) * linewidth;

    assert(is_bool(closed));
    assert(is_list(path));
    if (len(path) > 1) {
        assert(is_path(path,[2,3]), "The path argument must be a list of 2D or 3D points.");
    }
    path = deduplicate( closed? close_path(path) : path );

    assert(is_num(width) || (is_vector(width) && len(width)==len(path)));
    width = is_num(width)? [for (x=path) width] : width;
    assert(all([for (w=width) w>0]));

    endcap1 = first_defined([endcap1, endcaps, if(!closed) plots, "round"]);
    endcap2 = first_defined([endcap2, endcaps, plots, "round"]);
    joints  = first_defined([joints, plots, "round"]);
    assert(is_bool(endcap1) || is_string(endcap1) || is_path(endcap1));
    assert(is_bool(endcap2) || is_string(endcap2) || is_path(endcap2));
    assert(is_bool(joints)  || is_string(joints)  || is_path(joints));

    endcap1_dflts = _shape_defaults(endcap1);
    endcap2_dflts = _shape_defaults(endcap2);
    joint_dflts   = _shape_defaults(joints);

    endcap_width1 = first_defined([endcap_width1, endcap_width, plot_width, endcap1_dflts[0]]);
    endcap_width2 = first_defined([endcap_width2, endcap_width, plot_width, endcap2_dflts[0]]);
    joint_width   = first_defined([joint_width, plot_width, joint_dflts[0]]);
    assert(is_num(endcap_width1));
    assert(is_num(endcap_width2));
    assert(is_num(joint_width));

    endcap_length1 = first_defined([endcap_length1, endcap_length, plot_length, endcap1_dflts[1]*endcap_width1]);
    endcap_length2 = first_defined([endcap_length2, endcap_length, plot_length, endcap2_dflts[1]*endcap_width2]);
    joint_length   = first_defined([joint_length, plot_length, joint_dflts[1]*joint_width]);
    assert(is_num(endcap_length1));
    assert(is_num(endcap_length2));
    assert(is_num(joint_length));

    endcap_extent1 = first_defined([endcap_extent1, endcap_extent, plot_extent, endcap1_dflts[2]*endcap_width1]);
    endcap_extent2 = first_defined([endcap_extent2, endcap_extent, plot_extent, endcap2_dflts[2]*endcap_width2]);
    joint_extent   = first_defined([joint_extent, plot_extent, joint_dflts[2]*joint_width]);
    assert(is_num(endcap_extent1));
    assert(is_num(endcap_extent2));
    assert(is_num(joint_extent));

    endcap_angle1 = first_defined([endcap_angle1, endcap_angle, plot_angle]);
    endcap_angle2 = first_defined([endcap_angle2, endcap_angle, plot_angle]);
    joint_angle = first_defined([joint_angle, plot_angle]);
    assert(is_undef(endcap_angle1)||is_num(endcap_angle1));
    assert(is_undef(endcap_angle2)||is_num(endcap_angle2));
    assert(is_undef(joint_angle)||is_num(joint_angle));

    endcap_shape1 = _shape_path(endcap1, width[0], endcap_width1, endcap_length1, endcap_extent1);
    endcap_shape2 = _shape_path(endcap2, last(width), endcap_width2, endcap_length2, endcap_extent2);

    trim1 = width[0] * first_defined([
        trim1, trim,
        (endcap1=="arrow")? endcap_length1-0.01 :
        (endcap1=="arrow2")? endcap_length1*3/4 :
        0
    ]);
    assert(is_num(trim1));

    trim2 = last(width) * first_defined([
        trim2, trim,
        (endcap2=="arrow")? endcap_length2-0.01 :
        (endcap2=="arrow2")? endcap_length2*3/4 :
        0
    ]);
    assert(is_num(trim2));

    if (len(path) == 1) {
        if (len(path[0]) == 2) {
            translate(path[0]) circle(d=width[0]);
        } else {
            translate(path[0]) sphere(d=width[0]);
        }
    } else {
        spos = path_pos_from_start(path,trim1,closed=false);
        epos = path_pos_from_end(path,trim2,closed=false);
        path2 = path_subselect(path, spos[0], spos[1], epos[0], epos[1]);
        widths = concat(
            [lerp(width[spos[0]], width[(spos[0]+1)%len(width)], spos[1])],
            [for (i = [spos[0]+1:1:epos[0]]) width[i]],
            [lerp(width[epos[0]], width[(epos[0]+1)%len(width)], epos[1])]
        );

        start_vec = path[0] - path[1];
        end_vec = last(path) - select(path,-2);

        if (len(path[0]) == 2) {
            // Straight segments
            for (i = idx(path2,e=-2)) {
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
                translate(path2[i]) {
                    if (joints != undef) {
                        joint_shape = _shape_path(
                            joints, width[i],
                            joint_width,
                            joint_length,
                            joint_extent
                        );
                        v1 = unit(path2[i] - path2[i-1]);
                        v2 = unit(path2[i+1] - path2[i]);
                        vec = unit((v1+v2)/2);
                        mat = is_undef(joint_angle)
                          ? rot(from=BACK,to=v1)
                          : zrot(joint_angle);
                        multmatrix(mat) polygon(joint_shape);
                    } else if (hull) {
                        hull() {
                            rot(from=BACK, to=path2[i]-path2[i-1])
                                circle(d=widths[i]);
                            rot(from=BACK, to=path2[i+1]-path2[i])
                                circle(d=widths[i]);
                        }
                    } else {
                        rot(from=BACK, to=path2[i]-path2[i-1])
                            circle(d=widths[i]);
                        rot(from=BACK, to=path2[i+1]-path2[i])
                            circle(d=widths[i]);
                    }
                }
            }

            // Endcap1
            translate(path[0]) {
                mat = is_undef(endcap_angle1)? rot(from=BACK,to=start_vec) :
                    zrot(endcap_angle1);
                multmatrix(mat) polygon(endcap_shape1);
            }

            // Endcap2
            translate(last(path)) {
                mat = is_undef(endcap_angle2)? rot(from=BACK,to=end_vec) :
                    zrot(endcap_angle2);
                multmatrix(mat) polygon(endcap_shape2);
            }
        } else {
            quatsums = q_cumulative([
                for (i = idx(path2,e=-2)) let(
                    vec1 = i==0? UP : unit(path2[i]-path2[i-1], UP),
                    vec2 = unit(path2[i+1]-path2[i], UP),
                    axis = vector_axis(vec1,vec2),
                    ang = vector_angle(vec1,vec2)
                ) quat(axis,ang)
            ]);
            rotmats = [for (q=quatsums) q_matrix4(q)];
            sides = [
                for (i = idx(path2,e=-2))
                quantup(segs(max(widths[i],widths[i+1])/2),4)
            ];

            // Straight segments
            for (i = idx(path2,e=-2)) {
                dist = norm(path2[i+1] - path2[i]);
                w1 = widths[i]/2;
                w2 = widths[i+1]/2;
                $fn = sides[i];
                translate(path2[i]) {
                    multmatrix(rotmats[i]) {
                        cylinder(r1=w1, r2=w2, h=dist, center=false);
                    }
                }
            }

            // Joints
            for (i = [1:1:len(path2)-2]) {
                $fn = sides[i];
                translate(path2[i]) {
                    if (joints != undef) {
                        joint_shape = _shape_path(
                            joints, width[i],
                            joint_width,
                            joint_length,
                            joint_extent
                        );
                        multmatrix(rotmats[i] * xrot(180)) {
                            $fn = sides[i];
                            if (is_undef(joint_angle)) {
                                rotate_extrude(convexity=convexity) {
                                    right_half(planar=true) {
                                        polygon(joint_shape);
                                    }
                                }
                            } else {
                                rotate([90,0,joint_angle]) {
                                    linear_extrude(height=max(widths[i],0.001), center=true, convexity=convexity) {
                                        polygon(joint_shape);
                                    }
                                }
                            }
                        }
                    } else if (hull) {
                        hull(){
                            multmatrix(rotmats[i]) {
                                sphere(d=widths[i],style="aligned");
                            }
                            multmatrix(rotmats[i-1]) {
                                sphere(d=widths[i],style="aligned");
                            }
                        }
                    } else {
                        multmatrix(rotmats[i]) {
                            sphere(d=widths[i],style="aligned");
                        }
                        multmatrix(rotmats[i-1]) {
                            sphere(d=widths[i],style="aligned");
                        }
                    }
                }
            }

            // Endcap1
            translate(path[0]) {
                multmatrix(rotmats[0] * xrot(180)) {
                    $fn = sides[0];
                    if (is_undef(endcap_angle1)) {
                        rotate_extrude(convexity=convexity) {
                            right_half(planar=true) {
                                polygon(endcap_shape1);
                            }
                        }
                    } else {
                        rotate([90,0,endcap_angle1]) {
                            linear_extrude(height=max(widths[0],0.001), center=true, convexity=convexity) {
                                polygon(endcap_shape1);
                            }
                        }
                    }
                }
            }

            // Endcap2
            translate(last(path)) {
                multmatrix(last(rotmats)) {
                    $fn = last(sides);
                    if (is_undef(endcap_angle2)) {
                        rotate_extrude(convexity=convexity) {
                            right_half(planar=true) {
                                polygon(endcap_shape2);
                            }
                        }
                    } else {
                        rotate([90,0,endcap_angle2]) {
                            linear_extrude(height=max(last(widths),0.001), center=true, convexity=convexity) {
                                polygon(endcap_shape2);
                            }
                        }
                    }
                }
            }
        }
    }
}


// Function&Module: dashed_stroke()
// Usage: As a Module
//   dashed_stroke(path, dashpat, [closed=]);
// Usage: As a Function
//   dashes = dashed_stroke(path, dashpat, width=, [closed=]);
// Topics: Paths, Drawing Tools
// See Also: stroke(), path_cut()
// Description:
//   Given a path and a dash pattern, creates a dashed line that follows that
//   path with the given dash pattern.
//   - When called as a function, returns a list of dash sub-paths.
//   - When called as a module, draws all those subpaths using `stroke()`.
// Arguments:
//   path = The path to subdivide into dashes.
//   dashpat = A list of alternating dash lengths and space lengths for the dash pattern.  This will be scaled by the width of the line.
//   ---
//   width = The width of the dashed line to draw.  Module only.  Default: 1
//   closed = If true, treat path as a closed polygon.  Default: false
// Example(2D): Open Path
//   path = [for (a=[-180:10:180]) [a/3,20*sin(a)]];
//   dashed_stroke(path, [3,2], width=1);
// Example(2D): Closed Polygon
//   path = circle(d=100,$fn=72);
//   dashpat = [10,2,3,2,3,2];
//   dashed_stroke(path, dashpat, width=1, closed=true);
// Example(FlatSpin,VPD=250): 3D Dashed Path
//   path = [for (a=[-180:5:180]) [a/3, 20*cos(3*a), 20*sin(3*a)]];
//   dashed_stroke(path, [3,2], width=1);
function dashed_stroke(path, dashpat=[3,3], closed=false) =
    let(
        path = closed? close_path(path) : path,
        dashpat = len(dashpat)%2==0? dashpat : concat(dashpat,[0]),
        plen = path_length(path),
        dlen = sum(dashpat),
        doff = cumsum(dashpat),
        reps = floor(plen / dlen),
        step = plen / reps,
        cuts = [
            for (i=[0:1:reps-1], off=doff)
            let (st=i*step, x=st+off)
            if (x>0 && x<plen) x
        ],
        dashes = path_cut(path, cuts, closed=false),
        evens = [for (i=idx(dashes)) if (i%2==0) dashes[i]]
    ) evens;


module dashed_stroke(path, dashpat=[3,3], width=1, closed=false) {
    segs = dashed_stroke(path, dashpat=dashpat*width, closed=closed);
    for (seg = segs)
        stroke(seg, width=width, endcaps=false);
}


// Function&Module: arc()
// Usage: 2D arc from 0º to `angle` degrees.
//   arc(N, r|d=, angle);
// Usage: 2D arc from START to END degrees.
//   arc(N, r|d=, angle=[START,END])
// Usage: 2D arc from `start` to `start+angle` degrees.
//   arc(N, r|d=, start=, angle=)
// Usage: 2D circle segment by `width` and `thickness`, starting and ending on the X axis.
//   arc(N, width=, thickness=)
// Usage: Shortest 2D or 3D arc around centerpoint `cp`, starting at P0 and ending on the vector pointing from `cp` to `P1`.
//   arc(N, cp=, points=[P0,P1], [long=], [cw=], [ccw=])
// Usage: 2D or 3D arc, starting at `P0`, passing through `P1` and ending at `P2`.
//   arc(N, points=[P0,P1,P2])
// Topics: Paths (2D), Paths (3D), Shapes (2D), Path Generators
// Description:
//   If called as a function, returns a 2D or 3D path forming an arc.
//   If called as a module, creates a 2D arc polygon or pie slice shape.
// Arguments:
//   N = Number of vertices to form the arc curve from.
//   r = Radius of the arc.
//   angle = If a scalar, specifies the end angle in degrees (relative to start parameter).  If a vector of two scalars, specifies start and end angles.
//   ---
//   d = Diameter of the arc.
//   cp = Centerpoint of arc.
//   points = Points on the arc.
//   long = if given with cp and points takes the long arc instead of the default short arc.  Default: false
//   cw = if given with cp and 2 points takes the arc in the clockwise direction.  Default: false
//   ccw = if given with cp and 2 points takes the arc in the counter-clockwise direction.  Default: false
//   width = If given with `thickness`, arc starts and ends on X axis, to make a circle segment.
//   thickness = If given with `width`, arc starts and ends on X axis, to make a circle segment.
//   start = Start angle of arc.
//   wedge = If true, include centerpoint `cp` in output to form pie slice shape.
//   endpoint = If false exclude the last point (function only).  Default: true
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
// Example(FlatSpin,VPD=175):
//   path = arc(points=[[0,30,0],[0,0,30],[30,0,0]]);
//   trace_path(path, showpts=true, color="cyan");
function arc(N, r, angle, d, cp, points, width, thickness, start, wedge=false, long=false, cw=false, ccw=false, endpoint=true) =
    assert(is_bool(endpoint))
    !endpoint ? assert(!wedge, "endpoint cannot be false if wedge is true")
               list_head(arc(N+1,r,angle,d,cp,points,width,thickness,start,wedge,long,cw,ccw,true)) :
    assert(is_undef(N) || is_integer(N), "Number of points must be an integer")
    // First try for 2D arc specified by width and thickness
    is_def(width) && is_def(thickness)? (
                assert(!any_defined([r,cp,points]) && !any([cw,ccw,long]),"Conflicting or invalid parameters to arc")
                assert(width>0, "Width must be postive")
                assert(thickness>0, "Thickness must be positive")
        arc(N,points=[[width/2,0], [0,thickness], [-width/2,0]],wedge=wedge)
    ) : is_def(angle)? (
        let(
            parmok = !any_defined([points,width,thickness]) &&
                ((is_vector(angle,2) && is_undef(start)) || is_num(angle))
        )
        assert(parmok,"Invalid parameters in arc")
        let(
            cp = first_defined([cp,[0,0]]),
            start = is_def(start)? start : is_vector(angle) ? angle[0] : 0,
            angle = is_vector(angle)? angle[1]-angle[0] : angle,
            r = get_radius(r=r, d=d)
                )
                assert(is_vector(cp,2),"Centerpoint must be a 2d vector")
                assert(angle!=0, "Arc has zero length")
                assert(is_def(r) && r>0, "Arc radius invalid")
                let(
            N = max(3, is_undef(N)? ceil(segs(r)*abs(angle)/360) : N),
            arcpoints = [for(i=[0:N-1]) let(theta = start + i*angle/(N-1)) r*[cos(theta),sin(theta)]+cp],
            extra = wedge? [cp] : []
        )
        concat(extra,arcpoints)
    ) :
          assert(is_path(points,[2,3]),"Point list is invalid")
        // Arc is 3D, so transform points to 2D and make a recursive call, then remap back to 3D
         len(points[0])==3? (
                assert(!(cw || ccw), "(Counter)clockwise isn't meaningful in 3d, so `cw` and `ccw` must be false")
                assert(is_undef(cp) || is_vector(cp,3),"points are 3d so cp must be 3d")
        let(
            plane = [is_def(cp) ? cp : points[2], points[0], points[1]],
            center2d = is_def(cp) ? project_plane(plane,cp) : undef,
            points2d = project_plane(plane, points)
        )
        lift_plane(plane,arc(N,cp=center2d,points=points2d,wedge=wedge,long=long))
    ) : is_def(cp)? (
        // Arc defined by center plus two points, will have radius defined by center and points[0]
        // and extent defined by direction of point[1] from the center
                assert(is_vector(cp,2), "Centerpoint must be a 2d vector")
                assert(len(points)==2, "When pointlist has length 3 centerpoint is not allowed")
                assert(points[0]!=points[1], "Arc endpoints are equal")
                assert(cp!=points[0]&&cp!=points[1], "Centerpoint equals an arc endpoint")
                assert(count_true([long,cw,ccw])<=1, str("Only one of `long`, `cw` and `ccw` can be true",cw,ccw,long))
        let(    
            angle = vector_angle(points[0], cp, points[1]),
            v1 = points[0]-cp,
            v2 = points[1]-cp,
            prelim_dir = sign(det2([v1,v2])),   // z component of cross product
                        dir = prelim_dir != 0
                                  ? prelim_dir
                                  : assert(cw || ccw, "Collinear inputs don't define a unique arc")
                                    1,
            r=norm(v1),
                        final_angle = long || (ccw && dir<0) || (cw && dir>0) ? -dir*(360-angle) : dir*angle
        )
        arc(N,cp=cp,r=r,start=atan2(v1.y,v1.x),angle=final_angle,wedge=wedge)
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
//   turtle(commands, [state], [full_state=], [repeat=])
// Topics: Shapes (2D), Path Generators (2D), Mini-Language
// See Also: turtle3d()
// Description:
//   Use a sequence of turtle graphics commands to generate a path.  The parameter `commands` is a list of
//   turtle commands and optional parameters for each command.  The turtle state has a position, movement direction,
//   movement distance, and default turn angle.  If you do not give `state` as input then the turtle starts at the
//   origin, pointed along the positive x axis with a movement distance of 1.  By default, `turtle` returns just
//   the computed turtle path.  If you set `full_state` to true then it instead returns the full turtle state.
//   You can invoke `turtle` again with this full state to continue the turtle path where you left off.
//   .
//   The turtle state is a list with three entries: the path constructed so far, the current step as a 2-vector, the current default angle,
//   and the current arcsteps setting.  
//   .
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
//   commands = List of turtle commands
//   state = Starting turtle state (from previous call) or starting point.  Default: start at the origin, pointing right.
//   ---
//   full_state = If true return the full turtle state for continuing the path in subsequent turtle calls.  Default: false
//   repeat = Number of times to repeat the command list.  Default: 1
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

// Turtle state: state = [path, step_vector, default angle, default arcsteps]

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
        lastpt = last(state[path])
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
                concat(state[path], list_tail(arcpath)),
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
                concat(state[path], list_tail(arcpath)),
                rot(delta_angle,p=state[step],planar=true)
            ]
        ) :
    assert(false,str("Unknown turtle command \"",command,"\" at index",index))
    [];



// Section: 2D Primitives

// Function&Module: rect()
// Usage: As Module
//   rect(size, [center], [rounding], [chamfer], ...);
// Usage: With Attachments
//   rect(size, [center], ...) { attachables }
// Usage: As Function
//   path = rect(size, [center], [rounding], [chamfer], ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: square()
// Description:
//   When called as a module, creates a 2D rectangle of the given size, with optional rounding or chamfering.
//   When called as a function, returns a 2D path/list of points for a square/rectangle of the given size.
// Arguments:
//   size = The size of the rectangle to create.  If given as a scalar, both X and Y will be the same size.
//   rounding = The rounding radius for the corners.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   chamfer = The chamfer size for the corners.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
//   center = If given and true, overrides `anchor` to be `CENTER`.  If given and false, overrides `anchor` to be `FRONT+LEFT`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D):
//   rect(40);
// Example(2D): Centered
//   rect([40,30], center=true);
// Example(2D): Anchored
//   rect([40,30], anchor=FRONT);
// Example(2D): Spun
//   rect([40,30], anchor=FRONT, spin=30);
// Example(2D): Chamferred Rect
//   rect([40,30], chamfer=5, center=true);
// Example(2D): Rounded Rect
//   rect([40,30], rounding=5, center=true);
// Example(2D): Mixed Chamferring and Rounding
//   rect([40,30],center=true,rounding=[5,0,10,0],chamfer=[0,8,0,15],$fa=1,$fs=1);
// Example(2D): Called as Function
//   path = rect([40,30], chamfer=5, anchor=FRONT, spin=30);
//   stroke(path, closed=true);
//   move_copies(path) color("blue") circle(d=2,$fn=8);
module rect(size=1, center, rounding=0, chamfer=0, anchor, spin=0) {
    size = is_num(size)? [size,size] : point2d(size);
    anchor = get_anchor(anchor, center, FRONT+LEFT, FRONT+LEFT);
    if (rounding==0 && chamfer==0) {
        attachable(anchor,spin, two_d=true, size=size) {
            square(size, center=true);
            children();
        }
    } else {
        pts = rect(size=size, rounding=rounding, chamfer=chamfer, center=true);
        attachable(anchor,spin, two_d=true, path=pts) {
            polygon(pts);
            children();
        }
    }
}


function rect(size=1, center, rounding=0, chamfer=0, anchor, spin=0) =
    assert(is_num(size)     || is_vector(size))
    assert(is_num(chamfer)  || len(chamfer)==4)
    assert(is_num(rounding) || len(rounding)==4)
    let(
        size = is_num(size)? [size,size] : point2d(size),
        anchor = point2d(get_anchor(anchor, center, FRONT+LEFT, FRONT+LEFT)),
        complex = rounding!=0 || chamfer!=0
    )
    (rounding==0 && chamfer==0)? let(
        path = [
            [ size.x/2, -size.y/2],
            [-size.x/2, -size.y/2],
            [-size.x/2,  size.y/2],
            [ size.x/2,  size.y/2] 
        ]
    ) rot(spin, p=move(-v_mul(anchor,size/2), p=path)) :
    let(
        chamfer = is_list(chamfer)? chamfer : [for (i=[0:3]) chamfer],
        rounding = is_list(rounding)? rounding : [for (i=[0:3]) rounding],
        quadorder = [3,2,1,0],
        quadpos = [[1,1],[-1,1],[-1,-1],[1,-1]],
        insets = [for (i=[0:3]) chamfer[i]>0? chamfer[i] : rounding[i]>0? rounding[i] : 0],
        insets_x = max(insets[0]+insets[1],insets[2]+insets[3]),
        insets_y = max(insets[0]+insets[3],insets[1]+insets[2])
    )
    assert(insets_x <= size.x, "Requested roundings and/or chamfers exceed the rect width.")
    assert(insets_y <= size.y, "Requested roundings and/or chamfers exceed the rect height.")
    let(
        path = [
            for(i = [0:3])
            let(
                quad = quadorder[i],
                inset = insets[quad],
                cverts = quant(segs(inset),4)/4,
                cp = v_mul(size/2-[inset,inset], quadpos[quad]),
                step = 90/cverts,
                angs =
                    chamfer[quad] > 0?  [0,-90]-90*[i,i] :
                    rounding[quad] > 0? [for (j=[0:1:cverts]) 360-j*step-i*90] :
                    [0]
            )
            each [for (a = angs) cp + inset*[cos(a),sin(a)]]
        ]
    ) complex?
        reorient(anchor,spin, two_d=true, path=path, p=path) :
        reorient(anchor,spin, two_d=true, size=size, p=path);


// Function&Module: oval()
// Usage:
//   oval(r|d=, [realign=], [circum=])
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle()
// Description:
//   When called as a module, creates a 2D polygon that approximates a circle of the given size.
//   When called as a function, returns a 2D list of points (path) for a polygon that approximates a circle of the given size.
// Arguments:
//   r = Radius of the circle/oval to create.  Can be a scalar, or a list of sizes per axis.
//   ---
//   d = Diameter of the circle/oval to create.  Can be a scalar, or a list of sizes per axis.
//   realign = If true, rotates the polygon that approximates the circle/oval by half of one size.
//   circum = If true, the polygon that approximates the circle will be upsized slightly to circumscribe the theoretical circle.  If false, it inscribes the theoretical circle.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): By Radius
//   oval(r=25);
// Example(2D): By Diameter
//   oval(d=50);
// Example(2D): Anchoring
//   oval(d=50, anchor=FRONT);
// Example(2D): Spin
//   oval(d=50, anchor=FRONT, spin=45);
// Example(NORENDER): Called as Function
//   path = oval(d=50, anchor=FRONT, spin=45);
module oval(r, d, realign=false, circum=false, anchor=CENTER, spin=0) {
    r = get_radius(r=r, d=d, dflt=1);
    sides = segs(max(r));
    sc = circum? (1 / cos(180/sides)) : 1;
    rx = default(r[0],r) * sc;
    ry = default(r[1],r) * sc;
    attachable(anchor,spin, two_d=true, r=[rx,ry]) {
        if (rx < ry) {
            xscale(rx/ry) {
                zrot(realign? 180/sides : 0) {
                    circle(r=ry, $fn=sides);
                }
            }
        } else {
            yscale(ry/rx) {
                zrot(realign? 180/sides : 0) {
                    circle(r=rx, $fn=sides);
                }
            }
        }
        children();
    }
}


function oval(r, d, realign=false, circum=false, anchor=CENTER, spin=0) =
    let(
        r = get_radius(r=r, d=d, dflt=1),
        sides = segs(max(r)),
        offset = realign? 180/sides : 0,
        sc = circum? (1 / cos(180/sides)) : 1,
        rx = default(r[0],r) * sc,
        ry = default(r[1],r) * sc,
        pts = [for (i=[0:1:sides-1]) let(a=360-offset-i*360/sides) [rx*cos(a), ry*sin(a)]]
    ) reorient(anchor,spin, two_d=true, r=[rx,ry], p=pts);



// Section: 2D N-Gons

// Function&Module: regular_ngon()
// Usage:
//   regular_ngon(n, r/d=/or=/od=, [realign=]);
//   regular_ngon(n, ir=/id=, [realign=]);
//   regular_ngon(n, side=, [realign=]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), pentagon(), hexagon(), octagon(), oval(), star()
// Description:
//   When called as a function, returns a 2D path for a regular N-sided polygon.
//   When called as a module, creates a 2D regular N-sided polygon.
// Arguments:
//   n = The number of sides.
//   r/or = Outside radius, at points.
//   ---
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Extra Anchors:
//   "tip0", "tip1", etc. = Each tip has an anchor, pointing outwards.
//   "side0", "side1", etc. = The center of each side has an anchor, pointing outwards.
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
// Example(2D): Alignment by Tip
//   regular_ngon(n=5, r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   regular_ngon(n=5, r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   regular_ngon(n=5, od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, regular_ngon(n=6, or=30));
function regular_ngon(n=6, r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0, _mat, _anchs) =
    assert(is_undef(align_tip) || is_vector(align_tip))
    assert(is_undef(align_side) || is_vector(align_side))
    assert(is_undef(align_tip) || is_undef(align_side), "Can only specify one of align_tip and align-side")
    let(
        sc = 1/cos(180/n),
        ir = is_finite(ir)? ir*sc : undef,
        id = is_finite(id)? id*sc : undef,
        side = is_finite(side)? side/2/sin(180/n) : undef,
        r = get_radius(r1=ir, r2=or, r=r, d1=id, d2=od, d=d, dflt=side)
    )
    assert(!is_undef(r), "regular_ngon(): need to specify one of r, d, or, od, ir, id, side.")
    let(
        inset = opp_ang_to_hyp(rounding, (180-360/n)/2),
        mat = !is_undef(_mat) ? _mat :
            ( realign? rot(-180/n, planar=true) : affine2d_identity() ) * (
                !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip), planar=true) :
                !is_undef(align_side)? rot(from=RIGHT, to=point2d(align_side), planar=true) * rot(180/n, planar=true) :
                affine2d_identity()
            ),
        path4 = rounding==0? oval(r=r, $fn=n) : (
            let(
                steps = floor(segs(r)/n),
                step = 360/n/steps,
                path2 = [
                    for (i = [0:1:n-1]) let(
                        a = 360 - i*360/n,
                        p = polar_to_xy(r-inset, a)
                    )
                    each arc(N=steps, cp=p, r=rounding, start=a+180/n, angle=-360/n)
                ],
                maxx_idx = max_index(subindex(path2,0)),
                path3 = polygon_shift(path2,maxx_idx)
            ) path3
        ),
        path = apply(mat, path4),
        anchors = !is_undef(_anchs) ? _anchs :
            !is_string(anchor)? [] : [
            for (i = [0:1:n-1]) let(
                a1 = 360 - i*360/n,
                a2 = a1 - 360/n,
                p1 = apply(mat, polar_to_xy(r,a1)),
                p2 = apply(mat, polar_to_xy(r,a2)),
                tipp = apply(mat, polar_to_xy(r-inset+rounding,a1)),
                pos = (p1+p2)/2
            ) each [
                anchorpt(str("tip",i), tipp, unit(tipp,BACK), 0),
                anchorpt(str("side",i), pos, unit(pos,BACK), 0),
            ]
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path, anchors=anchors);


module regular_ngon(n=6, r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) {
    sc = 1/cos(180/n);
    ir = is_finite(ir)? ir*sc : undef;
    id = is_finite(id)? id*sc : undef;
    side = is_finite(side)? side/2/sin(180/n) : undef;
    r = get_radius(r1=ir, r2=or, r=r, d1=id, d2=od, d=d, dflt=side);
    assert(!is_undef(r), "regular_ngon(): need to specify one of r, d, or, od, ir, id, side.");
    mat = ( realign? rot(-180/n, planar=true) : affine2d_identity() ) * (
            !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip), planar=true) :
            !is_undef(align_side)? rot(from=RIGHT, to=point2d(align_side), planar=true) * rot(180/n, planar=true) :
            affine2d_identity()
        );
    inset = opp_ang_to_hyp(rounding, (180-360/n)/2);
    anchors = [
        for (i = [0:1:n-1]) let(
            a1 = 360 - i*360/n,
            a2 = a1 - 360/n,
            p1 = apply(mat, polar_to_xy(r,a1)),
            p2 = apply(mat, polar_to_xy(r,a2)),
            tipp = apply(mat, polar_to_xy(r-inset+rounding,a1)),
            pos = (p1+p2)/2
        ) each [
            anchorpt(str("tip",i), tipp, unit(tipp,BACK), 0),
            anchorpt(str("side",i), pos, unit(pos,BACK), 0),
        ]
    ];
    path = regular_ngon(n=n, r=r, rounding=rounding, _mat=mat, _anchs=anchors);
    attachable(anchor,spin, two_d=true, path=path, extent=false, anchors=anchors) {
        polygon(path);
        children();
    }
}


// Function&Module: pentagon()
// Usage:
//   pentagon(or|od=, [realign=]);
//   pentagon(ir=|id=, [realign=]);
//   pentagon(side=, [realign=]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), regular_ngon(), hexagon(), octagon(), oval(), star()
// Description:
//   When called as a function, returns a 2D path for a regular pentagon.
//   When called as a module, creates a 2D regular pentagon.
// Arguments:
//   r/or = Outside radius, at points.
//   ---
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip4" = Each tip has an anchor, pointing outwards.
//   "side0" ... "side4" = The center of each side has an anchor, pointing outwards.
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
// Example(2D): Alignment by Tip
//   pentagon(r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   pentagon(r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   pentagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, pentagon(or=30));
function pentagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) =
    regular_ngon(n=5, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin);


module pentagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0)
    regular_ngon(n=5, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin) children();


// Function&Module: hexagon()
// Usage: As Module
//   hexagon(r/or, [realign=], <align_tip=|align_side=>, [rounding=], ...);
//   hexagon(d=/od=, ...);
//   hexagon(ir=/id=, ...);
//   hexagon(side=, ...);
// Usage: With Attachments
//   hexagon(r/or, ...) { attachments }
// Usage: As Function
//   path = hexagon(r/or, ...);
//   path = hexagon(d=/od=, ...);
//   path = hexagon(ir=/id=, ...);
//   path = hexagon(side=, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), regular_ngon(), pentagon(), octagon(), oval(), star()
// Description:
//   When called as a function, returns a 2D path for a regular hexagon.
//   When called as a module, creates a 2D regular hexagon.
// Arguments:
//   r/or = Outside radius, at points.
//   ---
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip5" = Each tip has an anchor, pointing outwards.
//   "side0" ... "side5" = The center of each side has an anchor, pointing outwards.
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
// Example(2D): Alignment by Tip
//   hexagon(r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   hexagon(r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   hexagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, hexagon(or=30));
function hexagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) =
    regular_ngon(n=6, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin);


module hexagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0)
    regular_ngon(n=6, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin) children();


// Function&Module: octagon()
// Usage: As Module
//   octagon(r/or, [realign=], <align_tip=|align_side=>, [rounding=], ...);
//   octagon(d=/od=, ...);
//   octagon(ir=/id=, ...);
//   octagon(side=, ...);
// Usage: With Attachments
//   octagon(r/or, ...) { attachments }
// Usage: As Function
//   path = octagon(r/or, ...);
//   path = octagon(d=/od=, ...);
//   path = octagon(ir=/id=, ...);
//   path = octagon(side=, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), regular_ngon(), pentagon(), hexagon(), oval(), star()
// Description:
//   When called as a function, returns a 2D path for a regular octagon.
//   When called as a module, creates a 2D regular octagon.
// Arguments:
//   r/or = Outside radius, at points.
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip7" = Each tip has an anchor, pointing outwards.
//   "side0" ... "side7" = The center of each side has an anchor, pointing outwards.
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
// Example(2D): Alignment by Tip
//   octagon(r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   octagon(r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   octagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, octagon(or=30));
function octagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) =
    regular_ngon(n=8, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin);


module octagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0)
    regular_ngon(n=8, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin) children();



// Section: Other 2D Shapes


// Function&Module: trapezoid()
// Usage: As Module
//   trapezoid(h, w1, w2, [shift=], [rounding=], [chamfer=], ...);
//   trapezoid(h, w1, angle=, ...);
//   trapezoid(h, w2, angle=, ...);
//   trapezoid(w1, w2, angle=, ...);
// Usage: With Attachments
//   trapezoid(h, w1, w2, ...) { attachments }
// Usage: As Function
//   path = trapezoid(h, w1, w2, ...);
//   path = trapezoid(h, w1, angle=, ...);
//   path = trapezoid(h, w2=, angle=, ...);
//   path = trapezoid(w1=, w2=, angle=, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: rect(), square()
// Description:
//   When called as a function, returns a 2D path for a trapezoid with parallel front and back sides.
//   When called as a module, creates a 2D trapezoid with parallel front and back sides.
// Arguments:
//   h = The Y axis height of the trapezoid.
//   w1 = The X axis width of the front end of the trapezoid.
//   w2 = The X axis width of the back end of the trapezoid.
//   ---
//   angle = If given in place of `h`, `w1`, or `w2`, then the missing value is calculated such that the right side has that angle away from the Y axis.
//   shift = Scalar value to shift the back of the trapezoid along the X axis by.  Default: 0
//   rounding = The rounding radius for the corners.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   chamfer = The Length of the chamfer faces at the corners.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Examples(2D):
//   trapezoid(h=30, w1=40, w2=20);
//   trapezoid(h=25, w1=20, w2=35);
//   trapezoid(h=20, w1=40, w2=0);
//   trapezoid(h=20, w1=30, angle=30);
//   trapezoid(h=20, w1=20, angle=-30);
//   trapezoid(h=20, w2=10, angle=30);
//   trapezoid(h=20, w2=30, angle=-30);
//   trapezoid(w1=30, w2=10, angle=30);
// Example(2D): Chamferred Trapezoid
//   trapezoid(h=30, w1=60, w2=40, chamfer=5);
// Example(2D): Rounded Trapezoid
//   trapezoid(h=30, w1=60, w2=40, rounding=5);
// Example(2D): Mixed Chamfering and Rounding
//   trapezoid(h=30, w1=60, w2=40, rounding=[5,0,10,0],chamfer=[0,8,0,15],$fa=1,$fs=1);
// Example(2D): Called as Function
//   stroke(closed=true, trapezoid(h=30, w1=40, w2=20));
function trapezoid(h, w1, w2, angle, shift=0, chamfer=0, rounding=0, anchor=CENTER, spin=0) =
    assert(is_undef(h) || is_finite(h))
    assert(is_undef(w1) || is_finite(w1))
    assert(is_undef(w2) || is_finite(w2))
    assert(is_undef(angle) || is_finite(angle))
    assert(num_defined([h, w1, w2, angle]) == 3, "Must give exactly 3 of the arguments h, w1, w2, and angle.")
    assert(is_finite(shift))
    assert(is_finite(chamfer)  || is_vector(chamfer,4))
    assert(is_finite(rounding) || is_vector(rounding,4))
    let(
        simple = chamfer==0 && rounding==0,
        h  = !is_undef(h)?  h  : opp_ang_to_adj(abs(w2-w1)/2, abs(angle)),
        w1 = !is_undef(w1)? w1 : w2 + 2*(adj_ang_to_opp(h, angle) + shift),
        w2 = !is_undef(w2)? w2 : w1 - 2*(adj_ang_to_opp(h, angle) + shift)
    )
    assert(w1>=0 && w2>=0 && h>0, "Degenerate trapezoid geometry.")
    assert(w1+w2>0, "Degenerate trapezoid geometry.")
    let(
        base_path = [
            [w2/2+shift,h/2],
            [-w2/2+shift,h/2],
            [-w1/2,-h/2],
            [w1/2,-h/2],
        ],
        cpath = simple? base_path :
            path_chamfer_and_rounding(
                base_path, closed=true,
                chamfer=chamfer,
                rounding=rounding
            ),
        path = reverse(cpath)
    ) simple
      ? reorient(anchor,spin, two_d=true, size=[w1,h], size2=w2, shift=shift, p=path)
      : reorient(anchor,spin, two_d=true, path=path, p=path);



module trapezoid(h, w1, w2, angle, shift=0, chamfer=0, rounding=0, anchor=CENTER, spin=0) {
    path = trapezoid(h=h, w1=w1, w2=w2, angle=angle, shift=shift, chamfer=chamfer, rounding=rounding);
    union() {
        simple = chamfer==0 && rounding==0;
        h  = !is_undef(h)?  h  : opp_ang_to_adj(abs(w2-w1)/2, abs(angle));
        w1 = !is_undef(w1)? w1 : w2 + 2*(adj_ang_to_opp(h, angle) + shift);
        w2 = !is_undef(w2)? w2 : w1 - 2*(adj_ang_to_opp(h, angle) + shift);
        if (simple) {
            attachable(anchor,spin, two_d=true, size=[w1,h], size2=w2, shift=shift) {
                polygon(path);
                children();
            }
        } else {
            attachable(anchor,spin, two_d=true, path=path) {
                polygon(path);
                children();
            }
        }
    }
}


// Function&Module: teardrop2d()
//
// Description:
//   Makes a 2D teardrop shape. Useful for extruding into 3D printable holes.
//
// Usage: As Module
//   teardrop2d(r/d=, [ang], [cap_h]);
// Usage: With Attachments
//   teardrop2d(r/d=, [ang], [cap_h], ...) { attachments }
// Usage: As Function
//   path = teardrop2d(r/d=, [ang], [cap_h]);
//
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
//
// See Also: teardrop(), onion()
//
// Arguments:
//   r = radius of circular part of teardrop.  (Default: 1)
//   ang = angle of hat walls from the Y axis.  (Default: 45 degrees)
//   cap_h = if given, height above center where the shape will be truncated.
//   ---
//   d = diameter of spherical portion of bottom. (Use instead of r)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//
// Example(2D): Typical Shape
//   teardrop2d(r=30, ang=30);
// Example(2D): Crop Cap
//   teardrop2d(r=30, ang=30, cap_h=40);
// Example(2D): Close Crop
//   teardrop2d(r=30, ang=30, cap_h=20);
module teardrop2d(r, ang=45, cap_h, d, anchor=CENTER, spin=0)
{
    path = teardrop2d(r=r, d=d, ang=ang, cap_h=cap_h);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}


function teardrop2d(r, ang=45, cap_h, d, anchor=CENTER, spin=0) =
    let(
        r = get_radius(r=r, d=d, dflt=1),
        tanpt = polar_to_xy(r, ang),
        tip_y = adj_ang_to_hyp(r, 90-ang),
        cap_h = min(default(cap_h,tip_y), tip_y),
        cap_w = tanpt.y >= cap_h
          ? hyp_opp_to_adj(r, cap_h)
          : adj_ang_to_opp(tip_y-cap_h, ang),
        ang2 = min(ang,atan2(cap_h,cap_w)),
        sa = 180 - ang2,
        ea = 360 + ang2,
        steps = segs(r)*(ea-sa)/360,
        step = (ea-sa)/steps,
        path = deduplicate(
            [
                [ cap_w,cap_h],
                for (i=[0:1:steps]) let(a=ea-i*step) r*[cos(a),sin(a)],
                [-cap_w,cap_h]
            ], closed=true
        ),
        maxx_idx = max_index(subindex(path,0)),
        path2 = polygon_shift(path,maxx_idx)
    ) reorient(anchor,spin, two_d=true, path=path2, p=path2);



// Function&Module: glued_circles()
// Usage: As Module
//   glued_circles(r/d=, [spread=], [tangent=], ...);
// Usage: With Attachments
//   glued_circles(r/d=, [spread=], [tangent=], ...) { attachments }
// Usage: As Function
//   path = glued_circles(r/d=, [spread=], [tangent=], ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), oval()
// Description:
//   When called as a function, returns a 2D path forming a shape of two circles joined by curved waist.
//   When called as a module, creates a 2D shape of two circles joined by curved waist.
// Arguments:
//   r = The radius of the end circles.
//   spread = The distance between the centers of the end circles.  Default: 10
//   tangent = The angle in degrees of the tangent point for the joining arcs, measured away from the Y axis.  Default: 30
//   ---
//   d = The diameter of the end circles.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Examples(2D):
//   glued_circles(r=15, spread=40, tangent=45);
//   glued_circles(d=30, spread=30, tangent=30);
//   glued_circles(d=30, spread=30, tangent=15);
//   glued_circles(d=30, spread=30, tangent=-30);
// Example(2D): Called as Function
//   stroke(closed=true, glued_circles(r=15, spread=40, tangent=45));
function glued_circles(r, spread=10, tangent=30, d, anchor=CENTER, spin=0) =
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
        ),
        maxx_idx = max_index(subindex(path,0)),
        path2 = reverse_polygon(polygon_shift(path,maxx_idx))
    ) reorient(anchor,spin, two_d=true, path=path2, extent=true, p=path2);


module glued_circles(r, spread=10, tangent=30, d, anchor=CENTER, spin=0) {
    path = glued_circles(r=r, d=d, spread=spread, tangent=tangent);
    attachable(anchor,spin, two_d=true, path=path, extent=true) {
        polygon(path);
        children();
    }
}


// Function&Module: star()
// Usage: As Module
//   star(n, r/or, ir, [realign=], [align_tip=], [align_pit=], ...);
//   star(n, r/or, step=, ...);
// Usage: With Attachments
//   star(n, r/or, ir, ...) { attachments }
// Usage: As Function
//   path = star(n, r/or, ir, [realign=], [align_tip=], [align_pit=], ...);
//   path = star(n, r/or, step=, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), oval()
// Description:
//   When called as a function, returns the path needed to create a star polygon with N points.
//   When called as a module, creates a star polygon with N points.
// Arguments:
//   n = The number of stellate tips on the star.
//   r/or = The radius to the tips of the star.
//   ir = The radius to the inner corners of the star.
//   ---
//   d/od = The diameter to the tips of the star.
//   id = The diameter to the inner corners of the star.
//   step = Calculates the radius of the inner star corners by virtually drawing a straight line `step` tips around the star.  2 <= step < n/2
//   realign = If false, a tip is aligned with the Y+ axis.  If true, an inner corner is aligned with the Y+ axis.  Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first star tip points in that direction.  This occurs before spin.
//   align_pit = If given as a 2D vector, rotates the whole shape so that the first inner corner is pointed towards that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip4" = Each tip has an anchor, pointing outwards.
//   "pit0" ... "pit4" = The inside corner between each tip has an anchor, pointing outwards.
//   "midpt0" ... "midpt4" = The center-point between each pair of tips has an anchor, pointing outwards.
// Examples(2D):
//   star(n=5, r=50, ir=25);
//   star(n=5, r=50, step=2);
//   star(n=7, r=50, step=2);
//   star(n=7, r=50, step=3);
// Example(2D): Realigned
//   star(n=7, r=50, step=3, realign=true);
// Example(2D): Alignment by Tip
//   star(n=5, ir=15, or=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Pit
//   star(n=5, ir=15, or=30, align_pit=BACK+RIGHT)
//       attach("pit0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Called as Function
//   stroke(closed=true, star(n=5, r=50, ir=25));
function star(n, r, ir, d, or, od, id, step, realign=false, align_tip, align_pit, anchor=CENTER, spin=0, _mat, _anchs) =
    assert(is_undef(align_tip) || is_vector(align_tip))
    assert(is_undef(align_pit) || is_vector(align_pit))
    assert(is_undef(align_tip) || is_undef(align_pit), "Can only specify one of align_tip and align_pit")
    let(
        r = get_radius(r1=or, d1=od, r=r, d=d),
        count = num_defined([ir,id,step]),
        stepOK = is_undef(step) || (step>1 && step<n/2)
    )
    assert(is_def(n), "Must specify number of points, n")
    assert(count==1, "Must specify exactly one of ir, id, step")
    assert(stepOK, str("Parameter 'step' must be between 2 and ",floor(n/2)," for ",n," point star"))
    let(
        mat = !is_undef(_mat) ? _mat :
            ( realign? rot(-180/n, planar=true) : affine2d_identity() ) * (
                !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip), planar=true) :
                !is_undef(align_pit)? rot(from=RIGHT, to=point2d(align_pit), planar=true) * rot(180/n, planar=true) :
                affine2d_identity()
            ),
        stepr = is_undef(step)? r : r*cos(180*step/n)/cos(180*(step-1)/n),
        ir = get_radius(r=ir, d=id, dflt=stepr),
        offset = realign? 180/n : 0,
        path1 = [for(i=[2*n:-1:1]) let(theta=180*i/n, radius=(i%2)?ir:r) radius*[cos(theta), sin(theta)]],
        path = apply(mat, path1),
        anchors = !is_undef(_anchs) ? _anchs :
            !is_string(anchor)? [] : [
            for (i = [0:1:n-1]) let(
                a1 = 360 - i*360/n,
                a2 = a1 - 180/n,
                a3 = a1 - 360/n,
                p1 = apply(mat, polar_to_xy(r,a1)),
                p2 = apply(mat, polar_to_xy(ir,a2)),
                p3 = apply(mat, polar_to_xy(r,a3)),
                pos = (p1+p3)/2
            ) each [
                anchorpt(str("tip",i), p1, unit(p1,BACK), 0),
                anchorpt(str("pit",i), p2, unit(p2,BACK), 0),
                anchorpt(str("midpt",i), pos, unit(pos,BACK), 0),
            ]
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path, anchors=anchors);


module star(n, r, ir, d, or, od, id, step, realign=false, align_tip, align_pit, anchor=CENTER, spin=0) {
    assert(is_undef(align_tip) || is_vector(align_tip));
    assert(is_undef(align_pit) || is_vector(align_pit));
    assert(is_undef(align_tip) || is_undef(align_pit), "Can only specify one of align_tip and align_pit");
    r = get_radius(r1=or, d1=od, r=r, d=d, dflt=undef);
    stepr = is_undef(step)? r : r*cos(180*step/n)/cos(180*(step-1)/n);
    ir = get_radius(r=ir, d=id, dflt=stepr);
    mat = ( realign? rot(-180/n, planar=true) : affine2d_identity() ) * (
            !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip), planar=true) :
            !is_undef(align_pit)? rot(from=RIGHT, to=point2d(align_pit), planar=true) * rot(180/n, planar=true) :
            affine2d_identity()
        );
    anchors = [
        for (i = [0:1:n-1]) let(
            a1 = 360 - i*360/n - (realign? 180/n : 0),
            a2 = a1 - 180/n,
            a3 = a1 - 360/n,
            p1 = apply(mat, polar_to_xy(r,a1)),
            p2 = apply(mat, polar_to_xy(ir,a2)),
            p3 = apply(mat, polar_to_xy(r,a3)),
            pos = (p1+p3)/2
        ) each [
            anchorpt(str("tip",i), p1, unit(p1,BACK), 0),
            anchorpt(str("pit",i), p2, unit(p2,BACK), 0),
            anchorpt(str("midpt",i), pos, unit(pos,BACK), 0),
        ]
    ];
    path = star(n=n, r=r, ir=ir, realign=realign, _mat=mat, _anchs=anchors);
    attachable(anchor,spin, two_d=true, path=path, anchors=anchors) {
        polygon(path);
        children();
    }
}


function _superformula(theta,m1,m2,n1,n2=1,n3=1,a=1,b=1) =
    pow(pow(abs(cos(m1*theta/4)/a),n2)+pow(abs(sin(m2*theta/4)/b),n3),-1/n1);

// Function&Module: supershape()
// Usage: As Module
//   supershape(step, [m1=], [m2=], [n1=], [n2=], [n3=], [a=], [b=], <r=/d=>);
// Usage: With Attachments
//   supershape(step, [m1=], [m2=], [n1=], [n2=], [n3=], [a=], [b=], <r=/d=>) { attachments }
// Usage: As Function
//   path = supershape(step, [m1=], [m2=], [n1=], [n2=], [n3=], [a=], [b=], <r=/d=>);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), oval()
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
//   ---
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
function supershape(step=0.5, m1=4, m2, n1=1, n2, n3, a=1, b, r, d,anchor=CENTER, spin=0) =
    let(
        r = get_radius(r=r, d=d, dflt=undef),
        m2 = is_def(m2) ? m2 : m1,
        n2 = is_def(n2) ? n2 : n1,
        n3 = is_def(n3) ? n3 : n2,
        b = is_def(b) ? b : a,
        steps = ceil(360/step),
        step = 360/steps,
        angs = [for (i = [0:steps]) step*i],
        rads = [for (theta = angs) _superformula(theta=theta,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b)],
        scale = is_def(r) ? r/max(rads) : 1,
        path = [for (i = [steps:-1:1]) let(a=angs[i]) scale*rads[i]*[cos(a), sin(a)]]
    ) reorient(anchor,spin, two_d=true, path=path, p=path);

module supershape(step=0.5,m1=4,m2=undef,n1,n2=undef,n3=undef,a=1,b=undef, r=undef, d=undef, anchor=CENTER, spin=0) {
    path = supershape(step=step,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b,r=r,d=d);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}


// Function&Module: reuleaux_polygon()
// Usage: As Module
//   reuleaux_polygon(N, r|d, ...);
// Usage: As Function
//   path = reuleaux_polygon(N, r|d, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: regular_ngon(), pentagon(), hexagon(), octagon()
// Description:
//   Creates a 2D Reuleaux Polygon; a constant width shape that is not circular.
// Arguments:
//   N = Number of "sides" to the Reuleaux Polygon.  Must be an odd positive number.  Default: 3
//   r = Radius of the shape.  Scale shape to fit in a circle of radius r.
//   ---
//   d = Diameter of the shape.  Scale shape to fit in a circle of diameter d.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Extra Anchors:
//   "tip0", "tip1", etc. = Each tip has an anchor, pointing outwards.
// Examples(2D):
//   reuleaux_polygon(N=3, r=50);
//   reuleaux_polygon(N=5, d=100);
// Examples(2D): Standard vector anchors are based on extents
//   reuleaux_polygon(N=3, d=50) show_anchors(custom=false);
// Examples(2D): Named anchors exist for the tips
//   reuleaux_polygon(N=3, d=50) show_anchors(std=false);
module reuleaux_polygon(N=3, r, d, anchor=CENTER, spin=0) {
    assert(N>=3 && (N%2)==1);
    r = get_radius(r=r, d=d, dflt=1);
    path = reuleaux_polygon(N=N, r=r);
    anchors = [
        for (i = [0:1:N-1]) let(
            ca = 360 - i * 360/N,
            cp = polar_to_xy(r, ca)
        ) anchorpt(str("tip",i), cp, unit(cp,BACK), 0),
    ];
    attachable(anchor,spin, two_d=true, path=path, anchors=anchors) {
        polygon(path);
        children();
    }
}


function reuleaux_polygon(N=3, r, d, anchor=CENTER, spin=0) =
    assert(N>=3 && (N%2)==1)
    let(
        r = get_radius(r=r, d=d, dflt=1),
        ssegs = max(3,ceil(segs(r)/N)),
        slen = norm(polar_to_xy(r,0)-polar_to_xy(r,180-180/N)),
        path = [
            for (i = [0:1:N-1]) let(
                ca = 180 - (i+0.5) * 360/N,
                sa = ca + 180 + (90/N),
                ea = ca + 180 - (90/N),
                cp = polar_to_xy(r, ca)
            ) each arc(N=ssegs-1, r=slen, cp=cp, angle=[sa,ea], endpoint=false)
        ],
        anchors = [
            for (i = [0:1:N-1]) let(
                ca = 360 - i * 360/N,
                cp = polar_to_xy(r, ca)
            ) anchorpt(str("tip",i), cp, unit(cp,BACK), 0),
        ]
    ) reorient(anchor,spin, two_d=true, path=path, anchors=anchors, p=path);


// Section: 2D Masking Shapes

// Function&Module: mask2d_roundover()
// Usage: As Module
//   mask2d_roundover(r|d, [inset], [excess]);
// Usage: With Attachments
//   mask2d_roundover(r|d, [inset], [excess]) { attachments }
// Usage: As Module
//   path = mask2d_roundover(r|d, [inset], [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D roundover/bead mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   r = Radius of the roundover.
//   inset = Optional bead inset size.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   d = Diameter of the roundover.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): 2D Roundover Mask
//   mask2d_roundover(r=10);
// Example(2D): 2D Bead Mask
//   mask2d_roundover(r=10,inset=2);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_roundover(r=10, inset=2);
module mask2d_roundover(r, inset=0, excess=0.01, d, anchor=CENTER,spin=0) {
    path = mask2d_roundover(r=r,d=d,excess=excess,inset=inset);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

function mask2d_roundover(r, inset=0, excess=0.01, d, anchor=CENTER,spin=0) =
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
            [r+inset.x,-excess],
            [-excess,-excess],
            [-excess, r+inset.y],
            for (i=[0:1:steps]) [r,r] + inset + polar_to_xy(r,180+i*step)
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


// Function&Module: mask2d_cove()
// Usage: As Module
//   mask2d_cove(r|d, [inset], [excess]);
// Usage: With Attachments
//   mask2d_cove(r|d, [inset], [excess]) { attachments }
// Usage: As Function
//   path = mask2d_cove(r|d, [inset], [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D cove mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   r = Radius of the cove.
//   inset = Optional amount to inset code from corner.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   d = Diameter of the cove.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): 2D Cove Mask
//   mask2d_cove(r=10);
// Example(2D): 2D Inset Cove Mask
//   mask2d_cove(r=10,inset=3);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_cove(r=10, inset=2);
module mask2d_cove(r, inset=0, excess=0.01, d, anchor=CENTER,spin=0) {
    path = mask2d_cove(r=r,d=d,excess=excess,inset=inset);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

function mask2d_cove(r, inset=0, excess=0.01, d, anchor=CENTER,spin=0) =
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
            [r+inset.x,-excess],
            [-excess,-excess],
            [-excess, r+inset.y],
            for (i=[0:1:steps]) inset + polar_to_xy(r,90-i*step)
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path);


// Function&Module: mask2d_chamfer()
// Usage: As Module
//   mask2d_chamfer(edge, [angle], [inset], [excess]);
//   mask2d_chamfer(y, [angle], [inset], [excess]);
//   mask2d_chamfer(x, [angle], [inset], [excess]);
// Usage: With Attachments
//   mask2d_chamfer(edge, [angle], [inset], [excess]) { attachments }
// Usage: As Function
//   path = mask2d_chamfer(edge, [angle], [inset], [excess]);
//   path = mask2d_chamfer(y, [angle], [inset], [excess]);
//   path = mask2d_chamfer(x, [angle], [inset], [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D chamfer mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   edge = The length of the edge of the chamfer.
//   angle = The angle of the chamfer edge, away from vertical.  Default: 45.
//   inset = Optional amount to inset code from corner.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   x = The width of the chamfer.
//   y = The height of the chamfer.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
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
module mask2d_chamfer(edge, angle=45, inset=0, excess=0.01, x, y, anchor=CENTER,spin=0) {
    path = mask2d_chamfer(x=x, y=y, edge=edge, angle=angle, excess=excess, inset=inset);
    attachable(anchor,spin, two_d=true, path=path, extent=true) {
        polygon(path);
        children();
    }
}

function mask2d_chamfer(edge, angle=45, inset=0, excess=0.01, x, y, anchor=CENTER,spin=0) =
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
            [x+inset.x, -excess],
            [-excess, -excess],
            [-excess, y+inset.y],
            [inset.x, y+inset.y],
            [x+inset.x, inset.y]
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=true, p=path);


// Function&Module: mask2d_rabbet()
// Usage: As Module
//   mask2d_rabbet(size, [excess]);
// Usage: With Attachments
//   mask2d_rabbet(size, [excess]) { attachments }
// Usage: As Function
//   path = mask2d_rabbet(size, [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D rabbet mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   size = The size of the rabbet, either as a scalar or an [X,Y] list.
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): 2D Rabbet Mask
//   mask2d_rabbet(size=10);
// Example(2D): 2D Asymmetrical Rabbet Mask
//   mask2d_rabbet(size=[5,10]);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_rabbet(size=10);
module mask2d_rabbet(size, excess=0.01, anchor=CENTER,spin=0) {
    path = mask2d_rabbet(size=size, excess=excess);
    attachable(anchor,spin, two_d=true, path=path, extent=false) {
        polygon(path);
        children();
    }
}

function mask2d_rabbet(size, excess=0.01, anchor=CENTER,spin=0) =
    assert(is_num(size)||(is_vector(size)&&len(size)==2))
    assert(is_undef(excess)||is_num(excess))
    let(
        excess = default(excess,$overlap),
        size = is_list(size)? size : [size,size],
        path = [
            [size.x, -excess],
            [-excess, -excess],
            [-excess, size.y],
            size
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


// Function&Module: mask2d_dovetail()
// Usage: As Module
//   mask2d_dovetail(edge, [angle], [inset], [shelf], [excess], ...);
//   mask2d_dovetail(x=, [angle=], [inset=], [shelf=], [excess=], ...);
//   mask2d_dovetail(y=, [angle=], [inset=], [shelf=], [excess=], ...);
// Usage: With Attachments
//   mask2d_dovetail(edge, [angle], [inset], [shelf], ...) { attachments }
// Usage: As Function
//   path = mask2d_dovetail(edge, [angle], [inset], [shelf], [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D dovetail mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   edge = The length of the edge of the dovetail.
//   angle = The angle of the chamfer edge, away from vertical.  Default: 30.
//   inset = Optional amount to inset code from corner.  Default: 0
//   shelf = The extra height to add to the inside corner of the dovetail.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   x = The width of the dovetail.
//   y = The height of the dovetail.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
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
module mask2d_dovetail(edge, angle=30, inset=0, shelf=0, excess=0.01, x, y, anchor=CENTER, spin=0) {
    path = mask2d_dovetail(x=x, y=y, edge=edge, angle=angle, inset=inset, shelf=shelf, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

function mask2d_dovetail(edge, angle=30, inset=0, shelf=0, excess=0.01, x, y, anchor=CENTER, spin=0) =
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
            [inset.x,0],
            [-excess, 0],
            [-excess, y+inset.y+shelf],
            inset+[x,y+shelf],
            inset+[x,y],
            inset
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path);


// Function&Module: mask2d_teardrop()
// Usage: As Module
//   mask2d_teardrop(r|d, [angle], [excess]);
// Usage: With Attachments
//   mask2d_teardrop(r|d, [angle], [excess]) { attachments }
// Usage: As Function
//   path = mask2d_teardrop(r|d, [angle], [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D teardrop mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   This is particularly useful to make partially rounded bottoms, that don't need support to print.
// Arguments:
//   r = Radius of the rounding.
//   angle = The maximum angle from vertical.
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   d = Diameter of the rounding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): 2D Teardrop Mask
//   mask2d_teardrop(r=10);
// Example(2D): Using a Custom Angle
//   mask2d_teardrop(r=10,angle=30);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile(BOT)
//           mask2d_teardrop(r=10, angle=40);
function mask2d_teardrop(r, angle=45, excess=0.01, d, anchor=CENTER, spin=0) =  
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

module mask2d_teardrop(r, angle=45, excess=0.01, d, anchor=CENTER, spin=0) {
    path = mask2d_teardrop(r=r, d=d, angle=angle, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

// Function&Module: mask2d_ogee()
// Usage: As Module
//   mask2d_ogee(pattern, [excess], ...);
// Usage: With Attachments
//   mask2d_ogee(pattern, [excess], ...) { attachments }
// Usage: As Function
//   path = mask2d_ogee(pattern, [excess], ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
//
// Description:
//   Creates a 2D Ogee mask shape that is useful for extruding into a 3D mask for a 90º edge.
//   This 2D mask is designed to be `difference()`d  away from the edge of a shape that is in the first (X+Y+) quadrant.
//   Since there are a number of shapes that fall under the name ogee, the shape of this mask is given as a pattern.
//   Patterns are given as TYPE, VALUE pairs.  ie: `["fillet",10, "xstep",2, "step",[5,5], ...]`.  See Patterns below.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   .
//   ### Patterns
//   .
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
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//
// Example(2D): 2D Ogee Mask
//   mask2d_ogee([
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,  "xstep",1   // Ending shoulder.
//   ]);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile(TOP)
//           mask2d_ogee([
//               "xstep",1,  "ystep",1,  // Starting shoulder.
//               "fillet",5, "round",5,  // S-curve.
//               "ystep",1,  "xstep",1   // Ending shoulder.
//           ]);
module mask2d_ogee(pattern, excess=0.01, anchor=CENTER,spin=0) {
    path = mask2d_ogee(pattern, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

function mask2d_ogee(pattern, excess=0.01, anchor=CENTER, spin=0) =
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
        tot_x = last(x),
        tot_y = last(y),
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



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
