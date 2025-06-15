//////////////////////////////////////////////////////////////////////
// LibFile: drawing.scad
//   This file includes stroke(), which converts a path into a
//   geometric object, like drawing with a pen.  It even works on
//   three-dimensional paths.  You can make a dashed line or add arrow
//   heads.  The turtle() function provides a turtle graphics style
//   approach for producing paths.  The arc() function produces arc paths,
//   and helix() produces helical paths.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Create and draw 2D and 3D paths: arc, helix, turtle graphics
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: Line Drawing

// Module: stroke()
// Synopsis: Draws a line along a path or region boundary.
// SynTags: Geom
// Topics: Paths (2D), Paths (3D), Drawing Tools
// See Also: dashed_stroke(), offset_stroke(), path_sweep()
// Usage:
//   stroke(path, [width], [closed], [endcaps], [endcap_width], [endcap_length], [endcap_extent], [trim]);
//   stroke(path, [width], [closed], [endcap1], [endcap2], [endcap_width1], [endcap_width2], [endcap_length1], [endcap_length2], [endcap_extent1], [endcap_extent2], [trim1], [trim2]);
// Description:
//   Draws a 2D or 3D path with a given line width.  Joints and each endcap can be replaced with
//   various marker shapes, and can be assigned different colors.  If passed a region instead of
//   a path, draws each path in the region as a closed polygon by default. If `closed=false` is
//   given with a region or list of paths, then each path is drawn without the closing line segment.
//   When drawing a closed path or region, there are no endcaps, so you cannot give the endcap parameters. 
//   To facilitate debugging, stroke() accepts "paths" that have a single point.  These are drawn with
//   the style of endcap1, but have their own scale parameter, `singleton_scale`, which defaults to 2
//   so that singleton dots with endcap "round" are clearly visible.
//   .
//   In 2d the stroke module works by creating a sequence of rectangles (or trapezoids if line width varies) and
//   filling in the gaps with rounded wedges.  This is fast and produces a good result.  In 3d the modules
//   creates a cylinders (or cones) and fills the gaps with rounded wedges made using rotate_extrude.  This process is slow for
//   long paths due to the 3d unions, and the faces on sequential cylinders may not line up.  In many cases, {{path_sweep()}} is
//   a better choice, both running faster and producing superior output, when working in three dimensions. 
// Figure(Med,NoAxes,2D,VPR=[0,0,0],VPD=255): Endcap Types
//   cap_pairs = [
//       ["butt",  "chisel" ],
//       ["round", "square" ],
//       ["line",  "cross"  ],
//       ["x",     "diamond"],
//       ["dot",   "block"  ],
//       ["tail",  "arrow"  ],
//       ["tail2", "arrow2" ],
//       [undef, "arrow3" ]
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
//   joints  = Specifies the joint shape for each joint of the line.  If a 2D polygon is given, use that to draw custom joints.
//   endcaps = Specifies the endcap type for both ends of the line.  If a 2D polygon is given, use that to draw custom endcaps.
//   endcap1 = Specifies the endcap type for the start of the line.  If a 2D polygon is given, use that to draw a custom endcap.
//   endcap2 = Specifies the endcap type for the end of the line.  If a 2D polygon is given, use that to draw a custom endcap.
//   dots = Specifies both the endcap and joint types with one argument.  If given `true`, sets both to "dot".  If a 2D polygon is given, uses that to draw custom dots.
//   joint_width = Some joint shapes are wider than the line.  This specifies the width of the shape, in multiples of the line width.
//   endcap_width = Some endcap types are wider than the line.  This specifies the size of endcaps, in multiples of the line width.
//   endcap_width1 = This specifies the size of starting endcap, in multiples of the line width.
//   endcap_width2 = This specifies the size of ending endcap, in multiples of the line width.
//   dots_width = This specifies the size of the joints and endcaps, in multiples of the line width.
//   joint_length = Length of joint shape, in multiples of the line width.
//   endcap_length = Length of endcaps, in multiples of the line width.
//   endcap_length1 = Length of starting endcap, in multiples of the line width.
//   endcap_length2 = Length of ending endcap, in multiples of the line width.
//   dots_length = Length of both joints and endcaps, in multiples of the line width.
//   joint_extent = Extents length of joint shape, in multiples of the line width.
//   endcap_extent = Extents length of endcaps, in multiples of the line width.
//   endcap_extent1 = Extents length of starting endcap, in multiples of the line width.
//   endcap_extent2 = Extents length of ending endcap, in multiples of the line width.
//   dots_extent = Extents length of both joints and endcaps, in multiples of the line width.
//   joint_angle = Extra rotation given to joint shapes, in degrees.  If not given, the shapes are fully spun (for 3D lines).
//   endcap_angle = Extra rotation given to endcaps, in degrees.  If not given, the endcaps are fully spun (for 3D lines).
//   endcap_angle1 = Extra rotation given to a starting endcap, in degrees.  If not given, the endcap is fully spun (for 3D lines).
//   endcap_angle2 = Extra rotation given to a ending endcap, in degrees.  If not given, the endcap is fully spun (for 3D lines).
//   dots_angle = Extra rotation given to both joints and endcaps, in degrees.  If not given, the endcap is fully spun (for 3D lines).
//   trim = Trim the the start and end line segments by this much, to keep them from interfering with custom endcaps.
//   trim1 = Trim the the starting line segment by this much, to keep it from interfering with a custom endcap.
//   trim2 = Trim the the ending line segment by this much, to keep it from interfering with a custom endcap.
//   color = If given, sets the color of the line segments, joints and endcap.
//   endcap_color = If given, sets the color of both endcaps.  Overrides `color=` and `dots_color=`.
//   endcap_color1 = If give, sets the color of the starting endcap.  Overrides `color=`, `dots_color=`,  and `endcap_color=`.
//   endcap_color2 = If given, sets the color of the ending endcap.  Overrides `color=`, `dots_color=`,  and `endcap_color=`.
//   joint_color = If given, sets the color of the joints.  Overrides `color=` and `dots_color=`.
//   dots_color = If given, sets the color of the endcaps and joints.  Overrides `color=`.
//   singleton_scale = Change the scale of the endcap shape drawn for singleton paths.  Default: 2.  
//   convexity = Max number of times a line could intersect a wall of an endcap.
// Example(2D): Drawing a Path
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=20);
// Example(2D): Closing a Path
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=20, closed=true);
// Example(2D): Fancy Arrow Endcaps
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=10, endcaps="arrow2");
// Example(2D): Modified Fancy Arrow Endcaps
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=10, endcaps="arrow2", endcap_width=6, endcap_length=3, endcap_extent=2);
// Example(2D): Mixed Endcaps
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=10, endcap1="tail2", endcap2="arrow2");
// Example(2D): Plotting Points.  Setting endcap_angle to zero results in the weird arrow orientation. 
//   path = [for (a=[0:30:360]) [a-180, 60*sin(a)]];
//   stroke(path, width=3, joints="diamond", endcaps="arrow2", endcap_angle=0, endcap_width=5, joint_angle=0, joint_width=5);
// Example(2D): Default joint gives curves along outside corners of the path:
//   stroke([square(40)], width=18);
// Example(2D): Setting `joints="square"` gives flat outside corners 
//   stroke([square(40)], width=18, joints="square");
// Example(2D): Setting `joints="butt"` does not draw any transitions, just rectangular strokes for each segment, meeting at their centers:
//   stroke([square(40)], width=18, joints="butt");
// Example(2D): Joints and Endcaps
//   path = [for (a=[0:30:360]) [a-180, 60*sin(a)]];
//   stroke(path, width=8, joints="dot", endcaps="arrow2");
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
// Example: Coloring Lines, Joints, and Endcaps
//   path = [for (i=[0:15:360]) [(i-180)/3,20*cos(2*i),20*sin(2*i)]];
//   stroke(
//       path, width=2, joints="dot", endcap1="dot", endcap2="arrow2",
//       color="lightgreen", joint_color="red", endcap_color="blue",
//       joint_width=2.0, endcap_width2=3, $fn=18
//   );
// Example(2D): Simplified Plotting
//   path = [for (i=[0:15:360]) [(i-180)/3,20*cos(2*i)]];
//   stroke(path, width=2, dots=true, color="lightgreen", dots_color="red", $fn=18);
// Example(2D): Drawing a Region
//   rgn = [square(100,center=true), circle(d=60,$fn=18)];
//   stroke(rgn, width=2);
// Example(2D): Drawing a List of Lines
//   paths = [
//       for (y=[-60:60:60]) [
//           for (a=[-180:15:180])
//           [a, 2*y+60*sin(a+y)]
//       ]
//   ];
//   stroke(paths, closed=false, width=5);
// Example(2D): Paths with a singleton.  Note that the singleton is not a single point, but a list containing a single point.  
//   stroke([
//           [[0,0],[1,1]],
//           [[1.5,1.5]],
//           [[2,2],[3,3]]
//          ],width=0.2,closed=false,$fn=16);
function stroke(
    path, width=1, closed,
    endcaps,       endcap1,        endcap2,        joints,       dots,
    endcap_width,  endcap_width1,  endcap_width2,  joint_width,  dots_width,
    endcap_length, endcap_length1, endcap_length2, joint_length, dots_length,
    endcap_extent, endcap_extent1, endcap_extent2, joint_extent, dots_extent,
    endcap_angle,  endcap_angle1,  endcap_angle2,  joint_angle,  dots_angle,
    endcap_color,  endcap_color1,  endcap_color2,  joint_color,  dots_color, color,
    trim, trim1, trim2, singleton_scale=2,
    convexity=10
) = no_function("stroke");


