/////////////////////////////////////////////////////////////////////
// LibFile: text.scad
//   Historically fonts were specified by their "body size", the height of the metal body
//   on which the glyphs were cast.  This means the size was an upper bound on the size
//   of the font glyphs, not a direct measurement of their size.  In digital typesetting,
//   the metal body is replaced by an invisible box, the em square, whose side length is
//   defined to be the font's size.  The glyphs can be contained in that square, or they
//   can extend beyond it, depending on the choices made by the font designer.  As a
//   result, the meaning of font size varies between fonts: two fonts at the "same" size
//   can differ significantly in the actual size of their characters.  Typographers
//   customarily specify the size in the units of "points". A point is 1/72 inch.  In
//   OpenSCAD, you specify the size in OpenSCAD units (often treated as millimeters for 3d
//   printing), so if you want points you need to perform a suitable unit conversion.
//   .
//   In addition, the OpenSCAD font system has a bug: Specifying `size=s`, where `s` is the desired em size, results
//   in text having a size of `s/0.72`. For many fonts, this causes the size of uppercase letters (not the
//   ascender-descender range) to be approximately equal to `s` units, because fonts commonly use about 70% of their
//   height for their ascenders. More recent versions of OpenSCAD introduced the `em` parameter in `text()` to let
//   you specify font size the customary way, as em box size. Multiplying `em` by 100/72 converts it to the equivalent
//   OpenSCAD size that results in the true em size. The modules here let you specify font size a number of other ways, too.
//   .
//   Another bug in OpenSCAD involves letter spacing, in which the `spacing` parameter in `text()` results in the width
//   of each chracter being multiplied by the `spacing` value. This works fine for monospace fonts, but causes horribly
//   uneven spacing when using proportional fonts because wide characters like "m" or "W" end up with too much adjacent
//   spacing compared to narrow characters like "i" or "l". This situation is fixed by offering multiple ways to
//   achieve consistent letter spacing.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Text
// FileSummary: 2D and 3D text rendering
//////////////////////////////////////////////////////////////////////


// Section: Enhanced text operations
//   The modules and functions in this section require a build of OpenSCAD later than 2025-07-11.

/*
DATA OBJECTS
Listed from lowest level. Higher-level objects include lower level objects.


Font data, returned by _fontdata. Example:
{
    // fontmetrics() object properties, with font size inserted in 'font' property
    nominal   = { ascent = 12.5733; descent = -2.9433; };
    max       = { ascent = 14.3501; descent = -5.2287; };
    interline = 15.9709;
    font      = { family = "Liberation Sans"; style = "Bold"; size = 10; };
    // other data
    spacer    = 0;          // amount of space to insert between characters
    spc       = 3.8588;     // width of a space character for this font
    direction = "ltr";      // text direction, "ltr" or "rtl"
    language  = "en";       // passed through to text(), function unknown
    script    = "latin";    // passed through to text(), function unknown
}


Returned by _textobj() - primary workhorse, contains horizontal offset position data about a
single wrapped line of text. First character position is always zero.

{
    text                    // text for this line
    charpos                 // array of horizontal positions for each character, always >=0
    ascent                  // 'ascent' property for this line from textmetrics()
    descent                 // 'descent' property for this line from textmetrics()  
    boxwidth                // physical width of this line in CAD units
    nominal_boxheight       // nominal height (ascent to descent) of this line in CAD units
    actual_boxheight        // physical height of this line, ascent-descent from textmetrics()
}


_textwrap() returns a list of wrap objects, one for each wrapped line.
Each wrap object includes:

{
    textline                // the actual text for this line
    textobj                 // the _textobj() for this line, described above
    indent                  // the amount of indentation for this line
    newparagraph            // boolean, if true then this line starts a new wrapped paragraph
}


_justify_pos() also returns a textwrap object, takes a single textwrap object and returns it with
adjusted character positions in its textobj for full justification within a given maximum width.


_baseline_pos in write() is a list of objects, each of which includes dimensional
information about a wrap object adjusted for a box position centered on the origin,
as well as each line's baseline.

{
    xstart                  // x coordinate of start of baseline (right end for RTL text)
    xend                    // x coordinate of end of baseline (left end for RTL text)
    y                       // y coordinate of baseline (always negative)
    top                     // y coordinate of physical top of the line of text
    bot                     // y coordinate of physical bottom of the line of text
    linewrapobj             // the wrap object for this line of text
}


_writeob() returns a write object, which includes everything needed to render the text.

{
    fontname                // name of the font from _fontdata object
    tightboxsize            // dimension of tight box that fits snugly around all the text
    userboxsize             // dimensions of the user-defined box with INF values matching the tight box
    tightbox_offset         // position offset of the tight box within the user box
    vbaseline0              // distance from top of tight box to first baseline
    osize                   // OpenSCAD font size derived from one of the specified sizes passed
    baseline_pos            // list of baseline_pos objects
}
*/



