include <../std.scad>
include <../strings.scad>


function rec_cmp(a,b,eps=1e-9) =
    typeof(a)!=typeof(b)? false :
    is_num(a)? approx(a,b,eps=eps) :
    is_list(a)? len(a)==len(b) && all([for (i=idx(a)) rec_cmp(a[i],b[i],eps=eps)]) :
    a == b;

function Qstandard(q) = sign([for(qi=q) if( ! approx(qi,0)) qi,0 ][0])*q;

module verify_f(actual,expected) {
    if (!rec_cmp(actual,expected)) {
        echo(str("Expected: ",fmt_float(expected,10)));
        echo(str("        : ",expected));
        echo(str("Actual  : ",fmt_float(actual,10)));
        echo(str("        : ",actual));
        echo(str("Delta   : ",fmt_float(expected-actual,10)));
        echo(str("        : ",expected-actual));
        assert(approx(expected,actual));
    }
}


module test_Q_is_quat() {
    verify_f(Q_is_quat([0]),false);
    verify_f(Q_is_quat([0,0,0,0]),false);
    verify_f(Q_is_quat([1,0,2,0]),true);
    verify_f(Q_is_quat([1,0,2,0,0]),false);
}
test_Q_is_quat();


module test_Quat() {
    verify_f(Quat(UP,0),[0,0,0,1]);
    verify_f(Quat(FWD,0),[0,0,0,1]);
    verify_f(Quat(LEFT,0),[0,0,0,1]);
    verify_f(Quat(UP,45),[0,0,0.3826834324,0.9238795325]);
    verify_f(Quat(LEFT,45),[-0.3826834324, 0, 0, 0.9238795325]);
    verify_f(Quat(BACK,45),[0,0.3826834323,0,0.9238795325]);
    verify_f(Quat(FWD+RIGHT,30),[0.1830127019, -0.1830127019, 0, 0.9659258263]);
}
test_Quat();


module test_QuatX() {
    verify_f(QuatX(0),[0,0,0,1]);
    verify_f(QuatX(35),[0.3007057995,0,0,0.9537169507]);
    verify_f(QuatX(45),[0.3826834324,0,0,0.9238795325]);
}
test_QuatX();


module test_QuatY() {
    verify_f(QuatY(0),[0,0,0,1]);
    verify_f(QuatY(35),[0,0.3007057995,0,0.9537169507]);
    verify_f(QuatY(45),[0,0.3826834323,0,0.9238795325]);
}
test_QuatY();


module test_QuatZ() {
    verify_f(QuatZ(0),[0,0,0,1]);
    verify_f(QuatZ(36),[0,0,0.3090169944,0.9510565163]);
    verify_f(QuatZ(45),[0,0,0.3826834324,0.9238795325]);
}
test_QuatZ();


module test_QuatXYZ() {
    verify_f(QuatXYZ([0,0,0]), [0,0,0,1]);
    verify_f(QuatXYZ([30,0,0]), [0.2588190451, 0, 0, 0.9659258263]);
    verify_f(QuatXYZ([90,0,0]), [0.7071067812, 0, 0, 0.7071067812]);
    verify_f(QuatXYZ([-270,0,0]), [-0.7071067812, 0, 0, -0.7071067812]);
    verify_f(QuatXYZ([180,0,0]), [1,0,0,0]);
    verify_f(QuatXYZ([270,0,0]), [0.7071067812, 0, 0, -0.7071067812]);
    verify_f(QuatXYZ([-90,0,0]), [-0.7071067812, 0, 0, 0.7071067812]);
    verify_f(QuatXYZ([360,0,0]), [0,0,0,-1]);

    verify_f(QuatXYZ([0,0,0]), [0,0,0,1]);
    verify_f(QuatXYZ([0,30,0]), [0, 0.2588190451, 0, 0.9659258263]);
    verify_f(QuatXYZ([0,90,0]), [0, 0.7071067812, 0, 0.7071067812]);
    verify_f(QuatXYZ([0,-270,0]), [0, -0.7071067812, 0, -0.7071067812]);
    verify_f(QuatXYZ([0,180,0]), [0,1,0,0]);
    verify_f(QuatXYZ([0,270,0]), [0, 0.7071067812, 0, -0.7071067812]);
    verify_f(QuatXYZ([0,-90,0]), [0, -0.7071067812, 0, 0.7071067812]);
    verify_f(QuatXYZ([0,360,0]), [0,0,0,-1]);