module stroke(
    path, width=1, closed,
    endcaps,       endcap1,        endcap2,        joints,       dots,
    endcap_width,  endcap_width1,  endcap_width2,  joint_width,  dots_width,
    endcap_length, endcap_length1, endcap_length2, joint_length, dots_length,
    endcap_extent, endcap_extent1, endcap_extent2, joint_extent, dots_extent,
    endcap_angle,  endcap_angle1,  endcap_angle2,  joint_angle,  dots_angle,
    endcap_color,  endcap_color1,  endcap_color2,  joint_color,  dots_color, color,
    trim, trim1, trim2, singleton_scale=2,
    convexity=10
) {
    no_children($children);
    module setcolor(clr) {
        if (clr==undef) {
            children();
        } else {
            color(clr) children();
        }
    }
    function _shape_defaults(cap) =
        cap==undef?     [1.00, 0.00, 0.00] :
        cap==false?     [1.00, 0.00, 0.00] :
        cap==true?      [1.00, 1.00, 0.00] :
        cap=="butt"?    [1.00, 0.00, 0.00] :
        cap=="round"?   [1.00, 1.00, 0.00] :
        cap=="chisel"?  [1.00, 1.00, 0.00] :
        cap=="square"?  [1.00, 1.00, 0.00] :
        cap=="block"?   [2.00, 1.00, 0.00] :
        cap=="diamond"? [2.50, 1.00, 0.00] :
        cap=="dot"?     [2.00, 1.00, 0.00] :
        cap=="x"?       [2.50, 0.40, 0.00] :
        cap=="cross"?   [3.00, 0.33, 0.00] :
        cap=="line"?    [3.50, 0.22, 0.00] :
        cap=="arrow"?   [3.50, 0.40, 0.50] :
        cap=="arrow2"?  [3.50, 1.00, 0.14] :
        cap=="arrow3"?  [3.50, 1.00, 0.00] :
        cap=="tail"?    [3.50, 0.47, 0.50] :
        cap=="tail2"?   [3.50, 0.28, 0.50] :
        is_path(cap)?   [0.00, 0.00, 0.00] :
        assert(false, str("Invalid cap or joint: ",cap));

    function _shape_path(cap,linewidth,w,l,l2) = (
        cap=="butt" || cap==false || cap==undef ? [] : 
        cap=="round" || cap==true ? scale([w,l], p=circle(d=1, $fn=max(8, segs(w/2)))) :
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
        cap=="arrow3"?  [[0,0], [w/2,-l], [-w/2,-l]] :
        cap=="tail"?    [[0,0], [w/2,l2], [w/2,l2-l], [0,-l], [-w/2,l2-l], [-w/2,l2]] :
        cap=="tail2"?   [[w/2,0], [w/2,-l], [0,-l-l2], [-w/2,-l], [-w/2,0]] :
        is_path(cap)? cap :
        assert(false, str("Invalid endcap: ",cap))
    ) * linewidth;

    closed = default(closed, is_region(path));
    check1 = assert(is_bool(closed))
             assert(!closed || num_defined([endcaps,endcap1,endcap2])==0, "Cannot give endcap parameter(s) with closed path or region");

    dots = dots==true? "dot" : dots;

    endcap1 = first_defined([endcap1, endcaps, dots, "round"]);
    endcap2 = first_defined([endcap2, endcaps, if (!closed) dots, "round"]);
    joints  = first_defined([joints, dots, "round"]);
    check2 =
      assert(is_bool(endcap1) || is_string(endcap1) || is_path(endcap1))
      assert(is_bool(endcap2) || is_string(endcap2) || is_path(endcap2))
      assert(is_bool(joints)  || is_string(joints)  || is_path(joints));

    endcap1_dflts = _shape_defaults(endcap1);
    endcap2_dflts = _shape_defaults(endcap2);
    joint_dflts   = _shape_defaults(joints);

    endcap_width1 = first_defined([endcap_width1, endcap_width, dots_width, endcap1_dflts[0]]);
    endcap_width2 = first_defined([endcap_width2, endcap_width, dots_width, endcap2_dflts[0]]);
    joint_width   = first_defined([joint_width, dots_width, joint_dflts[0]]);

    endcap_length1 = first_defined([endcap_length1, endcap_length, dots_length, endcap1_dflts[1]*endcap_width1]);
    endcap_length2 = first_defined([endcap_length2, endcap_length, dots_length, endcap2_dflts[1]*endcap_width2]);
    joint_length   = first_defined([joint_length, dots_length, joint_dflts[1]*joint_width]);

    endcap_extent1 = first_defined([endcap_extent1, endcap_extent, dots_extent, endcap1_dflts[2]*endcap_width1]);
    endcap_extent2 = first_defined([endcap_extent2, endcap_extent, dots_extent, endcap2_dflts[2]*endcap_width2]);
    joint_extent   = first_defined([joint_extent, dots_extent, joint_dflts[2]*joint_width]);

    endcap_angle1 = first_defined([endcap_angle1, endcap_angle, dots_angle]);
    endcap_angle2 = first_defined([endcap_angle2, endcap_angle, dots_angle]);
    joint_angle = first_defined([joint_angle, dots_angle]);
    
    check3 =
      assert(all_nonnegative([endcap_length1]))
      assert(all_nonnegative([endcap_length2]))
      assert(all_nonnegative([joint_length]));
      assert(all_nonnegative([endcap_extent1]))
      assert(all_nonnegative([endcap_extent2]))
      assert(all_nonnegative([joint_extent]));
      assert(is_undef(endcap_angle1)||is_finite(endcap_angle1))
      assert(is_undef(endcap_angle2)||is_finite(endcap_angle2))
      assert(is_undef(joint_angle)||is_finite(joint_angle))
      assert(all_positive([singleton_scale]))
      assert(all_positive(width));
      
    endcap_color1 = first_defined([endcap_color1, endcap_color, dots_color, color]);
    endcap_color2 = first_defined([endcap_color2, endcap_color, dots_color, color]);
    joint_color = first_defined([joint_color, dots_color, color]);

    // We want to allow "paths" with length 1, so we can't use the normal path/region checks
    paths = is_matrix(path) ? [path] : path;
    assert(is_list(paths),"The path argument must be a list of 2D or 3D points, or a region.");
    attachable(two_d=len(path[0])==2)
    {
      for (path = paths) {
          pathvalid = is_path(path,[2,3]) || same_shape(path,[[0,0]]) || same_shape(path,[[0,0,0]]);

          check4 = assert(pathvalid,"The path argument must be a list of 2D or 3D points, or a region.")
                   assert(is_num(width) || len(width)==len(path),
                          "width must be a number or a vector the same length as the path (or all components of a region)");
          path = deduplicate( closed? list_wrap(path) : path );
          width = is_num(width)? [for (x=path) width]
                : closed? list_wrap(width)
                : width;
          check4a=assert(len(width)==len(path), "path had duplicated points and width was given as a list: this is not allowd");

          endcap_shape1 = _shape_path(endcap1, width[0], endcap_width1, endcap_length1, endcap_extent1);
          endcap_shape2 = _shape_path(endcap2, last(width), endcap_width2, endcap_length2, endcap_extent2);

          trim1 = width[0] * first_defined([
              trim1, trim,
              (endcap1=="arrow" || endcap1=="arrow3")? endcap_length1-0.01 :
              (endcap1=="arrow2")? endcap_length1*3/4 :
              0
          ]);

          trim2 = last(width) * first_defined([
              trim2, trim,
              (endcap2=="arrow" || endcap2=="arrow3")? endcap_length2-0.01 :
              (endcap2=="arrow2")? endcap_length2*3/4 :
              0
          ]);
          check10 = assert(is_finite(trim1))
                    assert(is_finite(trim2));

          if (len(path) == 1) {
              if (len(path[0]) == 2) {
                  // Endcap1
                  setcolor(endcap_color1) {
                      translate(path[0]) {
                          mat = is_undef(endcap_angle1)? ident(3) : zrot(endcap_angle1);
                          multmatrix(mat) polygon(scale(singleton_scale,endcap_shape1));
                      }
                  }
              } else {
                  // Endcap1
                  setcolor(endcap_color1) {
                      translate(path[0]) {
                          $fn = segs(width[0]/2);
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
              }
          } else {
              dummy=assert(trim1<path_length(path)-trim2, "Path is too short for endcap(s).  Try a smaller width, or set endcap_length to a smaller value.");
              // This section shortens the path to allow room for the specified endcaps.  Note that if
              // the path is closed, there are not endcaps, so we don't shorten the path, but in that case we
              // duplicate entry 1 so that the path wraps around a little more and we can correctly create all the joints.
              // (Why entry 1?  Because entry 0 was already duplicated by a list_wrap() call.)  
              pathcut = path_cut_points(path, [trim1, path_length(path)-trim2], closed=false);
              pathcut_su = _cut_to_seg_u_form(pathcut,path);
              path2 = closed ? [each path, path[1]]
                             : _path_cut_getpaths(path, pathcut, closed=false)[1];
              widths = closed ? [each width, width[1]]
                              : _path_select(width, pathcut_su[0][0], pathcut_su[0][1], pathcut_su[1][0], pathcut_su[1][1]);
              start_vec = path[0] - path[1];
              end_vec = last(path) - select(path,-2);

              if (len(path[0]) == 2) {  // Two dimensional case
                  // Straight segments
                  setcolor(color) {
                      for (i = idx(path2,e=-2)) {
                          seg = select(path2,i,i+1);
                          delt = seg[1] - seg[0];
                          translate(seg[0]) {
                              rot(from=BACK,to=delt) {
                                  trapezoid(w1=widths[i], w2=widths[i+1], h=norm(delt), anchor=FRONT);
                              }
                          }
                      }
                  }

                  // Joints
                  setcolor(joint_color) {
                      for (i = [1:1:len(path2)-2]) {
                          $fn = quantup(segs(widths[i]/2),4);
                          translate(path2[i]) {
                              if (joints != undef && joints != "round" && joints != "square") {
                                  joint_shape = _shape_path(
                                                    joints, widths[i],
                                                    joint_width,
                                                    joint_length,
                                                    joint_extent  
                                  );
                                  v1 = unit(path2[i] - path2[i-1]);
                                  v2 = unit(path2[i+1] - path2[i]);
                                  mat = is_undef(joint_angle)
                                    ? rot(from=BACK,to=v1)
                                    : zrot(joint_angle);
                                  multmatrix(mat) polygon(joint_shape);
                              } else {
                                  // These are parallel to the path
                                  v1 = path2[i] - path2[i-1];
                                  v2 = path2[i+1] - path2[i];
                                  ang = modang(v_theta(v2) - v_theta(v1));
                                  // Need 90 deg offset to make wedge perpendicular to path, and the wedge
                                  // position depends on whether we turn left (ang<0) or right (ang>0)
                                  theta = v_theta(v1) - sign(ang)*90;

                                  if (!approx(ang,0)){
                                      // This section creates a rounded wedge to fill in gaps.  The wedge needs to be oversized for overlap
                                      // in all directions, including its apex, but not big enough to create artifacts.
                                      // The core of the wedge is the proper arc we need to create.  We then add side points based
                                      // on firstang and secondang, where we try 1 degree, but if that appears too big we based it
                                      // on the segment length.  We pick the radius based on the smaller of the width at this point
                                      // and the adjacent width, which could be much smaller---meaning that we need a much smaller radius.
                                      // The apex offset we pick to be simply based on the width at this point. 
                                      firstang = sign(ang)*min(1,0.5*norm(v1)/PI/widths[i]*360);
                                      secondang = sign(ang)*min(1,0.5*norm(v2)/PI/widths[i]*360);
                                      firstR = 0.5*min(widths[i], lerp(widths[i],widths[i-1], abs(firstang)*PI*widths[i]/360/norm(v1)));
                                      secondR = 0.5*min(widths[i], lerp(widths[i],widths[i+1], abs(secondang)*PI*widths[i]/360/norm(v2)));
                                      apex_offset = widths[i]/10;
                                      arcpath = [
                                                 firstR*[cos(theta-firstang), sin(theta-firstang)], 
                                                 each arc(d=widths[i], angle=[theta, theta+ang],n=joints=="square"?2:undef),
                                                 secondR*[cos(theta+ang+secondang), sin(theta+ang+secondang)],
                                                 -apex_offset*[cos(theta+ang/2), sin(theta+ang/2)]
                                      ];
                                      polygon(arcpath);
                                  }
                              }
                          }
                      }
                  }
                  if (!closed){
                    // Endcap1
                    setcolor(endcap_color1) {
                        translate(path[0]) {
                            mat = is_undef(endcap_angle1)? rot(from=BACK,to=start_vec) :
                                zrot(endcap_angle1);
                            multmatrix(mat) polygon(endcap_shape1);
                        }
                    }

                    // Endcap2
                    setcolor(endcap_color2) {
                        translate(last(path)) {
                            mat = is_undef(endcap_angle2)? rot(from=BACK,to=end_vec) :
                                zrot(endcap_angle2);
                            multmatrix(mat) polygon(endcap_shape2);
                        }
                    }
                  }
              } else {  // Three dimensional case
                  rotmats = cumprod([
                      for (i = idx(path2,e=-2)) let(
                          vec1 = i==0? UP : unit(path2[i]-path2[i-1], UP),
                          vec2 = unit(path2[i+1]-path2[i], UP)
                      ) rot(from=vec1,to=vec2)
                  ]);

                  sides = [
                      for (i = idx(path2,e=-2))
                      quantup(segs(max(widths[i],widths[i+1])/2),4)
                  ];

                  // Straight segments
                  setcolor(color) {
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
                  }

                  // Joints
                  setcolor(joint_color) {
                      for (i = [1:1:len(path2)-2]) {
                          $fn = sides[i];
                          translate(path2[i]) {
                              if (joints != undef && joints != "round") {
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
                              } else {
                                  corner = select(path2,i-1,i+1);
                                  axis = vector_axis(corner);
                                  ang = vector_angle(corner);
                                  if (!approx(ang,0)) {
                                      frame_map(x=path2[i-1]-path2[i], z=-axis) {
                                          zrot(90-0.5) {
                                              rotate_extrude(angle=180-ang+1) {
                                                  arc(d=widths[i], start=-90, angle=180);
                                              }
                                          }
                                      }
                                  }
                              }
                          }
                      }
                  }
                  if (!closed){
                    // Endcap1
                    setcolor(endcap_color1) {
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
                    }

                    // Endcap2
                    setcolor(endcap_color2) {
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
          }
      }
      union();
    }
}


// Function&Module: dashed_stroke()
// Synopsis: Draws a dashed line along a path or region boundary.
// SynTags: Geom, PathList
// Topics: Paths, Drawing Tools
// See Also: stroke(), path_cut()
// Usage: As a Module
//   dashed_stroke(path, dashpat, [width=], [closed=]);
// Usage: As a Function
//   dashes = dashed_stroke(path, dashpat, [closed=]);
// Description:
//   Given a path (or region) and a dash pattern, creates a dashed line that follows that
//   path or region boundary with the given dash pattern.
//   - When called as a function, returns a list of dash sub-paths.
//   - When called as a module, draws all those subpaths using `stroke()`.
//   .
//   When called as a module the dash pattern is multiplied by the line width.  When called as
//   a function the dash pattern applies as you specify it.  
// Arguments:
//   path = The path or region to subdivide into dashes.
//   dashpat = A list of alternating dash lengths and space lengths for the dash pattern.  This will be scaled by the width of the line.
//   ---
//   width = The width of the dashed line to draw.  Module only.  Default: 1
//   closed = If true, treat path as a closed polygon.  Default: false
//   fit = If true, shrink or stretch the dash pattern so that the path ends ofter a logical dash.  Default: true
//   roundcaps = (Module only) If true, draws dashes with rounded caps.  This often looks better.  Default: true
//   mindash = (Function only) Specifies the minimal dash length to return at the end of a path when fit is false.  Default: 0.5
// Example(2D): Open Path
//   path = [for (a=[-180:10:180]) [a/3,20*sin(a)]];
//   dashed_stroke(path, [3,2], width=1);
// Example(2D): Closed Polygon
//   path = circle(d=100,$fn=72);
//   dashpat = [10,2, 3,2, 3,2];
//   dashed_stroke(path, dashpat, width=1, closed=true);
// Example(FlatSpin,VPD=250): 3D Dashed Path
//   path = [for (a=[-180:5:180]) [a/3, 20*cos(3*a), 20*sin(3*a)]];
//   dashed_stroke(path, [3,2], width=1);
function dashed_stroke(path, dashpat=[3,3], closed=false, fit=true, mindash=0.5) =
    is_region(path) ? [
        for (p = path)
        each dashed_stroke(p, dashpat, closed=true, fit=fit)
    ] : 
    let(
        path = closed? list_wrap(path) : path,
        dashpat = len(dashpat)%2==0? dashpat : concat(dashpat,[0]),
        plen = path_length(path),
        dlen = sum(dashpat),
        doff = cumsum(dashpat),
        freps = plen / dlen,
        reps = max(1, fit? round(freps) : floor(freps)),
        tlen = !fit? plen :
            reps * dlen + (closed? 0 : dashpat[0]),
        sc = plen / tlen,
        cuts = [
            for (i = [0:1:reps], off = doff*sc)
              let (x = i*dlen*sc + off)
              if (x > 0 && x < plen-EPSILON) x
        ],
        dashes = path_cut(path, cuts, closed=false),
        dcnt = len(dashes),
        evens = [
            for (i = idx(dashes))
            if (i % 2 == 0)
            let( dash = dashes[i] )
            if (i < dcnt-1 || path_length(dash) > mindash)
            dashes[i]
        ]
    ) evens;


module dashed_stroke(path, dashpat=[3,3], width=1, closed=false, fit=true, roundcaps=false) {
    no_children($children);
    segs = dashed_stroke(path, dashpat=dashpat*width, closed=closed, fit=fit, mindash=0.5*width);
    for (seg = segs)
        stroke(seg, width=width, endcaps=roundcaps? "round" : false);
}



// Section: Computing paths

// Function&Module: arc()
// Synopsis: Draws a 2D pie-slice or returns 2D or 3D path forming an arc.
// SynTags: Geom, Path 
// Topics: Paths (2D), Paths (3D), Shapes (2D), Path Generators, Rounding
// See Also: pie_slice(), stroke(), ring()
//
// Usage: 2D arc from 0º to `angle` degrees.
//   path=arc(n, r|d=, angle);
// Usage: 2D arc from START to END degrees.
//   path=arc(n, r|d=, angle=[START,END]);
// Usage: 2D arc from `start` to `start+angle` degrees.
//   path=arc(n, r|d=, start=, angle=);
// Usage: 2D circle segment by `width` and `thickness`, starting and ending on the X axis.
//   path=arc(n, width=, thickness=);
// Usage: Shortest 2D or 3D arc around centerpoint `cp`, starting at P0 and ending on the vector pointing from `cp` to `P1`.
//   path=arc(n, cp=, points=[P0,P1], [long=], [cw=], [ccw=]);
// Usage: 2D or 3D arc, starting at `P0`, passing through `P1` and ending at `P2`.
//   path=arc(n, points=[P0,P1,P2]);
// Usage: 2D or 3D arc, fron tangent point on segment `[P0,P1]` to the tangent point on segment `[P1,P2]`.
//   path=arc(n, corner=[P0,P1,P2], r=);
// Usage: Create a wedge using any other arc parameters
//   path=arc(wedge=true,[rounding=],...)
// Usage: as module
//   arc(...) [ATTACHMENTS];
// Description:
//   If called as a function, returns a 2D or 3D path forming an arc.  If `wedge` is true, the centerpoint of the arc appears as the first point in the result.
//   If called as a module, creates a 2D arc polygon or pie slice shape.  Numerous methods are available to specify the arc.
//   .
//   The `rounding` parameter is permitted only when `wedge=true` and applies specified radius roundings at each of the corners, with `rounding[0]` giving
//   the rounding at the center point, and then the other two the two outer corners in the direction that the arc travels.  If you don't need to control
//   the exact point count, you should use `$fs` and `$fa` to control the number of points on the roundings and arc.  If you give `n` then each arc
//   section in your curve uses `n` points, so the total number of points is `n` times one plus the number of non-zero roundings you specified.
// Arguments:
//   n = Number of vertices to use in the arc.  If `wedge=true` you will get `n+1` points.  
//   r = Radius of the arc.
//   angle = If a scalar, specifies the end angle in degrees (relative to start parameter).  If a vector of two scalars, specifies start and end angles.
//   ---
//   d = Diameter of the arc.
//   cp = Centerpoint of arc.
//   points = Points on the arc.
//   corner = A path of two segments to fit an arc tangent to.
//   long = if given with cp and points takes the long arc instead of the default short arc.  Default: false
//   cw = if given with cp and 2 points takes the arc in the clockwise direction.  Default: false
//   ccw = if given with cp and 2 points takes the arc in the counter-clockwise direction.  Default: false
//   width = If given with `thickness`, arc starts and ends on X axis, to make a circle segment.
//   thickness = If given with `width`, arc starts and ends on X axis, to make a circle segment.
//   start = Start angle of arc.  Default: 0
//   wedge = If true, include centerpoint `cp` in output to form pie slice shape.  Default: false
//   endpoint = If false exclude the last point (function only).  Default: true
//   rounding = Can set to a scalar or list of three rounding values to round the corners of an arc when wedge=true.  Default: 0
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  (Module only) Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  (Module only) Default: `0`
// Examples(2D):
//   arc(n=4, r=30, angle=30, wedge=true);
//   arc(r=30, angle=30, wedge=true);
//   arc(d=60, angle=30, wedge=true);
//   arc(d=60, angle=120);
//   arc(d=60, angle=120, wedge=true);
//   arc(r=30, angle=[75,135], wedge=true);
//   arc(r=30, start=45, angle=75, wedge=true);
//   arc(width=60, thickness=20);
//   arc(cp=[-10,5], points=[[20,10],[0,35]], wedge=true);
//   arc(points=[[30,-5],[20,10],[-10,20]], wedge=true);
// Example(2D): Fit to three points.
//   arc(points=[[5,30],[-10,-10],[30,5]], wedge=true);
// Example(2D):
//   path = arc(points=[[5,30],[-10,-10],[30,5]], wedge=true);
//   stroke(closed=true, path);
// Example(FlatSpin,VPD=175):
//   path = arc(points=[[0,30,0],[0,0,30],[30,0,0]]);
//   stroke(path, dots=true, dots_color="blue");
// Example(2D): Fit to a corner.
//   pts = [[0,40], [-40,-10], [30,0]];
//   path = arc(corner=pts, r=20);
//   stroke(pts, endcaps="arrow2");
//   stroke(path, endcap2="arrow2", color="blue");
// Example(2D, NoScales): Rounding the corners
//   $fs=.5; $fa=1;
//   arc(r=25, angle=[25,107], rounding=[6,5,7], wedge=true);
//   stroke(arc(r=25, angle=[25,107], wedge=true), color="red",closed=true, width=.5);
// Example(2D, NoScales): Negative roundings are permitted on the two outside corners, but not the center corner.  
//   $fs=.5; $fa=1;
//   arc(r=25, angle=[-30,45], rounding=[0,-12, -27], wedge=true);
//   stroke(arc(r=25, angle=[-30,45], wedge=true), color="red",closed=true, width=.5);

function arc(n, r, angle, d, cp, points, corner, width, thickness, start, wedge=false, long=false, cw=false, ccw=false, endpoint=true, rounding) =
    assert(is_bool(endpoint))
    !endpoint ?
        assert(!wedge, "endpoint cannot be false if wedge is true")
        list_head(arc(u_add(n,1),r,angle,d,cp,points,corner,width,thickness,start,wedge,long,cw,ccw,true,rounding))
  :
    assert(is_undef(start) || is_def(angle), "start requires angle")
    assert(is_undef(angle) || !any_defined([thickness,width,points,corner]), "Cannot give angle with points, corner, width or thickness")
    assert(is_undef(n) || (is_integer(n) && n>=2), "Number of points must be an integer 2 or larger")
    assert(is_undef(points) || is_path(points, [2,3]), "Points must be a list of 2d or 3d points")
    assert((is_def(points) && len(points)==2) || !any([cw,ccw,long]), "cw, ccw, and long are only allowed when points is a list of length 2")
    // First try for 2D arc specified by width and thickness
    is_def(width) && is_def(thickness)? 
        assert(!any_defined([r,cp,points,angle,start]),"Conflicting or invalid parameters to arc")
        assert(width>0, "Width must be postive")
        assert(thickness>0, "Thickness must be positive")
        arc(n,points=[[width/2,0], [0,thickness], [-width/2,0]],wedge=wedge,rounding=rounding)
  : is_def(angle)? 
        let(
            parmok = !any_defined([points,width,thickness]) &&
                ((is_vector(angle,2) && is_undef(start)) || is_finite(angle))
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
        is_def(rounding) ? assert(wedge,"rounding is only supportd with wedge=true") move(cp,zrot(start,_rounded_arc(r, rounding, angle, n)))
     :
        let(
            n = is_def(n) ? n : max(3, ceil(segs(r)*abs(angle)/360)),
            arcpoints = [for(i=[0:n-1]) let(theta = start + i*angle/(n-1)) r*[cos(theta),sin(theta)]+cp]
        )
        [
          if (wedge) cp,
          each arcpoints
        ]
  : is_def(corner)? 
        assert(is_path(corner,[2,3]) && len(corner)==3,str("Point list is invalid"))
        assert(is_undef(cp) && !any([long,cw,ccw]), "Cannot use cp, long, cw, or ccw with corner")
        // Arc is 3D, so transform corner to 2D and make a recursive call, then remap back to 3D
        len(corner[0]) == 3? (
            let(
                plane = [corner[2], corner[0], corner[1]],
                points2d = project_plane(plane, corner)
            )
            lift_plane(plane,arc(n,corner=points2d,wedge=wedge,r=r, d=d,rounding=rounding))
        ) :
        assert(is_path(corner) && len(corner) == 3)
        let(col = is_collinear(corner[0],corner[1],corner[2]))
        assert(!col, "Collinear inputs do not define an arc")
        let( r = get_radius(r=r, d=d) )
        assert(is_finite(r) && r>0, "Must specify r= or d= when corner= is given.")
        let(
            ci = circle_2tangents(r, corner[0], corner[1], corner[2], tangents=true),
            cp = ci[0], nrm = ci[1], tp1 = ci[2], tp2 = ci[3],
            dir = det2([corner[1]-corner[0],corner[2]-corner[1]]) > 0,
            corner = dir? [tp1,tp2] : [tp2,tp1],
            theta_start = atan2(corner[0].y-cp.y, corner[0].x-cp.x),
            theta_end = atan2(corner[1].y-cp.y, corner[1].x-cp.x),
            angle = posmod(theta_end-theta_start, 360),
            ang_range = dir ? [theta_start, theta_start+angle]
                            : [theta_start+angle, theta_start]
        )
        arc(n,cp=cp,r=r,angle=ang_range,wedge=wedge,rounding=rounding)
  : assert(is_def(points), "Arc not specified: must give points, angle, or width and thickness")
    assert(is_path(points,[2,3]),"Point list is invalid")
         // If arc is 3D, transform points to 2D and make a recursive call, then remap back to 3D
    len(points[0]) == 3? 
        assert(!(cw || ccw), "(Counter)clockwise isn't meaningful in 3d, so `cw` and `ccw` must be false")
        assert(is_undef(cp) || is_vector(cp,3),"points are 3d so cp must be 3d")
        let(
            plane = [is_def(cp) ? cp : points[2], points[0], points[1]],
            center2d = is_def(cp) ? project_plane(plane,cp) : undef,
            points2d = project_plane(plane, points)
        )
        lift_plane(plane,arc(n,cp=center2d,points=points2d,wedge=wedge,long=long,rounding=rounding))
  : len(points)==2?  
        // Arc defined by center plus two points, will have radius defined by center and points[0]
        // and extent defined by direction of point[1] from the center
        assert(is_vector(cp,2), "Centerpoint is required when points has length 2 and it must be a 2d vector")
        assert(len(points)==2, "When pointlist has length 3 centerpoint is not allowed")
        assert(points[0]!=points[1], "Arc endpoints are equal")
        assert(cp!=points[0]&&cp!=points[1], "Centerpoint equals an arc endpoint")
        assert(num_true([long,cw,ccw])<=1, str("Only one of `long`, `cw` and `ccw` can be true",cw,ccw,long))
        let(    
            angle = vector_angle(points[0], cp, points[1]),
            v1 = points[0]-cp,
            v2 = points[1]-cp,
            prelim_dir = sign(det2([v1,v2])),  // z component of cross product
            dir = prelim_dir != 0 ? prelim_dir :
                assert(cw || ccw, "Collinear inputs don't define a unique arc")
                1,
            r = norm(v1),
            final_angle = long || (ccw && dir<0) || (cw && dir>0) ?
                -dir*(360-angle) :
                dir*angle,
            sa = atan2(v1.y,v1.x)
        )
        arc(n,cp=cp,r=r,start=sa,angle=final_angle,wedge=wedge,rounding=rounding)
  : // Final case is arc passing through three points, starting at point[0] and ending at point[3]
        let(col = is_collinear(points[0],points[1],points[2]))
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
            // Specify endpoints exactly; skip those endpoints when producing arc points
            // Generating the whole arc and clipping ends is the easiest way to ensure that we
            // generate the proper number of points.
            ang_range = dir ? [theta_start, theta_start+angle]
                            : [theta_start+angle, theta_start],
            arcpts = is_def(rounding)? arc(n,cp=cp,r=r,angle=ang_range,wedge=wedge,rounding=rounding)
                   : [
                       if (wedge) cp, 
                       points[dir ? 0 : 1],
                       each select(arc(n,cp=cp,r=r,angle=ang_range),1,-2),
                       points[dir ? 1 : 0]
                     ]
        )
        arcpts;


module arc(n, r, angle, d, cp, points, corner, width, thickness, start, wedge=false, rounding, anchor=CENTER, spin=0)
{
    path = arc(n=n, r=r, angle=angle, d=d, cp=cp, points=points, corner=corner, width=width, thickness=thickness, start=start, wedge=wedge, rounding=rounding);
    attachable(anchor,spin, two_d=true, path=path, extent=false) {
        polygon(path);
        children();
    }
}


                        

function _rounded_arc(radius, rounding=0, angle, n) =
    assert(is_finite(angle) && abs(angle)<360, "angle must be strictly between -360 and 360")
    assert(is_finite(rounding) || is_vector(rounding,3), "rounding must be a scalar or 3-vector")
    let(
        rounding = force_list(rounding,3),
        
        dir = sign(angle),

        inner_corner_radius = abs(angle)>180 ? -dir*rounding[0] : dir*rounding[0],        
        arc1_opt_radius = radius - rounding[1],
        arc2_opt_radius = radius - rounding[2],
        check = assert(rounding[0]>=0, "rounding[0] must be nonnegative")
                assert(rounding[1]<arc1_opt_radius, "rounding[1] is too big to fit")
                assert(rounding[2]<arc2_opt_radius, "rounding[2] is too big to fit"),
        arc1_angle = asin(abs(rounding[1])/arc1_opt_radius),
        arc2_angle = asin(abs(rounding[2])/arc2_opt_radius),
        arc1_cut = radius - arc1_opt_radius*cos(arc1_angle),
        arc2_cut = radius - arc2_opt_radius*cos(arc2_angle),
        radius_of_ctrpt = inner_corner_radius/sin(angle/2),
        radius_of_ctrpt_edge = radius_of_ctrpt*cos(angle/2),
        
        pt1 = polar_to_xy(r=arc1_opt_radius, theta=dir*arc1_angle),
        pt2 = polar_to_xy(r=radius_of_ctrpt, theta=0.5*angle),
        pt3 = polar_to_xy(r=arc2_opt_radius, theta=angle - dir*arc2_angle),
        
        edge_gap1=radius-arc1_cut-radius_of_ctrpt_edge,
        edge_gap2=radius-arc2_cut-radius_of_ctrpt_edge,

        angle_span1 = rounding[1]>0 ? [-dir*90, dir*arc1_angle] : -[dir*90, dir*180 - arc1_angle],
        angle_span2 = [angle-dir*arc2_angle + (rounding[2]<0 ? dir*180 : 0), angle+dir*90]
    )
    assert(arc1_angle + arc2_angle<=abs(angle), "Roundings are too large: they interfere with each other on the arc")   
    assert(edge_gap1>=0, "Roundings are too large: center rounding (rounding[0]) interferes with first corner (rounding[1])")
    assert(edge_gap2>=0, "Roundings are too large: center rounding (rounding[0]) interferes with second corner (rounding[2])")   
    [
      each if (rounding[0]>0 && abs(angle)!=180)
                               arc(cp=pt2,
                                   points=[polar_to_xy(r=radius_of_ctrpt_edge, theta=angle),          // origin corner curve
                                   polar_to_xy(r=radius_of_ctrpt_edge, theta=0)],
                                   endpoint=edge_gap1!=0,n=n)
           else repeat([0,0],rounding[0]>0 && abs(angle)==180 && is_def(n) ? n : 1),                        
      each if (rounding[1]!=0) arc(r=abs(rounding[1]),cp=pt1,angle=angle_span1,endpoint=dir*arc1_angle==angle,n=n), // first corner
      each if (arc1_angle+arc2_angle<abs(angle))
                      arc(r=radius, angle=[dir*arc1_angle,angle - dir*arc2_angle], endpoint=rounding[2]==0, n=n),   // main arc section
      each if (rounding[2]!=0) arc(r=abs(rounding[2]),cp=pt3,  angle=angle_span2, endpoint=edge_gap2!=0, n=n)       // second corner
    ];



// Function: catenary()
// Synopsis: Returns a 2D Catenary chain or arch path.
// SynTags: Path
// Topics: Paths
// See Also: circle(), stroke()
// Usage:
//   path = catenary(width, droop=|angle=, n=);
// Description:
//   Returns a 2D Catenary path, which is the path a chain held at both ends will take.
//   The path will have the endpoints at `[±width/2, 0]`, and the middle of the path will droop
//   towards Y- if the given droop= or angle= is positive.  It will droop towards Y+ if the
//   droop= or angle= is negative.  You *must* specify one of droop= or angle=.
// Arguments:
//   width = The straight-line distance between the endpoints of the path.
//   droop = If given, specifies the height difference between the endpoints and the hanging middle of the path.  If given a negative value, returns an arch *above* the Y axis.
//   n = The number of points to return in the path.  Default: 100
//   ---
//   angle = If given, specifies the angle that the path will droop by at the endpoints.  If given a negative value, returns an arch *above* the Y axis.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  (Module only) Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  (Module only) Default: `0`
// Example(2D): By Droop
//   stroke(catenary(100, droop=30));
// Example(2D): By Angle
//   stroke(catenary(100, angle=30));
// Example(2D): Upwards Arch by Angle
//   stroke(catenary(100, angle=30));
// Example(2D): Upwards Arch by Height Delta
//   stroke(catenary(100, droop=-30));
// Example(2D): Specifying Vertex Count
//   stroke(catenary(100, angle=-85, n=11), dots="dot");
// Example(3D): Sweeping a Catenary Path
//   path = xrot(90, p=path3d(catenary(100, droop=20, n=41)));
//   path_sweep(circle(r=1.5, $fn=24), path);
function catenary(width, droop, n=100, angle) =
    assert(one_defined([droop, angle],"droop,angle"))
    let(
        sgn = is_undef(droop)? sign(angle) : sign(droop),
        droop = droop==undef? undef : abs(droop),
        angle = angle==undef? undef : abs(angle)
    )
    assert(is_finite(width) && width>0, "Bad width= value.")
    assert(is_integer(n) && n>0, "Bad n= value.  Must be a positive integer.")
    assert(is_undef(droop) || is_finite(droop), "Bad droop= value.")
    assert(is_undef(angle) || (is_finite(angle) && angle != 0 && abs(angle) < 90), "Bad angle= value.")
    let(
        catlup_fn = is_undef(droop)
          ? function(x) let(
                p1 = [x-0.001, cosh(x-0.001)-1],
                p2 = [x+0.001, cosh(x+0.001)-1],
                delta = p2-p1,
                ang = atan2(delta.y, delta.x)
            ) ang
          : function(x) (cosh(x)-1)/x,
        binsearch_fn = function(targ,x=0,inc=4)
            inc < 1e-9? lookup(targ,[[catlup_fn(x),x],[catlup_fn(x+inc),x+inc]]) :
            catlup_fn(x+inc) > targ? binsearch_fn(targ,x,inc/2) :
            binsearch_fn(targ,x+inc,inc),
        scx = is_undef(droop)? binsearch_fn(angle) :
            binsearch_fn(droop / (width/2)),
        sc = width/2 / scx,
        droop = !is_undef(droop)? droop : (cosh(scx)-1) * sc,
        path = [
            for (x = lerpn(-scx,scx,n))
            let(
                xval = x * sc,
                yval = approx(abs(x),scx)? 0 :
                    (cosh(x)-1) * sc - droop
            )
            [xval, yval]
        ],
        out = sgn>0? path : yflip(p=path)
    ) out;


module catenary(width, droop, n=100, angle, anchor=CTR, spin=0) {
    path = catenary(width=width, droop=droop, n=n, angle=angle);
    attachable(anchor,spin, two_d=true, path=path, extent=true) {
        polygon(path);
        children();
    }
}


// Function: helix()
// Synopsis: Creates a 2d spiral or 3d helical path.
// SynTags: Path
// Topics: Path Generators, Paths, Drawing Tools
// See Also: pie_slice(), stroke(), thread_helix(), path_sweep()
//
// Usage:
//   path = helix(l|h, [turns=], [angle=], r=|r1=|r2=, d=|d1=|d2=);
// Description:
//   Returns a 3D helical path on a cone, including the degerate case of flat spirals.
//   You can specify start and end radii.  You can give the length, the helix angle, or the number of turns: two
//   of these three parameters define the helix.  For a flat helix you must give length 0 and a turn count.
//   Helix will be right handed if turns is positive and left handed if it is negative.
//   The angle is calculateld based on the radius at the base of the helix.
// Arguments:
//   h/l = Height/length of helix, zero for a flat spiral
//   ---
//   turns = Number of turns in helix, positive for right handed
//   angle = helix angle
//   r = Radius of helix
//   r1 = Radius of bottom of helix
//   r2 = Radius of top of helix
//   d = Diameter of helix
//   d1 = Diameter of bottom of helix
//   d2 = Diameter of top of helix
// Example(3D):
//   stroke(helix(turns=2.5, h=100, r=50), dots=true, dots_color="blue");
// Example(3D):  Helix that turns the other way
//   stroke(helix(turns=-2.5, h=100, r=50), dots=true, dots_color="blue");
// Example(3D): Flat helix (note points are still 3d)
//   stroke(helix(h=0,r1=50,r2=25,l=0, turns=4));
module helix(l,h,turns,angle, r, r1, r2, d, d1, d2) {no_module();}
function helix(l,h,turns,angle, r, r1, r2, d, d1, d2)=
    let(
        r1=get_radius(r=r,r1=r1,d=d,d1=d1,dflt=1),
        r2=get_radius(r=r,r1=r2,d=d,d1=d2,dflt=1),
        length = first_defined([l,h])
    )
    assert(num_defined([length,turns,angle])==2,"Must define exactly two of l/h, turns, and angle")
    assert(is_undef(angle) || length!=0, "Cannot give length 0 with an angle")
    let(
        // length advances dz for each turn
        dz = is_def(angle) && length!=0 ? 2*PI*r1*tan(angle) : length/abs(turns),

        maxtheta = is_def(turns) ? 360*turns : 360*length/dz,
        N = segs(max(r1,r2))
    )
    [for(theta=lerpn(0,maxtheta, max(3,ceil(abs(maxtheta)*N/360))))
       let(R=lerp(r1,r2,theta/maxtheta))
       [R*cos(theta), R*sin(theta), abs(theta)/360 * dz]];


function _normal_segment(p1,p2) =
    let(center = (p1+p2)/2)
    [center, center + norm(p1-p2)/2 * line_normal(p1,p2)];


// Function: turtle()
// Synopsis: Uses [turtle graphics](https://en.wikipedia.org/wiki/Turtle_graphics) to generate a 2D path.
// SynTags: Path
// Topics: Shapes (2D), Path Generators (2D), Mini-Language
// See Also: turtle3d(), stroke(), path_sweep()
// Usage:
//   path = turtle(commands, [state], [full_state=], [repeat=])
// Description:
//   Use a sequence of [turtle graphics](https://en.wikipedia.org/wiki/Turtle_graphics) commands to generate a path.  The parameter `commands` is a list of
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
//   "untily"     | ytarget            | Move turtle in turtle direction until y==ytarget.  Produces an error if ytarget is not reachable.
//   "jump"       | point              | Move the turtle to the specified point
//   "xjump"      | x                  | Move the turtle's x position to the specified value
//   "yjump       | y                  | Move the turtle's y position to the specified value
//   "turn"       | [angle]            | Turn turtle direction by specified angle, or the turtle's default turn angle.  The default angle starts at 90.
//   "left"       | [angle]            | Same as "turn"
//   "right"      | [angle]            | Same as "turn", -angle
//   "angle"      | angle              | Set the default turn angle.
//   "setdir"     | dir                | Set turtle direction.  The parameter `dir` can be an angle or a vector. (A 3d vector with zero Z component is allowed.)  
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
//   stroke(path,width=.7);
// Example(2DMed): yet another spiral, without using `repeat`
//   path = turtle(concat(["angle",71],flatten(repeat(["move","left","addlength",1],50))));
//   stroke(path,width=.7);
// Example(2DMed): The previous spiral grows linearly and eventually intersects itself.  This one grows geometrically and does not.
//   path = turtle(["move","left",71,"scale",1.05],repeat=50);
//   stroke(path,width=.15);
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
module turtle(commands, state=[[[0,0]],[1,0],90,0], full_state=false, repeat=1) {no_module();}
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
        vec_or_num = !in_list(command,needeither) || (is_num(parm) || is_vector(parm,2) || (is_vector(parm,3)&&parm.z==0)),
        lastpt = last(state[path])
    )
    assert(chvec,str("\"",command,"\" requires a vector parameter at index ",index))
    assert(chnum,str("\"",command,"\" requires a numeric parameter at index ",index))
    assert(vec_or_num,str("\"",command,"\" requires a 2-vector or numeric parameter at index ",index))

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
    command=="turn" || command=="left" ? list_set(state, step, rot(default(parm,state[angle]),p=state[step])) :
    command=="right" ? list_set(state, step, rot(-default(parm,state[angle]),p=state[step])) :
    command=="angle" ? list_set(state, angle, parm) :
    command=="setdir" ? (
        is_vector(parm) ?
            list_set(state, step, norm(state[step]) * unit(point2d(parm))) :
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
            arcpath = myangle == 0 || radius == 0 ? []
                    : arc(
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
                rot(lrsign * myangle,p=state[step])
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
                rot(delta_angle,p=state[step])
            ]
        ) :
    assert(false,str("Unknown turtle command \"",command,"\" at index",index))
    [];


// Section: Debugging polygons

// Module: debug_polygon()
// Synopsis: Draws an annotated polygon.
// SynTags: Geom
// Topics: Shapes (2D)
// See Also: debug_region(), debug_vnf(), debug_bezier()
//
// Usage:
//   debug_polygon(points, paths, [vertices=], [edges=], [convexity=], [size=]);
// Description:
//   A drop-in replacement for `polygon()` that renders and labels the path points and
//   edges.  The start of each path is marked with a blue circle and the end with a pink diamond.
//   You can suppress the display of vertex or edge labeling using the `vertices` and `edges` arguments.
// Arguments:
//   points = The array of 2D polygon vertices.
//   paths = The path connections between the vertices.
//   ---
//   vertices = if true display vertex labels and start/end markers.  Default: true
//   edges = if true display edge labels.  Default: true
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
module debug_polygon(points, paths, vertices=true, edges=true, convexity=2, size=1)
{
    no_children($children);
    print_paths=is_def(paths);
    echo(points=points);
    if (print_paths)
      echo(paths=paths);
    paths = is_undef(paths)? [count(points)] :
        is_num(paths[0])? [paths] :
        paths;
    linear_extrude(height=0.01, convexity=convexity, center=true) {
        polygon(points=points, paths=paths, convexity=convexity);
    }
    if (vertices)
      _debug_poly_verts(points,size);
    if (edges)
      for (j = [0:1:len(paths)-1]) _debug_poly_edges(j, points, paths[j], vertices, size);
}


module _debug_poly_verts(points, size)
{
     labels=is_vector(points[0]) ? [for(i=idx(points)) str(i)]
           :[for(j=idx(points), i=idx(points[j])) str(chr(97+j),i)];
     points = is_vector(points[0]) ? points : flatten(points);
     dups = vector_search(points, EPSILON, points);
     color("red") {
        for (ind=dups){
            numstr = str_join(select(labels,ind),",");
            up(0.2) {
                translate(points[ind[0]]) {
                    linear_extrude(height=0.1, convexity=10, center=true) {
                        text(text=numstr, size=size, halign="center", valign="center");
                    }
                }
            }
        }
    }
}


module _debug_poly_edges(j,points, path,vertices,size)
{  
       path = default(path, count(len(points)));
       if (vertices){
            translate(points[path[0]]) {
                color("cyan") up(0.1) cylinder(d=size*1.5, h=0.01, center=false, $fn=12);
            }
            translate(points[path[len(path)-1]]) {
                color("pink") up(0.11) cylinder(d=size*1.5, h=0.01, center=false, $fn=4);
            }
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

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
