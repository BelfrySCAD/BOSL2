include <../std.scad>



function _q_standard(q) = sign([for(qi=q) if( ! approx(qi,0)) qi,0 ][0])*q;


module test_is_quaternion() {
    assert_approx(is_quaternion([0]),false);
    assert_approx(is_quaternion([0,0,0,0]),false);
    assert_approx(is_quaternion([1,0,2,0]),true);
    assert_approx(is_quaternion([1,0,2,0,0]),false);
}
test_is_quaternion();


module test_quat() {
    assert_approx(quat(UP,0),[0,0,0,1]);
    assert_approx(quat(FWD,0),[0,0,0,1]);
    assert_approx(quat(LEFT,0),[0,0,0,1]);
    assert_approx(quat(UP,45),[0,0,0.3826834324,0.9238795325]);
    assert_approx(quat(LEFT,45),[-0.3826834324, 0, 0, 0.9238795325]);
    assert_approx(quat(BACK,45),[0,0.3826834323,0,0.9238795325]);
    assert_approx(quat(FWD+RIGHT,30),[0.1830127019, -0.1830127019, 0, 0.9659258263]);
}
test_quat();


module test_quat_x() {
    assert_approx(quat_x(0),[0,0,0,1]);
    assert_approx(quat_x(35),[0.3007057995,0,0,0.9537169507]);
    assert_approx(quat_x(45),[0.3826834324,0,0,0.9238795325]);
}
test_quat_x();


module test_quat_y() {
    assert_approx(quat_y(0),[0,0,0,1]);
    assert_approx(quat_y(35),[0,0.3007057995,0,0.9537169507]);
    assert_approx(quat_y(45),[0,0.3826834323,0,0.9238795325]);
}
test_quat_y();


module test_quat_z() {
    assert_approx(quat_z(0),[0,0,0,1]);
    assert_approx(quat_z(36),[0,0,0.3090169944,0.9510565163]);
    assert_approx(quat_z(45),[0,0,0.3826834324,0.9238795325]);
}
test_quat_z();


module test_quat_xyz() {
    assert_approx(quat_xyz([0,0,0]), [0,0,0,1]);
    assert_approx(quat_xyz([30,0,0]), [0.2588190451, 0, 0, 0.9659258263]);
    assert_approx(quat_xyz([90,0,0]), [0.7071067812, 0, 0, 0.7071067812]);
    assert_approx(quat_xyz([-270,0,0]), [-0.7071067812, 0, 0, -0.7071067812]);
    assert_approx(quat_xyz([180,0,0]), [1,0,0,0]);
    assert_approx(quat_xyz([270,0,0]), [0.7071067812, 0, 0, -0.7071067812]);
    assert_approx(quat_xyz([-90,0,0]), [-0.7071067812, 0, 0, 0.7071067812]);
    assert_approx(quat_xyz([360,0,0]), [0,0,0,-1]);

    assert_approx(quat_xyz([0,0,0]), [0,0,0,1]);
    assert_approx(quat_xyz([0,30,0]), [0, 0.2588190451, 0, 0.9659258263]);
    assert_approx(quat_xyz([0,90,0]), [0, 0.7071067812, 0, 0.7071067812]);
    assert_approx(quat_xyz([0,-270,0]), [0, -0.7071067812, 0, -0.7071067812]);
    assert_approx(quat_xyz([0,180,0]), [0,1,0,0]);
    assert_approx(quat_xyz([0,270,0]), [0, 0.7071067812, 0, -0.7071067812]);
    assert_approx(quat_xyz([0,-90,0]), [0, -0.7071067812, 0, 0.7071067812]);
    assert_approx(quat_xyz([0,360,0]), [0,0,0,-1]);

    assert_approx(quat_xyz([0,0,0]), [0,0,0,1]);
    assert_approx(quat_xyz([0,0,30]), [0, 0, 0.2588190451, 0.9659258263]);
    assert_approx(quat_xyz([0,0,90]), [0, 0, 0.7071067812, 0.7071067812]);
    assert_approx(quat_xyz([0,0,-270]), [0, 0, -0.7071067812, -0.7071067812]);
    assert_approx(quat_xyz([0,0,180]), [0,0,1,0]);
    assert_approx(quat_xyz([0,0,270]), [0, 0, 0.7071067812, -0.7071067812]);
    assert_approx(quat_xyz([0,0,-90]), [0, 0, -0.7071067812, 0.7071067812]);
    assert_approx(quat_xyz([0,0,360]), [0,0,0,-1]);

