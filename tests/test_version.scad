include <../std.scad>


module test_bosl_version() {
    assert(is_vector(bosl_version()));  // Returned value is a vector.
    assert(len(bosl_version())==3);  //  of three numbers.
    assert(bosl_version()[0]==2);  // The major version is 2.
    for (v=bosl_version()) {
        assert(floor(v)==v);  // All version parts are integers.
    }
}
test_bosl_version();


module test_bosl_version_num() {
    assert(is_num(bosl_version_num()));
    v = bosl_version();
    assert(bosl_version_num() == v[0]+v[1]/100+v[2]/1000000);
}
test_bosl_version_num();


module test_bosl_version_str() {
    assert(is_string(bosl_version_str()));
    v = bosl_version();
    assert(bosl_version_str() == str(v[0],".",v[1],".",v[2]));
}
test_bosl_version_str();


module test_bosl_required() {
    bosl_required(2.000001);
    bosl_required("2.0.1");
    bosl_required([2,0,1]);
}
test_bosl_required();


module test_version_to_list() {
    assert(is_list(version_to_list(2.010001)));
    assert(is_list(version_to_list("2.1.1")));
    assert(is_list(version_to_list([2,1,1])));
    assert(version_to_list(2.010001)==[2,1,1]);
    assert(version_to_list("2.1.1")==[2,1,1]);
    assert(version_to_list([2,1,1])==[2,1,1]);
    assert(version_to_list(2.010035)==[2,1,35]);
    assert(version_to_list(2.345678)==[2,34,5678]);
    assert(version_to_list("2.34.5678")==[2,34,5678]);
    assert(version_to_list([2,34,5678])==[2,34,5678]);
    assert(version_to_list([2,34,56,78])==[2,34,56]);
}
test_version_to_list();


module test_version_to_str() {
    assert(is_string(version_to_str(2.010001)));
    assert(is_string(version_to_str("2.1.1")));
    assert(is_string(version_to_str([2,1,1])));
    assert(version_to_str(2.010001)=="2.1.1");
    assert(version_to_str("2.1.1")=="2.1.1");
    assert(version_to_str([2,1,1])=="2.1.1");
    assert(version_to_str(2.345678)=="2.34.5678");
    assert(version_to_str("2.34.5678")=="2.34.5678");
    assert(version_to_str([2,34,5678])=="2.34.5678");
    assert(version_to_str([2,34,56,78])=="2.34.56");
}
test_version_to_str();


module test_version_to_num() {
    assert(is_num(version_to_num(2.010001)));
    assert(is_num(version_to_num("2.1.1")));
    assert(is_num(version_to_num([2,1,1])));
    assert(version_to_num(2.010001)==2.010001);
    assert(version_to_num("2.1.1")==2.010001);
    assert(version_to_num([2,1,1])==2.010001);
    assert(version_to_num(2.345678)==2.345678);
    assert(version_to_num("2.34.5678")==2.345678);
    assert(version_to_num([2,34,5678])==2.345678);
    assert(version_to_num([2,34,56,78])==2.340056);
}
test_version_to_num();


module test_version_cmp() {
    function diversify(x) = [
        version_to_num(x),
        version_to_str(x),
        version_to_list(x)
    ];

    module testvercmp(x,y,z) {
        for (a = diversify(y)) {
            for (b = diversify(x)) {
                assert(version_cmp(a,b)>0);
            }
            for (b = diversify(y)) {
                assert(version_cmp(a,b)==0);
            }
            for (b = diversify(z)) {
                assert(version_cmp(a,b)<0);
            }
        }
    }

    testvercmp([2,1,33],[2,1,34],[2,1,35]);
    testvercmp([2,2,1],[2,2,34],[2,2,67]);
    testvercmp([2,2,34],[2,3,34],[2,4,34]);
    testvercmp([2,3,34],[3,3,34],[4,3,34]);
    testvercmp([2,3,34],[3,1,1],[4,1,1]);
    testvercmp([2,1,1],[3,3,34],[4,1,1]);
    testvercmp([2,1,1],[3,1,1],[4,3,34]);
}
test_version_cmp();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