    verify_f(QuatXYZ([0,0,0]), [0,0,0,1]);
    verify_f(QuatXYZ([0,0,30]), [0, 0, 0.2588190451, 0.9659258263]);
    verify_f(QuatXYZ([0,0,90]), [0, 0, 0.7071067812, 0.7071067812]);
    verify_f(QuatXYZ([0,0,-270]), [0, 0, -0.7071067812, -0.7071067812]);
    verify_f(QuatXYZ([0,0,180]), [0,0,1,0]);
    verify_f(QuatXYZ([0,0,270]), [0, 0, 0.7071067812, -0.7071067812]);
    verify_f(QuatXYZ([0,0,-90]), [0, 0, -0.7071067812, 0.7071067812]);
    verify_f(QuatXYZ([0,0,360]), [0,0,0,-1]);

    verify_f(QuatXYZ([30,30,30]), [0.1767766953, 0.3061862178, 0.1767766953, 0.9185586535]);
    verify_f(QuatXYZ([12,34,56]), [-0.04824789229, 0.3036636044, 0.4195145429, 0.8540890495]);
}
test_QuatXYZ();


module test_Q_From_to() {
    verify_f(Q_Mul(Q_From_to([1,2,3], [4,5,2]),Q_From_to([4,5,2], [1,2,3])), Q_Ident());
    verify_f(Q_Matrix4(Q_From_to([1,2,3], [4,5,2])), rot(from=[1,2,3],to=[4,5,2]));
    verify_f(Qrot(Q_From_to([1,2,3], -[1,2,3]),[1,2,3]), -[1,2,3]);
    verify_f(unit(Qrot(Q_From_to([1,2,3],  [4,5,2]),[1,2,3])), unit([4,5,2]));
}
test_Q_From_to();


module test_Q_Ident() {
    verify_f(Q_Ident(), [0,0,0,1]);
}
test_Q_Ident();


module test_Q_Add_S() {
    verify_f(Q_Add_S([0,0,0,1],3),[0,0,0,4]);
    verify_f(Q_Add_S([0,0,1,0],3),[0,0,1,3]);
    verify_f(Q_Add_S([0,1,0,0],3),[0,1,0,3]);
    verify_f(Q_Add_S([1,0,0,0],3),[1,0,0,3]);
    verify_f(Q_Add_S(Quat(LEFT+FWD,23),1),[-0.1409744184, -0.1409744184, 0, 1.979924705]);
}
test_Q_Add_S();


module test_Q_Sub_S() {
    verify_f(Q_Sub_S([0,0,0,1],3),[0,0,0,-2]);
    verify_f(Q_Sub_S([0,0,1,0],3),[0,0,1,-3]);
    verify_f(Q_Sub_S([0,1,0,0],3),[0,1,0,-3]);
    verify_f(Q_Sub_S([1,0,0,0],3),[1,0,0,-3]);
    verify_f(Q_Sub_S(Quat(LEFT+FWD,23),1),[-0.1409744184, -0.1409744184, 0, -0.02007529538]);
}
test_Q_Sub_S();


module test_Q_Mul_S() {
    verify_f(Q_Mul_S([0,0,0,1],3),[0,0,0,3]);
    verify_f(Q_Mul_S([0,0,1,0],3),[0,0,3,0]);
    verify_f(Q_Mul_S([0,1,0,0],3),[0,3,0,0]);
    verify_f(Q_Mul_S([1,0,0,0],3),[3,0,0,0]);
    verify_f(Q_Mul_S([1,0,0,1],3),[3,0,0,3]);
    verify_f(Q_Mul_S(Quat(LEFT+FWD,23),4),[-0.5638976735, -0.5638976735, 0, 3.919698818]);
}
test_Q_Mul_S();



module test_Q_Div_S() {
    verify_f(Q_Div_S([0,0,0,1],3),[0,0,0,1/3]);
    verify_f(Q_Div_S([0,0,1,0],3),[0,0,1/3,0]);
    verify_f(Q_Div_S([0,1,0,0],3),[0,1/3,0,0]);
    verify_f(Q_Div_S([1,0,0,0],3),[1/3,0,0,0]);
    verify_f(Q_Div_S([1,0,0,1],3),[1/3,0,0,1/3]);
    verify_f(Q_Div_S(Quat(LEFT+FWD,23),4),[-0.03524360459, -0.03524360459, 0, 0.2449811762]);
}
test_Q_Div_S();


