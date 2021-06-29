include <../std.scad>


module test_translate() {
    vals = [[-1,-2,-3],[0,0,0],[3,6,2],[1,2,3],[243,75,147]];
    for (val=vals) {
        assert_equal(translate(val), [[1,0,0,val.x],[0,1,0,val.y],[0,0,1,val.z],[0,0,0,1]]);
        assert_equal(translate(val, p=[1,2,3]), [1,2,3]+val);
    }
    // Verify that module at least doesn't crash.
    translate([-5,-5,-5]) translate([0,0,0]) translate([5,5,5]) nil();
}
test_translate();


module test_move() {
    vals = [[-1,-2,-3],[0,0,0],[3,6,2],[1,2,3],[243,75,147]];
    for (val=vals) {
        assert_equal(move(val), [[1,0,0,val.x],[0,1,0,val.y],[0,0,1,val.z],[0,0,0,1]]);
        assert_equal(move(val, p=[1,2,3]), [1,2,3]+val);
        assert_equal(move(x=val.x, y=val.y, z=val.z, p=[1,2,3]), [1,2,3]+val);
    }
    // Verify that module at least doesn't crash.
    move(x=-5) move(y=-5) move(z=-5) move([-5,-5,-5]) nil();
    move(x=5) move(y=5) move(z=5) move([5,5,5]) nil();
}
test_move();