// Module: write()
// Synopsis: Render multi-line text as an attachable 2D block.
// SynTags: Geom
// Topics: Attachments, Text
// See Also: get_font_size(), write3d()
// Usage:
//   write(text, [max_width], [max_height], ...);
// Usage: With attachments
//   write(text, [max_width], [max_height], ...) [ATTACHMENTS];
// Usage: Concatenation
//   write(...) write(...) write(...);
// Description:
//   Creates a 2D geometry of text within optional bounds, word-wrapping to multiple lines if needed.
//   The `text` input may be a simple string, a string with embedded newline (`\n`) characters, or an array
//   of either kind of string mixed together. The text may contain `"{ }"` or `"\u00a0"` for nonbreaking space
//   characters. The text is parsed into an array of simple strings, each of which is treated as a paragraph to be
//   word-wrapped if the font size is given with a finite `max_width` bound.
//   .
//   If a font size is given with a finite `max_width` and/or `max_height`, then the text is word-wrapped within those
//   dimensions; otherwise, no word-wrapping occurs. This table shows the results given different combinations
//   of font size, finite `max_width`, and finite `max_height`:
//   .
//   | Font size given | Finite `max_width` | Finite `max_height` | Result |
//   | :---: | :---: | :---: | --- |
//   | - | - | - | Treat as if `size=10`, emit warning |
//   | - | - | ✓ | Size the text to fit `max_height`, no wrapping |
//   | - | ✓ | - | Size the text to fit `max_width`, no wrapping |
//   | - | ✓ | ✓ | Size the text to fit within both constraints, no wrapping |
//   | ✓ | - | - | Works like `text()`, no wrapping |
//   | ✓ | - | ✓ | Wrap text to fit within the `max_height` |
//   | ✓ | ✓ | - | Wrap text if required to fit within the `max_width` |
//   | ✓ | ✓ | ✓ | Wrap to fit within `max_width`, echo warning if `max_height` exceeded |
//   .
//   When either `max_width` or `max_height` are specified, the wordwrapped text invariably doesn't span the entire dimensions
//   of the bounding box in one or both dimensions. It is usually a bit narrower than `max_width` due to wordwrapping if
//   `max_width` was set, or the wordwrapped lines are not as tall as `max_height` if `max_height` was set. Think of the
//   **tight bounding box** as the box that fits snugly around the text, and your defined bounding box surrounds it. The
//   margin (if any) between the tight bounds and your defined bounds depends on whether you set `max_width`, `max_height`,
//   or both, and also on how you set `align`, `vfit`, and `hfit`. The `box_align` parameter uses the usual direction
//   vectors `RIGHT`, `BACK`, etc., and controls the position of the tight bounding box within your defined bounds.
//   By default, the tight bounding box horizontal alignment follows the `align` parameter (which aligns the text within the tight
//   bounding box), and the vertical position is `CENTER`.
//   .
//   **Font sizes and spacing**
//   .
//   There are several mutually-exclusive font size parameters to choose from. At most one of them can be specified.
//   * `size` is exactly the same as the `size` parameter in OpenSCAD's `text()` module.
//   * `cap_height` is a useful size specification for uppercase labeling, and results in capital letters sized to this height. The special variable `$refchar_cap` is used as the reference character for a capital letter, and defaults to `H`.
//   * `nom_height` specifies the nominal height of common characters (e.g. A-Z, a-z, 0-9, punctuation) including ascenders and descenders with common diacritic marks. This is useful for creating labels with mixed-case text.
//   * `full_height` specifies the maximum height occupied by the font's character set. This would include characters with double diacritics and drawing characters like vertical bars. This size specification typically results in somewhat smaller glyphs than `nom_height` to account for fitting taller characters in the specified vertical space.
//   * `iline_height` lets you specify a font size in terms of the font's internal interline height, which is typically, but not always, equal or greater than the maximum glyph height.
//   * `em` is the standard em unit size in typography, the size of the design box for the glyphs. OpenSCAD's `text()` also has an `em` argument that you can specify instead of `size`.
//   .
//   Unlike the `spacing` parameter in OpenSCAD's `text()`, which results in non-uniform spacing of proportional fonts, three
//   letter spacing parameters are available to maintain uniform spacing between characters while also accounting for kerning
//   between character pairs. You can use `letterspacing` to specify a constant amount of space in CAD units to insert between
//   characters. The other two specify proportions: `letterspacing_em` is a multiple of the font's em-size, and
//   `letterspacing_ref` is a mutiple of the width of $refchar_width; default is `0` (zero).
//   .
//   **Concatenating**
//   .
//   Multiple `write()` calls may be concatenated in a parent-child fashion, to concatenate multiple instances along a
//   common baseline. The beginning of each child's baseline connects to the end of the parent's baseline. For example:
//   ````
//     write("Hello ", size=12)
//         write("there ", size=8)
//             write("world", size=12);
//   ````
//   This displays "Hello there world" with a smaller size for "there". Spaces should be included if spaces are needed.
//   Only the first instance of `write()` may have an anchor specified, and the position of each successive child
//   depends on its parent. If you need to do something with a chain of `write()` calls other than concatenate them,
//   you can use {{align()}}, {{attach()}}, or {{position()}} as usual in front of the child, causing the parent's
//   end-of-line offset for concatenation to be disregarded.
//   .
//   **Paragraphs**
//   .
//   The input text may be a string or a list of strings.
//   If the input text includes newline `\n` characters, the text is split at each newline into a list of simple strings.
//   Any `\n` characters that may be present in a list of strings also cause those strings to be split, expanding the list.
//   .
//   Once the input text has been processed into a list of simple strings without newlines, each string in the list is
//   considered to be a "paragraph" for the purposes of wordwrapping and positioning.
//   .
//   A paragraph may have its first line indented if `indent` is positive, or subsequent lines are indented if `indent`
//   is negative (effectively outdenting the first line). Spacing between paragraphs is controlled by `para_spacing`,
//   so there is no need to include consecutive newlines to achieve a blank vertical space between paragraphs, you can
//   simply adjust `para_spacing`, which defaults to 1 (multiple of `line_spacing`). If you really want to insert a
//   blank line in your text, make sure it consists of a space character; e.g. the space between the newlines in
//   `"line1\n \nline2"` would appear as a blank line between `"line1"` and `"line2"`.
// Arguments:
//   text = The text to display. May be a simple string, string with newline (`\n`) characters, or a list of strings (which can also contain newline characters). The alias `{ }` may be used for the nonbreaking space character `\u00a0`.
//   max_width = Constrains text to fit within a maximum horizontal width. If no font size is given then the size is chosen for the line of text (or longest line in an array) to span this width. If a font size is given, the text is wrapped to fit within this constraint. Default: `INF`
//   max_height = Maximum vertical height the text can occupy. If no font size is given, a `nom_height` font size is chosen so that the text spans this height top to bottom, accounting for `line_spacing` and `para_spacing` if specified. If a font size is given, the text is wrapped to produce the shortest horizontal width constrained by this height. Default: `INF`
//   ---
//   box = `[max_width, max_height]`, alternative parameter for passing `max_width` and `max_height` more compactly. If set, it overrides the `max_width` and `max_height` arguments. Default: `undef`
//   size = OpenSCAD font size, same as the size used in `text()`. If omitted while both `max_width` and `max_height` are not set, a warning is displayed in the console and `size=10` is assumed.
//   cap_height = Height of a capital letter, using `$refchar_cap` as the reference character.
//   nom_height = Height of normal characters, from nominal ascender to nominal descender.
//   full_height = Maximum height possible in the font, from maximum ascender to maximum descender.
//   iline_height = Interline height for the specified font; the resulting glyph size may be much smaller.
//   em = Standard font unit size, the size of the em-box in which the font was designed.
//   font = Name of the font to use. Default "Liberation Sans:style=Bold"
//   align = Horizontal alignment within the bounding box. Set this to "left", "right", "center", or "justify" (which requires setting a finite `max_width`). Ignored if `max_width=INF`. Default: "left"
//   justify_last = Alignment of last line in multiline full-justified text (when `align="justify"`). Defaults to "left" if `direction="ltr"` (default) or "right" if `direction="rtl"`.
//   hfit = Determines the the bounding box is calculated for horizontal alignment for anchoring, as well as for `align="justify"`. When set to "width", the `max_width` parameter is used. When set to "tight", the rendered horizontal width of the text is used (longest line for multi-line text). Default: "tight"
//   vfit = Determines how the bounding box is calculated for vertical alignment, accounting for `line_spacing` and `para_spacing`. When set to "max", the bounds fit the maximum ascender and descender for the entire font set. When set to "nominal", the nominal ascender and descender is used. When set to "tight", the bounds fit the actual ascender of the top line and actual descender of the bottom line. Default: "nominal"
//   box_align = Positions the tight bounding box within the bounds defined by `max_width` and/or `max_height`. Ignored if neither `max_width` nor `max_height` are set. Uses the standard direction vectors (for example, `LEFT+BACK`). If unset, the tight bounding box is positioned horizontally according to the `align` parameter (using `justify_last` if `align="justify"`), and vertically as `CENTER`.
//   letterspacing = If set, adds space between letters in CAD units. Cannot be used with `letterspacing_em` or `letterspacing_ref`. Can be negative to squish letters together.
//   letterspacing_em = If set, adds space between letters in relative units; that is, a proportion of the em size of the font (where 1.0 is no change, smaller values squish letters together). Cannot be used with `letterspacing` or `letterspacing_ref`. Must be positive.
//   letterspacing_ref = If set, adds space between letters relative to the width of `$refchar_width` (typically `"0"`); that is, a proportion of the width of the reference character (where 1.0 is no change, smaller values squish the letters together). Must be positive. Cannot be used with `letterspacing` or `letterspacing_em`.
//   indent = If positive, the first line of a paragraph is indented by this amount. If negative, the first line is effectively outdented by indenting subsequent lines by the positive value of this amount. Indents are from the left for LTR text, and from the right for RTL text. No effect if font size is not set, or if `align="center"`. Default: 0
//   wrap_optimize = If true, and wordwrapping is needed, attempt to equalize line lengths without increasing number of wrapped lines. If false, use greedy wordwrapping, which can result in "widow" words by themselves on the last line. Default: `true`
//   collapse_space = If `true`, collapse any repeated space characters in the input string into a single space. This is useful when the input string covers multiple indented lines in the source code. If set to `true` and consecutive spaces are required, you can use nonbreaking spaces (e.g. `"{ } { }"` gives 3 spaces, two nonbreaking and one normal space in between). Default: `true`
//   line_spacing = Proportion of font's interline height for vertical spacing of multiple lines. Default: 1.0
//   para_spacing = Proportion of font's interline height for vertical spacing between paragraphs: Default: 1.0
//   direction = Direction of the text flow, "ltr" (left-to-right), "rtl" (right-to-left). This module **does not** support "ttb" (top-to-bottom), or "btt" (bottom-to-top). Default: "ltr"
//   language = Two-letter language code for the text. Unknown purpose; passed through to `text()`. Default: "en"
//   script = The script of the text. Unknown purpose; passed through to `text()`. Default: "latin"
//   anchor = Translate so that the [anchor](attachments.scad#subsection-anchor) point is at origin (0,0,0). The usual anchors `LEFT`, `RIGHT`, `CENTER`, `FWD`, `BACK` apply to the final bounding box of the text. Mutiline text can use named anchors (see below), and a named anchor is the **only** way to position the baseline of the text onto the origin. Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor. See [spin](attachments.scad#subsection-spin).  Default: `0`
//   $fn = Works the same as with OpenSCAD's `text`. Used for subdividing curves in characters.
//   $refchar_cap = Reference character to use for gauging `cap_height`. Default: "H"
//   $refchar_width = Reference character for `letterspacing_ref`. Default: "0" (zero)
// Named Anchors:
//   BASELINE(n,[pos],[tight],[rtl]) = Anchor the baseline of line `n` at position `pos` (default `CENTER`). The line number `n` may be an integer (0, 1, 2,...) or a negative number (-1, -2,...) counting back from the last line; default is 0 if unset. The position `pos` may be `LEFT`, `CENTER` (default if omitted), or `RIGHT`, relative to the physical length of the line when `tight=true` (default if omitted) or the entire text bounding box when `tight=false`. You can use `BASELINE("start")` and `BASELINE("end")` as shortcuts for `BASELINE(0,"left")` and `BASELINE(-1,"right")`. For right-to-left text, setting `rtl=true` reverses the meanings of "start" and "end" (default is `rtl=false)`.
//   TEXTLINE(n,[pos],[tight],[rtl]) = Anchor the rendered text of line `n` at position `pos`. The line number `n` may be an integer (0, 1, 2,...) or a negative number (-1, -2,...) counting back from the last line; default is 0 if unset. The position `pos` (default `CENTER`) is relative to the bouding box containing that individual line, which is the physical horizontal width of the text when `tight=true` (default if omitted) or the entire text bounding box when `tight=false`. You can use `TEXTLINE("start")` and `TEXTLINE("end")` as shortcuts for `TEXTLINE(0,"left")` and `TEXTLINE(-1,"right")`. For right-to-left text, setting `rtl=true` reverses the meanings of "start" and "end". `TEXTLINE(2,RIGHT+FWD,tight=false)` would position lower right corner of the line's bounding box at the origin, using a bounding box as wide as the overall bounds containing all lines of text (`max_width`, or the tight bounds if `max_width` is not set).
// Example(2D,VPT=[0,0,0],VPD=125): Basic usage of write(). Default is to center the text on the origin. In this case the font size is set by `nom_height` to specify the size of the font from nominal ascender to nominal descender.
//   write("Flying high", nom_height=14, font="Liberation Sans");
// Example(2D,NoAxes,VPT=[0,0,0],VPD=285): You can pass multi-line text by inserting newline (`\n`) characters, or passing an array of strings. An array of strings may also contain newlines, and they are split into separate lines. The results are identical.
//   left(50)      write("Hello\nthere,\nworld!", size=10);
//   color("gray") write(["Hello", "there,", "world!"], size=10);
//   right(50)     write(["Hello\nthere,", "world!"], size=10);
// Example(2D,VPT=[0,0,0],VPD=270): If your text is just uppercase characters, you can use `cap_height` for the font size to specify the uppercase ascender height only. The character `H` for your font is used as the reference character, which you may reset by changing `$refchar_cap`. The text height spans exactly -20 to 20.
//   write("THIS", cap_height=40);
// Example(2D,Med,NoAxes,VPT=[51,8,0],VPD=210): If you need to concatenate instances of `write()` to display things in different fonts, sizes, or styles, you can do it without anchors simply by making each subsequent `write()` as a child of the parent. Use spaces if needed to keep the words separate.
//   write("The", size=8, font="Liberation Sans", anchor=LEFT+FWD) // position the first one
//     write(" right ", size=14, font="Liberation Serif:style=Bold Italic")
//       write("stuff", size=11, font="Liberation Sans:style=Bold");
// Example(2D,Med,NoAxes,VPT=[27,6,0],VPD=320): As described above, OpenSCAD's `text()` creates unevenly-spaced text with proportional typefaces when `spacing` is not 1.0. This is solved by `write()`, letting you use one of three different options for setting character spacing. Here we use `letterspacing_ref=2`, which uses `$refchar_width` (default `"0"`) to calculate a constant amount of space to insert between each character.
//   font = "Liberation Sans:style=Bold";
//   string = "Animals";
//   spacing = 2;
//   back(12) {
//       color("black") text(str("text():"), size=10, font=font, halign="right");
//       text(string, size=10, font=font, spacing=spacing);
//   }
//   fwd(12) {
//       color("black") write("write():", size=10, font=font, anchor=(BASELINE(0,RIGHT)));
//       write(string, size=10, font=font, letterspacing_ref=spacing, anchor=(BASELINE(0,LEFT)));
//   }
// Example(2D,VPT=[0,0,0],VPD=280): Basic textwrap of a single long string to fit within specified bounding box. We override the default wrapping behavior by setting `wrap_optimize=false` to force `write()` to use "greedy" word-wrapping, causing each line to use as much of the allowed horizontal width as possible without exceeding it. This results in a "widow" word by itself on the last line.
//   string = "Go placidly amid the noise and haste,
//   and remember what peace there may be in silence.";
//   fontname = "Liberation Serif:style=Bold Italic";
//   write(string, size=10, box=[130,90], font=fontname,
//        wrap_optimize=false);
// Example(2D,VPT=[0,0,0],VPD=280): Same as previous example, but using the default `wrap_optimize=true`. Optimization never increases the number of wrapped lines, and the resulting lines have roughly equal length with no "widow" at the end. Setting `show_bounds=true` reveals the first line's baseline shown in magenta, the tight bounding box shown in green centered inside the maximum width defined in `box`. The vertical size of the tight bounding box is determined by the default value `vfit="nominal". By default, the tight bounding box is positioned inside your defined `box` according to `align` horizontally (default "left" for left-to-right text), and centered vertically.
//   string = "Go placidly amid the noise and haste,
//   and remember what peace there may be in silence.";
//   fontname = "Liberation Serif:style=Bold Italic";
//   write(string, size=10, box=[130,90], font=fontname,
//       show_bounds=true);
// Example(2D,VPT=[0,0,0],VPD=280): To position the tight bounding box within your defined box, set `box_align` to a combination of direction vectors. Here the tight bounding box is aligned to the upper right corner of bounds defined by `box`.
//   string = "Go placidly amid the noise and haste,
//   and remember what peace there may be in silence.";
//   fontname = "Liberation Serif:style=Bold Italic";
//   write(string, size=10, box=[130,90], font=fontname,
//       show_bounds=true, box_align=RIGHT+BACK);
// Example(2D,VPT=[0,0,0],VPD=280): This example demonstrates several things using the same text as previous example, disabling `wrap_optimize` again. We use `align="justify"`, which spreads out the word spacing so the text fits the horizontal width of the tight bounding box, leaving the last word justified according to `justify_last` (which defaults to "left" for left-to-right text). 
//   string = "Go placidly amid the noise and haste,
//   and remember what peace there may be in silence.";
//   fontname = "Liberation Serif:style=Bold Italic";
//   write(string, size=10, box=[130,90], font=fontname,
//        align="justify", justify_last="right",
//        wrap_optimize=false, show_bounds=true);
// Example(2D,NoAxes,VPD=230): There may be a situation where you need a nonbreaking space. The code `{ }` (a space between two curly braces) is used for this purpose. In this example, the string `"1000 kg"` should be treated as a single word with a nonbreaking space, to prevent wordwrapping the "kg" to a separate line.
//   back(20) write("Heavy: 1000 kg", size=10, max_width=90,
//       align="center", wrap_optimize=false, show_bounds=true);
//   fwd(20)  write("Heavy: 1000{ }kg", size=10, max_width=90,
//       align="center", wrap_optimize=false, show_bounds=true);
// Example(2D,VPD=230): `write()` normally collapses consecutive spaces (because `collapse_space=true` by default). If you want to insert multiple spaces while collapsing others, you can use the nonbreaking space code `{ }` for this purpose. Here 5 spaces are inserted between two words by alternating normal and nonbreaking spaces, but you could also use all nonbreaking spaces.
//   write("Five { } { } spaces", size=10);
// Example(2D,VPT=[0,0,0],VPD=200): If `max_width` is set with no font size, then the font size is automatically adjusted so the text spans the specified maximum width. No automatic wordwrapping occurs; only manual wordwrapping by inserting `\n` is possible.
//   write("Hello,\nworld!", max_width=80, show_bounds=true);
// Example(2D, VPT=[0,0,0],VPD=200): Likewise, if only `max_height` is set with no font size, then the font size is automatically adjusted so the text spans the specified vertical height. We set `vfit="tight` to maximize the vertical space used within the `max_height` constraint.
//   write("Hello,\nworld!", max_height=40, vfit="tight",
//       show_bounds=true); 

