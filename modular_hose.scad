//////////////////////////////////////////////////////////////////////////
// LibFile: modular_hose.scad
//   Modular hose segment and attachment ends. 
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/modular_hose.scad>
// FileGroup: Parts
// FileSummary: Modular flexible hose segments.
//////////////////////////////////////////////////////////////////////////

// Section: Modular Hose Parts

_modhose_small_end = [
             turtle([
                     "left", 90-38.5,            //   1/4" hose
                     "arcsteps", 12, 
                     "arcleft", 6.38493, 62.15,
                     "arcsteps", 4,
                     "arcleft", .5, 90+38.5-62.15,
                     "move", .76,
                     "left", 67.5,
                     "move", .47,
                     "left", 90-67.5,
                     "move", 4.165,
                     "right", 30,
                     "move", 2.1
                    ],
                    state=[4.864,0]),
             turtle([                            //   1/2" hose
                     "left", 90-41,
                     "arcsteps", 16, 
                     "arcleft", 10.7407, 64.27,
                     "arcsteps", 4,
                     "arcleft", .5, 90+41-64.27,
                     "move", .95-.4,
                     "left", 45,
                     "move", .4*sqrt(2), 
                     "left",45,
                     "move", 7.643-.4,
                     "right", 30,
                     "move", 4.06
                   ],
                   state=[8.1, 0]),
             turtle([                            //   3/4" hose
                     "left", 90-30.4,
                     "arcsteps", 16,
                     "arcleft", 13.99219,53,
                     "arcsteps", 4, 
                     "arcleft", .47,90-53+30.4,
                     "move", .597,
                     "left", 
                     "move", 9.908-1.905/tan(25) +3.81*cos(30),  // Change to 25 deg angle
                     "right", 25,                                // to remove narrow point in wall
                     "move",1.905 /sin(25),
                  ],
                  state=[11.989,0])
            ];
  

_modhose_big_end = [
           turtle([                            //   1/4" hose
                   "left", 90-22,
                   "move", 6.5,
                   "left",.75,
                   "arcsteps", 8,
                   "arcleft", 6.5, 37.3,
                   "setdir",90,
                   "move", .21,
                   "right",
                   "move", 1.24,
                   "right", 45,
                   "move", .7835,
                   "right", 19, 
                   "move", 1.05,
                   "setdir", -90,
                   "move", 1,
                   "right", 22,
                   "move", 8.76
                  ],
                  state = [3.268,0]),
           turtle([                            //   1/2" hose
                   "left",     
                   "right", 22,
                   "move", 9,
                   "arcsteps", 8,
                   "arcleft", 11, 36.5,
                   "setdir",90,
                   "move",2-1.366,
                   "right",
                   "move",.91,
                   "arcsteps", 4, 
                   "arcright", 1.25, 90,
                   "move", 2.2,
                   "arcsteps", 8, 
                   "arcright", 13, 22.4,
                   "move", 8.73
                  ],
                  state=[6.42154, 0]),
           turtle([                            //   3/4" hose
                   "left", 90-22, 
                   "move", 7.633,
                   "arcsteps", 16,
                   "arcleft", 13.77, 35.27,
                   "setdir", 90,
                   "move", 1.09,
                   "right",
                   "move",1.0177,
                   "right", 45,
                   "move", 1.009,
                   "right", 77.8-45,
                   "move", .3,
                   "arcright", 15.5, 34.2,
                   "move", 6.47
                  ],
                  state=[9.90237,0])
        ];


_modhose_waist = [1.7698, 1.8251, 3.95998];


