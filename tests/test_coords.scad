include <../std.scad>


module test_point2d() {
    assert(point2d([1,2,3])==[1,2]);
    assert(point2d([2,3])==[2,3]);
    assert(point2d([1])==[1,0]);
}
test_point2d();


module test_path2d() {
    assert(path2d([[1,2], [3,4], [5,6], [7,8]])==[[1,2],[3,4],[5,6],[7,8]]);
    assert(path2d([[1,2,3], [2,3,4], [3,4,5], [4,5,6]])==[[1,2],[2,3],[3,4],[4,5]]);
    assert(path2d([[1,2,3,4], [2,3,4,5], [3,4,5,6], [4,5,6,7]])==[[1,2],[2,3],[3,4],[4,5]]);
}
test_path2d();


module test_point3d() {
    assert(point3d([1,2,3,4,5])==[1,2,3]);
    assert(point3d([1,2,3,4])==[1,2,3]);
    assert(point3d([1,2,3])==[1,2,3]);
    assert(point3d([2,3])==[2,3,0]);
    assert(point3d([1])==[1,0,0]);
}
test_point3d();


module test_path3d() {
    assert(path3d([[1,2], [3,4], [5,6], [7,8]])==[[1,2,0],[3,4,0],[5,6,0],[7,8,0]]);
    assert(path3d([[1,2], [3,4], [5,6], [7,8]],9)==[[1,2,9],[3,4,9],[5,6,9],[7,8,9]]);
    assert(path3d([[1,2,3], [2,3,4], [3,4,5], [4,5,6]])==[[1,2,3],[2,3,4],[3,4,5],[4,5,6]]);
    assert(path3d([[1,2,3,4], [2,3,4,5], [3,4,5,6], [4,5,6,7]])==[[1,2,3],[2,3,4],[3,4,5],[4,5,6]]);
}
test_path3d();


module test_point4d() {
    assert(point4d([1,2,3,4,5])==[1,2,3,4]);
    assert(point4d([1,2,3,4])==[1,2,3,4]);
    assert(point4d([1,2,3])==[1,2,3,0]);
    assert(point4d([2,3])==[2,3,0,0]);
    assert(point4d([1])==[1,0,0,0]);
    assert(point4d([1,2,3],9)==[1,2,3,9]);
    assert(point4d([2,3],9)==[2,3,9,9]);
    assert(point4d([1],9)==[1,9,9,9]);
}
test_point4d();


module test_path4d() {
    assert(path4d([[1,2], [3,4], [5,6], [7,8]])==[[1,2,0,0],[3,4,0,0],[5,6,0,0],[7,8,0,0]]);
    assert(path4d([[1,2,3], [2,3,4], [3,4,5], [4,5,6]])==[[1,2,3,0],[2,3,4,0],[3,4,5,0],[4,5,6,0]]);
    assert(path4d([[1,2,3,4], [2,3,4,5], [3,4,5,6], [4,5,6,7]])==[[1,2,3,4],[2,3,4,5],[3,4,5,6],[4,5,6,7]]);
    assert(path4d([[1,2,3,4,5], [2,3,4,5,6], [3,4,5,6,7], [4,5,6,7,8]])==[[1,2,3,4],[2,3,4,5],[3,4,5,6],[4,5,6,7]]);
}
test_path4d();


module test_polar_to_xy() {
    assert(approx(polar_to_xy(20,45), [20/sqrt(2), 20/sqrt(2)]));
    assert(approx(polar_to_xy(20,135), [-20/sqrt(2), 20/sqrt(2)]));
    assert(approx(polar_to_xy(20,-135), [-20/sqrt(2), -20/sqrt(2)]));
    assert(approx(polar_to_xy(20,-45), [20/sqrt(2), -20/sqrt(2)]));
    assert(approx(polar_to_xy(40,30), [40*sqrt(3)/2, 40/2]));
    assert(approx(polar_to_xy([40,30]), [40*sqrt(3)/2, 40/2]));
}
test_polar_to_xy();


module test_xy_to_polar() {
    assert(approx(xy_to_polar([20/sqrt(2), 20/sqrt(2)]),[20,45]));
    assert(approx(xy_to_polar([-20/sqrt(2), 20/sqrt(2)]),[20,135]));
    assert(approx(xy_to_polar([-20/sqrt(2), -20/sqrt(2)]),[20,-135]));
    assert(approx(xy_to_polar([20/sqrt(2), -20/sqrt(2)]),[20,-45]));
    assert(approx(xy_to_polar([40*sqrt(3)/2, 40/2]),[40,30]));
    assert(approx(xy_to_polar([-40*sqrt(3)/2, 40/2]),[40,150]));
    assert(approx(xy_to_polar([-40*sqrt(3)/2, -40/2]),[40,-150]));
    assert(approx(xy_to_polar([40*sqrt(3)/2, -40/2]),[40,-30]));
}
test_xy_to_polar();