$refchar_cap = "H";   // Reference character for measuring the height of an uppercase character
$refchar_width = "0"; // Reference character for the letterspacing_ref argument in write()

module write(text, max_width=INF, max_height=INF, box, 
 size, cap_height, nom_height, full_height, iline_height, em,
 font="Liberation Sans:style=bold",
 align="left", justify_last=undef, hfit="tight", vfit="nominal", box_align=undef,
 letterspacing=undef, letterspacing_em=undef, letterspacing_ref=undef, indent=0,
 wrap_optimize=true, collapse_space = true, line_spacing=1, para_spacing=1,
 direction="ltr", language="en", script="latin", anchor=undef, spin=0, show_bounds=false) {
 
    // get write object

    w = _writeobj(text, 0, max_width, max_height, box, size, cap_height, nom_height, full_height,
        iline_height, em, font, align, justify_last, hfit, vfit, box_align,
        letterspacing, letterspacing_em, letterspacing_ref, indent, wrap_optimize, collapse_space,
        line_spacing, para_spacing, direction, language, script, "write");

    // if concatenating write() calls, get the parent offset

    parent_end = is_undef($parent_geom) || is_def(anchor) || is_def($attach_to) || is_def($attach_alignment) ? undef
    : let(
        anchors = last($parent_geom),
        found = search([BASELINE("end")], anchors, num_returns_per_match=1)[0]
    ) found==[] ? undef : anchors[found];
    parent_offset = is_undef(parent_end) ? [0,0,0] : parent_end[1];
    anch = is_def(anchor) ? anchor
        : is_undef(parent_end) ? CENTER
        : BASELINE("start");

    // display the text

    dir = direction == "rtl" ? -1 : 1;
    ilast = len(w.baseline_pos) - 1;
    ha = dir>0 ? "left" : "right";
    translate(parent_offset) attachable(anch, spin, two_d=true, size=w.tightboxsize, anchors=_line_anchors(w.baseline_pos, w.tightboxsize)) {
        union() {
            if(show_bounds) {
                stroke(square(w.userboxsize, center=true), width=0.6, color="lightgray", closed=true);
                translate(w.tightbox_offset) stroke(square(w.tightboxsize, center=true), width=0.6, color="green", closed=true);
                ybase = w.tightboxsize.y/2 - w.vbaseline0;
                wd = is_finite(w.wid) ? w.wid : w.tightboxsize[0];
                translate(w.tightbox_offset) stroke([[-w.osize-wd/2, ybase], [w.osize+wd/2, ybase]], width=0.4, color="magenta");
            }
            for(i=[0:ilast]) let(wo=w.baseline_pos[i].linewrapobj, tx = wo.textobj.text, cp=wo.textobj.charpos)
                for(p=[0:len(tx)-1])
                    translate([w.baseline_pos[i].xstart+dir*cp[p], w.baseline_pos[i].y])
                        text(tx[p], w.osize, w.fontname, direction=direction, language=language,
                                script=script, halign=ha, valign="baseline", spacing=1);
        }
        children();
    }
}



// Module: write3d()
// Synopsis: Render multi-line text as an attachable 3D block.
// SynTags: Geom
// Topics: Attachments, Text
// See Also: get_font_size(), write()
// Usage:
//   write3d(text, [thickness|h=], [max_width], [max_height], ...);
// Usage: With attachments
//   write3d(text, [thickness|h=], [max_width], [max_height], ...) [ATTACHMENTS];
// Usage: Concatenation
//   write3d(...) write3d(...) write3d(...);
// Description:
//   This is a 3D extension of the 2D {{write()}} module, with 3D anchors.
//   The argument list is the same as `write()` except for the addition of extrusion height `thickness`, and the
//   absence of `show_bounds`. See the `write()` documentation above for a full description of behavior and
//   the argument list.
//   .
//   The named anchors `BASELINE()` and `TEXTLINE()` apply here, but they can use 3D anchors. For example,
//   `BASELINE("end",TOP)` gives an anchor at the end of the last line of text, at the top of the extrusion.
// Example(3D,VPD=81,VPT=[1.5,0.5,1.3]): Basic 3D text, 6 units thickness. This example contains a hardcoded newline (`\n`), resulting in two lines of text. The default anchor is to center the bounding box at the origin.
//   write3d("Flying\nhigh", h=6, size=10, align="center",
//       font="Liberation Serif:style=Bold Italic");
// Example(3D,VPD=81,VPT=[20.5,-2,-2]): The same text anchored with the top-surface start of the first baseline at the origin.
//   write3d("Flying\nhigh", h=6, size=10, align="center",
//       font="Liberation Serif:style=Bold Italic",
//       anchor=BASELINE("start",TOP));
// Example(3D): A message embossed onto the top of a rounded cuboid, using the default font. The text is 4 units thick and sunk 2 units into the cuboid. The message is automatically word-wrapped to fit within `max_width`. 
//   cuboid([105,80,15], rounding=6, clip_angle=40)
//   attach(TOP,BOT,overlap=2)
//       color("lightgreen")
//           write3d("Beware ye all who enter!",
//               thickness=4, size=12, max_width=90,
//               letterspacing=1, align="center");
// Example(3D): The same message engraved 2 units into the top of a rounded cuboid, using the default font. For a difference operation to work properly with attachments, we must use the BOSL2 `diff()` module rather than OpenSCAD's `difference()`.
//   diff()
//       cuboid([105,80,15], rounding=6, clip_angle=40)
//       attach(TOP,BOT,overlap=2)
//           tag("remove") color("lightgreen")
//               write3d("Beware ye all who enter!",
//                   thickness=4, size=12, max_width=90,
//                   letterspacing=1, align="center");
// Example(3D,VPD=405,VPR=[56,0,40],VPT=[2,0,2]): Attaching 3D text to three sides of a cuboid.
//   cuboid(100, chamfer=6) {
//       attach(TOP,BOT,overlap=1) color("lightgreen")
//           write3d("ETERNAL", thickness=4, size=14, spin=45);
//       attach(FRONT,BOT,overlap=1) color("lightgreen")
//           write3d("GOLDEN", thickness=4, size=14);
//       attach(RIGHT,BOT,overlap=1) color("lightgreen")
//               write3d("BRAID", thickness=4, size=14);
//   }

module write3d(text, thickness, max_width=INF, max_height=INF, box, 
 size, cap_height, nom_height, full_height, iline_height, em,
 font="Liberation Sans:style=bold",
 align="left", justify_last=undef, hfit="tight", vfit="nominal", box_align=undef,
 letterspacing=undef, letterspacing_em=undef, letterspacing_ref=undef, indent=0,
 wrap_optimize=true, collapse_space = true, line_spacing=1, para_spacing=1,
 direction="ltr", language="en", script="latin", anchor=undef, spin=0, orient=UP, h) {
    thk = first_defined([thickness,h]);
    er1 = assert(thk>0, "\nwrite3d(): Either thickness or h must be defined as a positive number.");
 
    // get write object

    w = _writeobj(text, thk, max_width, max_height, box, size, cap_height, nom_height, full_height,
        iline_height, em, font, align, justify_last, hfit, vfit, box_align,
        letterspacing, letterspacing_em, letterspacing_ref, indent, wrap_optimize, collapse_space,
        line_spacing, para_spacing, direction, language, script, "write3d");

    // if concatenating write() calls, get the parent offset

    parent_end = is_undef($parent_geom) || is_def(anchor) || is_def($attach_to) || is_def($attach_alignment) ? undef
    : let(
        anchors = last($parent_geom),
        found = search([BASELINE("end")], anchors, num_returns_per_match=1)[0]
    ) found==[] ? undef : anchors[found];
    parent_offset = is_undef(parent_end) ? [0,0,0] : parent_end[1];
    anch = is_def(anchor) ? anchor
        : is_undef(parent_end) ? CENTER
        : BASELINE("start");

    // display the text

    dir = direction == "rtl" ? -1 : 1;
    ilast = len(w.baseline_pos) - 1;
    ha = dir>0 ? "left" : "right";
    translate(parent_offset) attachable(anch, spin, orient, size=w.tightboxsize, anchors=_line_anchors(w.baseline_pos, w.tightboxsize)) {
        translate([0,0,-thk/2]) linear_extrude(thk) union() {
            for(i=[0:ilast]) let(wo=w.baseline_pos[i].linewrapobj, tx = wo.textobj.text, cp=wo.textobj.charpos)
                for(p=[0:len(tx)-1])
                    translate([w.baseline_pos[i].xstart+dir*cp[p], w.baseline_pos[i].y])
                        text(tx[p], w.osize, w.fontname, direction=direction, language=language,
                                script=script, halign=ha, valign="baseline", spacing=1);
        }
        children();
    }
}



/// Internal function: _writeobj() - called by write(), write3d(), path_write()
/// Return a 2D write object with all information required to render wrapped text at the correct posotions.
/// Arguments are the same as for write() but without the anchor-related ones.

