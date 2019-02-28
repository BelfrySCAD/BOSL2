//////////////////////////////////////////////////////////////////////
// Useful Constants
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


// Vectors useful for mirror(), offsetcube(), rotate(), etc.
V_LEFT  = [-1,  0,  0];
V_RIGHT = [ 1,  0,  0];
V_FWD   = [ 0, -1,  0];
V_BACK  = [ 0,  1,  0];
V_DOWN  = [ 0,  0, -1];
V_UP    = [ 0,  0,  1];
V_ZERO  = [ 0,  0,  0];


// Orientations for cyl(), etc.  Euller angles for rotating a vertical shape into the given orientations.
ORIENT_X    = [  0, 90,  0];
ORIENT_Y    = [-90,  0,  0];
ORIENT_Z    = [  0,  0,  0];
ORIENT_XNEG = [  0,-90,  0];
ORIENT_YNEG = [ 90,  0,  0];
ORIENT_ZNEG = [  0,180,  0];


// Constants for defining edges for chamfer(), etc.
EDGE_TOP_BK = [[1,0,0,0], [0,0,0,0], [0,0,0,0]];
EDGE_TOP_FR = [[0,1,0,0], [0,0,0,0], [0,0,0,0]];
EDGE_BOT_FR = [[0,0,1,0], [0,0,0,0], [0,0,0,0]];
EDGE_BOT_BK = [[0,0,0,1], [0,0,0,0], [0,0,0,0]];

EDGE_TOP_RT = [[0,0,0,0], [1,0,0,0], [0,0,0,0]];
EDGE_TOP_LF = [[0,0,0,0], [0,1,0,0], [0,0,0,0]];
EDGE_BOT_LF = [[0,0,0,0], [0,0,1,0], [0,0,0,0]];
EDGE_BOT_RT = [[0,0,0,0], [0,0,0,1], [0,0,0,0]];

EDGE_BK_RT  = [[0,0,0,0], [0,0,0,0], [1,0,0,0]];
EDGE_BK_LF  = [[0,0,0,0], [0,0,0,0], [0,1,0,0]];
EDGE_FR_LF  = [[0,0,0,0], [0,0,0,0], [0,0,1,0]];
EDGE_FR_RT  = [[0,0,0,0], [0,0,0,0], [0,0,0,1]];

EDGES_X_TOP = [[1,1,0,0], [0,0,0,0], [0,0,0,0]];
EDGES_X_BOT = [[0,0,1,1], [0,0,0,0], [0,0,0,0]];
EDGES_X_FR  = [[0,1,1,0], [0,0,0,0], [0,0,0,0]];
EDGES_X_BK  = [[1,0,0,1], [0,0,0,0], [0,0,0,0]];
EDGES_X_ALL = [[1,1,1,1], [0,0,0,0], [0,0,0,0]];

EDGES_Y_TOP = [[0,0,0,0], [1,1,0,0], [0,0,0,0]];
EDGES_Y_BOT = [[0,0,0,0], [0,0,1,1], [0,0,0,0]];
EDGES_Y_LF  = [[0,0,0,0], [0,1,1,0], [0,0,0,0]];
EDGES_Y_RT  = [[0,0,0,0], [1,0,0,1], [0,0,0,0]];
EDGES_Y_ALL = [[0,0,0,0], [1,1,1,1], [0,0,0,0]];

EDGES_Z_BK  = [[0,0,0,0], [0,0,0,0], [1,1,0,0]];
EDGES_Z_FR  = [[0,0,0,0], [0,0,0,0], [0,0,1,1]];
EDGES_Z_LF  = [[0,0,0,0], [0,0,0,0], [0,1,1,0]];
EDGES_Z_RT  = [[0,0,0,0], [0,0,0,0], [1,0,0,1]];
EDGES_Z_ALL = [[0,0,0,0], [0,0,0,0], [1,1,1,1]];

EDGES_LEFT   = [[0,0,0,0], [0,1,1,0], [0,1,1,0]];
EDGES_RIGHT  = [[0,0,0,0], [1,0,0,1], [1,0,0,1]];

EDGES_FRONT  = [[0,1,1,0], [0,0,0,0], [0,0,1,1]];
EDGES_BACK   = [[1,0,0,1], [0,0,0,0], [1,1,0,0]];

EDGES_BOTTOM = [[0,0,1,1], [0,0,1,1], [0,0,0,0]];
EDGES_TOP    = [[1,1,0,0], [1,1,0,0], [0,0,0,0]];

EDGES_NONE = [[0,0,0,0], [0,0,0,0], [0,0,0,0]];
EDGES_ALL  = [[1,1,1,1], [1,1,1,1], [1,1,1,1]];


EDGE_OFFSETS = [
	[[0, 1, 1], [ 0,-1, 1], [ 0,-1,-1], [0, 1,-1]],
	[[1, 0, 1], [-1, 0, 1], [-1, 0,-1], [1, 0,-1]],
	[[1, 1, 0], [-1, 1, 0], [-1,-1, 0], [1,-1, 0]]
];


function corner_edge_count(edges, v) =
	(v[2]<=0)? (
		(v[1]<=0)? (
			(v[0]<=0)? (
				edges[0][2] + edges[1][2] + edges[2][2]
			) : (
				edges[0][2] + edges[1][3] + edges[2][3]
			)
		) : (
			(v[0]<=0)? (
				edges[0][3] + edges[1][2] + edges[2][1]
			) : (
				edges[0][3] + edges[1][3] + edges[2][0]
			)
		)
	) : (
		(v[1]<=0)? (
			(v[0]<=0)? (
				edges[0][1] + edges[1][1] + edges[2][2]
			) : (
				edges[0][1] + edges[1][0] + edges[2][3]
			)
		) : (
			(v[0]<=0)? (
				edges[0][0] + edges[1][1] + edges[2][1]
			) : (
				edges[0][0] + edges[1][0] + edges[2][0]
			)
		)
	);


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
