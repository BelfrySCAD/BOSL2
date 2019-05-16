//////////////////////////////////////////////////////////////////////
// LibFile: errors.scad
//   Functions and modules to facilitate error reporting.
//   To use, include this line at the top of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////



// Section: Warnings and Errors


// Function&Module: assert_in_list()
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
	dummy = assert_in_list(argname, val, l, idx);
}

function assert_in_list(argname, val, l, idx=undef) =
	let(succ = search([val], l, num_returns_per_match=1, index_col_num=idx) != [[]])
	succ? 0 : let(
		msg = str(
			"In argument '", argname, "', ",
			(is_string(val)? str("\"", val, "\"") : val),
			" must be one of ",
			(!is_undef(idx)? [for (v=l) v[idx]] : l)
		),
		FAILED=succ
	) assert(FAILED, msg);


// Function&Module: echo_error()
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


// Function&Module: echo_warning()
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


// Function&Module: deprecate()
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


// Function&Module: deprecate_argument()
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
