//////////////////////////////////////////////////////////////////////////////////////////////
// LibFile: handles.scad
//   2-point handles
//   Ported from Fully_Customizable_General_Purpose_Handles_-_Dual_Point_Customizer v1.2 by
//   codeandmake.com
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/handles.scad>
// FileGroup: Parts
// FileSummary: 2-point U-shaped handles
//////////////////////////////////////////////////////////////////////////////////////////////

// Original Copyright notice:
/*
 * Copyright 2020-2022 Code and Make (codeandmake.com)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * Fully Customizable General Purpose Handles by Code and Make (https://codeandmake.com/)
 *
 * https://www.thingiverse.com/thing:4643658
 *
 * General Purpose Handle Dual Point v1.2 (25 March 2022)
 */ 
// *** Former Customizer Variables ***
/* [Screws] */
// Distance between the screws
Screw_Distance = undef;
// Screw hole diameter
Screw_Hole_Diameter = undef;
// Screw from front or rear
Screw_Direction = undef;
/* [Front Screws] */
// Screw head hole diameter
Screw_Head_Hole_Diameter = undef;
// Material thickness (between screw head and base)
Screw_Material_Thickness = undef;
// Screw countersink angle (82 and 90 are common)
Screw_Countersink_Angle = undef;
/* [Rear Screws] */
// Depth of screw holes
Screw_Hole_Depth = undef;
/* [Handle] */
// Thickness of handle (X and Y axis)
Handle_Material_Thickness = undef;
// Height of handle (Z axis)
Handle_Height = undef;
// Handle end length (in addition to Handle_Material_Thickness)
Handle_End_Length = undef;
/* [Hand Hole] */
// Width of hand hole (X axis)
Hand_Hole_Width = undef;
// Depth of hand hole (Y axis)
Hand_Hole_Depth = undef;
/* [Bevel] */
// Radius of bevel
Bevel_Radius = undef;
// Should bevel be rounded?
Bevel_Rounded = undef;

// Function & Module: handle()
// Synopsis: Creates a U-shaped handle secured by two screws
// SynTags: 
// Topics: Handles, Parts
// See Also: 
// Usage: As a Module
//   handle([screw_s], [screw_d], [screw_z_dir], [screw_head_d], [base_t], [countersink_angle], [counterbore_h], [w], [t], [end_l], [gap_l], [gap_h], [fillet_r], [chamfer_s], [a_skew]);
// Usage: As a Function
//  not supported
// Description:
//  Creates a U-shaped handle secured by two screws.
//  One simple usage would be to specify the handle thickness [t] and the space under the handle (gap_h) and leave the rest as default.
// Arguments:
// handle(
//     screw_s = Distance between screw centers. Default is screw_d + gap_l.
//     screw_d = Screw through-hole diameter.
//     screw_z_dir = Screw orientation. -1 for downward (countersink on top), 1 - upward (counterbore underneath)
//     screw_head_d = Maximum diameter of the countersink or counterbore
//     base_t = Thickness between the bottom of the base and the bottom of the counterbore/countersink.
//     countersink_angle
//     counterbore_h = Depth of the counterbore if screw_z_dir == 1. 
//     w = Width of the handle in the y direction.
//     t = Thickness of the handle in the z direction. Default is w.
//     end_l = Length of handle past the screw center.
//     gap_l = Gap length in the y direction.
//     gap_h = Gap height in the z direction.
//     fillet_r = Fillet radius. Default is chamfer instead of fillet.
//     chamfer_s = Chamfer face length. Default is 1.5.
//     a_skew = Skew angle in the y direction. Screw holes remain parallel to z axis.
// Extra Anchors:
//     none (anchors not yet supported)
// Side Effects:
//     none known
// Example:
// handle($fa=5,$fs=0.4,t=15,gap_h=24,w=16.5,screw_d=7.5, countersink_angle=90,base_t=10,end_l=12,gap_l=40,fillet_r=7.5,a_skew=22.5);

