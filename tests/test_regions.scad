include<../std.scad>

module test_is_region() {
    assert(is_region([circle(d=10),square(10)]));
    assert(is_region([circle(d=10),square(10),circle(d=50)]));
    assert(is_region([square(10)]));
    assert(!is_region([]));
    assert(!is_region(23));
    assert(!is_region(true));
    assert(!is_region("foo"));
}
test_is_region();



module test_union() {
  R1 = [square(10,center=true), square(9,center=true)];
  R2 = [square(9,center=true)];
  assert(are_regions_equal(union(R1,R2), [square(10,center=true)]));
  assert(are_regions_equal(union(R2,R1), [square(10,center=true)]));
  R8 = [right(8,square(10,center=true)), left(8,square(10,center=true))];
  R9 = [back(8,square(10,center=true)), fwd(8,square(10,center=true))];
  assert(are_regions_equal(union(R9,R8), [[[-5, -5], [-13, -5], [-13, 5], [-5, 5], [-5, 13], [5, 13], [5, 5], [13, 5], [13, -5], [5, -5], [5, -13], [-5, -13]], [[-3, 3], [-3, -3], [3, -3], [3, 3]]]));
  assert(are_regions_equal(union(R8,R9), [[[-5, -5], [-13, -5], [-13, 5], [-5, 5], [-5, 13], [5, 13], [5, 5], [13, 5], [13, -5], [5, -5], [5, -13], [-5, -13]], [[-3, 3], [-3, -3], [3, -3], [3, 3]]]));

}
test_union();


module test_intersection() {
  R1 = [square(10,center=true), square(9,center=true)];
  R6 = [square(9.5,center=true), square(9,center=true)];
  assert(are_regions_equal(intersection(R6,R1), R6));
  assert(are_regions_equal(intersection(R1,R6), R6));
  R8 = [right(8,square(10,center=true)), left(8,square(10,center=true))];
  R9 = [back(8,square(10,center=true)), fwd(8,square(10,center=true))];
  assert(are_regions_equal(intersection(R9,R8),[[[-3, -5], [-5, -5], [-5, -3], [-3, -3]], [[-5, 5], [-3, 5], [-3, 3], [-5, 3]], [[5, -5], [3, -5], [3, -3], [5, -3]], [[3, 3], [3, 5], [5, 5], [5, 3]]]));
  assert(are_regions_equal(intersection(R8,R9),[[[-3, -5], [-5, -5], [-5, -3], [-3, -3]], [[-5, 5], [-3, 5], [-3, 3], [-5, 3]], [[5, -5], [3, -5], [3, -3], [5, -3]], [[3, 3], [3, 5], [5, 5], [5, 3]]]));


}
test_intersection();


module test_difference() {
  R5 = [square(10,center=true), square(9,center=true),square(4,center=true)];
  R4 = [square(9,center=true), square(3,center=true)];
  assert(are_regions_equal(difference(R5,R4),
                         [square(10,center=true), square(9, center=true), square(3,center=true)]));
  pathA = [
    [-9,12], [-6,2], [-3,12], [0,2], [3,10], [5,10], [19,-4], [-8,-4], [-12,0]
  ];
  pathB = [
    [-12,8], [7,8], [9,6], [7,5], [-3,5], [-5,-6], [-2,-6], [0,-4],
    [6,-4], [2,-8], [-7,-8], [-15,0]
  ];

  right=[[[-10, 8], [-9, 12], [-7.8, 8]], [[0, -4], [-4.63636363636, -4], [-3, 5], [-0.9, 5], [0, 2], [1.125, 5], [7, 5], [9, 6], [19, -4], [6, -4]], [[-4.2, 8], [-1.8, 8], [-3, 12]], [[2.25, 8], [3, 10], [5, 10], [7, 8]]];
  assert(are_regions_equal(difference(pathA,pathB),right));

  R8 = [right(8,square(10,center=true)), left(8,square(10,center=true))];
  R9 = [back(8,square(10,center=true)), fwd(8,square(10,center=true))];