module test_project_plane() {
    assert(approx(project_plane([[-10,0,-10], [0,0,0], [0,-10,-10]],[-5,0,-5]),[0,10*sqrt(2)/2]));
    assert(approx(project_plane([[-10,0,-10], [0,0,0], [0,-10,-10]],[0,-5,-5]),[6.12372, 10.6066],eps=1e-5));
    assert_approx(project_plane([[3,4,5],[1,3,9],[4,7,13]], [[3,4,5],[1,3,9],[5,3,2]]),[[0,0],[0,4.58257569496],[-0.911684611677,-3.27326835354]]);
    assert_approx(project_plane([[3,4,5],[1,3,9],[4,7,13]], [[3,4,5],[1,3,9],[4,7,13]]),[[0,0],[0,4.58257569496],[6.26783170528,5.89188303637]]);

    assert_approx(project_plane([2,3,4,2], [4,2,3]),[2.33181857677,-0.502272134844]);
    assert_approx(project_plane([2,3,4,2], [[1,1,1],[0,0,0]]),[[0.430748825729,0.146123238594],[0,0]]);
    assert_approx(project_plane([2,3,4,2]),[[0.920855800833,-0.11871629875,-0.371390676354,0],[-0.11871629875,0.821925551875,-0.557086014531,-2.77555756156e-17],[0.371390676354,0.557086014531,0.742781352708,-0.371390676354],[0,0,0,1]]);
    assert_approx(project_plane([[1,1,1],[3,1,3],[1,1,4]]),[[-1/sqrt(2),1/sqrt(2),0,0],[0,0,1,-1],[1/sqrt(2),1/sqrt(2),0,-sqrt(2)],[0,0,0,1]]);

    normal = rands(-1,1,3,seed=3)+[2,0,0];
    offset = rands(-1,1,1,seed=4)[0];
    assert_approx(project_plane([0,0,1,offset]),move([0,0,-offset]) );
    assert_approx(project_plane([0,1,0,offset]),xrot(90)*move([0,-offset,0]) );
}
test_project_plane();


module test_lift_plane() {
    assert(approx(lift_plane([[-10,0,-10], [0,0,0], [0,-10,-10]],[0,10*sqrt(2)/2]),[-5,0,-5]));
    assert(approx(lift_plane([[-10,0,-10], [0,0,0], [0,-10,-10]],[6.12372, 10.6066]),[0,-5,-5],eps=1e-5));

    assert_approx(lift_plane([[3,4,5],[1,3,9],[4,7,13]], [[0,0],[0,4.58257569496],[6.26783170528,5.89188303637]]),[[3,4,5],[1,3,9],[4,7,13]]);

    assert_approx(project_plane([2,3,4,2]),[[0.920855800833,-0.11871629875,-0.371390676354,0],[-0.11871629875,0.821925551875,-0.557086014531,-2.77555756156e-17],[0.371390676354,0.557086014531,0.742781352708,-0.371390676354],[0,0,0,1]]);
    assert_approx(project_plane([[1,1,1],[3,1,3],[1,1,4]]),[[-1/sqrt(2),1/sqrt(2),0,0],[0,0,1,-1],[1/sqrt(2),1/sqrt(2),0,-sqrt(2)],[0,0,0,1]]);

    N=30;
    data2 = list_to_matrix(rands(0,10,3*N,seed=77),3);
    data3 = [for (d=data2) [d.x,d.y,d.x*3+d.y*5+2]];
    planept = select(data3,0,N-4);
    testpt = select(data3, N-3,-1);
    newdata = project_plane(planept,testpt);
    assert_approx( lift_plane(planept, newdata), testpt);
    assert_approx( lift_plane(planept, project_plane(planept, last(testpt))), last(testpt));
    assert_approx( lift_plane(planept) * project_plane(planept) , ident(4));
    assert_approx( lift_plane([1,2,3,4]) * project_plane([1,2,3,4]) , ident(4));
    assert_approx( lift_plane([[1,1,1],[3,1,3],[1,1,4]]) * project_plane([[1,1,1],[3,1,3],[1,1,4]]) , ident(4));        
    
}
test_lift_plane();