    assert_approx(quat_xyz([30,30,30]), [0.1767766953, 0.3061862178, 0.1767766953, 0.9185586535]);
    assert_approx(quat_xyz([12,34,56]), [-0.04824789229, 0.3036636044, 0.4195145429, 0.8540890495]);
}
test_quat_xyz();


module test_q_from_to() {
    assert_approx(q_mul(q_from_to([1,2,3], [4,5,2]),q_from_to([4,5,2], [1,2,3])), q_ident());
    assert_approx(q_matrix4(q_from_to([1,2,3], [4,5,2])), rot(from=[1,2,3],to=[4,5,2]));
    assert_approx(q_rot(q_from_to([1,2,3], -[1,2,3]),[1,2,3]), -[1,2,3]);
    assert_approx(unit(q_rot(q_from_to([1,2,3],  [4,5,2]),[1,2,3])), unit([4,5,2]));
}
test_q_from_to();


module test_q_ident() {
    assert_approx(q_ident(), [0,0,0,1]);
}
test_q_ident();


module test_q_add_s() {
    assert_approx(q_add_s([0,0,0,1],3),[0,0,0,4]);
    assert_approx(q_add_s([0,0,1,0],3),[0,0,1,3]);
    assert_approx(q_add_s([0,1,0,0],3),[0,1,0,3]);
    assert_approx(q_add_s([1,0,0,0],3),[1,0,0,3]);
    assert_approx(q_add_s(quat(LEFT+FWD,23),1),[-0.1409744184, -0.1409744184, 0, 1.979924705]);
}
test_q_add_s();


module test_q_sub_s() {
    assert_approx(q_sub_s([0,0,0,1],3),[0,0,0,-2]);
    assert_approx(q_sub_s([0,0,1,0],3),[0,0,1,-3]);
    assert_approx(q_sub_s([0,1,0,0],3),[0,1,0,-3]);
    assert_approx(q_sub_s([1,0,0,0],3),[1,0,0,-3]);
    assert_approx(q_sub_s(quat(LEFT+FWD,23),1),[-0.1409744184, -0.1409744184, 0, -0.02007529538]);
}
test_q_sub_s();


module test_q_mul_s() {
    assert_approx(q_mul_s([0,0,0,1],3),[0,0,0,3]);
    assert_approx(q_mul_s([0,0,1,0],3),[0,0,3,0]);
    assert_approx(q_mul_s([0,1,0,0],3),[0,3,0,0]);
    assert_approx(q_mul_s([1,0,0,0],3),[3,0,0,0]);
    assert_approx(q_mul_s([1,0,0,1],3),[3,0,0,3]);
    assert_approx(q_mul_s(quat(LEFT+FWD,23),4),[-0.5638976735, -0.5638976735, 0, 3.919698818]);
}
test_q_mul_s();



module test_q_div_s() {
    assert_approx(q_div_s([0,0,0,1],3),[0,0,0,1/3]);
    assert_approx(q_div_s([0,0,1,0],3),[0,0,1/3,0]);
    assert_approx(q_div_s([0,1,0,0],3),[0,1/3,0,0]);
    assert_approx(q_div_s([1,0,0,0],3),[1/3,0,0,0]);
    assert_approx(q_div_s([1,0,0,1],3),[1/3,0,0,1/3]);
    assert_approx(q_div_s(quat(LEFT+FWD,23),4),[-0.03524360459, -0.03524360459, 0, 0.2449811762]);
}
test_q_div_s();