module handle(
    screw_s,
    screw_d,
    screw_z_dir, // -1 downward (from front), 1 - upward (from rear)
    screw_head_d,
    base_t,
    countersink_angle,
    counterbore_h,
    w,
    t,
    end_l,
    gap_l,
    gap_h,
    fillet_r,
    chamfer_s,
    a_skew) {

    // Screw hole diameter
    Screw_Hole_Diameter = default(screw_d,5); // [2:0.5:10]
    assert(Screw_Hole_Diameter >= 0.5, "screw_d is less than minimum value of 0.5");
    // Screw from front or rear
    Screw_Direction = default(screw_z_dir,-1) == -1 ? 0 : 1; // [0:Front, 1:Rear]
    /* [Front Screws] */
    // Screw head hole diameter
    Screw_Head_Hole_Diameter = default(screw_head_d, Screw_Hole_Diameter*2); // [2:0.5:15]
    assert(Screw_Head_Hole_Diameter >= 0.5, "screw_head_d is less than minimum value of 0.5");
    // Material thickness (between screw head and base)
    Screw_Material_Thickness = default(base_t, 5); // [2:0.5:15]
    // assert(Screw_Material_Thickness >= 0.5, "base_t is less than minimum value of 0.5");
    // Screw countersink angle (82 and 90 are common)
    Screw_Countersink_Angle = default(countersink_angle, 90); // [1:0.5:180]
    assert(Screw_Countersink_Angle >= 0, "countersink_angle is less than minimum of 0 degrees");
    assert(Screw_Countersink_Angle <= 180, "countersink_angle is greather than maximum of 180 degrees");
    /* [Rear Screws] */
    // Depth of screw holes
    Screw_Hole_Depth = default(counterbore_h, 10); // [1:1:50]
    /* [Handle] */
    assert(Handle_Material_Thickness >= 0.5, "t is less than minimum value of 0.5");
    // Height of handle (Z axis). Width actually.
    Handle_Height = default(w, 18); // [10:0.5:50]
    assert(Handle_Height >= 0.5, "w is less than minimum value of 0.5");
    // Thickness of handle (X and Y axis). Top to gap, actually.
    Handle_Material_Thickness = default(t, Handle_Height); // [10:0.5:50]
    // Handle end length (in addition to Handle_Material_Thickness)
    Handle_End_Length = default(end_l, 17.5); // [0:0.5:100]
    assert(Handle_End_Length >= 0.5, "end_l is less than minimum value of 0.5");
    /* [Hand Hole] */
    // Width of hand hole (X axis)
    Hand_Hole_Width = default(gap_l, 65); // [50:0.5:150]
    assert(Hand_Hole_Width >= 0.5, "gap_l is less than minimum value of 0.5");
    // Depth of hand hole (Y axis)
    Hand_Hole_Depth = default(gap_h, 20); // [10:0.5:50]
    assert(Hand_Hole_Depth >= 0.5, "h is less than minimum value of 0.5");
    /* [Bevel] */
    // Should bevel be rounded (filleted)?
    Bevel_Rounded = is_undef(fillet_r) ? 0 : 1; // [0:false, 1:true]
    // Radius of fillet or face length of chamfer. Bevel_Radius is equivalent to the z-height of the fillet or chamfer
    Bevel_Radius = (Bevel_Rounded == 1) ? default(fillet_r, 1.5) : default(chamfer_s, 1.5) * sin(45);
    // Distance between the screws
    Screw_Distance = default(screw_s, Hand_Hole_Width + Handle_Material_Thickness + Screw_Hole_Diameter); // [50:1:300]
    assert(Screw_Distance >= 1, "screw_s is less than minimum value of 1");
    A_Skew = default(a_skew, 0);

    fwd(Handle_Height/2) 
    xrot(-90) 
    _handle(
        Screw_Distance = Screw_Distance,
        Screw_Hole_Diameter=        Screw_Hole_Diameter,
        Screw_Direction=        Screw_Direction,
        Screw_Head_Hole_Diameter=        Screw_Head_Hole_Diameter,
        Screw_Material_Thickness=        Screw_Material_Thickness,
        Screw_Countersink_Angle=        Screw_Countersink_Angle,
        Screw_Hole_Depth=        Screw_Hole_Depth,
        Handle_Material_Thickness=        Handle_Material_Thickness,
        Handle_Height=        Handle_Height,
        Handle_End_Length=        Handle_End_Length,
        Hand_Hole_Width=        Hand_Hole_Width,
        Hand_Hole_Depth=        Hand_Hole_Depth,
        Bevel_Rounded=        Bevel_Rounded,
        Bevel_Radius = Bevel_Radius,
        A_Skew = A_Skew 
        );

    children();

    }
    