module test_left() {
    assert_equal(left(5),[[1,0,0,-5],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(left(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(left(-5),[[1,0,0,5],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(left(5,p=[1,2,3]),[-4,2,3]);
    assert_equal(left(0,p=[1,2,3]),[1,2,3]);
    assert_equal(left(-5,p=[1,2,3]),[6,2,3]);
    // Verify that module at least doesn't crash.
    left(-5) left(0) left(5) nil();
}
test_left();


module test_right() {
    assert_equal(right(-5),[[1,0,0,-5],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(right(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(right(5),[[1,0,0,5],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(right(-5,p=[1,2,3]),[-4,2,3]);
    assert_equal(right(0,p=[1,2,3]),[1,2,3]);
    assert_equal(right(5,p=[1,2,3]),[6,2,3]);
    // Verify that module at least doesn't crash.
    right(-5) right(0) right(5) nil();
}
test_right();


module test_back() {
    assert_equal(back(-5),[[1,0,0,0],[0,1,0,-5],[0,0,1,0],[0,0,0,1]]);
    assert_equal(back(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(back(5),[[1,0,0,0],[0,1,0,5],[0,0,1,0],[0,0,0,1]]);
    assert_equal(back(-5,p=[1,2,3]),[1,-3,3]);
    assert_equal(back(0,p=[1,2,3]),[1,2,3]);
    assert_equal(back(5,p=[1,2,3]),[1,7,3]);
    // Verify that module at least doesn't crash.
    back(-5) back(0) back(5) nil();
}
test_back();


module test_fwd() {
    assert_equal(fwd(5),[[1,0,0,0],[0,1,0,-5],[0,0,1,0],[0,0,0,1]]);
    assert_equal(fwd(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(fwd(-5),[[1,0,0,0],[0,1,0,5],[0,0,1,0],[0,0,0,1]]);
    assert_equal(fwd(5,p=[1,2,3]),[1,-3,3]);
    assert_equal(fwd(0,p=[1,2,3]),[1,2,3]);
    assert_equal(fwd(-5,p=[1,2,3]),[1,7,3]);
    // Verify that module at least doesn't crash.
    fwd(-5) fwd(0) fwd(5) nil();
}
test_fwd();


module test_down() {
    assert_equal(down(5),[[1,0,0,0],[0,1,0,0],[0,0,1,-5],[0,0,0,1]]);
    assert_equal(down(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(down(-5),[[1,0,0,0],[0,1,0,0],[0,0,1,5],[0,0,0,1]]);
    assert_equal(down(5,p=[1,2,3]),[1,2,-2]);
    assert_equal(down(0,p=[1,2,3]),[1,2,3]);
    assert_equal(down(-5,p=[1,2,3]),[1,2,8]);
    // Verify that module at least doesn't crash.
    down(-5) down(0) down(5) nil();
}
test_down();


module test_up() {
    assert_equal(up(-5),[[1,0,0,0],[0,1,0,0],[0,0,1,-5],[0,0,0,1]]);
    assert_equal(up(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(up(5),[[1,0,0,0],[0,1,0,0],[0,0,1,5],[0,0,0,1]]);
    assert_equal(up(-5,p=[1,2,3]),[1,2,-2]);
    assert_equal(up(0,p=[1,2,3]),[1,2,3]);
    assert_equal(up(5,p=[1,2,3]),[1,2,8]);
    // Verify that module at least doesn't crash.
    up(-5) up(0) up(5) nil();
}
test_up();


module test_scale() {
    cb = cube(1);
    vals = [[-1,-2,-3],[1,1,1],[3,6,2],[1,2,3],[243,75,147]];
    for (val=vals) {
        assert_equal(scale(point2d(val)), [[val.x,0,0],[0,val.y,0],[0,0,1]]);
        assert_equal(scale(val), [[val.x,0,0,0],[0,val.y,0,0],[0,0,val.z,0],[0,0,0,1]]);
        assert_equal(scale(val, p=[1,2,3]), v_mul([1,2,3], val));
        scale(val) nil();
    }
    assert_equal(scale(3), [[3,0,0,0],[0,3,0,0],[0,0,3,0],[0,0,0,1]]);
    assert_equal(scale(3, p=[1,2,3]), 3*[1,2,3]);
    assert_equal(scale(3, p=cb), cube(3));
    assert_equal(scale(2, p=square(1)), square(2));
    assert_equal(scale(2, cp=[1,1], p=square(1)), square(2, center=true));
    assert_equal(scale([2,3], p=square(1)), square([2,3]));
    assert_equal(scale([2,2], cp=[0.5,0.5], p=square(1)), move([-0.5,-0.5], p=square([2,2])));
    assert_equal(scale([2,3,4], p=cb), cube([2,3,4]));
    assert_equal(scale([-2,-3,-4], p=cb), [[for (p=cb[0]) v_mul(p,[-2,-3,-4])], [for (f=cb[1]) reverse(f)]]);
    // Verify that module at least doesn't crash.
    scale(-5) scale(5) nil();
}
test_scale();


module test_xscale() {
    vals = [1,-1,-2,-3,10,147];
    for (val=vals) {
        assert_equal(xscale(val), [[val,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
        assert_equal(xscale(val, p=[1,2,3]), [val*1,2,3]);
        xscale(val) nil();
    }
    // Verify that module at least doesn't crash.
    xscale(-5) xscale(5) nil();
}
test_xscale();


module test_yscale() {
    vals = [1,-1,-2,-3,10,147];
    for (val=vals) {
        assert_equal(yscale(val), [[1,0,0,0],[0,val,0,0],[0,0,1,0],[0,0,0,1]]);
        assert_equal(yscale(val, p=[1,2,3]), [1,val*2,3]);
        yscale(val) nil();
    }
    // Verify that module at least doesn't crash.
    yscale(-5) yscale(5) nil();
}
test_yscale();


module test_zscale() {
    vals = [1,-1,-2,-3,10,147];
    for (val=vals) {
        assert_equal(zscale(val), [[1,0,0,0],[0,1,0,0],[0,0,val,0],[0,0,0,1]]);
        assert_equal(zscale(val, p=[1,2,3]), [1,2,val*3]);
        zscale(val) nil();
    }
    // Verify that module at least doesn't crash.
    zscale(-5) zscale(5) nil();
}
test_zscale();


module test_mirror() {
    vals = [LEFT,RIGHT,FWD,BACK,DOWN,UP,BACK+UP+RIGHT,FWD+LEFT];
    for (val=vals) {
        v = unit(val);
        a = v.x;
        b = v.y;
        c = v.z;
        m = [
            [1-2*a*a,  -2*b*a,  -2*c*a, 0],
            [ -2*a*b, 1-2*b*b,  -2*c*b, 0],
            [ -2*a*c,  -2*b*c, 1-2*c*c, 0],
            [      0,       0,       0, 1]
        ];
        assert_approx(mirror(val), m, str("mirror(",val,")"));
        assert_approx(mirror(val, p=[1,2,3]), apply(m, [1,2,3]), str("mirror(",val,",p=...)"));
        // Verify that module at least doesn't crash.
        mirror(val) nil();
    }
}
test_mirror();


module test_xflip() {
    assert_approx(xflip(), [[-1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_approx(xflip(p=[1,2,3]), [-1,2,3]);
    // Verify that module at least doesn't crash.
    xflip() nil();
}
test_xflip();


module test_yflip() {
    assert_approx(yflip(), [[1,0,0,0],[0,-1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_approx(yflip(p=[1,2,3]), [1,-2,3]);
    // Verify that module at least doesn't crash.
    yflip() nil();
}
test_yflip();


module test_zflip() {
    assert_approx(zflip(), [[1,0,0,0],[0,1,0,0],[0,0,-1,0],[0,0,0,1]]);
    assert_approx(zflip(p=[1,2,3]), [1,2,-3]);
    // Verify that module at least doesn't crash.
    zflip() nil();
}
test_zflip();


module test_xyflip() {
    assert_approx(xyflip(), [[0,1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_approx(xyflip(p=[1,2,3]), [2,1,3]);
    // Verify that module at least doesn't crash.
    xyflip() nil();
}
test_xyflip();


module test_xzflip() {
    assert_approx(xzflip(), [[0,0,1,0],[0,1,0,0],[1,0,0,0],[0,0,0,1]]);
    assert_approx(xzflip(p=[1,2,3]), [3,2,1]);
    // Verify that module at least doesn't crash.
    xzflip() nil();
}
test_xzflip();


module test_yzflip() {
    assert_approx(yzflip(), [[1,0,0,0],[0,0,1,0],[0,1,0,0],[0,0,0,1]]);
    assert_approx(yzflip(p=[1,2,3]), [1,3,2]);
    // Verify that module at least doesn't crash.
    yzflip() nil();
}
test_yzflip();


module test_rot() {
    pts2d = 50 * [for (x=[-1,0,1],y=[-1,0,1]) [x,y]];
    pts3d = 50 * [for (x=[-1,0,1],y=[-1,0,1],z=[-1,0,1]) [x,y,z]];
    vecs2d = [
        for (x=[-1,0,1], y=[-1,0,1]) if(x!=0||y!=0) [x,y],
        polar_to_xy(1, -75),
        polar_to_xy(1,  75)
    ];
    vecs3d = [
        LEFT, RIGHT, FRONT, BACK, DOWN, UP,
        spherical_to_xyz(1, -30,  45),
        spherical_to_xyz(1,   0,  45),
        spherical_to_xyz(1,  30,  45),
        spherical_to_xyz(2, -30, 135),
        spherical_to_xyz(1,  30, 135),
        spherical_to_xyz(1, -30,  75),
        spherical_to_xyz(1,  45,  45),
    ];
    angs = [-180, -90, 0, 30, 45, 90];
    for (a = [-360*3:360:360*3]) {
        assert_approx(rot(a), affine3d_identity(), info=str("rot(",a,") != identity"));
        assert_approx(rot(a,p=pts2d), pts2d, info=str("rot(",a,",p=...), 2D"));
        assert_approx(rot(a,p=pts3d), pts3d, info=str("rot(",a,",p=...), 3D"));
    }
    assert_approx(rot(90), [[0,-1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]]);
    for (a=angs) {
        assert_approx(rot(a), affine3d_zrot(a), info=str("Z angle (only) = ",a));
        assert_approx(rot([a,0,0]), affine3d_xrot(a), info=str("X angle = ",a));
        assert_approx(rot([0,a,0]), affine3d_yrot(a), info=str("Y angle = ",a));
        assert_approx(rot([0,0,a]), affine3d_zrot(a), info=str("Z angle = ",a));

        assert_approx(rot(a,p=pts2d), apply(affine3d_zrot(a),pts2d), info=str("Z angle (only) = ",a, ", p=..., 2D"));
        assert_approx(rot([0,0,a],p=pts2d), apply(affine3d_zrot(a),pts2d), info=str("Z angle = ",a, ", p=..., 2D"));

        assert_approx(rot(a,p=pts3d), apply(affine3d_zrot(a),pts3d), info=str("Z angle (only) = ",a, ", p=..., 3D"));
        assert_approx(rot([a,0,0],p=pts3d), apply(affine3d_xrot(a),pts3d), info=str("X angle = ",a, ", p=..., 3D"));
        assert_approx(rot([0,a,0],p=pts3d), apply(affine3d_yrot(a),pts3d), info=str("Y angle = ",a, ", p=..., 3D"));
        assert_approx(rot([0,0,a],p=pts3d), apply(affine3d_zrot(a),pts3d), info=str("Z angle = ",a, ", p=..., 3D"));
    }
    for (xa=angs, ya=angs, za=angs) {
        assert_approx(
            rot([xa,ya,za]),
            affine3d_zrot(za) * affine3d_yrot(ya) * affine3d_xrot(xa),
            info=str("[X,Y,Z] = ",[xa,ya,za])
        );
        assert_approx(
            rot([xa,ya,za],p=pts3d),
            apply(
                affine3d_zrot(za) * affine3d_yrot(ya) * affine3d_xrot(xa),
                pts3d
            ),
            info=str("[X,Y,Z] = ",[xa,ya,za], ", p=...")
        );
    }
    for (vec1 = vecs3d) {
        for (ang = angs) {
            assert_approx(
                rot(a=ang, v=vec1),
                affine3d_rot_by_axis(vec1,ang),
                info=str("a = ",ang,", v = ", vec1)
            );
            assert_approx(
                rot(a=ang, v=vec1, p=pts3d),
                apply(affine3d_rot_by_axis(vec1,ang), pts3d),
                info=str("a = ",ang,", v = ", vec1, ", p=...")
            );
        }
    }
    for (vec1 = vecs2d) {
        for (vec2 = vecs2d) {
            assert_approx(
                rot(from=vec1, to=vec2, p=pts2d, planar=true),
                apply(affine2d_zrot(v_theta(vec2)-v_theta(vec1)), pts2d),
                info=str(
                    "from = ", vec1, ", ",
                    "to = ", vec2, ", ",
                    "planar = ", true, ", ",
                    "p=..., 2D"
                )
            );
        }
    }
    for (vec1 = vecs3d) {
        for (vec2 = vecs3d) {
            for (a = angs) {
                assert_approx(
                    rot(from=vec1, to=vec2, a=a),
                    affine3d_rot_from_to(vec1,vec2) * affine3d_rot_by_axis(vec1,a),
                    info=str(
                        "from = ", vec1, ", ",
                        "to = ", vec2, ", ",
                        "a = ", a
                    )
                );
                assert_approx(
                    rot(from=vec1, to=vec2, a=a, p=pts3d),
                    apply(
                        affine3d_rot_from_to(vec1,vec2) * affine3d_rot_by_axis(vec1,a),
                        pts3d
                    ),
                    info=str(
                        "from = ", vec1, ", ",
                        "to = ", vec2, ", ",
                        "a = ", a, ", ",
                        "p=..., 3D"
                    )
                );
            }
        }
    }
}
test_rot();


module test_xrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = [[1,0,0,0],[0,cos(a),-sin(a),0],[0,sin(a),cos(a),0],[0,0,0,1]];
        assert_approx(xrot(a), m);
        assert_approx(xrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(xrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        xrot(a) nil();
    }
}
test_xrot();


module test_yrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = [[cos(a),0,sin(a),0],[0,1,0,0],[-sin(a),0,cos(a),0],[0,0,0,1]];
        assert_approx(yrot(a), m);
        assert_approx(yrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(yrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        yrot(a) nil();
    }
}
test_yrot();


module test_zrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = [[cos(a),-sin(a),0,0],[sin(a),cos(a),0,0],[0,0,1,0],[0,0,0,1]];
        assert_approx(zrot(a), m);
        assert_approx(zrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(zrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        zrot(a) nil();
    }
}
test_zrot();


module test_xyrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = affine3d_rot_by_axis(RIGHT+BACK,a);
        assert_approx(xyrot(a), m);
        assert_approx(xyrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(xyrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        xyrot(a) nil();
    }
}
test_xyrot();


module test_xzrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = affine3d_rot_by_axis(RIGHT+UP,a);
        assert_approx(xzrot(a), m);
        assert_approx(xzrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(xzrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        xzrot(a) nil();
    }
}
test_xzrot();


module test_yzrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = affine3d_rot_by_axis(BACK+UP,a);
        assert_approx(yzrot(a), m);
        assert_approx(yzrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(yzrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        yzrot(a) nil();
    }
}
test_yzrot();


module test_xyzrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = affine3d_rot_by_axis(RIGHT+BACK+UP,a);
        assert_approx(xyzrot(a), m);
        assert_approx(xyzrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(xyzrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        xyzrot(a) nil();
    }
}
test_xyzrot();


module test_skew() {
    m = affine3d_skew(sxy=2, sxz=3, syx=4, syz=5, szx=6, szy=7);
    assert_approx(skew(sxy=2, sxz=3, syx=4, syz=5, szx=6, szy=7), m);
    assert_approx(skew(sxy=2, sxz=3, syx=4, syz=5, szx=6, szy=7, p=[1,2,3]), apply(m,[1,2,3]));
    // Verify that module at least doesn't crash.
    skew(undef,2,3,4,5,6,7) nil();
}
test_skew();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