module test_q_add() {
    assert_approx(q_add([2,3,4,5],[-1,-1,-1,-1]),[1,2,3,4]);
    assert_approx(q_add([2,3,4,5],[-3,-3,-3,-3]),[-1,0,1,2]);
    assert_approx(q_add([2,3,4,5],[0,0,0,0]),[2,3,4,5]);
    assert_approx(q_add([2,3,4,5],[1,1,1,1]),[3,4,5,6]);
    assert_approx(q_add([2,3,4,5],[1,0,0,0]),[3,3,4,5]);
    assert_approx(q_add([2,3,4,5],[0,1,0,0]),[2,4,4,5]);
    assert_approx(q_add([2,3,4,5],[0,0,1,0]),[2,3,5,5]);
    assert_approx(q_add([2,3,4,5],[0,0,0,1]),[2,3,4,6]);
    assert_approx(q_add([2,3,4,5],[2,1,2,1]),[4,4,6,6]);
    assert_approx(q_add([2,3,4,5],[1,2,1,2]),[3,5,5,7]);
}
test_q_add();


module test_q_sub() {
    assert_approx(q_sub([2,3,4,5],[-1,-1,-1,-1]),[3,4,5,6]);
    assert_approx(q_sub([2,3,4,5],[-3,-3,-3,-3]),[5,6,7,8]);
    assert_approx(q_sub([2,3,4,5],[0,0,0,0]),[2,3,4,5]);
    assert_approx(q_sub([2,3,4,5],[1,1,1,1]),[1,2,3,4]);
    assert_approx(q_sub([2,3,4,5],[1,0,0,0]),[1,3,4,5]);
    assert_approx(q_sub([2,3,4,5],[0,1,0,0]),[2,2,4,5]);
    assert_approx(q_sub([2,3,4,5],[0,0,1,0]),[2,3,3,5]);
    assert_approx(q_sub([2,3,4,5],[0,0,0,1]),[2,3,4,4]);
    assert_approx(q_sub([2,3,4,5],[2,1,2,1]),[0,2,2,4]);
    assert_approx(q_sub([2,3,4,5],[1,2,1,2]),[1,1,3,3]);
}
test_q_sub();


module test_q_mul() {
    assert_approx(q_mul(quat_z(30),quat_x(57)),[0.4608999698, 0.1234977747, 0.2274546059, 0.8488721457]);
    assert_approx(q_mul(quat_y(30),quat_z(23)),[0.05160021841, 0.2536231763, 0.1925746368, 0.94653458]);
}
test_q_mul();


module test_q_cumulative() {
    assert_approx(q_cumulative([quat_z(30),quat_x(57),quat_y(18)]),[[0, 0, 0.2588190451, 0.9659258263], [0.4608999698, -0.1234977747, 0.2274546059, 0.8488721457], [0.4908072659, 0.01081554785, 0.1525536221, 0.8577404293]]);
}
test_q_cumulative();


module test_q_dot() {
    assert_approx(q_dot(quat_z(30),quat_x(57)),0.8488721457);
    assert_approx(q_dot(quat_y(30),quat_z(23)),0.94653458);
}
test_q_dot();


module test_q_neg() {
    assert_approx(q_neg([1,0,0,1]),[-1,0,0,-1]);
    assert_approx(q_neg([0,1,1,0]),[0,-1,-1,0]);
    assert_approx(q_neg(quat_xyz([23,45,67])),[0.0533818345,-0.4143703268,-0.4360652669,-0.7970537592]);
}
test_q_neg();


module test_q_conj() {
    assert_approx(q_conj([1,0,0,1]),[-1,0,0,1]);
    assert_approx(q_conj([0,1,1,0]),[0,-1,-1,0]);
    assert_approx(q_conj(quat_xyz([23,45,67])),[0.0533818345, -0.4143703268, -0.4360652669, 0.7970537592]);
}
test_q_conj();


module test_q_inverse() {

    assert_approx(q_inverse([1,0,0,1]),[-1,0,0,1]/sqrt(2));
    assert_approx(q_inverse([0,1,1,0]),[0,-1,-1,0]/sqrt(2));
    assert_approx(q_inverse(quat_xyz([23,45,67])),q_conj(quat_xyz([23,45,67])));
    assert_approx(q_mul(q_inverse(quat_xyz([23,45,67])),quat_xyz([23,45,67])),q_ident());
}
test_q_inverse();