function _writeobj(text, thickness=0, max_width=INF, max_height=INF, box, 
 size, cap_height, nom_height, full_height, iline_height, em,
 font="Liberation Sans:style=bold", align="left", justify_last=undef,
 hfit="tight", vfit="nominal", box_align=undef,
 letterspacing=undef, letterspacing_em=undef, letterspacing_ref=undef, indent=0,
 wrap_optimize=true, collapse_space = true, line_spacing=1, para_spacing=1,
 direction="ltr", language="en", script="latin", caller) = let(
    // version 20250711 is when objects became available, and this needs objects.
    err1=assert(version_num() >= 20250711, "\nOpenSCAD version must be dated on or after 2025-07-11 to use write()."),
    err_internal = assert(is_string(caller), "\n_writeobj(): Must specify string name of caller to this function."),
    err2=assert(direction=="ltr" || direction=="rtl", str("\n",caller,"(): Only directions 'ltr' and 'rtl' are supported.")),
    err3=assert(!((is_finite(max_width) || is_finite(max_height)) && is_def(box)), str("\n",caller,"(): The box parameter cannot be specified along with max_width or max_height.")),
    err4=assert(hfit=="width" || hfit=="tight", str("\n",caller,"(): hfit must be \"width\" or \"tight\"")),
    err5=assert(vfit=="max" || vfit=="nominal" || vfit=="tight", str("\n",caller,"(): vfit must be \"max\", \"nominal\", or \"tight\"")),
    wid = is_num(box.x) ? box.x : max_width,
    ht = is_num(box.y) ? box.y : max_height,
    err6=assert(wid>0 && ht>0, str("\n",caller,"(): max_width and/or max_height must be a positive number or INF.")),
    fontsizes = num_defined([size, cap_height, nom_height, full_height, iline_height, em]),

    //err7 = false,
    //err8=assert(numfontsizes>0 || is_finite(wid) || is_finite(ht), str("\n",caller,"() requires a font size if max_width and max_height are not specified.")),

// if deciding that there should be no default font size if no max_width or max_height specified,
// then uncomment the 2 lines above and comment out the next 2 lines.

    err7 = (fontsizes==0 && !(is_finite(wid) || is_finite(ht))),
    size = err7 ? echo(str("\n\u26A0Warning: ",caller,"() requires a font size if max_width and max_height are not specified; assuming size=10.")) 10 : size,

    numfontsizes = err7 ? 1 : fontsizes,
    err8=assert(numfontsizes<=1, str("\n",caller,"(): No more than one font size can be specified: size, cap_height, nom_height, full_height, iline_height, or em).")),
    txt = _preprocess_text(text, collapse_space, caller),
    fd = numfontsizes == 1 ?
        _fontdata(font, size,cap_height,nom_height,full_height,iline_height,em, letterspacing, letterspacing_em, letterspacing_ref, direction, language, script)
        : let(siz = fit_font_size(txt, wid, ht, font=font, letterspacing_ref, vfit=vfit, direction=direction))
        _fontdata(font, siz, letterspacing=letterspacing, letterspacing_em=letterspacing_em, letterspacing_ref=letterspacing_ref, direction=direction, language=language, script=script),
    osize = fd.font.size,
    use_indent = (align=="left" && direction=="ltr") || align=="justify" || (align=="right" && direction=="rtl"),
    de1 = indent != 0 && !use_indent ? echo(str("\n\u26A0Warning: In write(), indent=", indent, " ignored with align=\"", align, "\" and direction=\"", direction, "\".")) : 0,
    de2 = indent != 0 && numfontsizes==0 ? echo(str("\n\u26A0Warning: In write(), indent=", indent, " ignored with no font size specified.")) : 0,
    indnt = use_indent && numfontsizes>0 ? indent : 0,
    just_last = is_undef(justify_last) ? (direction=="ltr" ? "left" : "right") : justify_last,

    wrapobj = _textwrap(txt, width=wid, optimize=wrap_optimize, indent=indnt, fontdata=fd, rtl=(direction=="rtl")),
    firstbaseline = wrapobj[0].textobj.ascent,
    baselines = _baselines(wrapobj, line_spacing, para_spacing, fd.interline),
    fontname = str(fd.font.family, ":style=", fd.font.style),
    ilast = len(wrapobj) - 1,

    vtight = wrapobj[0].textobj.ascent + baselines[0] - wrapobj[ilast].textobj.descent - baselines[ilast],
    vnominal = fd.nominal.ascent + baselines[0] - fd.nominal.descent - baselines[ilast],
    vmax = fd.max.ascent + baselines[0] - fd.max.descent - baselines[ilast],
    vboxsize = vfit=="tight" ? vtight : vfit=="max" ? vmax : vnominal,
    htight = align=="justify" && hfit=="width" && is_finite(wid) ? wid
        : max([ for(i=[0:len(wrapobj)-1]) wrapobj[i].textobj.boxwidth ]),

    boxpos = is_undef(box_align)
        ? (align=="left"
            ? LEFT
            : align=="right" ? RIGHT
            : align=="justify"
                ? (just_last=="left" ? LEFT : just_last=="right" ? RIGHT : CENTER)
                : CENTER)
        : box_align,
    userboxsizex = is_finite(wid) ? wid : htight,
    userboxsizey = is_finite(ht) ? ht : vboxsize,

    // container boxes

    tightboxsize = thickness > 0 ? [htight, vboxsize, thickness] : [htight, vboxsize],
    userboxsize = thickness > 0 ? [userboxsizex, userboxsizey, thickness] : [userboxsizex, userboxsizey],
    tboff = [
        boxpos.x<0 ? tightboxsize.x-userboxsize.x
        : boxpos.x>0 ? userboxsize.x-tightboxsize.x : 0,
        boxpos.y<0 || boxpos.z<0 ? tightboxsize.y-userboxsize.y
        : boxpos.y>0 || boxpos.z>0 ? userboxsize.y-tightboxsize.y : 0
        ] / 2,
    tightbox_offset = thickness > 0 ? [tboff.x, tboff.y, thickness] : [tboff.x, tboff.y],

    // baseline_pos array: each element is an object with properties relative to text box centered on origin:
    // xstart = x position of first character (left edge if LTR, right edge if RTL)
    // xend = x position of end of line (right edge if LTR, left edge if RTL)
    // y = y position of baseline
    // wrapobj = the line of text, which may be full-justified

    vbaseline0 = vfit == "tight" ? wrapobj[0].textobj.ascent
        : vfit == "max" ? fd.max.ascent : fd.nominal.ascent,
    dir = direction == "rtl" ? -1 : 1,
    ha = dir>0 ? "left" : "right", // halign to use for individual characters depending on direction

    // calculate positions for all baselines, offsetting by tightbox_offset

    baseline_pos = let(dir = direction=="rtl" ? -1:1,
                        hbox = align=="justify" && hfit=="width" ? userboxsize.x : htight,
                        xoff = -dir*hbox/2 + tightbox_offset.x,
                        yoff = vboxsize/2 + tightbox_offset.y - vbaseline0) [
        for(i=[0:len(wrapobj)-1])
            let(
                lastline = (i<len(wrapobj)-1 && wrapobj[i+1].newparagraph) || (i==len(wrapobj)-1),
                wo = align=="justify" ? _justify_pos(wrapobj[i], hbox, fd, lastline)
                    : wrapobj[i],
                leftover = hbox - wo.textobj.boxwidth,
                xoffset = (align=="left" && dir>0) || (align=="right" && dir<0) ? wo.indent
                    : align == "center" ? leftover/2
                    : (align=="right" && dir>0) || (align=="left" && dir<0) ? leftover - wo.indent
                    : align=="justify" ?
                        (lastline ? (
                            just_last=="center" ? leftover/2
                            : (just_last=="right" && dir>0) || (just_last=="left" && dir<0) ? leftover-wo.indent : 0
                                    )
                                : wo.indent
                        )
                    : 0,
                y = yoff + baselines[i]
            ) object(
                xstart = xoff + dir*(xoffset),
                xend = xoff + dir*(xoffset + wo.textobj.boxwidth),
                y = y,
                top = y + wo.textobj.ascent,
                bot = y - wo.textobj.descent,
                linewrapobj = wo
            )
    ]
) object(
    fontname = fontname,
    tightboxsize = tightboxsize,
    userboxsize = userboxsize,
    tightbox_offset = tightbox_offset,
    vbaseline0 = vbaseline0,
    osize = osize,
    baseline_pos = baseline_pos
);



/// Internal function: _preprocess_text() - called by _writeob()
function _preprocess_text(text, collapse_space, caller="write") =
    is_string(text) ? let(
        txtpass1 = str_replace(text, "{ }", "\u00A0"), // replace nonbreaking space codes
        txtpass2 = collapse_space ? str_collapse_char(txtpass1, " ") : txtpass1 // optionally collapse spaces
    ) collapse_space ? str_replace(txtpass2, "\n ", "\n") : txtpass2 // remove any remaining leading collapsed spaces after \n
    : is_list(text) && is_string(text[0]) ? let(
        txtpass1 = [for(t=text) str_replace(t, "{ }", "\u00A0")],
        txtpass2 = collapse_space ? [for(t=txtpass1) str_collapse_char(t, " ")] : txtpass1
    ) collapse_space ? [for(t=txtpass2) str_replace(t, "\n ", "\n")] : txtpass2
    : assert(false, str("\n",caller,"(): 'text' must be a string or list of strings.")) "";



/// Internal function: _baselines() - called by _writeobj()
/// Return baseline positions for multi-line text, starting at 0 and going negative from there.
/// Arguments:
///    wrapobj = return from _textwrap(), regardless if text is wrapped
///    lheight = user-defined line height multiple of font interline height
///    pheight = user-defined paragraph height multiple of font interline height

function _baselines(wrapobj, lheight, pheight, interline) =
    cumsum([
        for(i=[0:len(wrapobj)-1]) i==0?0: -(wrapobj[i].newparagraph ? pheight : lheight)
    ] * interline);

    

/// Internal function _justify_pos() - called by _writeobj()
/// Given a line of output from _textwrap(), adjust the charpos values so that the text is
/// full-justified within the given width.
/// Aguments:
///   lineobj = a line object returned in wrapobj from _textwrap() regardless if text is wrapped
///   width = width to justify within; must be at least as large as the longest line in wrapobj

function _justify_pos(lineobj, width, fontdata, lastline) =
let(
    excess = lastline ? 0 : max(0, width-lineobj.textobj.boxwidth) - lineobj.indent,
    spaces = len(str_find(lineobj.textline, " ", all=true)),
    spcadd = spaces > 0 ? excess / spaces : 0
) object(lineobj, textobj = _textobj(lineobj.textline, fontdata, spcadd));



/// Anchor name helper functions

function BASELINE(n, pos=CENTER, tight=true, rtl=false) =
    is_undef(n) ? BASELINE(rtl?-1:0,pos,tight,rtl)
    : assert(is_int(n) || n=="start" || n=="end", "\nBASELINE() first arg must be integer, undef, \"start\", or \"end\".")
    n=="start" ? BASELINE(rtl?-1:0, (rtl?RIGHT:LEFT)+pos, tight, rtl)
    : n=="end" ? BASELINE(rtl?0:-1, (rtl?LEFT:RIGHT)+pos, tight, rtl)
    : str("base", n, tight ? "_tight" : "_box", pos);

function TEXTLINE(n, pos=CENTER, tight=true, rtl=false) =
    is_undef(n) ? TEXTLINE(rtl?-1:0,pos,tight,rtl)
    : assert(is_int(n) || n=="start" || n=="end", "\nTEXTLINE() first arg must be integer, undef, \"start\", or \"end\".")
    let(line = n=="last" ? -1 : n)
    n=="start" ? TEXTLINE(rtl?-1:0, (rtl?RIGHT:LEFT)+pos, tight, rtl)
    : n=="end" ? TEXTLINE(rtl?0:-1, (rtl?LEFT:RIGHT)+pos, tight, rtl)
    : str("text", n, tight ? "_tight" : "_box", pos);

 

/// Internal function: _line_anchors() - called by _writeobj()
/// Named anchor generator to pass to attachable() - anchors can be 2D or 3D
/// boxsize is the tight bounding box [xsize,ysize] or [xsize,ysize,zsize]
function _line_anchors(baseline_pos, boxsize) =
    let(
        n = len(baseline_pos),
        bboxsize = is_vector(boxsize,3) ? boxsize : [boxsize[0], boxsize[1], 0],
        xbhi = bboxsize[0]/2,
        xblo = -xbhi,
        zbhi = bboxsize[2]/2,
        zblo = -zbhi,
        indx = count(n+1)
    ) [
        for (i=[0:n-1])
            let(
                bp = baseline_pos[i],
                xlo = min(bp.xstart, bp.xend),
                xhi = max(bp.xstart, bp.xend),
                xmid = (xlo+xhi)/2,
                ylo = bp.bot,
                yhi = bp.top,
                ymid = (ylo+yhi)/2,
                
                // container edges: real box edge if bounded, else same as text edge
                box_lo = is_finite(boxsize.x) ? -boxsize.x/2 : xlo,
                box_hi = is_finite(boxsize.x) ? boxsize.x/2 : xhi
            )
            for(x=[-1:1:1]) for(y=[-1:1:1]) for(z=[-1:1:1]) let(
                a = [x,y,z], in = i-n,
                // coordinates for different anchor modes
                btight = [a.x<0 ? xlo : a.x>0 ?  xhi : xmid, bp.y, a.z<0 ? zblo : a.z>0?zbhi:0],
                bbox =   [a.x<0 ? xblo : a.x>0 ? xbhi : 0,   bp.y, a.z<0 ? zblo : a.z>0?zbhi:0],
                ttight = [a.x<0 ? xlo : a.x>0 ? xhi : xmid, a.y<0 ? ylo : a.y>0 ? yhi : ymid, a.z<0 ? zblo : a.z>0?zbhi:0],
                tbox =   [a.x<0 ? xblo : a.x>0 ? xbhi : 0, a.y<0 ? ylo : a.y>0 ? yhi : ymid, a.z<0 ? zblo : a.z>0?zbhi:0]
            ) each [
                // normal line numbers
                named_anchor(str("base",i,"_tight",a), btight, UP, 0),
                named_anchor(str("base",i,"_box",a), bbox, UP, 0),
                named_anchor(str("text",i,"_tight",a), ttight, UP, 0),
                named_anchor(str("text",i,"_box",a), tbox, UP, 0),
                // negative line numbers, last line forward
                named_anchor(str("base",in,"_tight",a), btight, UP, 0),
                named_anchor(str("base",in,"_box",a), bbox, UP, 0),
                named_anchor(str("text",in,"_tight",a), ttight, UP, 0),
                named_anchor(str("text",in,"_box",a), tbox, UP, 0)                
        ]
    ];