module _handle(
    Screw_Distance,
    Screw_Hole_Diameter,
    Screw_Direction,
    Screw_Head_Hole_Diameter,
    Screw_Material_Thickness,
    Screw_Countersink_Angle,
    Screw_Hole_Depth,
    Handle_Material_Thickness,
    Handle_Height,
    Handle_End_Length,
    Hand_Hole_Width,
    Hand_Hole_Depth,
    Bevel_Rounded,
    Bevel_Radius,
    A_Skew
) {
  dimensionsX = ((Hand_Hole_Width / 2) + Handle_Material_Thickness + Handle_End_Length) * 2;
  dimensionsY = Hand_Hole_Depth + Handle_Material_Thickness;
  dimensionsZ = Handle_Height;

  rotate([90, 0, 0]) {
    handleHalf();
    mirror([1, 0, 0]) {
      handleHalf();
    }
  }

  module handleHalf() {
    difference() {
      // handle
      //module skew(p, sxy, sxz, syx, syz, szx, szy, axy, axz, ayx, ayz, azx, azy)
      skew(ayz=A_Skew) hull() {
        // upright profile
        mirror([1, 0, -1]) {
          linear_extrude(height = 1, convexity = 10) {
            handleProfile(0);
          }
        }

        // handle end
        translate([(Hand_Hole_Width) / 2, 0, 0]) {
          intersection() {
            cube([Handle_End_Length + Handle_Material_Thickness, Handle_Height, Hand_Hole_Depth + Handle_Material_Thickness]);

            hull() {
              // bottom profile
              mirror([0, 0, 1]) {
                linear_extrude(height = 1, convexity = 10) {
                  handleProfile(Hand_Hole_Depth - Handle_End_Length);
                }
              }

              translate([0, 0, Hand_Hole_Depth]) {
                intersection() {
                  cube([Handle_Material_Thickness, Handle_Height, Handle_Material_Thickness]);

                  rotate([-90, 0, 0]) {
                    rotate_extrude(convexity=10) {
                      handleProfile(Hand_Hole_Depth);
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      // handle hole
      skew(ayz=A_Skew) union() {
        r = min(Handle_Material_Thickness / 2, Hand_Hole_Depth, Hand_Hole_Width / 2);

        handHoleCorner(r);

        translate([0, 0, -0.5]) {
          linear_extrude(height = Hand_Hole_Depth - r + 0.5, convexity = 10) {
            projection() {
              handHoleCorner(r);
            }
          }
        }

        translate([(Hand_Hole_Width / 2) - r, 0, Hand_Hole_Depth - r]) {
          rotate([0, -90, 0]) {
            translate([-((Hand_Hole_Width / 2) - r), 0, 0]) {
              linear_extrude(height = (Hand_Hole_Width / 2) - r  + 0.5, convexity = 10) {
                projection() {
                  handHoleCorner(r);
                }
              }
            }
          }
        }

        translate([-0.5, -0.5, -0.5]) {
          cube([(Hand_Hole_Width / 2) - r  + 0.5, Handle_Height + 1, Hand_Hole_Depth - r + 0.5]);
        }
      }

      // screw hole
      translate([Screw_Distance / 2, Handle_Height / 2, 0]) {
        if (Screw_Direction == 0) {
            screwHole(Hand_Hole_Depth + Handle_Material_Thickness,
              Screw_Hole_Diameter,
              Screw_Head_Hole_Diameter,
              (Hand_Hole_Depth + Handle_Material_Thickness) - Screw_Material_Thickness,
              0,
              Screw_Countersink_Angle);
        }
        else if (Screw_Direction == 1) {
          translate([0, 0, -1]) {
            cylinder(d = Screw_Hole_Diameter, h = Screw_Hole_Depth + 1);
          }
        }
      }
    }
  }

  module screwHole(holeDepth, holeDiameter, headDiameter, boreDepth, aboveHoleBoreDepth, sinkAngle) {
    boreDiameter = (holeDiameter > 0 ? max(holeDiameter, headDiameter) : 0);
    countersinkAdjacent = (boreDiameter / 2) / tan(sinkAngle / 2);
    translate([0, 0, -0.001]) {
      // screw hole
      cylinder(holeDepth + 0.002, holeDiameter / 2, holeDiameter / 2, false);

      // countersink
      if (sinkAngle > 0) {
        translate([0, 0, holeDepth - countersinkAdjacent - boreDepth]) {
          cylinder(countersinkAdjacent + 0.002, 0, (boreDiameter / 2), false);
        }

        // above hole and bore
        translate([0, 0, holeDepth - boreDepth]) {
          cylinder(boreDepth + aboveHoleBoreDepth + 0.002, boreDiameter / 2, boreDiameter / 2, false);
        }
      } else {
        // full bore
        cylinder(holeDepth + aboveHoleBoreDepth + 0.002, boreDiameter / 2, boreDiameter / 2, false);
      }
    }      
  }

  module handHoleCorner(r) {
    translate([(Hand_Hole_Width / 2) - r, -0.5, Hand_Hole_Depth - r]) {
      // corner
      rotate([-90, 0, 0]) {
        cylinder(r = r + 0.01, h = Handle_Height + 1);
      }

      // bevel
      translate([0, 0.5, 0]) {
        rotate([90, -90, 180]) {
          innerBevel(r);
        }

        translate([0, Handle_Height, 0]) {
          rotate([90, 0, 0]) {
            innerBevel(r);
          }
        }
      }
    }
  }

  module innerBevel(r) {
    translate([0, 0, -1]) {
      cylinder(r = r + Bevel_Radius, h = 1);
    }

    cylinder(r = r, h = Bevel_Radius);

    rotate_extrude(convexity=10) {
      translate([r, 0, 0]) {
        difference() {
          polygon([
            [0, 0],

            [0, Bevel_Radius],

            [Bevel_Radius, 0],
          ]);

          if (Bevel_Rounded) {
            translate([Bevel_Radius, Bevel_Radius, 0]) {
              intersection() {
                circle(r=Bevel_Radius);

                translate([-Bevel_Radius, -Bevel_Radius, 0]) {
                  square([Bevel_Radius, Bevel_Radius]);
                }
              }
            }
          }
        }
      }
    }
  }

  /**
   * xTrim - Amount to trim from 'flat' end
   */
  module handleProfile(xTrim) {
    translate([0, Handle_Height / 2, 0]) {
      handleHalfProfile(xTrim);
      mirror([0, 1, 0]) {
        handleHalfProfile(xTrim);
      }
    }
  }

  module handleHalfProfile(xTrim) {
    xLen = Hand_Hole_Depth + Handle_Material_Thickness;

    polygon([
      [0, 0],

      [0, Handle_Height / 2],

      [xLen - xTrim - Bevel_Radius, Handle_Height / 2],
      [xLen - xTrim, (Handle_Height / 2) - Bevel_Radius],
      
      [xLen - xTrim, 0],
    ]);

    translate([xLen - xTrim - Bevel_Radius, (Handle_Height / 2) - Bevel_Radius, 0]) {
      if (Bevel_Rounded) {
        intersection() {
          square([Bevel_Radius, Bevel_Radius]);
          circle(r = Bevel_Radius);
        }
      }
    }
  }
}

//handle();