module test_q_Norm() {
    assert_approx(q_norm([1,0,0,1]),1.414213562);
    assert_approx(q_norm([0,1,1,0]),1.414213562);
    assert_approx(q_norm(quat_xyz([23,45,67])),1);
}
test_q_Norm();


module test_q_normalize() {
    assert_approx(q_normalize([1,0,0,1]),[0.7071067812, 0, 0, 0.7071067812]);
    assert_approx(q_normalize([0,1,1,0]),[0, 0.7071067812, 0.7071067812, 0]);
    assert_approx(q_normalize(quat_xyz([23,45,67])),[-0.0533818345, 0.4143703268, 0.4360652669, 0.7970537592]);
}
test_q_normalize();


module test_q_dist() {
    assert_approx(q_dist(quat_xyz([23,45,67]),quat_xyz([23,45,67])),0);
    assert_approx(q_dist(quat_xyz([23,45,67]),quat_xyz([12,34,56])),0.1257349854);
}
test_q_dist();


module test_q_slerp() {
    assert_approx(q_slerp(quat_x(45),quat_y(30),0.0),quat_x(45));
    assert_approx(q_slerp(quat_x(45),quat_y(30),0.5),[0.1967063121, 0.1330377423, 0, 0.9713946602]);
    assert_approx(q_slerp(quat_x(45),quat_y(30),1.0),quat_y(30));
}
test_q_slerp();


module test_q_matrix3() {
    assert_approx(q_matrix3(quat_z(37)),rot(37,planar=true));
    assert_approx(q_matrix3(quat_z(-49)),rot(-49,planar=true));
}
test_q_matrix3();


module test_q_matrix4() {
    assert_approx(q_matrix4(quat_z(37)),rot(37));
    assert_approx(q_matrix4(quat_z(-49)),rot(-49));
    assert_approx(q_matrix4(quat_x(37)),rot([37,0,0]));
    assert_approx(q_matrix4(quat_y(37)),rot([0,37,0]));
    assert_approx(q_matrix4(quat_xyz([12,34,56])),rot([12,34,56]));
}
test_q_matrix4();


module test_q_axis() {
    assert_approx(q_axis(quat_x(37)),RIGHT);
    assert_approx(q_axis(quat_x(-37)),LEFT);
    assert_approx(q_axis(quat_y(37)),BACK);
    assert_approx(q_axis(quat_y(-37)),FWD);
    assert_approx(q_axis(quat_z(37)),UP);
    assert_approx(q_axis(quat_z(-37)),DOWN);
}
test_q_axis();


module test_q_angle() {
    assert_approx(q_angle(quat_x(0)),0);
    assert_approx(q_angle(quat_y(0)),0);
    assert_approx(q_angle(quat_z(0)),0);
    assert_approx(q_angle(quat_x(37)),37);
    assert_approx(q_angle(quat_x(-37)),37);
    assert_approx(q_angle(quat_y(37)),37);
    assert_approx(q_angle(quat_y(-37)),37);
    assert_approx(q_angle(quat_z(37)),37);
    assert_approx(q_angle(quat_z(-37)),37);

    assert_approx(q_angle(quat_z(-37),quat_z(-37)), 0);
    assert_approx(q_angle(quat_z( 37.123),quat_z(-37.123)), 74.246);
    assert_approx(q_angle(quat_x( 37),quat_y(-37)), 51.86293283);
}
test_q_angle();


module test_q_rot() {
    assert_approx(q_rot(quat_xyz([12,34,56])),rot([12,34,56]));
    assert_approx(q_rot(quat_xyz([12,34,56]),p=[2,3,4]),rot([12,34,56],p=[2,3,4]));
    assert_approx(q_rot(quat_xyz([12,34,56]),p=[[2,3,4],[4,9,6]]),rot([12,34,56],p=[[2,3,4],[4,9,6]]));
}
test_q_rot();


module test_q_rotation() {
    assert_approx(_q_standard(q_rotation(q_matrix3(quat([12,34,56],33)))),_q_standard(quat([12,34,56],33)));
    assert_approx(q_matrix3(q_rotation(q_matrix3(quat_xyz([12,34,56])))),
             q_matrix3(quat_xyz([12,34,56])));
}
test_q_rotation();


