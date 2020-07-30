include<../std.scad>
include<../polyhedra.scad>


if (true) {

   $fn=96;

  // Display of all solids with insphere, midsphere and circumsphere
    
  for(i=[0:len(_polyhedra_)-1]) {
    move_copies([[3*i,0,0]])              // Plain polyhedron
      regular_polyhedron(index=i, mr=1,facedown=true);
    move_copies([[3*i,3.5,0]]){           // Inner radius means sphere touches faces of the polyhedron
      sphere(r=1.005);                     // Sphere is slightly oversized so you can see it poking out from each face
      %regular_polyhedron(index=i, ir=1,facedown=true);
      }
    move_copies([[3*i,7,0]]){             // Mid radius means the sphere touches the center of each edge
      sphere(r=1);
      %regular_polyhedron(index=i, mr=1,facedown=true);
      }
    move_copies([[3*i,11,0]]){            // outer radius means points of the polyhedron are on the sphere
      %sphere(r=.99);                      // Slightly undersized sphere means the points poke out a bit
      regular_polyhedron(index=i, or=1,facedown=true);
      }
    }
}



///////////////////////////////////////////////////////////////////////////////////////////////////
//
// Examples start here: not part of library



/*
// Test that rounded shapes are the same size as unrounded
shape = "dodecahedron";
//shape = "cube";
top_half(cp=[0,0,.2])
difference(){
    regular_polyhedron(shape);
    regular_polyhedron(shape, rounding=0.2,side=1.0000);
}
*/
