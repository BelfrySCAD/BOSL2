//////////////////////////////////////////////////////////////////////
// Snap-together joiners
//////////////////////////////////////////////////////////////////////

/*
BSD 2-Clause License

Copyright (c) 2017, Revar Desmera
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


include <transforms.scad>


module half_joiner_clear(h=20, w=10, a=30, clearance=0)
{
	dmnd_height = h*1.0;
	dmnd_width = dmnd_height*tan(a);
	guide_size = w/3;
	guide_width = 2*(dmnd_height/2-guide_size)*tan(a);

	difference() {
		// Diamonds.
		scale([w+clearance, dmnd_width/2, dmnd_height/2]) {
			xrot(45) cube(size=[1,sqrt(2),sqrt(2)], center=true);
		}
		// Blunt point of tab.
		grid_of(ya=[-(guide_width/2+2), (guide_width/2+2)]) {
			cube(size=[(w+clearance)*1.05, 4, h*0.99], center=true);
		}
	}
}
//half_joiner_clear();



module half_joiner(h=20, w=10, l=10, a=30, screwsize=undef, guides=true, slop=printer_slop)
{
	dmnd_height = h*1.0;
	dmnd_width = dmnd_height*tan(a);
	guide_size = w/3;
	guide_width = 2*(dmnd_height/2-guide_size)*tan(a);

	difference() {
		union() {
			// Make base.
			difference() {
				// Solid backing base.
				translate([0,-l/2,0])
					cube(size=[w, l, h], center=true);

				// Clear diamond for tab
				grid_of(xa=[-(w*2/3), (w*2/3)]) {
					half_joiner_clear(h=h+0.01, w=w, clearance=slop*2, a=a);
				}
			}

			difference() {
				// Make tab
				scale([w/3-slop*2, dmnd_width/2, dmnd_height/2]) xrot(45)
					cube(size=[1,sqrt(2),sqrt(2)], center=true);

				// Blunt point of tab.
				translate([0,guide_width/2+2,0])
					cube(size=[w*0.99,4,guide_size*2], center=true);
			}


			// Guide ridges.
			if (guides == true) {
				xspread(w/3-slop*2) {
					// Guide ridge.
					fwd(0.05/2) {
						scale([0.75, 1, 2]) yrot(45)
							cube(size=[guide_size/sqrt(2), guide_width+0.05, guide_size/sqrt(2)], center=true);
					}

					// Snap ridge.
					scale([0.25, 0.5, 1]) zrot(45)
						cube(size=[guide_size/sqrt(2), guide_size/sqrt(2), dmnd_width], center=true);
				}
			}
		}

		// Make screwholes, if needed.
		if (screwsize != undef) {
			yrot(90) cylinder(r=screwsize*1.1/2, h=w+1, center=true, $fn=12);
		}
	}
}
//half_joiner(screwsize=3);



module half_joiner2(h=20, w=10, l=10, a=30, screwsize=undef, guides=true)
{
	difference() {
		union () {
			translate([0,-l/2,0])
				cube(size=[w, l, h], center=true);
			half_joiner_clear(h=h, w=w, a=a);
		}

		// Subtract mated half_joiner.
		zrot(180) half_joiner(h=h+0.05, w=w+0.05, l=l+0.05, a=a, screwsize=undef, guides=guides, slop=0.0);

		// Make screwholes, if needed.
		if (screwsize != undef) {
			yrot(90) cylinder(r=screwsize*1.1/2, h=w+1, center=true, $fn=12);
		}
	}
}
//half_joiner2(screwsize=3);



module joiner(h=40, w=10, l=10, a=30, screwsize=undef, guides=true, slop=printer_slop)
{
	union() {
		translate([0,0,h/4])
			half_joiner(h=h/2, w=w, l=l, a=a, screwsize=screwsize, guides=guides, slop=slop);
		translate([0,0,-h/4])
			half_joiner2(h=h/2, w=w, l=l, a=a, screwsize=screwsize, guides=guides);
	}
}
//joiner(screwsize=3);



module joiner_clear(h=40, w=10, a=30, clearance=0)
{
	grid_of(za=[-h/4,h/4]) {
		half_joiner_clear(h=h/2.0, w=w, a=a, clearance=clearance);
	}
}
//joiner_clear();



module joiner_pair(spacing=100, h=40, w=10, l=10, a=30, screwsize=undef, guides=true)
{
	yrot_copies([0,180]) {
		translate([spacing/2, 0, 0]) {
			joiner(h=h, w=w, l=l, a=a, screwsize=screwsize, guides=guides);
		}
	}
}
//joiner_pair(spacing=100, h=40, w=10, l=10, a=30, screwsize=3, guides=true);



module joiner_pair_clear(spacing=100, h=40, w=10, a=30, clearance=0)
{
	yrot_copies([0,180]) {
		translate([spacing/2, 0, 0]) {
			joiner_clear(h=h, w=w, a=a, clearance=clearance);
		}
	}
}
//joiner_pair_clear(spacing=100, h=40, w=10, a=30);



module joiner_quad(xspacing=100, yspacing=50, h=40, w=10, l=10, a=30, screwsize=undef, guides=true)
{
	zrot_copies([0,180]) {
		translate([0, yspacing/2, 0]) {
			joiner_pair(spacing=xspacing, h=h, w=w, l=l, a=a, screwsize=screwsize, guides=guides);
		}
	}
}
//joiner_quad(xspacing=100, yspacing=50, h=40, w=10, l=10, a=30, screwsize=3, guides=true);



module joiner_quad_clear(xspacing=100, yspacing=50, h=40, w=10, a=30, clearance=0)
{
	zrot_copies([0,180]) {
		translate([0, yspacing/2, 0]) {
			joiner_pair_clear(spacing=xspacing, h=h, w=w, a=a, clearance=clearance);
		}
	}
}
//joiner_quad_clear(xspacing=100, yspacing=50, h=40, w=10, a=30);



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

