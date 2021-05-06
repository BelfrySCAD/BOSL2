include <BOSL2/std.scad>
include <BOSL2/gears.scad>
include <BOSL2/beziers.scad>
include <BOSL2/screws.scad>
include <BOSL2/cubetruss.scad>

$fa=1;
$fs=1;

xdistribute(50) {
	recolor("#f77")
	diff("hole")
	cuboid([45,45,10], chamfer=10, edges=[RIGHT+BACK,RIGHT+FRONT], anchor=FRONT) {
		cuboid([30,30,11], chamfer=5, edges=[RIGHT+BACK,RIGHT+FRONT], $tags="hole");
		attach(FRONT,BACK, overlap=5) {
			diff("hole")
			cuboid([45,45,10], rounding=15, edges=[RIGHT+BACK,RIGHT+FRONT]) {
				cuboid([30,30,11], rounding=10, edges=[RIGHT+BACK,RIGHT+FRONT], $tags="hole");
			}
		}
	}

    recolor("#7f7")
	bevel_gear(pitch=8, teeth=20, face_width=12, shaft_diam=25, pitch_angle=45, slices=12, spiral_angle=30);

	x = 18;
	y = 20;
	s1 = 25;
	s2 = 20;
	sbez = [
		            [-x,-y], [-x,-y-s1],
		[ x,-y-s1], [ x,-y], [ x,-y+s2],
		[-x, y-s2], [-x, y], [-x, y+s1],
		[ x, y+s1], [ x, y]
	];
	recolor("#99f")
	path_sweep(regular_ngon(n=3,d=10,spin=90), bezier_path(sbez));

	recolor("#0bf")
	translate([-15,-35,0])
	cubetruss_corner(size=10, strut=1, h=1, bracing=false, extents=[3,8,0,0,0], clipthick=0);

	recolor("#777")
	xdistribute(24) {
		screw("M12,70", head="hex", anchor="origin", orient=BACK)
			attach(BOT,CENTER)
				nut("M12", thickness=10, diameter=20, details=true);
		screw("M12,70", head="hex", anchor="origin", orient=BACK)
			attach(BOT,CENTER)
				nut("M12", thickness=10, diameter=20, details=true);
	}
}