  assert(are_regions_equal(difference(R9,R8), [[[-5, 5], [-5, 13], [5, 13], [5, 5], [3, 5], [3, 3], [-3, 3], [-3, 5]], [[5, -13], [-5, -13], [-5, -5], [-3, -5], [-3, -3], [3, -3], [3, -5], [5, -5]]]));

  assert(are_regions_equal(difference(R8,R9),[[[-5, -5], [-13, -5], [-13, 5], [-5, 5], [-5, 3], [-3, 3], [-3, -3], [-5, -3]], [[3, -3], [3, 3], [5, 3], [5, 5], [13, 5], [13, -5], [5, -5], [5, -3]]]));

  
}
test_difference();



module test_exclusive_or() {
  R8 = [right(8,square(10,center=true)), left(8,square(10,center=true))];
  R9 = [back(8,square(10,center=true)), fwd(8,square(10,center=true))];
  assert(are_regions_equal(exclusive_or(R8,R9),[[[-5, -5], [-13, -5], [-13, 5], [-5, 5], [-5, 3], [-3, 3], [-3, -3], [-5, -3]], [[-3, -5], [-5, -5], [-5, -13], [5, -13], [5, -5], [3, -5], [3, -3], [-3, -3]], [[-5, 5], [-3, 5], [-3, 3], [3, 3], [3, 5], [5, 5], [5, 13], [-5, 13]], [[3, -3], [3, 3], [5, 3], [5, 5], [13, 5], [13, -5], [5, -5], [5, -3]]],either_winding=true));
  assert(are_regions_equal(exclusive_or(R9,R8),[[[-5, -5], [-13, -5], [-13, 5], [-5, 5], [-5, 3], [-3, 3], [-3, -3], [-5, -3]], [[-3, -5], [-5, -5], [-5, -13], [5, -13], [5, -5], [3, -5], [3, -3], [-3, -3]], [[-5, 5], [-3, 5], [-3, 3], [3, 3], [3, 5], [5, 5], [5, 13], [-5, 13]], [[3, -3], [3, 3], [5, 3], [5, 5], [13, 5], [13, -5], [5, -5], [5, -3]]],either_winding=true));  

  p = turtle(["move",100,"left",144], repeat=4);
  p2 = move(-centroid(p),p);
  p3 = polygon_parts(p2);
  p4 = exclusive_or(p3,square(51,center=true));

  star_square = [[[-50, -16.2459848116], [-25.5, -16.2459848116],
  [-25.5, 1.55430712449]], [[-7.45841874701, 25.5], [-30.9016994375,
  42.5325404176], [-25.3674915789, 25.5]], [[-19.0983005625,
  6.20541401733], [-25.5, 1.55430712449], [-25.5, 25.5],
  [-25.3674915789, 25.5]], [[-11.803398875, -16.2459848116],
  [-19.0983005625, 6.20541401733], [-3.5527136788e-15, 20.0811415886],
  [19.0983005625, 6.20541401733], [11.803398875, -16.2459848116]],
  [[7.45841874701, 25.5], [0, 20.0811415886], [-7.45841874701, 25.5]],
  [[25.3674915789, 25.5], [7.45841874701, 25.5], [30.9016994375,
  42.5325404176]], [[25.5, 1.55430712449], [19.0983005625,
  6.20541401733], [25.3674915789, 25.5], [25.5, 25.5]], [[25.5,
  -16.2459848116], [25.5, 1.55430712449], [50, -16.2459848116]],
  [[8.79658707105, -25.5], [11.803398875, -16.2459848116], [25.5,
  -16.2459848116], [25.5, -25.5]], [[-8.79658707105, -25.5],
  [8.79658707105, -25.5], [0, -52.5731112119]], [[-25.5,
  -16.2459848116], [-11.803398875, -16.2459848116], [-8.79658707105,
  -25.5], [-25.5, -25.5]]];
  assert(are_regions_equal(exclusive_or(p3,square(51,center=true)),star_square,either_winding=true));
  assert(are_regions_equal(exclusive_or(square(51,center=true),p3),star_square,either_winding=true));

}
test_exclusive_or();