// Function: get_font_size()
// Synopsis: Return an OpenSCAD font size corresponding to an alternative size metric.
// Topics: Text
// See Also: write(), fit_font_size()
// Usage:
//   size = get_font_size(font, [size=], [cap_height=], [nom_height=], [full_height=], [iline_height=], [em=]);
// Description:
//   Returns the equivalent OpenSCAD font size corresponding to the specified alternative size metric, for use with
//   OpenSCAD's `text()`. See {{write()}} above for a discussion of the different font size parameters.
// Arguments:
//   font = The font to use. Default: "Liberation Sans:style=Bold"
//   ---
//   size = OpenSCAD `size` of a font. If set, the same value is returned.
//   cap_height = Height of a capital letter, using `$refchar_cap` as the reference character.
//   nom_height = Height of normal characters, from nominal ascender to nominal descender.
//   full_height = Maximum height possible in the font, from maximum ascender to maximum descender.
//   iline_height = Interline height for the specified font; the resulting glyph size may be much smaller.
//   em = Standard font unit size, the size of the em-box in which the font was designed.
// Example:
//   // "Liberation Sans:style=Bold" is the default font if not specified
//   size = get_font_size(size=20);           // returns 20 (unchanged)
//   size = get_font_size("Liberation Mono",
//                        cap_height=20);     // returns 21.8531
//   size = get_font_size(nom_height=20);     // returns 12.8894
//   size = get_font_size(full_height=20);    // returns 10.2151
//   size = get_font_size("Liberation Serif",
//                        iline_height=20);   // returns 12.5228
//   size = get_font_size(em = 20);           // returns 13.8889
function get_font_size(font="Liberation Sans:style=Bold", size, cap_height, nom_height, full_height, iline_height, em) =
    assert(version_num() >= 20210816, "\nget_font_size() requires OpenSCAD release after 2021-08-16.")
    assert(num_defined([size, cap_height, nom_height, full_height, iline_height, em])==1, "\nget_font_size(): Exactly one of size, cap_height, nom_height, full_height, iline_height, or em must be specified.")
    is_def(size) ? size // pass through
    : let( // arbitrarily use a size 10 font to calculate scaling factor
        fm10 = fontmetrics(10, font),
        tmc = textmetrics($refchar_cap, 10, font), // $refchar_cap defaults to H
        fontscale = is_def(cap_height) ? cap_height / tmc.size[1]
            : is_def(nom_height) ? nom_height / (fm10.nominal.ascent-fm10.nominal.descent)
            : is_def(full_height) ? full_height / (fm10.max.ascent-fm10.max.descent)
            : is_def(iline_height) ? iline_height / fm10.interline
            : 1 / 0.72  // em
     ) 10*fontscale;



// Function: fit_font_size()
// Synopsis: Return a font size causing text to fit within bounds.
// Topics: Text
// See Also: write(), get_font_size()
// Usage:
//   size = fit_font_size(text, [max_width=], [max_height=], [box=], [font=], ...);
// Description:
//   Given some text, returns the largest font size that would cause the text to fit within the given dimension constraints.
//   Either of the 'max_width' or 'max_height' constraints may be `INF`, but not both.
//   If both constraints are finite, a size is found that equals one constraint without exceeding the
//   other, which could be either the 'max_width' or the 'max_height'.
//   .
//   Because the final font size is unknown at first, if extra space between characters is desired,
//   one of the two *relative* letterspacing arguments must be set to a proportion of the size of a character, where
//   `letterspacing_ref` is a proportion of `$refchar_width` (default `"0"`) and `letterspacing_em`
//   is a proportion of the font's em-box.
// Arguments:
//   text = The text to analyze. May be a string with newline (`\n`) characters, or a list of strings (which can also contain newlines).
//   max_width = Maximum width the text can occupy. Default: INF
//   max_height = Maximum height the text can occupy. Default: INF
//   ---
//   box = `[max_width, max_height]`, compact alternative to passing `max_width` and `max_height` separately. If set, it overrides the `max_width` and `max_height` arguments.
//   font = Name of the font to use. Default "Liberation Sans:style=Bold"
//   letterspacing_ref = Proportion of `$refchar_width` to be used to calculate letter spacing. Default: 1.0
//   letterspacing_em = Proportion of font's em-box to be used to calculate letter spaciing. Default: 1.0
//   vfit = Determines how the vertical size of the block of text is calculated for vertical alignment, accounting for `line_spacing` and `para_spacing`. When set to "nominal", the nominal ascender at the top and nominal descender at the bottom is used. When set to "tight", the actual ascender at the top and descender at the bottom is used. Default: "nominal"
//   direction = Text direction, "ltr" (left to right) or "rtl" (right to left). This matters for kerning. Default: "ltr"
//   line_spacing = Proportion of font's interline height for vertical spacing between lines in a paragraph. Default: 1.0
//   para_spacing = Proportion of font's interline height for vertical spacing between paragraphs. Each line in the text is considered to be a paragraph. Because there is no word-wrapping when fitting text into the given bounds, line spacing is assumed to be the same as paragraph spacing. Default: 1.0
// Example: Various ways to find a font that causes the text to fit within the given constraint. The default font is "Liberation Sans:style=Bold" if not specified.
//   
//   // returns 9.001
//   size1 = fit_font_size("Fitting to a width", max_width=100);
//   //
//   // returns 9.276
//   size2 = fit_font_size("Fitting multi-line\ntext to a width", max_width=100);
//   //
//   // returns 12.888
//   size3 = fit_font_size("Fitting to a height", max_height=20);
//   //
//   // returns 6.3511
//   size4 = fit_font_size("Fitting multi-line\ntext to a height", max_height=20);
//   //
//   // returns 5.592
//   size5 = fit_font_size("Fitting multi-line\ntext to a width and height", box=[100,40]);
function fit_font_size(text, max_width=INF, max_height=INF, box,
    font="Liberation Sans:style=bold", letterspacing_ref=undef, letterspacing_em=undef,
    vfit="nominal", direction="ltr", line_spacing=1, para_spacing=1) =
assert(vfit=="max" || vfit=="nominal" || vfit=="tight", "\nfit_font_size(): vfit must be \"max\", \"nominal\", or \"tight\"")
let(
    wid = is_num(box.x) ? box.x : max_width,
    ht = is_num(box.y) ? box.y : max_height,
    err1 = assert(is_finite(wid) || is_finite(ht), "\nfit_font_size(): One or both of max_width and max_height must be finite."),
    err2 = assert(wid>0 && ht>0, "\nfit_font_size(): max_width and max_height must be greater than zero."),
    nls = num_defined([letterspacing_ref, letterspacing_em]),
    ds = assert(nls <= 1, "\nfit_font_size(): At most one of letterspacing_ref or letterspacing_em can be defined."),
    lspc_ref = nls==0 ? 1.0 : letterspacing_ref,
    lspc_em = is_undef(lspc_ref) && is_undef(letterspacing_em) ? 1.0 : letterspacing_em,
    fd10 = _fontdata(font, osize=10),
    // don't actually wrap multi-line text, but pass to _textwrap to get all the metadata
    wrapobj = _textwrap(text, width=INF, optimize=false, indent=0, fontdata=fd10, rtl=(direction=="rtl")),
    baselines = _baselines(wrapobj, line_spacing, para_spacing, fd10.interline),
    ilast = len(wrapobj) - 1,
    vboxsize = vfit=="tight" ?
        wrapobj[0].textobj.ascent + baselines[0] - wrapobj[ilast].textobj.descent - baselines[ilast]
        : fd10.nominal.ascent + baselines[0] - fd10.nominal.descent - baselines[ilast],
    htight = max([ for(i=[0:len(wrapobj)-1]) wrapobj[i].textobj.boxwidth ])
) 9.999 * min(wid / htight, ht / vboxsize); // multiplying by 10 can introduce roundoff that overflows width in _textwrap()



/// Internal function: _textobj()
///   Given a simple string without newlines, a font spec, and letter spacing spec, return an object
//    containing font metrics and character positions.
///   The object returned has these properties:
///   * text: the line of text being represented, reversed if fontdata.direction="rtl"
///   * charpos: array of character positions for each character in the text
///   * ascent: the ascentfor this line of text
///   * descent: the descent for this line of text
///   * boxwidth: the width of the text
///   * nominal_boxheight: the nominal height of the bounding box using the fontmetrics nominal ascent and descent
///   * actual_boxheight: the actual height of the bounding box using the text's own ascent and descent
///   .
///   The font sizes in the argument list are mutually exclusive; exactly one must be passed.
/// Arguments:
///   txt = line of text, containing displayable characters, free of newlines
///   fontdata = object returned from _fontdata()
///   spcadd = amount to increase size of a space character (for full justification)
function _textobj(txt, fontdata, spcadd=0) =
let(
    osiz = fontdata.font.size,
    spacer = fontdata.spacer,
    fontname = str(fontdata.font.family, ":style=", fontdata.font.style),
    direction = fontdata.direction,
    language = fontdata.language,
    script = fontdata.script,
    advance = [ // single character widths (account for nonbreaking space as a normal space)
        for(i=[0:len(txt)-1]) textmetrics(txt[i], osiz, fontname, direction, language, script).advance[0]
            + (txt[i] == " " || txt[i] == "\u00A0" ? spcadd : 0)
    ],
    kern = [ 0, // position changes for each character
        for(i=[0:len(txt)-2]) let(
            c1 = txt[i]=="\u00A0" ? " " : txt[i],     // kerning for a normal space is different
            c2 = txt[i+1]=="\u00A0" ? " " : txt[i+1], // from a nonbreaking space; use normal space
            wid2 = textmetrics(str(c1,c2), osiz, fontname, direction, language, script).advance[0]
                + (c1 == " " ? spcadd : 0)
                + (c2 == " " ? spcadd : 0)
        ) wid2 - advance[i] - advance[i+1]
    ],
    newadv = [ for(i=[0:len(txt)-2]) advance[i] + kern[i+1] + spacer], // new widths
    charpos = [0, each cumsum(newadv) ], // horizontal position of each character
    tm = textmetrics(txt, osiz, fontname, direction, language, script, valign="baseline", spacing=1)
) object(text=txt, charpos=charpos, /* charwid=advance, kern=kern, */
    ascent=tm.ascent, descent=tm.descent,
    boxwidth = charpos[len(charpos)-1] + advance[len(advance)-1],
    nominal_boxheight = fontdata.nominal.ascent - fontdata.nominal.descent,
    actual_boxheight = tm.ascent-tm.descent);