module test_cylindrical_to_xyz() {
    assert(approx(cylindrical_to_xyz(100,90,10),[0,100,10]));
    assert(approx(cylindrical_to_xyz(100,270,-10),[0,-100,-10]));
    assert(approx(cylindrical_to_xyz(100,-90,-10),[0,-100,-10]));
    assert(approx(cylindrical_to_xyz(100,180,0),[-100,0,0]));
    assert(approx(cylindrical_to_xyz(100,0,0),[100,0,0]));
    assert(approx(cylindrical_to_xyz(100,45,10),[100*sqrt(2)/2,100*sqrt(2)/2,10]));
    assert(approx(cylindrical_to_xyz([100,90,10]),[0,100,10]));
    assert(approx(cylindrical_to_xyz([100,270,-10]),[0,-100,-10]));
    assert(approx(cylindrical_to_xyz([100,-90,-10]),[0,-100,-10]));
    assert(approx(cylindrical_to_xyz([100,180,0]),[-100,0,0]));
    assert(approx(cylindrical_to_xyz([100,0,0]),[100,0,0]));
    assert(approx(cylindrical_to_xyz([100,45,10]),[100*sqrt(2)/2,100*sqrt(2)/2,10]));
}
test_cylindrical_to_xyz();


module test_xyz_to_cylindrical() {
    assert(approx(xyz_to_cylindrical(0,100,10),[100,90,10]));
    assert(approx(xyz_to_cylindrical(0,-100,-10),[100,-90,-10]));
    assert(approx(xyz_to_cylindrical(-100,0,0),[100,180,0]));
    assert(approx(xyz_to_cylindrical(100,0,0),[100,0,0]));
    assert(approx(xyz_to_cylindrical(100*sqrt(2)/2,100*sqrt(2)/2,10),[100,45,10]));
    assert(approx(xyz_to_cylindrical([0,100,10]),[100,90,10]));
    assert(approx(xyz_to_cylindrical([0,-100,-10]),[100,-90,-10]));
    assert(approx(xyz_to_cylindrical([-100,0,0]),[100,180,0]));
    assert(approx(xyz_to_cylindrical([100,0,0]),[100,0,0]));
    assert(approx(xyz_to_cylindrical([100*sqrt(2)/2,100*sqrt(2)/2,10]),[100,45,10]));
}
test_xyz_to_cylindrical();


module test_spherical_to_xyz() {
    assert(approx(spherical_to_xyz(100,90,45),100*[0,sqrt(2)/2,sqrt(2)/2]));
    assert(approx(spherical_to_xyz(100,270,45),100*[0,-sqrt(2)/2,sqrt(2)/2]));
    assert(approx(spherical_to_xyz(100,-90,45),100*[0,-sqrt(2)/2,sqrt(2)/2]));
    assert(approx(spherical_to_xyz(100,90,90),100*[0,1,0]));
    assert(approx(spherical_to_xyz(100,-90,90),100*[0,-1,0]));
    assert(approx(spherical_to_xyz(100,180,90),100*[-1,0,0]));
    assert(approx(spherical_to_xyz(100,0,90),100*[1,0,0]));
    assert(approx(spherical_to_xyz(100,0,0),100*[0,0,1]));
    assert(approx(spherical_to_xyz(100,0,180),100*[0,0,-1]));
    assert(approx(spherical_to_xyz([100,90,45]),100*[0,sqrt(2)/2,sqrt(2)/2]));
    assert(approx(spherical_to_xyz([100,270,45]),100*[0,-sqrt(2)/2,sqrt(2)/2]));
    assert(approx(spherical_to_xyz([100,-90,45]),100*[0,-sqrt(2)/2,sqrt(2)/2]));
    assert(approx(spherical_to_xyz([100,90,90]),100*[0,1,0]));
    assert(approx(spherical_to_xyz([100,-90,90]),100*[0,-1,0]));
    assert(approx(spherical_to_xyz([100,180,90]),100*[-1,0,0]));
    assert(approx(spherical_to_xyz([100,0,90]),100*[1,0,0]));
    assert(approx(spherical_to_xyz([100,0,0]),100*[0,0,1]));
    assert(approx(spherical_to_xyz([100,0,180]),100*[0,0,-1]));
}
test_spherical_to_xyz();


