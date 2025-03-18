//////////////////////////////////////////////////////////////////////////
// LibFile: cubetruss.scad
//   Parts for making modular open-frame cross-braced trusses and connectors.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/cubetruss.scad>
// FileGroup: Parts
// FileSummary: Modular open-framed trusses and joiners.
//////////////////////////////////////////////////////////////////////////

$cubetruss_size = 30;
$cubetruss_strut_size = 4;
$cubetruss_bracing = true;
$cubetruss_clip_thickness = 1.6;


// Section: Cube Trusses

// Module: cubetruss()
// Synopsis: Creates a multi-cube straight cubetruss shape.
// SynTags: Geom
// Topics: Trusses, CubeTruss, FDM Optimized, Parts
// See Also: cubetruss_segment(), cubetruss_support(), cubetruss(), cubetruss_corner()
// Usage:
//   cubetruss(extents, [clips=], [bracing=], [size=], [strut=], [clipthick=], ...) [ATTACHMENTS];
// Description:
//   Creates a cubetruss truss, assembled out of one or more cubical segments.
// Arguments:
//   extents = The number of cubes in length to make the truss.  If given as a [X,Y,Z] vector, specifies the number of cubes in each dimension.
//   clips = List of vectors pointing towards the sides to add clips to.
//   bracing = If true, adds internal cross-braces.  Default: `$cubetruss_bracing` (usually true)
//   size = The length of each side of the cubetruss cubes.  Default: `$cubetruss_size` (usually 30)
//   strut = The width of the struts on the cubetruss cubes.  Default: `$cubetruss_strut_size` (usually 3)
//   clipthick = The thickness of the clips.  Default: `$cubetruss_clip_thickness` (usually 1.6)
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   cubetruss(extents=3);
//   cubetruss(extents=3, clips=FRONT);
//   cubetruss(extents=3, clips=[FRONT,BACK]);
//   cubetruss(extents=[2,3]);
//   cubetruss(extents=[1,4,2]);
//   cubetruss(extents=[1,4,2], bracing=false);
module cubetruss(extents=6, clips=[], bracing, size, strut, clipthick, anchor=CENTER, spin=0, orient=UP) {
    clips = is_vector(clips)? [clips] : clips;
    size = is_undef(size)? $cubetruss_size : size;
    strut = is_undef(strut)? $cubetruss_strut_size : strut;
    bracing = is_undef(bracing)? $cubetruss_bracing : bracing;
    clipthick = is_undef(clipthick)? $cubetruss_clip_thickness : clipthick;
    extents = is_vector(extents)? point3d(extents,fill=1) : [1,extents,1];
    w = extents[0];
    l = extents[1];
    h = extents[2];
    s = [cubetruss_dist(w,1,size,strut), cubetruss_dist(l,1,size,strut), cubetruss_dist(h,1,size,strut)];
    attachable(anchor,spin,orient, size=s) {
        union() {
            for (zrow = [0:h-1]) {
                up((zrow-(h-1)/2)*(size-strut)) {
                    for (xcol = [0:w-1]) {
                        right((xcol-(w-1)/2)*(size-strut)) {
                            for (ycol = [0:l-1]) {
                                back((ycol-(l-1)/2)*(size-strut)) {
                                    cubetruss_segment(size=size, strut=strut, bracing=bracing);
                                }
                            }
                        }
                    }
                }
            }
            if (clipthick > 0) {
                for (vec = clips) {
                    exts = v_abs(rot(from=FWD, to=vec, p=extents));
                    rot(from=FWD,to=vec) {
                        for (zrow = [0:1:exts.z-1]) {
                            up((zrow-(exts.z-1)/2)*(size-strut)) {
                                fwd((exts.y*(size-strut)+strut)/2) {
                                    cubetruss_clip(size=size, strut=strut, extents=exts.x, clipthick=clipthick);
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


// Module: cubetruss_corner()
// Synopsis: Creates a multi-cube corner cubetruss shape.
// SynTags: Geom
// Topics: Trusses, CubeTruss, FDM Optimized, Parts
// See Also: cubetruss_segment(), cubetruss_support(), cubetruss(), cubetruss_corner()
// Usage:
//   cubetruss_corner(h, extents, [bracing=], [size=], [strut=], [clipthick=]);
// Description:
//   Creates a corner cubetruss with extents jutting out in one or more directions.
// Arguments:
//   h = The number of cubes high to make the base and horizontal extents.
//   extents = The number of cubes to extend beyond the corner.  If given as a vector of cube counts, gives the number of cubes to extend right, back, left, front, and up in order.  If the vector is shorter than length 5 the extra cube counts are taken to be zero.  
//   bracing = If true, adds internal cross-braces.  Default: `$cubetruss_bracing` (usually true)
//   size = The length of each side of the cubetruss cubes.  Default: `$cubetruss_size` (usually 30)
//   strut = The width of the struts on the cubetruss cubes.  Default: `$cubetruss_strut_size` (usually 3)
//   clipthick = The thickness of the clips.  Default: `$cubetruss_clip_thickness` (usually 1.6)
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   cubetruss_corner(extents=2);
//   cubetruss_corner(extents=2, h=2);
//   cubetruss_corner(extents=[3,3,0,0,2]);
//   cubetruss_corner(extents=[3,0,3,0,2]);
//   cubetruss_corner(extents=[3,3,3,3,2]);
module cubetruss_corner(h=1, extents=[1,1,0,0,1], bracing, size, strut, clipthick, anchor=CENTER, spin=0, orient=UP) {
    size = is_undef(size)? $cubetruss_size : size;
    strut = is_undef(strut)? $cubetruss_strut_size : strut;
    bracing = is_undef(bracing)? $cubetruss_bracing : bracing;
    clipthick = is_undef(clipthick)? $cubetruss_clip_thickness : clipthick;
    exts = is_vector(extents)? list_pad(extents,5,fill=0) : [extents, extents, 0, 0, extents];
    dummy = assert(len(exts)==5, "Input extents must be a scalar or vector with length 5 or less.");
    s = [cubetruss_dist(exts[0]+1+exts[2],1,size,strut), cubetruss_dist(exts[1]+1+exts[3],1,size,strut), cubetruss_dist(h+exts[4],1,size,strut)];
    offset = [cubetruss_dist(exts[0]-exts[2],0,size,strut), cubetruss_dist(exts[1]-exts[3],0,size,strut), cubetruss_dist(h+exts[4]-1,0,size,strut)]/2;
    attachable(anchor,spin,orient, size=s, offset=offset) {
        union() {
            for (zcol = [0:h-1]) {
                up((size-strut)*zcol) {
                    cubetruss_segment(size=size, strut=strut, bracing=bracing);
                }
            }
            for (dir = [0:3]) {
                if (exts[dir] != undef && exts[dir] > 0) {
                    zrot(dir*90) {
                        for (zcol = [0:h-1]) {
                            up((size-strut+0.01)*zcol) {
                                for (i = [1:exts[dir]]) {
                                    right((size-strut+0.01)*i) cubetruss_segment(size=size, strut=strut, bracing=bracing);
                                }
                                if (clipthick > 0) {
                                    right(exts[dir]*(size-strut)+size/2) {
                                        zrot(90) cubetruss_clip(size=size, strut=strut, clipthick=clipthick);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if (exts[4] != undef && exts[4] > 0) {
                for (i = [1:exts[4]]) {
                    up((size-strut+0.01)*(i+h-1)) cubetruss_segment(size=size, strut=strut, bracing=bracing);
                }
                if (clipthick > 0) {
                    up((exts[4]+h-1)*(size-strut)+size/2) {
                        xrot(-90) cubetruss_clip(size=size, strut=strut, clipthick=clipthick);
                    }
                }
            }
        }
        children();
    }
}


// Module: cubetruss_support()
// Synopsis: Creates a cubetruss support structure shape.
// SynTags: Geom
// Topics: Trusses, CubeTruss, FDM Optimized, Parts
// See Also: cubetruss_segment(), cubetruss_support(), cubetruss(), cubetruss_corner()
// Usage:
//   cubetruss_support([size=], [strut=], [extents=]) [ATTACHMENTS];
// Description:
//   Creates a single cubetruss support.
// Arguments:
//   size = The length of each side of the cubetruss cubes.  Default: `$cubetruss_size` (usually 30)
//   strut = The width of the struts on the cubetruss cubes.  Default: `$cubetruss_strut_size` (usually 3)
//   extents = If given as an integer, specifies the number of vertical segments for the support.  If given as a list of 3 integers, specifies the number of segments in the X, Y, and Z directions.  Default: 1.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example(VPT=[0,0,0],VPD=150):
//   cubetruss_support();
// Example(VPT=[0,0,0],VPD=200):
//   cubetruss_support(extents=2);
// Example(VPT=[0,0,0],VPD=250):
//   cubetruss_support(extents=3);
// Example(VPT=[0,0,0],VPD=350):
//   cubetruss_support(extents=[2,2,3]);
// Example(VPT=[0,0,0],VPD=150):
//   cubetruss_support(strut=4);
// Example(VPT=[0,0,0],VPD=260):
//   cubetruss_support(extents=2) show_anchors();
module cubetruss_support(size, strut, extents=1, anchor=CENTER, spin=0, orient=UP) {
    extents = is_num(extents)? [1,1,extents] : extents;
    size = is_undef(size)? $cubetruss_size : size;
    strut = is_undef(strut)? $cubetruss_strut_size : strut;
    check =
      assert(is_int(extents.x) && extents.x > 0)
      assert(is_int(extents.y) && extents.y > 0)
      assert(is_int(extents.z) && extents.z > 0);
    w = (size-strut) * extents.x + strut;
    l = (size-strut) * extents.y + strut;
    h = (size-strut) * extents.z + strut;
    attachable(anchor,spin,orient, size=[w,l,h], size2=[l,0], shift=[0,l/2], axis=DOWN) {
        xcopies(size-strut, n=extents.x) {
            difference() {
                half_of(BACK/extents.y + UP/extents.z, s=size*(max(extents)+1))
                    cube([size,l,h], center=true);
                half_of(BACK/extents.y + UP/extents.z, cp=strut, s=size*(max(extents)+1)) {
                    ycopies(size-strut, n=extents.y) {
                        zcopies(size-strut, n=extents.z) {
                            cyl(h=size+1, d=size-2*strut, circum=true, realign=true, orient=RIGHT, $fn=8);
                            cyl(h=size+1, d=size-2*strut, circum=true, realign=true, $fn=8);
                            cube(size-2*strut, center=true);
                        }
                    }
                }
                zcopies(size-strut, n=extents.z) {
                    cyl(h=extents.y*size+1, d=size-2*strut, circum=true, realign=true, orient=BACK, $fn=8);
                }
            }
        }
        children();
    }
}



// Section: Cubetruss Support

// Module: cubetruss_foot()
// Synopsis: Creates a foot that can connect two cubetrusses.
// SynTags: Geom
// Topics: Trusses, CubeTruss, FDM Optimized, Parts
// See Also: cubetruss_segment(), cubetruss_support(), cubetruss(), cubetruss_corner()
// Usage:
//   cubetruss_foot(w, [size=], [strut=], [clipthick=]) [ATTACHMENTS];
// Description:
//   Creates a foot that can be clipped onto the bottom of a truss for support.
// Arguments:
//   w = The number of cube segments to span between the clips.  Default: 1
//   size = The length of each side of the cubetruss cubes.  Default: `$cubetruss_size` (usually 30)
//   strut = The width of the struts on the cubetruss cubes.  Default: `$cubetruss_strut_size` (usually 3)
//   clipthick = The thickness of the clips.  Default: `$cubetruss_clip_thickness` (usually 1.6)
//   ---
//   $slop = make fit looser to allow for printer overextrusion
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   cubetruss_foot(w=1);
//   cubetruss_foot(w=3);
module cubetruss_foot(w=1, size, strut, clipthick, anchor=CENTER, spin=0, orient=UP) {
    size = is_undef(size)? $cubetruss_size : size;
    strut = is_undef(strut)? $cubetruss_strut_size : strut;
    clipthick = is_undef(clipthick)? $cubetruss_clip_thickness : clipthick;
    clipsize = 0.5;
    wall_h = strut+clipthick*1.5;
    cyld = (size-2*strut)/cos(180/8);
    s = [w*(size-strut)+strut+2*clipthick, size-2*strut, strut+clipthick];
    attachable(anchor,spin,orient, size=s, offset=[0,0,(strut-clipthick)/2]) {
        down(clipthick) {
            // Base
            up(clipthick/2) {
                cuboid([w*(size-strut)+strut+2*clipthick, size-2*strut, clipthick], chamfer=strut, edges="Z");
            }

            // Walls
            xcopies(w*(size-strut)+strut+clipthick) {
                up(clipthick-0.01) {
                    prismoid([clipthick, (size-4*strut)], [clipthick, size/3.5], h=wall_h, anchor=BOT);
                }
            }

            // Horiz Wall Clips
            up(clipthick+strut+get_slop()*2) {
                xcopies(w*(size-strut)+strut) {
                    prismoid([clipsize*2, size/3.5], [0.1, size/3.5], h=clipsize*3, anchor=BOT);
                }
            }

            // Middle plugs
            for (xcol = [0:w-1]) {
                right((xcol-(w-1)/2)*(size-strut)) {
                    difference() {
                        // Start with octagon to fit sides.
                        up(clipthick-0.01) {
                            zrot(180/8) cylinder(h=strut, d1=cyld-4*get_slop(), d2=cyld-4*get_slop()-1, center=false, $fn=8);
                        }

                        // Bevel to fit.
                        up(clipthick+strut) {
                            ycopies(size-2*strut-4*get_slop()) {
                                chamfer_edge_mask(l=size-strut, chamfer=strut*2/3, orient=RIGHT);
                            }
                        }

                        // Cut out X for possible top mount.
                        zrot_copies([-45, 45]) {
                            cube([size*3, strut/sqrt(2)+2*get_slop(), size*3], center=true);
                        }
                    }
                }
            }
        }
        children();
    }
}


// Module: cubetruss_joiner()
// Synopsis: Creates a joiner that can connect two cubetrusses end-to-end.
// SynTags: Geom
// Topics: Trusses, CubeTruss, FDM Optimized, Parts
// See Also: cubetruss_segment(), cubetruss_support(), cubetruss(), cubetruss_corner()
// Usage:
//   cubetruss_joiner([w=], [vert=], [size=], [strut=], [clipthick=]) [ATTACHMENTS];
// Description:
//   Creates a part to join two cubetruss trusses end-to-end.
// Arguments:
//   w = The number of cube segments to span between the clips.  Default: 1
//   vert = If true, add vertical risers to clip to the ends of the cubetruss trusses.  Default: true
//   size = The length of each side of the cubetruss cubes.  Default: `$cubetruss_size` (usually 30)
//   strut = The width of the struts on the cubetruss cubes.  Default: `$cubetruss_strut_size` (usually 3)
//   clipthick = The thickness of the clips.  Default: `$cubetruss_clip_thickness` (usually 1.6)
//   ---
//   $slop = Make fit looser by this amount to allow for printer overextrusion
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   cubetruss_joiner(w=1, vert=false);
//   cubetruss_joiner(w=1, vert=true);
//   cubetruss_joiner(w=2, vert=true, anchor=BOT);
module cubetruss_joiner(w=1, vert=true, size, strut, clipthick, anchor=CENTER, spin=0, orient=UP) {
    size = is_undef(size)? $cubetruss_size : size;
    strut = is_undef(strut)? $cubetruss_strut_size : strut;
    clipthick = is_undef(clipthick)? $cubetruss_clip_thickness : clipthick;
    clipsize = 0.5;
    s = [cubetruss_dist(w,1,size,strut)+2*clipthick, cubetruss_dist(2,0,size,strut)-0.1, strut+clipthick];
    attachable(anchor,spin,orient, size=s, offset=[0,0,-(clipthick-strut)/2]) {
        down(clipthick) {
            // Base
            cube([w*(size-strut)+strut+2*clipthick, size, clipthick], anchor=BOT);

            xcopies(w*(size-strut)+strut+clipthick) {
                cube([clipthick, size, clipthick+strut*3/4], anchor=BOT);
            }

            // Use feet
            ycopies(size) {
                cubetruss_foot(w=w, size=size, strut=strut, clipthick=clipthick, anchor=BOT);
            }

            if (vert) {
                // Vert Walls
                xcopies(w*(size-strut)+strut+clipthick) {
                    up(clipthick-0.01) {
                        prismoid([clipthick, size], [clipthick, 2*strut+2*clipthick], h=size*0.6, anchor=BOT);
                    }
                }

                // Vert Wall Clips
                up(size/2) {
                    xflip_copy(offset=(w*(size-strut)+strut+0.02)/2) {
                        yflip_copy(offset=strut+get_slop()/2) {
                            yrot(-90) {
                                back_half() {
                                    prismoid([size/3.5, clipthick*2], [size/3.5-4*2*clipsize, 0.1], h=2*clipsize, anchor=BOT);
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


// Module: cubetruss_uclip()
// Synopsis: Creates a joiner that can connect two cubetrusses end-to-end.
// SynTags: Geom
// Topics: Trusses, CubeTruss, FDM Optimized, Parts
// See Also: cubetruss_segment(), cubetruss_support(), cubetruss(), cubetruss_corner()
// Usage:
//   cubetruss_uclip(dual, [size=], [strut=], [clipthick=]) [ATTACHMENTS];
// Description:
//   Creates a small clip that can snap around one or two adjacent struts.
// Arguments:
//   dual = If true, create a clip to clip around two adjacent struts.  If false, just fit around one strut.  Default: true
//   size = The length of each side of the cubetruss cubes.  Default: `$cubetruss_size` (usually 30)
//   strut = The width of the struts on the cubetruss cubes.  Default: `$cubetruss_strut_size` (usually 3)
//   clipthick = The thickness of the clips.  Default: `$cubetruss_clip_thickness` (usually 1.6)
//   ---
//   $slop = Make fit looser by this amount
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   cubetruss_uclip(dual=false);
//   cubetruss_uclip(dual=true);
module cubetruss_uclip(dual=true, size, strut, clipthick, anchor=CENTER, spin=0, orient=UP) {
    size = is_undef(size)? $cubetruss_size : size;
    strut = is_undef(strut)? $cubetruss_strut_size : strut;
    clipthick = is_undef(clipthick)? $cubetruss_clip_thickness : clipthick;
    clipsize = 0.5;
    s = [(dual?2:1)*strut+2*clipthick+get_slop(), strut+2*clipthick, size/3.5];
    attachable(anchor,spin,orient, size=s) {
        union() {
            difference() {
                cube(s, center=true);
                back(clipthick) cube([(dual?2:1)*strut+get_slop(), strut+2*clipthick, size+1], center=true);
            }
            back((strut+get_slop())/2) {
                xflip_copy(offset=(dual?1:0.5)*strut+get_slop()/2) {
                    yrot(-90) {
                        back_half() {
                            prismoid([size/3.5, clipthick*1.87], [size/3.5, 0.1], h=clipsize, anchor=BOT);
                        }
                    }
                }
            }
        }
        children();
    }
}



// Section: Cubetruss Primitives

// Module: cubetruss_segment()
// Synopsis: Creates a single cubetruss cube.
// SynTags: Geom
// Topics: Trusses, CubeTruss, FDM Optimized, Parts
// See Also: cubetruss_segment(), cubetruss_support(), cubetruss(), cubetruss_corner()
// Usage:
//   cubetruss_segment([size=], [strut=], [bracing=]);
// Description:
//   Creates a single cubetruss cube segment.
// Arguments:
//   size = The length of each side of the cubetruss cubes.  Default: `$cubetruss_size` (usually 30)
//   strut = The width of the struts on the cubetruss cubes.  Default: `$cubetruss_strut_size` (usually 3)
//   bracing = If true, adds internal cross-braces.  Default: `$cubetruss_bracing` (usually true)
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   cubetruss_segment(bracing=false);
//   cubetruss_segment(bracing=true);
//   cubetruss_segment(strut=4);
//   cubetruss_segment(size=40);
module cubetruss_segment(size, strut, bracing, anchor=CENTER, spin=0, orient=UP) {
    size = is_undef(size)? $cubetruss_size : size;
    strut = is_undef(strut)? $cubetruss_strut_size : strut;
    bracing = is_undef(bracing)? $cubetruss_bracing : bracing;
    h = size;
    crossthick = strut/sqrt(2);
    voffset = 0.333;
    attachable(anchor,spin,orient, size=[size,size,size]) {
        render(convexity=10)
        union() {
            difference() {
                // Start with a cube.
                cube([size, size, h], center=true);

                cube([size-strut*2, size-strut*2, h-strut*2+1], center=true);

                // Hollow out octogons in X and Y axes.
                zrot_copies([0,90]) {
                    xrot(90) zrot(180/8) cylinder(h=max(h,size)+1, d=(min(h,size)-2*strut)/cos(180/8), center=true, $fn=8);
                }

                // Hollow out octogon vertically.
                zrot(180/8) cylinder(h=max(h,size)+1, d=(min(h,size)-2*strut)/cos(180/8), center=true, $fn=8);
            }

            // Interior cross-supports
            if (bracing) {
                for (i = [-1,1]) {
                    zrot(i*45) {
                        difference() {
                            cube([crossthick, (size-strut)*sqrt(2), h], center=true);
                            up(i*voffset) {
                                yscale(1.3) {
                                    yrot(90) {
                                        zrot(180/6) {
                                            cylinder(h=crossthick+1, d=(min(h,size)-2*strut)/cos(180/6)-2*voffset, center=true, $fn=6);
                                        }
                                    }
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


// Module: cubetruss_clip()
// Synopsis: Creates a clip for the end of a cubetruss to snap-lock it to another cubetruss.
// SynTags: Geom
// Topics: Trusses, CubeTruss, FDM Optimized, Parts
// See Also: cubetruss_segment(), cubetruss_support(), cubetruss(), cubetruss_corner()
// Usage:
//   cubetruss_clip(extents, [size=], [strut=], [clipthick=]) [ATTACHMENTS];
// Description:
//   Creates a pair of clips to add onto the end of a truss.
// Arguments:
//   extents = How many cubes to separate the clips by.
//   size = The length of each side of the cubetruss cubes.  Default: `$cubetruss_size` (usually 30)
//   strut = The width of the struts on the cubetruss cubes.  Default: `$cubetruss_strut_size` (usually 3)
//   clipthick = The thickness of the clip.  Default: `$cubetruss_clip_thickness` (usually 1.6)
//   ---
//   $slop = allowance for printer overextrusion
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   cubetruss_clip(extents=2);
//   cubetruss_clip(extents=1);
//   cubetruss_clip(clipthick=2.5);
module cubetruss_clip(extents=1, size, strut, clipthick, anchor=CENTER, spin=0, orient=UP) {
    size = is_undef(size)? $cubetruss_size : size;
    strut = is_undef(strut)? $cubetruss_strut_size : strut;
    clipthick = is_undef(clipthick)? $cubetruss_clip_thickness : clipthick;
    cliplen = strut * 2.6;
    clipheight = min(size+strut, size/3+2*strut*2.6);
    clipsize = 0.5;
    s = [extents*(size-strut)+strut+2*clipthick, strut*2, clipheight-2*strut];
    attachable(anchor,spin,orient, size=s) {
        xflip_copy(offset=(extents*(size-strut)+strut)/2) {
            difference() {
                union() {
                    difference() {
                        right(clipthick/2-0.01) {
                            back(strut) {
                                difference() {
                                    xrot(90) prismoid([clipthick, clipheight], [clipthick, clipheight-cliplen*2], h=cliplen);
                                    right(clipthick/2) chamfer_edge_mask(l=clipheight+0.1, chamfer=clipthick);
                                }
                            }
                        }
                        fwd(strut*3/2) {
                            cube([get_slop(), strut*3, size], center=true);
                        }
                    }
                    right(get_slop()/2+0.01) {
                        fwd(strut*1.25+get_slop()) {
                            yrot(-90) prismoid([clipheight-cliplen*2, strut/2], [clipheight-cliplen*2-2*clipsize, strut/2], h=clipsize+0.01);
                        }
                    }
                }
                fwd(strut*1.6) {
                    left(clipsize) {
                        yscale(1.5) chamfer_edge_mask(l=size+1, chamfer=clipsize+clipthick/3);
                    }
                }
                zcopies(clipheight-strut) cube([clipthick*3, cliplen*2, strut], center=true);
                zcopies(clipheight-2*strut) right(clipthick) chamfer_edge_mask(l=cliplen*2, chamfer=clipthick, orient=BACK);
            }
        }
        children();
    }
}


// Function: cubetruss_dist()
// Synopsis: Returns the length of a cubetruss truss.
// Topics: Trusses, CubeTruss, FDM Optimized, Parts
// See Also: cubetruss_segment(), cubetruss_support(), cubetruss(), cubetruss_corner()
// Usage:
//   length = cubetruss_dist(cubes, [gaps], [size=], [strut=]);
// Description:
//   Function to calculate the length of a cubetruss truss.
// Arguments:
//   cubes = The number of cubes along the truss's length.
//   gaps = The number of extra strut widths to add in, corresponding to each time a truss butts up against another.
//   size = The length of each side of the cubetruss cubes.  Default: `$cubetruss_size` (usually 30)
//   strut = The width of the struts on the cubetruss cubes.  Default: `$cubetruss_strut_size` (usually 3)
function cubetruss_dist(cubes=0, gaps=0, size, strut) =
    let(
        size = is_undef(size)? $cubetruss_size : size,
        strut = is_undef(strut)? $cubetruss_strut_size : strut
    ) cubes*(size-strut)+gaps*strut;



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