module test_Q_Add() {
    verify_f(Q_Add([2,3,4,5],[-1,-1,-1,-1]),[1,2,3,4]);
    verify_f(Q_Add([2,3,4,5],[-3,-3,-3,-3]),[-1,0,1,2]);
    verify_f(Q_Add([2,3,4,5],[0,0,0,0]),[2,3,4,5]);
    verify_f(Q_Add([2,3,4,5],[1,1,1,1]),[3,4,5,6]);
    verify_f(Q_Add([2,3,4,5],[1,0,0,0]),[3,3,4,5]);
    verify_f(Q_Add([2,3,4,5],[0,1,0,0]),[2,4,4,5]);
    verify_f(Q_Add([2,3,4,5],[0,0,1,0]),[2,3,5,5]);
    verify_f(Q_Add([2,3,4,5],[0,0,0,1]),[2,3,4,6]);
    verify_f(Q_Add([2,3,4,5],[2,1,2,1]),[4,4,6,6]);
    verify_f(Q_Add([2,3,4,5],[1,2,1,2]),[3,5,5,7]);
}
test_Q_Add();


module test_Q_Sub() {
    verify_f(Q_Sub([2,3,4,5],[-1,-1,-1,-1]),[3,4,5,6]);
    verify_f(Q_Sub([2,3,4,5],[-3,-3,-3,-3]),[5,6,7,8]);
    verify_f(Q_Sub([2,3,4,5],[0,0,0,0]),[2,3,4,5]);
    verify_f(Q_Sub([2,3,4,5],[1,1,1,1]),[1,2,3,4]);
    verify_f(Q_Sub([2,3,4,5],[1,0,0,0]),[1,3,4,5]);
    verify_f(Q_Sub([2,3,4,5],[0,1,0,0]),[2,2,4,5]);
    verify_f(Q_Sub([2,3,4,5],[0,0,1,0]),[2,3,3,5]);
    verify_f(Q_Sub([2,3,4,5],[0,0,0,1]),[2,3,4,4]);
    verify_f(Q_Sub([2,3,4,5],[2,1,2,1]),[0,2,2,4]);
    verify_f(Q_Sub([2,3,4,5],[1,2,1,2]),[1,1,3,3]);
}
test_Q_Sub();


module test_Q_Mul() {
    verify_f(Q_Mul(QuatZ(30),QuatX(57)),[0.4608999698, 0.1234977747, 0.2274546059, 0.8488721457]);
    verify_f(Q_Mul(QuatY(30),QuatZ(23)),[0.05160021841, 0.2536231763, 0.1925746368, 0.94653458]);
}
test_Q_Mul();


module test_Q_Cumulative() {
    verify_f(Q_Cumulative([QuatZ(30),QuatX(57),QuatY(18)]),[[0, 0, 0.2588190451, 0.9659258263], [0.4608999698, -0.1234977747, 0.2274546059, 0.8488721457], [0.4908072659, 0.01081554785, 0.1525536221, 0.8577404293]]);
}
test_Q_Cumulative();


module test_Q_Dot() {
    verify_f(Q_Dot(QuatZ(30),QuatX(57)),0.8488721457);
    verify_f(Q_Dot(QuatY(30),QuatZ(23)),0.94653458);
}
test_Q_Dot();


module test_Q_Neg() {
    verify_f(Q_Neg([1,0,0,1]),[-1,0,0,-1]);
    verify_f(Q_Neg([0,1,1,0]),[0,-1,-1,0]);
    verify_f(Q_Neg(QuatXYZ([23,45,67])),[0.0533818345,-0.4143703268,-0.4360652669,-0.7970537592]);
}
test_Q_Neg();


module test_Q_Conj() {
    verify_f(Q_Conj([1,0,0,1]),[-1,0,0,1]);
    verify_f(Q_Conj([0,1,1,0]),[0,-1,-1,0]);
    verify_f(Q_Conj(QuatXYZ([23,45,67])),[0.0533818345, -0.4143703268, -0.4360652669, 0.7970537592]);
}
test_Q_Conj();


module test_Q_Inverse() {

    verify_f(Q_Inverse([1,0,0,1]),[-1,0,0,1]/sqrt(2));
    verify_f(Q_Inverse([0,1,1,0]),[0,-1,-1,0]/sqrt(2));
    verify_f(Q_Inverse(QuatXYZ([23,45,67])),Q_Conj(QuatXYZ([23,45,67])));
    verify_f(Q_Mul(Q_Inverse(QuatXYZ([23,45,67])),QuatXYZ([23,45,67])),Q_Ident());
}
test_Q_Inverse();