/// Internal function: _fontdata()
/// Get information about a font, given a size and a spacing.
/// Returns a fontmetrics object, with the `font` property containing the properties:
///    osize = OpenSCAD font size calculated from one of the size inputs
///    spacer = amount of space to insert between each character
///    spc = size of a space character, shortcut for use in wordwrapping
/// The `spacer` property is a constant value calculated from the `spacing` parameter, using
/// a proportion of average glyph width size weighted by frequency of occurrence in English.
/// Inserting a constant space between characters results in more natural and uniform spacing
/// than simply multiplying the width of each glyph by the `spacing` proportion, which results
/// in too much spacing for wide characters and too little spacing for narrow characters.
/// When `spacing=1`, `spacer=0`, which results in the same behavior as the `spacing`
/// argument in OpenSCAD's `text()` module.
/// The size parameters `osize`, `nom_height`, `iline_height`, `em72`, and `cap_height` are mutually exclusive;
/// one and only one of them must be specified.
/// The `cap_height` parameter is probably the most useful size specification. The special
/// variable `$refchar_cap` is used as the reference character for a capital letter, and
/// defaults to `H`. If your text uses only numbers you may want to pass `$refchar_cap=0` in the 
/// argument list.
/// Arguments:
///    font = Name of font. Default: "Liberation Sans:style=Bold"
///    osize = OpenSCAD font size used in OpenSCAD's `text()`.
///    cap_height = Height of a capital letter proportional to $refchar_cap
///    nom_height = Height of characters proportional to nominal ascender to nominal descender.
///    full_height = Height of characters proportional to max ascender to max descender
///    iline_height = Height of characters proportional to interline height
///    em_size = Height of characters proportional to em size
///    letterspacing, letterspacing_em = same as in write()
///    direction, language, script = same as in text()
/*
// Following is used just for estimating average character spacing in _fontdata().
// Proportions are roughly similar in most other languages.
_letter_occur_lc_en = "etaoinshrdlcumwfgypbvkjxqz";
_letter_occur_uc_en = "ETAOINSHRDLCUMWFGYPBVKJXQZ";
_letter_freq_en = [ // adds up to 1.0
    0.12702, 0.09056, 0.08167, 0.07507, 0.06966,
    0.06749, 0.06327, 0.06094, 0.05987, 0.04253,
    0.04025, 0.02782, 0.02758, 0.02407, 0.0236,
    0.02228, 0.02015, 0.01974, 0.01929, 0.01492,
    0.00978, 0.00772, 0.00153, 0.0015, 0.00095, 0.00074
];
*/
function _fontdata(font="Liberation Sans:style=Bold", osize, cap_height, nom_height, full_height, iline_height, em_size, letterspacing, letterspacing_em, letterspacing_ref, direction, language, script) =
    assert(num_defined([letterspacing, letterspacing_em, letterspacing_ref]) <= 1, "\nAt most one of letterspacing, letterspacing_em, or letterspacing_ref can be defined.")
    let(
        osiz = get_font_size(font, osize, cap_height, nom_height, full_height, iline_height, em_size),
        fm = fontmetrics(osiz, font),
        tmc = textmetrics($refchar_width, osiz, font, direction, language, script, spacing=1),
        spacer = is_def(letterspacing_em) ? (letterspacing_em / 0.72 - 1) * osiz
            : is_def(letterspacing_ref) ? (letterspacing_ref - 1) * tmc.advance[0]
            : is_def(letterspacing) ? letterspacing : 0
        /* spacer = sum([ // weighted average letter spacing using English character frequency
            for(i=[0:25]) let(
                p = _letter_freq_en[i],
                al = textmetrics(_letter_occur_lc_en[i], osiz).advance[0],
                au = textmetrics(_letter_occur_uc_en[i], osiz).advance[0]
            ) p*(al+au)/2]) * (spacing-1)
        */
    ) object(fm, 
        spacer = spacer,
        spc = textmetrics(" ", osiz, font).advance[0],
        //refcharspace = tmc.advance[0] - tmc.size[0],
        font = object(fm.font, size=osiz),
        direction = direction,
        language = language,
        script = script);



/// Internal function: _textwrap()
/// Usage:
//   text_array = _textwrap(string, width, [optimize=], [indent=], [fontdata=], [rtl=]);
/// Description:
//   Return an array of wrap objects, where each object represents an array of substrings of the original
//   text such that each substring fits within a specified width when displayed with the specified font.
//   If `optimize=true` (usual default), text wrapping is optimized so that each line of text is roughly
//   the same length to minimize the occurrence of an unusually short final line.
//   The actual overall width of the final text always is less than or equal to the requested width.
//   You can use `{{text_array_size()}}` to get the actual bounding box of the wrapped text.
//   Multple paragraphs are returned if the `string` argument contains newline (`\n`) characters that
//   split the string. To insert a blank line, use two newlines with a space in between (`\n \n`).
/// Arguments:
//   string = The text to render. May be a simple string, a string with `\n` newlines, or an array of both kinds of strings. Any leading or trailing non-space whitespace are stripped before word-wrapping. Use `\u00a0` for a non-breaking space.
//   width = the maximum width of a line of text in display units.
//   ---
//   optimize = When false, tries to fit as many words as possible on each successive line, which may result in a "widow" (a word all by itself) on the last line. When true, attempts to make the wrapped lines more equal in length.  Default: `true`
//   indent = If positive, first line of paragraph is indented by this amount. If negative, first line is effectively outdented by indenting subsequent lines by the positive value of this amount. Default: 0
//   fontdata = structure returned from _fontdata()
//   rtl = true if text is to be rendered right-to-left

function _textwrap(texts, width=INF, optimize=true, indent=0, fontdata=undef, rtl=false) =
    let(
        strings = _strings_to_array(texts),
        lines = [
            for(line = strings)
                let(tx = str(line, " ")) // make last word end in a space
                    object(text=tx, textobj=_textobj(tx, fontdata)), 
        ],
        spc = fontdata.spc + fontdata.spacer,
        spacepos = [ // at each space, record character index and position
            for (p=lines) let(tx = p.text, charpos = p.textobj.charpos) [
                if(len(charpos) < 2)
                    [0, 0]//, "spc"]
                else for(i=[0:len(charpos)-1])
                    if(tx[i]==" ") [i, charpos[i]]
            ]
        ],
        wlens = [ for(c=spacepos) [ c[0][1], if(len(c)>1) for(i=[1:len(c)-1]) c[i][1]-c[i-1][1] ] ],
        maxwordwid = max(flatten(wlens)) // length of longest word in text
) assert(maxwordwid <= width, str("\n",maxwordwid,">",width,": A word exceeds the specified width."))
let(
    breaks_unop = [ for(sp=spacepos) _getbreaks(width, spc, sp, indent) ],
    breaks = optimize ?
        let(nlines = sum([for(b=breaks_unop) len(b.breakspc)]))
        _wrap_optimize(nlines, maxwordwid, spacepos, breaks_unop, width, spc, indent)
        : breaks_unop,
    wrapped = [
        for(i=[0:len(lines)-1])
            let(line = substr(lines[i].text, 0, len(lines[i].text)))
                _str_split_at_breaks(line, breaks[i].breakspc)
    ]
) [
    for(i=[0:len(wrapped)-1])
        let(firstline=0, lastline=len(wrapped[i])-1, inc=1)
        for(j=[firstline:inc:lastline])
            let(tx = len(wrapped[i][j])==0 ? " " : wrapped[i][j])
            object(
                textline = tx,
                textobj = _textobj(tx, fontdata),
                indent = j != firstline ? 0 : indent,
                newparagraph = (j==firstline)
            )
];



/// Internal function: _strings_to_array()
/// Synopsis: Converts a string or paragraph array to a flat string array, splitting at newlines.
/// Topics: Text
/// See Also: write()
/// Usage:
///   text_array = _strings_to_array(string);
/// Description:
//   Given a simple string, a string containing `\n` characters, an array of either of those two kinds of strings,
//   or an array that includes strings and other embedded string arrays,
//   returns a flat array of simple strings, split appropriately on newline characters.
//   Any leading or trailing non-space-character white space is stripped out from each string in the returned array.
/// Arguments:
//   string = Input string or string array, which may contain embedded newlines.
function _strings_to_array(strings) = let(
    list = is_string(strings) ? [strings] : is_list(strings) ? full_flatten(strings) : undef,
    err = assert(is_string(list[0]), "\nNot a string or list of strings.")
) [
    for(s=list) each [
        for(p = str_split(s, "\n", false))
                str_strip(p, "\t\r\n")
    ]
];



/// Private recursive function: _getbreaks() - called by _textwrap() and _wrap_optimize()
/// Given a wrap width, size of a space, and a list of space starting positions,
/// break the lines to wrap within the width, and return an object containing three arrays,
/// each with one element per line: spacepos index of break, indent of line.
function _getbreaks(width, spc, spacepos, indent, i=0, startwid=0, breaks=[], breakpos=[]) =
let(ind = (indent>0 && startwid==0 ? indent : 0) + (indent<0 && startwid>0 ? -indent : 0))
    i > len(spacepos)-1 ? //let(x=echo("in getbreaks i>len(spacepos)-1", i, breaks))
        object(breakspc=concat(breaks, spacepos[i-1][0]),
            breakpos = concat(breakpos, spacepos[i-1][1] - startwid + ind))
    : spacepos[i][1] - startwid + ind > width ? //let(x=echo("in getbreaks width exceed", i, breaks))
        _getbreaks(width, spc, spacepos, indent, i, spacepos[max(0,i-1)][1]+spc,
            concat(breaks, spacepos[i-1][0]),
            concat(breakpos, spacepos[i-1][1] - startwid + ind))
    : //let(x=echo("in getbreaks continue", i, breaks))
        _getbreaks(width, spc, spacepos, indent, i+1, startwid, breaks, breakpos);



/// Private recursive function: _string_split_at_breaks() - called by _textwrap()
/// Given a single string and a list of space location line breaks for that string, return a list of strings.
function _str_split_at_breaks(string, break, i=0, res=[]) =
    i >= len(break) ? res
    : i==0 ? _str_split_at_breaks(string, break, 1, [substr(string, 0, break[i])])
    : _str_split_at_breaks(string, break, i+1,
        concat(res, substr(string, break[i-1]+1, break[i]-break[i-1]-1))); // strip leading and trailing space


/// Private recursive function: _wrap_optimize(), called by _textwrap()
/// Recursively find minimum wrap width in all paragraphs represented by breaks[]
/// such that the total number of lines of wrapped text does not increase.
/// Arguments:
///   maxlines = total number of lines not to exceed
///   minwid = minimum wrap width allowable (length of longest word)
///   spacepos = array of character positions of spaces
///   breaks = a _get_breaks() object representing no more than maxlines line breaks
///   reqwid = requested wrap width
///   spc = length of a space
///   cumlen = cumulative list of line lengths with same paragraph structure as line_indexes
///   iter = maximum number of recursions allowed
function _wrap_optimize(maxlines, minwid, spacepos, breaks, reqwid, spc, indent, iter=20) =
    let(
        newbreaks = [ for(sp=spacepos) _getbreaks(reqwid, spc, sp, indent) ],
        nlines = sum([ for(b=newbreaks) len(b.breakspc) ]),
        maxlinewid = max([ for(b=newbreaks) max(b.breakpos) ]),
        newreqwid = maxlinewid - 0.01
    )
    iter<=0 || nlines>maxlines || newreqwid<=minwid
        ? breaks
        : _wrap_optimize(maxlines, minwid, spacepos, newbreaks, newreqwid, spc, indent, iter-1);



/// Function: _str_replace_edges()
/// Synopsis: Returns a string with the specified leading and trailing characters replaced with a character
/// Topics: Strings
/// See Also: str_join(), str_strip(), repeat()
/// Usage:
///    result = str_replace_edges(string, edge_chars, replacement);
/// Description:
///   Returns a string with any leading or trailing characters specified in the string `edge_chars` replaced by the character specified in `replacement`.
///   This can be used, for example, to replace leading and trailing spaces with the nonbreaking space `\u00a0`.
/// Arguments:
///   string = The string to search
///   edge_chars = A single character or a string specifying the characters to search for in the head and tail of `string`
///   replacement = Character to replace any edge characters found
/// Examples
///   s1 = str_replace_edges("  hello  ", " ", "\u00A0"); // returns "\u00A0\u00A0hello\u00A0\u00A0"
///   s2 = str_replace_edges("\t hello \t", " \t", "-");  // returns "--hello--"
///   s3 = str_replace_edges("ab-cd-", "ab-", "?");       // returns "???cd?"

function _edgecount(s, edge_chars, i=0, from_start=true) = // Count consecutive chars in s that are in edge_chars
  let (
    idx = from_start ? i : len(s) - 1 - i,
    done = from_start ? idx >= len(s) : idx < 0
  )
  done || str_find(edge_chars, s[idx]) == undef ? i : _edgecount(s, edge_chars, i + 1, from_start);

function _str_replace_edges(string, edge_chars, replacement) =
  let (
    h = _edgecount(string, edge_chars),
    t = _edgecount(string, edge_chars, from_start=false),
    total = h + t
  )
  total >= len(string)
    ? str_join(repeat(replacement, len(string)))
    : str(str_join(repeat(replacement, h)),
          substr(string, h, len(string) - total),
          str_join(repeat(replacement, t)));



