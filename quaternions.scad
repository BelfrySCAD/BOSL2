///////////////////////////////////////////
// Quaternions
///////////////////////////////////////////

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


use <math.scad>


// Quaternions are stored internally as a 4-value vector:
//  [X, Y, Z, W]  =  W + Xi + Yj + Zk
function _Quat(a,s,w) = [a[0]*s, a[1]*s, a[2]*s, w];
function Quat(ax=[0,0,1], ang=0) = _Quat(ax/norm(ax), sin(ang/2), cos(ang/2));

function QuatX(a=0) = Quat([1,0,0],a);
function QuatY(a=0) = Quat([0,1,0],a);
function QuatZ(a=0) = Quat([0,0,1],a);

// Creates a quaternion from standard [X,Y,Z] euller rotation angles in degrees.
function QuatEuller(a=[0,0,0]) =
	let(
		qx = QuatX(a[0]),
		qy = QuatY(a[1]),
		qz = QuatZ(a[2])
	)
	Q_Mul(qz, Q_Mul(qy, qx));

function Q_Ident() = [0, 0, 0, 1];

function Q_Add_S(q, s) = [q[0], q[1], q[2], q[3]+s];
function Q_Sub_S(q, s) = [q[0], q[1], q[2], q[3]-s];
function Q_Mul_S(q, s) = [q[0]*s, q[1]*s, q[2]*s, q[3]*s];
function Q_Div_S(q, s) = [q[0]/s, q[1]/s, q[2]/s, q[3]/s];

function Q_Add(a, b) = [a[0]+b[0], a[1]+b[1], a[2]+b[2], a[3]+b[3]];
function Q_Sub(a, b) = [a[0]-b[0], a[1]-b[1], a[2]-b[2], a[3]-b[3]];
function Q_Mul(a, b) = [
	a[3]*b[0] + a[0]*b[3] + a[1]*b[2] - a[2]*b[1],
	a[3]*b[1] - a[0]*b[2] + a[1]*b[3] + a[2]*b[0],
	a[3]*b[2] + a[0]*b[1] - a[1]*b[0] + a[2]*b[3],
	a[3]*b[3] - a[0]*b[0] - a[1]*b[1] - a[2]*b[2],
];
function Q_Dot(a, b) = a[0]*b[0] + a[1]*b[1] + a[2]*b[2] + a[3]*b[3];

function Q_Neg(q) = [-q[0], -q[1], -q[2], -q[3]];
function Q_Conj(q) = [-q[0], -q[1], -q[2], q[3]];
function Q_Norm(q) = sqrt(q[0]*q[0] + q[1]*q[1] + q[2]*q[2] + q[3]*q[3]);
function Q_Normalize(q) = q/Q_Norm(q);
function Q_Dist(q1, q2) = Q_Norm(Q_Sub(q1-q2));


// Returns a spherical interpolation between two quaternions.
function Q_Slerp(q1, q2, t) = let(
		dot = Q_Dot(q1, q2),
		qq2 = dot<0? Q_Neg(q2) : q2,
		dott = dot<0? -dot : dot,
		theta = t * acos(constrain(dott,-1,1))
	) (dott>0.9995)?
		Q_Normalize(Q_Add(q1, Q_Mul_S(Q_Sub(qq2,q1), t))) :
		Q_Add(Q_Mul_S(q1,cos(theta)), Q_Mul_S(Q_Normalize(Q_Sub(qq2, Q_Mul_S(q1, dott))), sin(theta)));


// Returns the 3x3 rotation matrix for the given normalized quaternion q.
function Q_Matrix3(q) = [
	[1-2*q[1]*q[1]-2*q[2]*q[2],   2*q[0]*q[1]-2*q[2]*q[3],   2*q[0]*q[2]+2*q[1]*q[3]],
	[  2*q[0]*q[1]+2*q[2]*q[3], 1-2*q[0]*q[0]-2*q[2]*q[2],   2*q[1]*q[2]-2*q[0]*q[3]],
	[  2*q[0]*q[2]-2*q[1]*q[3],   2*q[1]*q[2]+2*q[0]*q[3], 1-2*q[0]*q[0]-2*q[1]*q[1]]
];


// Returns the 4x4 rotation matrix for the given normalized quaternion q.
function Q_Matrix4(q) = [
	[1-2*q[1]*q[1]-2*q[2]*q[2],   2*q[0]*q[1]-2*q[2]*q[3],   2*q[0]*q[2]+2*q[1]*q[3], 0],
	[  2*q[0]*q[1]+2*q[2]*q[3], 1-2*q[0]*q[0]-2*q[2]*q[2],   2*q[1]*q[2]-2*q[0]*q[3], 0],
	[  2*q[0]*q[2]-2*q[1]*q[3],   2*q[1]*q[2]+2*q[0]*q[3], 1-2*q[0]*q[0]-2*q[1]*q[1], 0],
	[                        0,                         0,                         0, 1]
];


// Returns the quaternion's axis of rotation as a vector.
function Q_Axis(q) = let(d = sqrt(1-(q[3]*q[3]))) (d==0)? [0,0,1] : [q[0]/d, q[1]/d, q[2]/d];


// Returns the quaternion's angle of rotation in degrees.
function Q_Angle(q) = 2 * acos(q[3]);


// Returns the vector `v` after rotating it by the quaternion `q`.
function Q_Rot_Vector(v,q) = Q_Mul(Q_Mul(q,concat(v,0)),Q_Conj(q));


// Rotates all children by the given quaternion q.
module Qrot(q) {
	multmatrix(Q_Matrix4(q)) {
		children();
	}
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