module test_point_in_region(){
   region = [for(i=[2:8]) hexagon(r=i)];
   pir=[for(x=[-6:6],y=[-6:6]) point_in_region([x,y],region)];
   assert_equal(pir,
          [-1, -1, -1, 1, 1, -1, 0, -1, 1, 1, -1, -1, -1, -1, 1, 1,
          -1, -1, 1, 0, 1, -1, -1, 1, 1, -1, 1, -1, -1, 1, 1, -1, 0,
          -1, 1, 1, -1, -1, 1, -1, 1, 1, -1, -1, 1, 0, 1, -1, -1, 1,
          1, -1, -1, 1, -1, 1, 1, -1, 0, -1, 1, 1, -1, 1, -1, -1, 1,
          -1, 1, -1, 1, 1, 1, -1, 1, -1, 1, -1, -1, 1, -1, 1, -1, 1,
          1, 1, -1, 1, -1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, -1, 1,
          -1, 1, -1, -1, 1, -1, 1, 1, -1, 0, -1, 1, 1, -1, 1, -1, -1,
          1, 1, -1, -1, 1, 0, 1, -1, -1, 1, 1, -1, 1, -1, -1, 1, 1,
          -1, 0, -1, 1, 1, -1, -1, 1, -1, 1, 1, -1, -1, 1, 0, 1, -1,
          -1, 1, 1, -1, -1, -1, -1, 1, 1, -1, 0, -1, 1, 1, -1, -1, -1]);
}
test_point_in_region();


module test_make_region(){
   pentagram = turtle(["move",100,"left",144], repeat=4);
   region1 = make_region(pentagram);
   assert(are_regions_equal(region1,
            [[[0, 0], [38.196601125, 0], [30.9016994375, 22.451398829]], [[50,
            36.3271264003], [19.0983005625, 58.7785252292], [30.9016994375,
            22.451398829]], [[69.0983005625, 22.451398829], [50, 36.3271264003],
            [80.9016994375, 58.7785252292]], [[61.803398875, 3.5527136788e-15],
            [69.0983005625, 22.451398829], [100, 0]], [[38.196601125, 0],
            [61.803398875, 3.94430452611e-31], [50, -36.3271264003]]], either_winding=true));
   /*assert_approx(region1, 
            [[[0, 0], [38.196601125, 0], [30.9016994375, 22.451398829]], [[50,
            36.3271264003], [19.0983005625, 58.7785252292], [30.9016994375,
            22.451398829]], [[69.0983005625, 22.451398829], [50, 36.3271264003],
            [80.9016994375, 58.7785252292]], [[61.803398875, 3.5527136788e-15],
            [69.0983005625, 22.451398829], [100, 0]], [[38.196601125, 0],
            [61.803398875, 3.94430452611e-31], [50, -36.3271264003]]]);*/
   region2 = make_region(pentagram,nonzero=true);
   assert_approx(region2,
            [[[0, 0], [38.196601125, 0], [50, -36.3271264003],
            [61.803398875, 3.5527136788e-15], [100, 0],
            [69.0983005625, 22.451398829], [80.9016994375,
            58.7785252292], [50, 36.3271264003], [19.0983005625,
            58.7785252292], [30.9016994375, 22.451398829]]]);
   region3 = make_region([square(10), move([5,5],square(8))]);
   assert_equal(region3, [[[10, 0], [0, 0], [0, 10], [5, 10], [5, 5], [10, 5]], [[5, 10], [10, 10], [10, 5], [13, 5], [13, 13], [5, 13]]]);
}
test_make_region();



module test_region_area(){
  assert_equal(region_area([square(10), right(20,square(8))]), 164);
}
test_region_area();

  
