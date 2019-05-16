include <BOSL2/std.scad>


module test_vmul() {
	assert(vmul([3,4,5], [8,7,6]) == [24,28,30]);
	assert(vmul([1,2,3], [4,5,6]) == [4,10,18]);
}
test_vmul();


module test_vdiv() {
	assert(vdiv([24,28,30], [8,7,6]) == [3, 4, 5]);
}
test_vdiv();


module test_vabs() {
	assert(vabs([2,4,8]) == [2,4,8]);
	assert(vabs([-2,-4,-8]) == [2,4,8]);
	assert(vabs([-2,4,8]) == [2,4,8]);
	assert(vabs([2,-4,8]) == [2,4,8]);
	assert(vabs([2,4,-8]) == [2,4,8]);
}
test_vabs();


module test_normalize() {
	assert(normalize([10,0,0]) == [1,0,0]);
	assert(normalize([0,10,0]) == [0,1,0]);
	assert(normalize([0,0,10]) == [0,0,1]);
	assert(abs(norm(normalize([10,10,10]))-1) < EPSILON);
	assert(abs(norm(normalize([-10,-10,-10]))-1) < EPSILON);
	assert(abs(norm(normalize([-10,0,0]))-1) < EPSILON);
	assert(abs(norm(normalize([0,-10,0]))-1) < EPSILON);
	assert(abs(norm(normalize([0,0,-10]))-1) < EPSILON);
}
test_normalize();


module test_vector_angle() {
	vecs = [[10,0,0], [-10,0,0], [0,10,0], [0,-10,0], [0,0,10], [0,0,-10]];
	for (a=vecs, b=vecs) {
		if(a==b) {
			assert(vector_angle(a,b)==0);
			assert(vector_angle([a,b])==0);
		} else if(a==-b) {
			assert(vector_angle(a,b)==180);
			assert(vector_angle([a,b])==180);
		} else {
			assert(vector_angle(a,b)==90);
			assert(vector_angle([a,b])==90);
		}
	}
	assert(abs(vector_angle([10,10,0],[10,0,0])-45) < EPSILON);
	assert(abs(vector_angle([[10,10,0],[10,0,0]])-45) < EPSILON);
	assert(abs(vector_angle([11,11,1],[1,1,1],[11,-9,1])-90) < EPSILON);
	assert(abs(vector_angle([[11,11,1],[1,1,1],[11,-9,1]])-90) < EPSILON);
}
test_vector_angle();


module test_vector_axis() {
	assert(norm(vector_axis([10,0,0],[10,10,0]) - [0,0,1]) < EPSILON);
	assert(norm(vector_axis([[10,0,0],[10,10,0]]) - [0,0,1]) < EPSILON);
	assert(norm(vector_axis([10,0,0],[0,10,0]) - [0,0,1]) < EPSILON);
	assert(norm(vector_axis([[10,0,0],[0,10,0]]) - [0,0,1]) < EPSILON);
	assert(norm(vector_axis([0,10,0],[10,0,0]) - [0,0,-1]) < EPSILON);
	assert(norm(vector_axis([[0,10,0],[10,0,0]]) - [0,0,-1]) < EPSILON);
	assert(norm(vector_axis([0,0,10],[10,0,0]) - [0,1,0]) < EPSILON);
	assert(norm(vector_axis([[0,0,10],[10,0,0]]) - [0,1,0]) < EPSILON);
	assert(norm(vector_axis([10,0,0],[0,0,10]) - [0,-1,0]) < EPSILON);
	assert(norm(vector_axis([[10,0,0],[0,0,10]]) - [0,-1,0]) < EPSILON);
	assert(norm(vector_axis([10,0,10],[0,-10,0]) - [sin(45),0,-sin(45)]) < EPSILON);
	assert(norm(vector_axis([[10,0,10],[0,-10,0]]) - [sin(45),0,-sin(45)]) < EPSILON);
	assert(norm(vector_axis([11,1,11],[1,1,1],[1,-9,1]) - [sin(45),0,-sin(45)]) < EPSILON);
	assert(norm(vector_axis([[11,1,11],[1,1,1],[1,-9,1]]) - [sin(45),0,-sin(45)]) < EPSILON);
}
test_vector_axis();


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