// Section: Legacy text operations
//   These modules are included for compatibility with older code that uses BOSL2.
//   The {{write()}} and {{write3d()}} modules can be used instead of `text()` and `text3d()`.
//   .
//   Use the legacy modules if you need:
//   * compatibility with the argument list in OpenSCAD's `text()`.
//   * compatibility with OpenSCAD 2021.01 (non-snapshot build).
//   * the ability to render text along a path.


// Module: text()
// Synopsis: Creates an attachable block of text.
// SynTags: Geom
// Topics: Attachments, Text
// See Also: text3d(), attachable()
// Usage:
//   text(text, [size], [font], ...);
// Description:
//   Creates a 3D text block that can be attached to other attachable objects.
//   You cannot attach children to text.
//   .
//   To find the fonts that you have available in your OpenSCAD installation,
//   go to the Help menu and select "Font List".  
// Arguments:
//   text = Text to create.
//   size = The font will be created at this size divided by 0.72.   Default: 10
//   font = Font to use.  Default: "Liberation Sans" (standard OpenSCAD default)
//   ---
//   halign = If given, specifies the horizontal alignment of the text.  `"left"`, `"center"`, or `"right"`.  Overrides `anchor=`.
//   valign = If given, specifies the vertical alignment of the text.  `"top"`, `"center"`, `"baseline"` or `"bottom"`.  Overrides `anchor=`.
//   spacing = The relative spacing multiplier between characters.  Default: `1.0`
//   direction = The text direction.  `"ltr"` for left to right.  `"rtl"` for right to left. `"ttb"` for top to bottom. `"btt"` for bottom to top.  Default: `"ltr"`
//   language = The language the text is in.  Default: `"en"`
//   script = The script the text is in.  Default: `"latin"`
//   em = Set the standard font size (the em) to this value without scaling by 0.72  
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"baseline"`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Named Anchors:
//   "baseline" = Anchors at the baseline of the text, at the start of the string.
//   str("baseline",VECTOR) = Anchors at the baseline of the text, modified by the X and Z components of the appended vector.
// Examples(2D):
//   text("Foobar", size=10);
//   text("Foobar", size=12, font="Liberation Mono");
//   text("Foobar", anchor=CENTER);
//   text("Foobar", anchor=str("baseline",CENTER));
// Example: Using line_copies() distributor
//   txt = "This is the string.";
//   line_copies(spacing=[10,-5],n=len(txt))
//       text(txt[$idx], size=10, anchor=CENTER);
// Example: Using arc_copies() distributor
//   txt = "This is the string";
//   arc_copies(r=50, n=len(txt), sa=0, ea=180)
//       text(select(txt,-1-$idx), size=10, anchor=str("baseline",CENTER), spin=-90);
module text(text, size, font, direction="ltr", language="en", script="latin", halign, valign, spacing=1.0,em,anchor="baseline", spin=0) {
    no_children($children);
    pass_em = version_num() >= 20260314;
    if (!pass_em && num_defined([size,em])==2)
       echo("\n\u26A0WARNING: text: \"size\" ignored when \"em\" is set");
    size = pass_em ? size
         : first_defined([size, u_mul(em,0.72),10]);
    dummy1 =
        assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Invalid anchor: ",anchor))
        assert(is_finite(spin), str("Invalid spin: ",spin));
    anchor = default(anchor, CENTER);
    geom = attach_geom(size=[1,1],two_d=true);    
    anch = !any([for (c=anchor) c=="["])? anchor :
        let(
            parts = str_split(str_split(str_split(anchor,"]")[0],"[")[1],","),
            vec = [for (p=parts) parse_float(str_strip(p," ",start=true))]
        ) vec;
    ha = halign!=undef? halign
       : anchor=="baseline"? "left"
       : anchor==anch && is_string(anchor)? "center"
       : anch.x<0? "left"
       : anch.x>0? "right" 
       : "center";
    va = valign != undef? valign
       : starts_with(anchor,"baseline")? "baseline"
       : anchor==anch && is_string(anchor)? "center"
       : anch.y<0 || (anch.z<0 && anch.y==0)? "bottom"
       : anch.y>0 || (anch.z>0 && anch.y==0) ? "top"
       : "center";
    m = _attach_transform(CENTER,spin,undef,geom);
    multmatrix(m) {
        $parent_anchor = anchor;
        $parent_spin   = spin;
        $parent_orient = undef;
        $parent_geom   = geom;
        $parent_size   = _attach_geom_size(geom);
        $attach_to   = undef;
        if (_is_shown()){
            _color($color) _show_ghost() {
               if(pass_em)
                  _text(
                    text=text, size=size, font=font,
                    halign=ha, valign=va, spacing=spacing,
                    direction=direction, language=language,
                    script=script, em=em);
               else
                _text(
                    text=text, size=size, font=font,
                    halign=ha, valign=va, spacing=spacing,
                    direction=direction, language=language,
                    script=script
                );
            }
        }
    }
}



// Module: text3d()
// Synopsis: Creates an attachable 3d text block.
// SynTags: Geom
// Topics: Attachments, Text
// See Also: path_text(), text() 
// Usage:
//   text3d(text, [h], [size], [font], [em=], [language=], [script=], [direction=], [atype=], [anchor=], [spin=], [orient=]);
// Description:
//   Creates a 3D text block that supports anchoring and single-parameter attachment to attachable objects.  You cannot attach children to text.
//   .
//   To find the fonts that you have available in your OpenSCAD installation,
//   go to the Help menu and select "Font List".
// Arguments:
//   text = Text to create.
//   h / height / thickness = Extrusion height for the text.  Default: 1
//   size = The font is created at this size divided by 0.72.   Default: 10
//   font = Font to use.  Default: "Liberation Sans" (standard OpenSCAD default)
//   ---
//   em = Set the standard font size (the em) to this value without scaling by 0.72  
//   spacing = The relative spacing multiplier between characters.  Default: `1.0`
//   direction = The text direction.  `"ltr"` for left to right.  `"rtl"` for right to left. `"ttb"` for top to bottom. `"btt"` for bottom to top.  Default: `"ltr"`
//   language = The language the text is in.  Default: `"en"`
//   script = The script the text is in.  Default: `"latin"`
//   atype = Change vertical center between "baseline" and "ycenter".  Default: "baseline"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"baseline"`
//   center = Center the text.  Equivalent to `atype="center", anchor=CENTER`.  Default: false
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Anchor Types:
//   baseline = Anchor center is relative to text baseline
//   ycenter = Anchor center is relative to the actual y direction center of the text
// Examples:
//   text3d("Fogmobar", h=3, size=10);
//   text3d("Fogmobar", h=2, size=12, font=":style=bold");
//   text3d("Fogmobar", h=2, anchor=CENTER);
//   text3d("Fogmobar", h=2, anchor=CENTER, atype="ycenter");
//   text3d("Fogmobar", h=2, anchor=RIGHT);
//   text3d("Fogmobar", h=2, anchor=RIGHT+BOT, atype="ycenter");
module text3d(text, h, size, font, spacing=1.0, direction="ltr", language="en", script="latin",
              height, thickness, atype, center=false, em,
              anchor, spin=0, orient=UP) {
    no_children($children);
    h = one_defined([h,height,thickness],"h,height,thickness",dflt=1);
    checks = 
        assert(is_undef(atype) || in_list(atype,["ycenter","baseline"]), "\natype must be \"ycenter\" or \"baseline\".")
        assert(is_bool(center))
        assert(is_undef($attach_to),"\ntext3d() does not support parent-child anchor attachment with two parameters.")
        assert(num_defined([size,em])<2, "Cannot give both \"size\" and \"em\"");
    size = first_defined([size, u_mul(em,0.72), 10]);
    atype = default(atype, center?"ycenter":"baseline");
    anchor = default(anchor, center?CENTER:LEFT);
    geom = attach_geom(size=[size,size,h]);
    ha = anchor.x<0? "left" 
       : anchor.x>0? "right" 
       : "center";
    va = anchor.y<0? "bottom" 
       : anchor.y>0? "top" 
       : atype=="baseline"? "baseline"
       : "center";
    m = _attach_transform([0,0,anchor.z],spin,orient,geom);
    multmatrix(m) {
        $parent_anchor = anchor;
        $parent_spin   = spin;
        $parent_orient = orient;
        $parent_geom   = geom;
        $parent_size   = _attach_geom_size(geom);
        $attach_to   = undef;
        if (_is_shown()) {
            _color($color) _show_ghost() {
                linear_extrude(height=h, center=true)
                    _text(
                        text=text, size=size, font=font,
                        halign=ha, valign=va, spacing=spacing,
                        direction=direction, language=language,
                        script=script
                    );
            }
        }
    }
}


// This could be replaced with _cut_to_seg_u_form
function _cut_interp(pathcut, path, data) =
  [for(entry=pathcut)
    let(
       a = path[entry[1]-1],
        b = path[entry[1]],
        c = entry[0],
        i = max_index(v_abs(b-a)),
        factor = (c[i]-a[i])/(b[i]-a[i])
    )
    (1-factor)*data[entry[1]-1]+ factor * data[entry[1]]
  ];