module test_xyz_to_spherical() {
    assert(approx(xyz_to_spherical(0, 100*sqrt(2)/2,100*sqrt(2)/2),[100, 90,45]));
    assert(approx(xyz_to_spherical(0,-100*sqrt(2)/2,100*sqrt(2)/2),[100,-90,45]));
    assert(approx(xyz_to_spherical(   0, 100,   0),[100, 90, 90]));
    assert(approx(xyz_to_spherical(   0,-100,   0),[100,-90, 90]));
    assert(approx(xyz_to_spherical(-100,   0,   0),[100,180, 90]));
    assert(approx(xyz_to_spherical( 100,   0,   0),[100,  0, 90]));
    assert(approx(xyz_to_spherical(   0,   0, 100),[100,  0,  0]));
    assert(approx(xyz_to_spherical(   0,   0,-100),[100,  0,180]));
    assert(approx(xyz_to_spherical([0, 100*sqrt(2)/2,100*sqrt(2)/2]),[100, 90,45]));
    assert(approx(xyz_to_spherical([0,-100*sqrt(2)/2,100*sqrt(2)/2]),[100,-90,45]));
    assert(approx(xyz_to_spherical([   0, 100,   0]),[100, 90, 90]));
    assert(approx(xyz_to_spherical([   0,-100,   0]),[100,-90, 90]));
    assert(approx(xyz_to_spherical([-100,   0,   0]),[100,180, 90]));
    assert(approx(xyz_to_spherical([ 100,   0,   0]),[100,  0, 90]));
    assert(approx(xyz_to_spherical([   0,   0, 100]),[100,  0,  0]));
    assert(approx(xyz_to_spherical([   0,   0,-100]),[100,  0,180]));
}
test_xyz_to_spherical();


module test_altaz_to_xyz() {
    assert(approx(altaz_to_xyz(  0,  0,100),[   0,100,   0]));
    assert(approx(altaz_to_xyz( 90,  0,100),[   0,  0, 100]));
    assert(approx(altaz_to_xyz(-90,  0,100),[   0,  0,-100]));
    assert(approx(altaz_to_xyz(  0, 90,100),[ 100,  0,   0]));
    assert(approx(altaz_to_xyz(  0,-90,100),[-100,  0,   0]));
    assert(approx(altaz_to_xyz( 45, 90,100),[100*sqrt(2)/2,0,100*sqrt(2)/2]));
    assert(approx(altaz_to_xyz(-45, 90,100),[100*sqrt(2)/2,0,-100*sqrt(2)/2]));
    assert(approx(altaz_to_xyz([  0,  0,100]),[   0,100,   0]));
    assert(approx(altaz_to_xyz([ 90,  0,100]),[   0,  0, 100]));
    assert(approx(altaz_to_xyz([-90,  0,100]),[   0,  0,-100]));
    assert(approx(altaz_to_xyz([  0, 90,100]),[ 100,  0,   0]));
    assert(approx(altaz_to_xyz([  0,-90,100]),[-100,  0,   0]));
    assert(approx(altaz_to_xyz([ 45, 90,100]),[100*sqrt(2)/2,0,100*sqrt(2)/2]));
    assert(approx(altaz_to_xyz([-45, 90,100]),[100*sqrt(2)/2,0,-100*sqrt(2)/2]));
}
test_altaz_to_xyz();


module test_xyz_to_altaz() {
    assert(approx(xyz_to_altaz(   0,100,   0),[  0,  0,100]));
    assert(approx(xyz_to_altaz(   0,  0, 100),[ 90,  0,100]));
    assert(approx(xyz_to_altaz(   0,  0,-100),[-90,  0,100]));
    assert(approx(xyz_to_altaz( 100,  0,   0),[  0, 90,100]));
    assert(approx(xyz_to_altaz(-100,  0,   0),[  0,-90,100]));
    assert(approx(xyz_to_altaz(100*sqrt(2)/2,0,100*sqrt(2)/2),[ 45, 90,100]));
    assert(approx(xyz_to_altaz(100*sqrt(2)/2,0,-100*sqrt(2)/2),[-45, 90,100]));
    assert(approx(xyz_to_altaz([   0,100,   0]),[  0,  0,100]));
    assert(approx(xyz_to_altaz([   0,  0, 100]),[ 90,  0,100]));
    assert(approx(xyz_to_altaz([   0,  0,-100]),[-90,  0,100]));
    assert(approx(xyz_to_altaz([ 100,  0,   0]),[  0, 90,100]));
    assert(approx(xyz_to_altaz([-100,  0,   0]),[  0,-90,100]));
    assert(approx(xyz_to_altaz([100*sqrt(2)/2,0,100*sqrt(2)/2]),[ 45, 90,100]));
    assert(approx(xyz_to_altaz([100*sqrt(2)/2,0,-100*sqrt(2)/2]),[-45, 90,100]));
}
test_xyz_to_altaz();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