module test_Q_Norm() {
    verify_f(Q_Norm([1,0,0,1]),1.414213562);
    verify_f(Q_Norm([0,1,1,0]),1.414213562);
    verify_f(Q_Norm(QuatXYZ([23,45,67])),1);
}
test_Q_Norm();


module test_Q_Normalize() {
    verify_f(Q_Normalize([1,0,0,1]),[0.7071067812, 0, 0, 0.7071067812]);
    verify_f(Q_Normalize([0,1,1,0]),[0, 0.7071067812, 0.7071067812, 0]);
    verify_f(Q_Normalize(QuatXYZ([23,45,67])),[-0.0533818345, 0.4143703268, 0.4360652669, 0.7970537592]);
}
test_Q_Normalize();


module test_Q_Dist() {
    verify_f(Q_Dist(QuatXYZ([23,45,67]),QuatXYZ([23,45,67])),0);
    verify_f(Q_Dist(QuatXYZ([23,45,67]),QuatXYZ([12,34,56])),0.1257349854);
}
test_Q_Dist();


module test_Q_Slerp() {
    verify_f(Q_Slerp(QuatX(45),QuatY(30),0.0),QuatX(45));
    verify_f(Q_Slerp(QuatX(45),QuatY(30),0.5),[0.1967063121, 0.1330377423, 0, 0.9713946602]);
    verify_f(Q_Slerp(QuatX(45),QuatY(30),1.0),QuatY(30));
}
test_Q_Slerp();


module test_Q_Matrix3() {
    verify_f(Q_Matrix3(QuatZ(37)),rot(37,planar=true));
    verify_f(Q_Matrix3(QuatZ(-49)),rot(-49,planar=true));
}
test_Q_Matrix3();


module test_Q_Matrix4() {
    verify_f(Q_Matrix4(QuatZ(37)),rot(37));
    verify_f(Q_Matrix4(QuatZ(-49)),rot(-49));
    verify_f(Q_Matrix4(QuatX(37)),rot([37,0,0]));
    verify_f(Q_Matrix4(QuatY(37)),rot([0,37,0]));
    verify_f(Q_Matrix4(QuatXYZ([12,34,56])),rot([12,34,56]));
}
test_Q_Matrix4();


module test_Q_Axis() {
    verify_f(Q_Axis(QuatX(37)),RIGHT);
    verify_f(Q_Axis(QuatX(-37)),LEFT);
    verify_f(Q_Axis(QuatY(37)),BACK);
    verify_f(Q_Axis(QuatY(-37)),FWD);
    verify_f(Q_Axis(QuatZ(37)),UP);
    verify_f(Q_Axis(QuatZ(-37)),DOWN);
}
test_Q_Axis();


module test_Q_Angle() {
    verify_f(Q_Angle(QuatX(0)),0);
    verify_f(Q_Angle(QuatY(0)),0);
    verify_f(Q_Angle(QuatZ(0)),0);
    verify_f(Q_Angle(QuatX(37)),37);
    verify_f(Q_Angle(QuatX(-37)),37);
    verify_f(Q_Angle(QuatY(37)),37);
    verify_f(Q_Angle(QuatY(-37)),37);
    verify_f(Q_Angle(QuatZ(37)),37);
    verify_f(Q_Angle(QuatZ(-37)),37);

    verify_f(Q_Angle(QuatZ(-37),QuatZ(-37)), 0);
    verify_f(Q_Angle(QuatZ( 37.123),QuatZ(-37.123)), 74.246);
    verify_f(Q_Angle(QuatX( 37),QuatY(-37)), 51.86293283);
}
test_Q_Angle();


module test_Qrot() {
    verify_f(Qrot(QuatXYZ([12,34,56])),rot([12,34,56]));
    verify_f(Qrot(QuatXYZ([12,34,56]),p=[2,3,4]),rot([12,34,56],p=[2,3,4]));
    verify_f(Qrot(QuatXYZ([12,34,56]),p=[[2,3,4],[4,9,6]]),rot([12,34,56],p=[[2,3,4],[4,9,6]]));
}
test_Qrot();


module test_Q_Rotation() {
    verify_f(Qstandard(Q_Rotation(Q_Matrix3(Quat([12,34,56],33)))),Qstandard(Quat([12,34,56],33)));
    verify_f(Q_Matrix3(Q_Rotation(Q_Matrix3(QuatXYZ([12,34,56])))),
             Q_Matrix3(QuatXYZ([12,34,56])));
}
test_Q_Rotation();