// Module: path_text()
// Synopsis: Creates 2d or 3d text placed along a path.
// SynTags: Geom
// Topics: Text, Paths, Paths (2D), Paths (3D), Path Generators, Path Generators (2D)
// See Also, text(), text2d()
// Usage:
//   path_text(path, text, [size], [thickness], [font], [lettersize=], [offset=], [reverse=], [normal=], [top=], [textmetrics=], [kern=])
// Description:
//   Place the text letter by letter onto the specified path using textmetrics (if available and requested)
//   or user specified letter spacing.  The path can be 2D or 3D.  In 2D the text appears along the path with letters upright
//   as determined by the path direction.  In 3D by default letters are positioned on the tangent line to the path with the path normal
//   pointing toward the reader.  The path normal points away from the center of curvature (the opposite of the normal produced
//   by path_normals()).  Note that this means that if the center of curvature switches sides, the text flips upside down.
//   If you want text on such a path you must supply your own normal or top vector.
//   .
//   Text appears starting at the beginning of the path, so if the 3D path moves right to left,
//   then a left-to-right reading language displays in the wrong order (for a 2D path text appears upside down).
//   The text for a 3D path appears positioned to be read from "outside" of the curve (from a point on the other side of the
//   curve from the center of curvature).  If you need the text to read properly from the inside, you can set reverse to
//   true to flip the text, or supply your own normal.
//   .
//   If you do not have the experimental textmetrics feature enabled then you must specify the space for the letters
//   using lettersize, which can be a scalar or array.  You can easily get good results by using
//   a monospace font such as "Liberation Mono".  Note that even with text metrics, spacing may be different because path_text()
//   doesn't do kerning to adjust positions of individual glyphs.  Also if your font has ligatures they won't be used.
//   .
//   By default letters appear centered on the path.  The offset can be specified to shift letters toward the reader (in
//   the direction of the normal).
//   .
//   You can specify your own normal by setting `normal` to a direction or a list of directions.  Your normal vector should
//   point toward the reader.  You can also specify
//   top, which directs the top of the letters in a desired direction.  If you specify your own directions and they
//   are not perpendicular to the path, then the direction you specify takes priority and the
//   letters will not rest on the tangent line of the path.  Note that the normal or top directions that you
//   specify must not be parallel to the path.
//   .
//   Historically fonts were specified by their "body size", the height of the metal body
//   on which the glyphs were cast.  This means the size was an upper bound on the size
//   of the font glyphs, not a direct measurement of their size.  In digital typesetting,
//   the metal body is replaced by an invisible box, the em square, whose side length is
//   defined to be the font's size.  The glyphs can be contained in that square, or they
//   can extend beyond it, depending on the choices made by the font designer.  As a
//   result, the meaning of font size varies between fonts: two fonts at the "same" size
//   can differ significantly in the actual size of their characters.  Typographers
//   customarily specify the size in the units of "points".  A point is 1/72 inch.  In
//   OpenSCAD, you specify the size in OpenSCAD units (often treated as millimeters for 3d
//   printing), so if you want points you need to perform a suitable unit conversion.
//   In addition, the OpenSCAD font system has a bug: if you specify size=s you
//   instead get a font whose size is s/0.72.  For many fonts this means the size of
//   capital letters is approximately equal to s, because it is common for fonts to
//   use about 70% of their height for the ascenders in the font.  To get the customary
//   font size, you should multiply your desired size by 0.72.
//   .
//   To find the fonts that you have available in your OpenSCAD installation,
//   go to the Help menu and select "Font List".
// Arguments:
//   path = path to place the text on
//   text = text to create
//   size = The font is created at this size divided by 0.72.   
//   thickness / h / height = thickness of letters (not allowed for 2D path)
//   font = Font to use.  Default: "Liberation Sans" (standard OpenSCAD default)
//   ---
//   lettersize = scalar or array giving size of letters
//   center = center text on the path instead of starting at the first point.  Default: false
//   offset = distance to shift letters "up" (toward the reader).  Not allowed for 2D path.  Default: 0
//   normal = direction or list of directions pointing toward the reader of the text.  Not allowed for 2D path.
//   top = direction or list of directions pointing toward the top of the text
//   reverse = reverse the letters if true.  Not allowed for 2D path.  Default: false
//   textmetrics = if set to true and lettersize is not given then use the experimental textmetrics feature.  You must be running a dev snapshot that includes this feature and have the feature turned on in your preferences.  Default: false
//   valign = align text to the path using "top", "bottom", "center" or "baseline".  You can also adjust position with a numerical offset as in "top-5" or "bottom+2".  This works only with textmetrics enabled.  You can give a simple numerical offset, which is relative to the baseline and works even without textmetrics.  Default: "baseline"
//   kern = scalar or array giving spacing adjusments between each letter.  If it's an array it should have one less entry than the text string.  Default: 0
//   language = text language, passed to OpenSCAD `text()`.  Default: "en"
//   script = text script, passed to OpenSCAD `text()`.  Default: "latin" 
// Example(3D,NoScales):  The examples use Liberation Mono, a monospaced font.  The width is 1/1.2 times the specified size for this font.  This text could wrap around a cylinder.
//   path = path3d(arc(100, r=25, angle=[245, 370]));
//   color("red")stroke(path, width=.3);
//   path_text(path, "Example text", font="Liberation Mono", size=5, lettersize = 5/1.2);
// Example(3D,NoScales): By setting the normal to UP we can get text that lies flat, for writing around the edge of a disk:
//   path = path3d(arc(100, r=25, angle=[245, 370]));
//   color("red")stroke(path, width=.3);
//   path_text(path, "Example text", font="Liberation Mono", size=5, lettersize = 5/1.2, normal=UP);
// Example(3D,NoScales):  If we want text that reads from the other side we can use reverse.  Note we have to reverse the direction of the path and also set the reverse option.
//   path = reverse(path3d(arc(100, r=25, angle=[65, 190])));
//   color("red")stroke(path, width=.3);
//   path_text(path, "Example text", font="Liberation Mono", size=5, lettersize = 5/1.2, reverse=true);
// Example(3D,Med,NoScales): text debossed onto a cylinder in a spiral.  The text is 1 unit deep because it is half in, half out.
//   text = ("A long text example to wrap around a cylinder, possibly for a few times.");
//   L = 5*len(text);
//   maxang = 360*L/(PI*50);
//   spiral = [for(a=[0:1:maxang]) [25*cos(a), 25*sin(a), 10-30/maxang*a]];
//   difference(){
//     cyl(d=50, l=50, $fn=120);
//     path_text(spiral, text, size=5, lettersize=5/1.2, font="Liberation Mono", thickness=2);
//   }
// Example(3D,Med,NoScales): Same example but text embossed.  Make sure you have enough depth for the letters to fully overlap the object.
//   text = ("A long text example to wrap around a cylinder, possibly for a few times.");
//   L = 5*len(text);
//   maxang = 360*L/(PI*50);
//   spiral = [for(a=[0:1:maxang]) [25*cos(a), 25*sin(a), 10-30/maxang*a]];
//   cyl(d=50, l=50, $fn=120);
//   path_text(spiral, text, size=5, lettersize=5/1.2, font="Liberation Mono", thickness=2);
// Example(3D,NoScales): Here the text baseline sits on the path.  (Note the default orientation makes text readable from below, so we specify the normal.)
//   path = arc(100, points = [[-20, 0, 20], [0,0,5], [20,0,20]]);
//   color("red")stroke(path,width=.2);
//   path_text(path, "Example Text", size=5, lettersize=5/1.2, font="Liberation Mono", normal=FRONT);
// Example(3D,NoScales): If we use top to orient the text upward, the text baseline is no longer aligned with the path.
//   path = arc(100, points = [[-20, 0, 20], [0,0,5], [20,0,20]]);
//   color("red")stroke(path,width=.2);
//   path_text(path, "Example Text", size=5, lettersize=5/1.2, font="Liberation Mono", top=UP);
// Example(3D,Med,NoScales): This sine wave wrapped around the cylinder has a twisting normal that produces wild letter layout.  We fix it with a custom normal that is different at every path point.
//   path = [for(theta = [0:360]) [25*cos(theta), 25*sin(theta), 4*cos(theta*4)]];
//   normal = [for(theta = [0:360]) [cos(theta), sin(theta),0]];
//   zrot(-120)
//   difference(){
//     cyl(r=25, h=20, $fn=120);
//     path_text(path, "A sine wave wiggles", font="Liberation Mono", lettersize=5/1.2, size=5, normal=normal);
//   }
// Example(3D,Med,NoScales): The path center of curvature changes, and the text flips.
//   path =  zrot(-120,p=path3d( concat(arc(100, r=25, angle=[0,90]), back(50,p=arc(100, r=25, angle=[268, 180])))));
//   color("red")stroke(path,width=.2);
//   path_text(path, "A shorter example",  size=5, lettersize=5/1.2, font="Liberation Mono", thickness=2);
// Example(3D,Med,NoScales): We can fix it with top:
//   path =  zrot(-120,p=path3d( concat(arc(100, r=25, angle=[0,90]), back(50,p=arc(100, r=25, angle=[268, 180])))));
//   color("red")stroke(path,width=.2);
//   path_text(path, "A shorter example",  size=5, lettersize=5/1.2, font="Liberation Mono", thickness=2, top=UP);
// Example(2D,NoScales): With a 2D path instead of 3D there's no ambiguity about direction and it works by default:
//   path =  zrot(-120,p=concat(arc(100, r=25, angle=[0,90]), back(50,p=arc(100, r=25, angle=[268, 180]))));
//   color("red")stroke(path,width=.2);
//   path_text(path, "A shorter example",  size=5, lettersize=5/1.2, font="Liberation Mono");
// Example(3D,NoScales): The kern parameter lets you adjust the letter spacing either with a uniform value for each letter, or with an array to make adjustments throughout the text.  Here we show a case where adding some extra space gives a better look in a tight circle.  When textmetrics are off, `lettersize` can do this job, but with textmetrics, you'll need to use `kern` to make adjustments relative to the text metric sizes.
//   path = path3d(arc(100, r=12, angle=[150, 450]));
//   color("red")stroke(path, width=.3);
//   kern = [1,1.2,1,1,.3,-.2,1,0,.8,1,1.1];
//   path_text(path, "Example text", font="Liberation Mono", size=5, lettersize = 5/1.2, kern=kern, normal=UP);

module path_text(path, text, font, size, thickness, lettersize, offset=0, reverse=false, normal, top, center=false,
                 textmetrics=false, kern=0, height,h, valign="baseline", language, script)
{
  no_children($children);
  dummy2=assert(is_path(path,[2,3]),"\nMust supply a 2d or 3d path.")
         assert(num_defined([normal,top])<=1, "\nCannot define both \"normal\" and \"top\".")
         assert(all_positive([size]), "\nMust give positive text size.");
  dim = len(path[0]);
  normalok = is_undef(normal) || is_vector(normal,3) || (is_path(normal,3) && len(normal)==len(path));
  topok = is_undef(top) || is_vector(top,dim) || (dim==2 && is_vector(top,3) && top[2]==0)
                        || (is_path(top,dim) && len(top)==len(path));
  dummy4 = assert(dim==3 || !any_defined([thickness,h,height]), "\nCannot give a thickness or height with 2d path.")
           assert(dim==3 || !reverse, "\nReverse not allowed with 2d path.")
           assert(dim==3 || offset==0, "\nCannot give offset with 2d path.")
           assert(dim==3 || is_undef(normal), "\nCannot define \"normal\" for a 2d path, only \"top\".")
           assert(normalok,"\n\"normal\" must be a vector or path compatible with the given path.")
           assert(topok,"\n\"top\" must be a vector or path compatible with the given path.");
  thickness = one_defined([thickness,h,height],"thickness,h,height",dflt=1);
  normal = is_vector(normal) ? repeat(normal, len(path))
         : is_def(normal) ? normal
         : undef;

  top = is_vector(top) ? repeat(dim==2?point2d(top):top, len(path))
         : is_def(top) ? top
         : undef;

  kern = force_list(kern, len(text)-1);
  dummy3 = assert(is_list(kern) && len(kern)==len(text)-1, "\nkern must be a scalar or list whose length is len(text)-1.");

  lsize = is_def(lettersize) ? force_list(lettersize, len(text))
        : textmetrics ? [for(letter=text) let(t=textmetrics(letter, font=font, size=size)) t.advance[0]]
        : assert(false, "\ntextmetrics disabled: Must specify letter size.");
  lcenter = convolve(lsize,[1,1]/2)+[0,each kern,0] ;
  textlength = sum(lsize)+sum(kern);

  ascent = !textmetrics ? undef
         : textmetrics(text, font=font, size=size).ascent;
  descent = !textmetrics ? undef
          : textmetrics(text, font=font, size=size).descent;

  vadjustment = is_num(valign) ? -valign
              : !textmetrics ? assert(valign=="baseline","\nvalign requires textmetrics support.") 0
              : let(
                     table = [
                              ["baseline", 0],
                              ["top", -ascent],
                              ["bottom", descent],
                              ["center", (descent-ascent)/2]
                             ],
                     match = [for(i=idx(table)) if (starts_with(valign,table[i][0])) i]
                )
                assert(len(match)==1, "\nInvalid valign value.")
                table[match[0]][1] - parse_num(substr(valign,len(table[match[0]][0])));

  dummy1 = assert(textlength<=path_length(path),"\nPath is too short for the text.");

  start = center ? (path_length(path) - textlength)/2 : 0;
   
  pts = path_cut_points(path, add_scalar(cumsum(lcenter),start), direction=true);

  usernorm = is_def(normal);
  usetop = is_def(top);
  normpts = is_undef(normal) ? (reverse?1:-1)*column(pts,3) : _cut_interp(pts,path, normal);
  toppts = is_undef(top) ? undef : _cut_interp(pts,path,top);
  attachable(){
    for (i = idx(text)) {
      tangent = pts[i][2];
      checks =
          assert(!usetop || !approx(tangent*toppts[i],norm(top[i])*norm(tangent)),
                 str("\nSpecified top direction parallel to path at character ",i))
          assert(usetop || !approx(tangent*normpts[i],norm(normpts[i])*norm(tangent)),
                 str("\nSpecified normal direction parallel to path at character ",i));
      adjustment = usetop ?  (tangent*toppts[i])*toppts[i]/(toppts[i]*toppts[i])
                 : usernorm ?  (tangent*normpts[i])*normpts[i]/(normpts[i]*normpts[i])
                 : [0,0,0];
      move(pts[i][0]) {
        if (dim==3) {
          frame_map(
            x=tangent-adjustment,
            z=usetop ? undef : normpts[i],
            y=usetop ? toppts[i] : undef
          ) up(offset-thickness/2) {
            linear_extrude(height=thickness)
              back(vadjustment)
              {
              left(lsize[i]/2)
                text(text[i], font=font, size=size, language=language, script=script);
              }
          }
        } else {
            frame_map(
              x=point3d(tangent-adjustment),
              y=point3d(usetop ? toppts[i] : -normpts[i])
            ) left(lsize[i]/2) {
                text(text[i], font=font, size=size, language=language, script=script);
            }
        }
      }
    }
    union();
  }
}


