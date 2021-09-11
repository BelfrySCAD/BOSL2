include <../std.scad>


module test_tri_functions() {
    sides = rands(1,100,100,seed_value=8181);
    for (p = pair(sides,true)) {
        adj = p.x;
        opp = p.y;
        hyp = norm([opp,adj]);
        ang = atan2(opp,adj);

        assert_approx(hyp_ang_to_adj(hyp,ang), adj);
        assert_approx(opp_ang_to_adj(opp,ang), adj);
        assert_approx(hyp_adj_to_opp(hyp,adj), opp);
        assert_approx(hyp_ang_to_opp(hyp,ang), opp);
        assert_approx(adj_ang_to_opp(adj,ang), opp);
        assert_approx(adj_opp_to_hyp(adj,opp), hyp);
        assert_approx(adj_ang_to_hyp(adj,ang), hyp);
        assert_approx(opp_ang_to_hyp(opp,ang), hyp);
        assert_approx(hyp_adj_to_ang(hyp,adj), ang);
        assert_approx(hyp_opp_to_ang(hyp,opp), ang);
        assert_approx(adj_opp_to_ang(adj,opp), ang);
    }
}
*test_tri_functions();


module test_hyp_opp_to_adj() nil();  // Covered in test_tri_functions()
module test_hyp_ang_to_adj() nil();  // Covered in test_tri_functions()
module test_opp_ang_to_adj() nil();  // Covered in test_tri_functions()
module test_hyp_adj_to_opp() nil();  // Covered in test_tri_functions()
module test_hyp_ang_to_opp() nil();  // Covered in test_tri_functions()
module test_adj_ang_to_opp() nil();  // Covered in test_tri_functions()
module test_adj_opp_to_hyp() nil();  // Covered in test_tri_functions()
module test_adj_ang_to_hyp() nil();  // Covered in test_tri_functions()
module test_opp_ang_to_hyp() nil();  // Covered in test_tri_functions()
module test_hyp_adj_to_ang() nil();  // Covered in test_tri_functions()
module test_hyp_opp_to_ang() nil();  // Covered in test_tri_functions()
module test_adj_opp_to_ang() nil();  // Covered in test_tri_functions()


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