module test_q_rotation_path() {
    assert_approx(q_rotation_path(quat_x(135), 5, quat_y(13.5))[0] , q_matrix4(quat_x(135)));
    assert_approx(q_rotation_path(quat_x(135), 11, quat_y(13.5))[11] , yrot(13.5));
    assert_approx(q_rotation_path(quat_x(135), 16, quat_y(13.5))[8] , q_rotation_path(quat_x(135), 8, quat_y(13.5))[4]);
    assert_approx(q_rotation_path(quat_x(135), 16, quat_y(13.5))[7] , 
             q_rotation_path(quat_y(13.5),16, quat_x(135))[9]);

    assert_approx(q_rotation_path(quat_x(11), 5)[0] , xrot(11));
    assert_approx(q_rotation_path(quat_x(11), 5)[4] , xrot(55));

}
test_q_rotation_path();


module test_q_nlerp() {
    assert_approx(q_nlerp(quat_x(45),quat_y(30),0.0),quat_x(45));
    assert_approx(q_nlerp(quat_x(45),quat_y(30),0.5),[0.1967063121, 0.1330377423, 0, 0.9713946602]);
    assert_approx(q_rotation_path(quat_x(135), 16, quat_y(13.5))[8] , q_matrix4(q_nlerp(quat_x(135), quat_y(13.5),0.5)));
    assert_approx(q_nlerp(quat_x(45),quat_y(30),1.0),quat_y(30));
}
test_q_nlerp();


module test_q_squad() {
    assert_approx(q_squad(quat_x(45),quat_z(30),quat_x(90),quat_y(30),0.0),quat_x(45));
    assert_approx(q_squad(quat_x(45),quat_z(30),quat_x(90),quat_y(30),1.0),quat_y(30));
    assert_approx(q_squad(quat_x(0),quat_x(30),quat_x(90),quat_x(120),0.5),
              q_slerp(quat_x(0),quat_x(120),0.5));
    assert_approx(q_squad(quat_y(0),quat_y(0),quat_x(120),quat_x(120),0.3),
              q_slerp(quat_y(0),quat_x(120),0.3));
}
test_q_squad();


module test_q_exp() {
   assert_approx(q_exp(q_ident()), exp(1)*q_ident()); 
   assert_approx(q_exp([0,0,0,33.7]), exp(33.7)*q_ident());
   assert_approx(q_exp(q_ln(q_ident())), q_ident());
   assert_approx(q_exp(q_ln([1,2,3,0])), [1,2,3,0]);
   assert_approx(q_exp(q_ln(quat_xyz([31,27,34]))), quat_xyz([31,27,34]));
   let(q=quat_xyz([12,23,34])) 
     assert_approx(q_exp(q+q_inverse(q)),q_mul(q_exp(q),q_exp(q_inverse(q))));

}
test_q_exp();


module test_q_ln() {
   assert_approx(q_ln([1,2,3,0]),  [24.0535117721, 48.1070235442, 72.1605353164, 1.31952866481]); 
   assert_approx(q_ln(q_ident()), [0,0,0,0]); 
   assert_approx(q_ln(5.5*q_ident()), [0,0,0,ln(5.5)]); 
   assert_approx(q_ln(q_exp(quat_xyz([13,37,43]))), quat_xyz([13,37,43]));
   assert_approx(q_ln(quat_xyz([12,23,34]))+q_ln(q_inverse(quat_xyz([12,23,34]))), [0,0,0,0]);
} 
test_q_ln();


module test_q_pow() {
    q = quat([1,2,3],77);
    assert_approx(q_pow(q,1), q);
    assert_approx(q_pow(q,0), q_ident());
    assert_approx(q_pow(q,-1), q_inverse(q));
    assert_approx(q_pow(q,2), q_mul(q,q));
    assert_approx(q_pow(q,3), q_mul(q,q_pow(q,2)));
    assert_approx(q_mul(q_pow(q,0.456),q_pow(q,0.544)), q);
    assert_approx(q_mul(q_pow(q,0.335),q_mul(q_pow(q,.552),q_pow(q,.113))), q);
}
test_q_pow();






// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
