//////////////////////////////////////////////////////////////////////
// LibFile: compat.scad
//   Backwards Compatability library
//   To use, include this line at the top of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


/*
BSD 2-Clause License

Copyright (c) 2017-2019, Revar Desmera
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


// Section: Functions


// Function: default()
// Description:
//   Returns the value given as `v` if it is not `undef`.
//   Otherwise, returns the value of `dflt`.
// Arguments:
//   v = Value to pass through if not `undef`.
//   dflt = Value to return if `v` *is* `undef`.
function default(v,dflt=undef) = is_undef(v)? dflt : v;


// Function: is_vector()
// Usage:
//   is_vector(v)
// Description:
//   Returns true if the given value is a list, and at least the first item is a number.
function is_vector(v) = is_list(v) && is_num(v[0]);


// Function: get_radius()
// Description:
//   Given various radii and diameters, returns the most specific radius.
//   If a diameter is most specific, returns half its value, giving the radius.
//   If no radii or diameters are defined, returns the value of dflt.
//   Value specificity order is r1, d1, r, d, then dflt
// Arguments:
//   r1 = Most specific radius.
//   d1 = Most specific Diameter.
//   r = Most general radius.
//   d = Most general diameter.
//   dflt = Value to return if all other values given are `undef`.
function get_radius(r1=undef, r=undef, d1=undef, d=undef, dflt=undef) = (
	!is_undef(r1)? r1 :
	!is_undef(d1)? d1/2 :
	!is_undef(r)? r :
	!is_undef(d)? d/2 :
	dflt
);



// Function: remove_undefs()
// Description: Removes all `undef`s from a list.
function remove_undefs(v) = [for (x = v) if (!is_undef(x)) x];


// Function: first_defined()
// Description:
//   Returns the first item in the list that is not `undef`.
//   If all items are `undef`, or list is empty, returns `undef`.
function first_defined(v) = remove_undefs(v)[0];


// Function: any_defined()
// Description:
//   Returns true if any item in the given array is not `undef`.
function any_defined(v) = len(remove_undefs(v))>0;


// Function: scalar_vec3()
// Usage:
//   scalar_vec3(v, [dflt]);
// Description:
//   If `v` is a scalar, and `dflt==undef`, returns `[v, v, v]`.
//   If `v` is a scalar, and `dflt!=undef`, returns `[v, dflt, dflt]`.
//   If `v` is a vector, returns the first 3 items, with any missing values replaced by `dflt`.
//   If `v` is `undef`, returns `undef`.
// Arguments:
//   v = Value to return vector from.
//   dflt = Default value to set empty vector parts from.
function scalar_vec3(v, dflt=undef) =
	is_undef(v)? undef :
	is_list(v)? [for (i=[0:2]) default(v[i], default(dflt, 0))] :
	!is_undef(dflt)? [v,dflt,dflt] : [v,v,v];




// Section: Modules


// Module: assert_in_list()
// Usage:
//   assert_in_list(argname, val, l, [idx]);
// Description:
//   Emulates the newer OpenSCAD `assert()` with an `in_list()` test.
//   You can also use this as a function call from a function.
// Arguments:
//   argname = The name of the argument value being tested.
//   val = The value to test if it exists in the list.
//   l = The list to look for `val` in.
//   idx = If given, and `l` is a list of lists, look for `val` in the given index of each sublist.
module assert_in_list(argname, val, l, idx=undef) {
	succ = search([val], l, num_returns_per_match=1, index_col_num=idx) != [[]];
	if (!succ) {
		msg = str(
			"In argument '", argname, "', ",
			(is_string(val)? str("\"", val, "\"") : val),
			" must be one of ",
			(!is_undef(idx)? [for (v=l) v[idx]] : l)
		);
		assertion(succ, msg);
	}
}

function assert_in_list(argname, val, l, idx=undef) =
	let(succ = search([val], l, num_returns_per_match=1, index_col_num=idx) != [[]])
	succ? 0 : let(
		msg = str(
			"In argument '", argname, "', ",
			(is_string(val)? str("\"", val, "\"") : val),
			" must be one of ",
			(!is_undef(idx)? [for (v=l) v[idx]] : l)
		)
	) assertion(succ, msg);


// Module: assertion()
// Usage:
//   assertion(succ, msg);
// Description:
//   Backwards compatible assert() semi-replacement.
//   If `succ` is false, then print an error with `msg`.
//   You can also use this as a function call from a function.
// Arguments:
//   succ = If this is `false`, trigger the assertion.
//   msg = The message to emit if `succ` is `false`.
module assertion(succ, msg) {
	// assert() will echo the variable name, and `succ` looks confusing there.  So we store it in FAILED.
	FAILED = succ;
	assert(FAILED, msg);
}

function assertion(succ, msg) =
	let(FAILED=succ) assert(FAILED, msg);


// Module: echo_error()
// Usage:
//   echo_error(msg, [pfx]);
// Description:
//   Emulates printing of an error message.  The text will be shaded red.
//   You can also use this as a function call from a function.
// Arguments:
//   msg = The message to print.
//   pfx = The prefix to print before `msg`.  Default: `ERROR`
module echo_error(msg, pfx="ERROR") {
	echo(str("<p style=\"background-color: #ffb0b0\"><b>", pfx, ":</b> ", msg, "</p>"));
}

function echo_error(msg, pfx="ERROR") =
	echo(str("<p style=\"background-color: #ffb0b0\"><b>", pfx, ":</b> ", msg, "</p>"));


// Module: echo_warning()
// Usage:
//   echo_warning(msg, [pfx]);
// Description:
//   Emulates printing of a warning message.  The text will be shaded yellow.
//   You can also use this as a function call from a function.
// Arguments:
//   msg = The message to print.
//   pfx = The prefix to print before `msg`.  Default: `WARNING`
module echo_warning(msg, pfx="WARNING") {
	echo(str("<p style=\"background-color: #ffffb0\"><b>", pfx, ":</b> ", msg, "</p>"));
}

function echo_warning(msg, pfx="WARNING") =
	echo(str("<p style=\"background-color: #ffffb0\"><b>", pfx, ":</b> ", msg, "</p>"));


// Module: deprecate()
// Usage:
//   deprecate(name, [suggest]);
// Description:
//   Show module deprecation warnings.
//   You can also use this as a function call from a function.
// Arguments:
//   name = The name of the module that is deprecated.
//   suggest = If given, the module to recommend using instead.
module deprecate(name, suggest=undef) {
	echo_warning(pfx="DEPRECATED",
		str(
			"`<code>", name, "</code>` is deprecated and should not be used.",
			is_undef(suggest)? "" : str(
				"  You should use `<code>", suggest, "</code>` instead."
			)
		)
	);
}

function deprecate(name, suggest=undef) =
	echo_warning(pfx="DEPRECATED",
		str(
			"`<code>", name, "</code>` is deprecated and should not be used.",
			is_undef(suggest)? "" : str(
				"  You should use `<code>", suggest, "</code>` instead."
			)
		)
	);


// Module: deprecate_argument()
// Usage:
//   deprecate(name, arg, [suggest]);
// Description:
//   Show argument deprecation warnings.
//   You can also use this as a function call from a function.
// Arguments:
//   name = The name of the module/function the deprecated argument is used in.
//   arg = The name of the deprecated argument.
//   suggest = If given, the argument to recommend using instead.
module deprecate_argument(name, arg, suggest=undef) {
	echo_warning(pfx="DEPRECATED ARG", str(
		"In `<code>", name, "</code>`, ",
		"the argument `<code>", arg, "</code>` ",
		"is deprecated and should not be used.",
		is_undef(suggest)? "" : str(
			"  You should use `<code>", suggest, "</code>` instead."
		)
	));
}

function deprecate_argument(name, arg, suggest=undef) =
	echo_warning(pfx="DEPRECATED ARG", str(
		"In `<code>", name, "</code>`, ",
		"the argument `<code>", arg, "</code>` ",
		"is deprecated and should not be used.",
		is_undef(suggest)? "" : str(
			"  You should use `<code>", suggest, "</code>` instead."
		)
	));



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