// Module: modular_hose()
// Synopsis: Creates modular hose parts.
// Topics: Modular Hose, Parts
// See Also: modular_hose_radius(), tube()
// Usage:
//    modular_hose(size, type, [clearance], [waist_len], [anchor], [spin], [orient]) [ATTACHMENTS];
// Description:
//    Construct moduler hose segments or modular hose ends for connection to standard
//    modular hose systems.  The 1/4", 1/2" and 3/4" sizes are supported and you can
//    produce just one end to make a mount or end attachment to a modular hose,
//    or you can make modular hose segments.  To make assembly possible with printed
//    parts you can add clearances that make the ball end smaller and the socket end
//    larger.  These work by simply increasing the radius of the whole end by the specified
//    amount.  On a Prusa printer with PETG, a clearance of 0.05 allows the 3/4" hose parts to mate
//    with standard modular hose or itself.  A clearance of 0.05 to 0.1 allows the 1/2" parts to mate with
//    standard hose, and with clearance 0 the 1/4" parts will mate with standard hose.  Note that clearance values
//    are different for the different sizes.  You will have to experiment with your machine and materials.  Small
//    adjustments will change the stiffness of the connection.
// Arguments:
//    size = size of modular hose part, must be 1/4, 1/2 or 3/4.
//    type = type of part to make, either "segment", "socket" (or "big"), or "ball" (or "small")
//    clearance = clearance to make assembly possible.  Either a scalar to apply the same to both ends or a vector [small,large] to apply different clearances to the two ends.  Default: 0
//    waist_len = size of central "waist" of the part.  Default: standard length.
// Example:
//    modular_hose(1/4,"segment");
//    right(25)modular_hose(1/2,"segment");
//    right(60)modular_hose(3/4,"segment");
// Example: A mount point for modular hose
//    cylinder(h=10, r=20)
//       attach(TOP) modular_hose(1/2, "ball", waist_len=15);
// Example: Mounting plate for something at the end of the hose
//    cuboid([50,50,5])
//       attach(TOP) modular_hose(3/4, "socket", waist_len=0);
function modular_hose(size, type, clearance=0, waist_len, anchor=BOTTOM, spin=0,orient=UP) = no_function("modular_hose");
module modular_hose(size, type, clearance=0, waist_len, anchor=BOTTOM, spin=0,orient=UP)
{
  clearance = force_list(clearance,2);
  ind = search([size],[1/4, 1/2, 3/4])[0];
  sbound =
    assert(ind!=[], "Must specify size as 1/4, 1/2 or 3/4")
    pointlist_bounds(_modhose_small_end[ind]);
  bbound = pointlist_bounds(_modhose_big_end[ind]);
  smallend =
    assert(is_vector(clearance,2), "Clearance must be a scalar or length 2 vector")
    move([-clearance[0],-sbound[0].y],p=_modhose_small_end[ind]);
  bigend = move([clearance[1], -bbound[0].y], p=_modhose_big_end[ind]);

  midlength = first_defined([waist_len, _modhose_waist[ind]]);
  dummy = assert(midlength>=0,"midlength must be nonnegative");

  goodtypes = ["small","big","segment","socket","ball"];
  shape =
    assert(in_list(type,goodtypes), str("type must be one of ",goodtypes))
    type=="segment"? concat(back(midlength,p=smallend),yflip(p=bigend))
  : type=="small" || type=="ball" ?
          concat(back(midlength,p=smallend),
                 [[last(smallend).x,0],[ smallend[0].x,0]])
  : concat( back(midlength,p=bigend), 
                  [[last(bigend).x,0],[ bigend[0].x,0]]);
  bounds = pointlist_bounds(shape);
  center = mean(bounds);
  attachable(anchor,spin,orient,l=bounds[1].y-bounds[0].y, r=bounds[1].x)
  {
    rotate_extrude(convexity=4)
      polygon(fwd(center.y,p=shape));
    children();
  }  
}


// Function: modular_hose_radius()
// Synopsis: Returns the waist radius of the given modular hose size.
// Topics: Modular Hose, Parts
// See Also: modular_hose(), tube()
// Usage:
//   r = modular_hose_radius(size, [outer]);
// Description:
//   Returns the inner (or outer) diameter of the waist section
//   of the modular hose to enable hollowing out connecting channels.
//   Note: diameter is accurate to about 1e-4.  
// Arguments:
//   size = size of hose part, must be 1/4, 1/2 or 3/4
//   outer = set to true to get the outer diameter. 
// Example(3D):
//   $fn=64;
//   back_half()
//      diff("remove")
//        cuboid(50){
//          attach(TOP) modular_hose(1/2, "ball");
//          up(0.01)position(TOP+RIGHT)tag("remove")
//            rot(180)
//            xrot(-90)
//            rotate_extrude(angle=135)
//            right(25)
//            circle(r=modular_hose_radius(1/2));
//        }
function modular_hose_radius(size, outer=false) =
  let(
      ind = search([size],[1/4, 1/2, 3/4])[0]
  )
  assert(ind!=[], "Must specify size as 1/4, 1/2 or 3/4")
  let(
     b = select(_modhose_big_end[ind], [0,-1]),
     s = select(_modhose_small_end[ind], [0,-1])
  )
  outer ? b[1][0] : b[0][0];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