module test_Q_Rotation_path() {
    
    verify_f(Q_Rotation_path(QuatX(135), 5, QuatY(13.5))[0] , Q_Matrix4(QuatX(135)));
    verify_f(Q_Rotation_path(QuatX(135), 11, QuatY(13.5))[11] , yrot(13.5));
    verify_f(Q_Rotation_path(QuatX(135), 16, QuatY(13.5))[8] , Q_Rotation_path(QuatX(135), 8, QuatY(13.5))[4]);
    verify_f(Q_Rotation_path(QuatX(135), 16, QuatY(13.5))[7] , 
             Q_Rotation_path(QuatY(13.5),16, QuatX(135))[9]);

    verify_f(Q_Rotation_path(QuatX(11), 5)[0] , xrot(11));
    verify_f(Q_Rotation_path(QuatX(11), 5)[4] , xrot(55));

}
test_Q_Rotation_path();


module test_Q_Nlerp() {
    verify_f(Q_Nlerp(QuatX(45),QuatY(30),0.0),QuatX(45));
    verify_f(Q_Nlerp(QuatX(45),QuatY(30),0.5),[0.1967063121, 0.1330377423, 0, 0.9713946602]);
    verify_f(Q_Rotation_path(QuatX(135), 16, QuatY(13.5))[8] , Q_Matrix4(Q_Nlerp(QuatX(135), QuatY(13.5),0.5)));
    verify_f(Q_Nlerp(QuatX(45),QuatY(30),1.0),QuatY(30));
}
test_Q_Nlerp();


module test_Q_Squad() {
    verify_f(Q_Squad(QuatX(45),QuatZ(30),QuatX(90),QuatY(30),0.0),QuatX(45));
    verify_f(Q_Squad(QuatX(45),QuatZ(30),QuatX(90),QuatY(30),1.0),QuatY(30));
    verify_f(Q_Squad(QuatX(0),QuatX(30),QuatX(90),QuatX(120),0.5),
              Q_Slerp(QuatX(0),QuatX(120),0.5));
    verify_f(Q_Squad(QuatY(0),QuatY(0),QuatX(120),QuatX(120),0.3),
              Q_Slerp(QuatY(0),QuatX(120),0.3));
}
test_Q_Squad();


module test_Q_exp() {
   verify_f(Q_exp(Q_Ident()), exp(1)*Q_Ident()); 
   verify_f(Q_exp([0,0,0,33.7]), exp(33.7)*Q_Ident());
   verify_f(Q_exp(Q_ln(Q_Ident())), Q_Ident());
   verify_f(Q_exp(Q_ln([1,2,3,0])), [1,2,3,0]);
   verify_f(Q_exp(Q_ln(QuatXYZ([31,27,34]))), QuatXYZ([31,27,34]));
   let(q=QuatXYZ([12,23,34])) 
     verify_f(Q_exp(q+Q_Inverse(q)),Q_Mul(Q_exp(q),Q_exp(Q_Inverse(q))));

}
test_Q_exp();


module test_Q_ln() {
   verify_f(Q_ln([1,2,3,0]),  [24.0535117721, 48.1070235442, 72.1605353164, 1.31952866481]); 
   verify_f(Q_ln(Q_Ident()), [0,0,0,0]); 
   verify_f(Q_ln(5.5*Q_Ident()), [0,0,0,ln(5.5)]); 
   verify_f(Q_ln(Q_exp(QuatXYZ([13,37,43]))), QuatXYZ([13,37,43]));
   verify_f(Q_ln(QuatXYZ([12,23,34]))+Q_ln(Q_Inverse(QuatXYZ([12,23,34]))), [0,0,0,0]);
} 
test_Q_ln();


module test_Q_pow() {
    q = Quat([1,2,3],77);
    verify_f(Q_pow(q,1), q);
    verify_f(Q_pow(q,0), Q_Ident());
    verify_f(Q_pow(q,-1), Q_Inverse(q));
    verify_f(Q_pow(q,2), Q_Mul(q,q));
    verify_f(Q_pow(q,3), Q_Mul(q,Q_pow(q,2)));
    verify_f(Q_Mul(Q_pow(q,0.456),Q_pow(q,0.544)), q);
    verify_f(Q_Mul(Q_pow(q,0.335),Q_Mul(Q_pow(q,.552),Q_pow(q,.113))), q);
}
test_Q_pow();






// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
