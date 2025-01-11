//////////////////////////////////////////////////////////////////////
// LibFile: text.scad
//   This file contains useful utilities for managing text objects.
//   * A replacement module for OpenSCAD's `text()` is povided to make the block of text attachable to children.
//   * Text wrapping between specified margins can be done with proportionally spaced fonts
//   (requires an OpenSCAD build more recent than 2021-08-16) or fixed-width fonts (all versions),
//   and an array of wrapped text can be rendered as an attachable object as with `text()`.
//   * Create attachable 3D text blocks, and arrange 2D or 3D text along an arbitrary path.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Attachable text objects in 2D and 3D.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

use <builtins.scad>


// Section: 2D Text

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
//   printing), so if you want points you will need to perform a suitable unit conversion.
//   In addition, the OpenSCAD font system has a bug: if you specify size=s you will
//   instead get a font whose size is s/0.72.  For many fonts this means the size of
//   capital letters will be approximately equal to s, because it is common for fonts to
//   use about 70% of their height for the ascenders in the font.  To get the customary
//   font size, you should multiply your desired size by 0.72.
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
module text(text, size=10, font, halign, valign, spacing=1.0, direction="ltr", language="en", script="latin", anchor="baseline", spin=0) {
    no_children($children);
    dummy1 =
        assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Invalid anchor: ",anchor))
        assert(is_finite(spin), str("Invalid spin: ",spin));
    anchor = default(anchor, CENTER);
    geom = attach_geom(size=[size,size],two_d=true);
    anch = !any([for (c=anchor) c=="["])? anchor :
        let(
            parts = str_split(str_split(str_split(anchor,"]")[0],"[")[1],","),
            vec = [for (p=parts) parse_float(str_strip(p," ",start=true))]
        ) vec;
    ha = halign!=undef? halign :
        anchor=="baseline"? "left" :
        anchor==anch && is_string(anchor)? "center" :
        anch.x<0? "left" :
        anch.x>0? "right" :
        "center";
    va = valign != undef? valign :
        starts_with(anchor,"baseline")? "baseline" :
        anchor==anch && is_string(anchor)? "center" :
        anch.y<0? "bottom" :
        anch.y>0? "top" :
        "center";
    base = anchor=="baseline"? CENTER :
        anchor==anch && is_string(anchor)? CENTER :
        anch.z<0? BOTTOM :
        anch.z>0? TOP :
        CENTER;
    m = _attach_transform(base,spin,undef,geom);
    multmatrix(m) {
        $parent_anchor = anchor;
        $parent_spin   = spin;
        $parent_orient = undef;
        $parent_geom   = geom;
        $parent_size   = _attach_geom_size(geom);
        $attach_to   = undef;
        if (_is_shown()){
            _color($color) {
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



// Section: Text Wrapping
//   **Text wrapping with proportional fonts requires an OpenSCAD snapshot or stable build released after 2021-08-16.**
//   While you *can* pass a proportional font to `wraptext()` in older versions of OpenSCAD, and display the wrapped
//   text using that proportional font, the wrapping algorithm still treats it as a monospace font. This actually works
//   much of the time but the line lengths would not be the same as from text wrapped using proportional character spacing.
//   .
//   If you are using a version of OpenSCAD dated earlier than 2021-08-16 when `textmetrics()` appeared the OpenSCAD snapshots,
//   then only monospace fonts are supported, and unless specified otherwise in `textwrap()`,
//   the width of all characters is assumed to be 83.35% of the font size, corresponding to the font "Liberation Mono:style=Bold".
//   Results may be different with other monospace fonts.


// Function: textwrap()
// Synopsis: Wraps a text string with a specified font to fit within a specified width, returning an array of strings.
// Topics: Text
// See Also: text(), str_split(), textarray_boundingbox()
// Usage:
//   textarray = textwrap(string, width, [optimize=], [line_spacing=], ...);
// Description:
//   Returns an array of paragrahs, where each paragraph is an array of substrings of the original text,
//   such that each substring fits within a specified width when displayed with the specified font.
//   By default, the text wrapping is optimized so that each line of text is roughly the same
//   length to minimize the occurrence of an unusually short final line.
//   The actual overall width of the final text is less than or equal to the requested width.
//   You can use `{{textarray_boundingbox()}}` to get the actual bounding box of the wrapped text.
//   .
//   Multple paragraphs are returned if the `string` argument contains newline (`\n`) characters that split the string.
//   To insert a blank line, use two newlines with a space in between (`\n \n`).
//   Referring to Example 3 below, if the return value is in `textarray`, then the lines of text are in the paragraph `textarray[paragraph_number]`.
//   If the string contains no newlines, then a single paragraph is returned in `textarray`,
//   and `textarray[0]` contains the substrings lines from the wrapped text, as shown in Examples 1 and 2.
//   .
//   Several parameters are the same as for OpenSCAD's builtin `text()`. Some don't seem to have any effect, but are present here for compatibility: `direction`, `language`, and `script`.
// Arguments:
//   string = The text to generate. Any leading whitespace, trailing whitespace, and consecutive spaces are stripped before word-wrapping.
//   width = the maximum width of a line of text in display units.
//   ---
//   optimize = When false, tries to fit as many words as possible on each successive line, which may result in a widow (a word all by itself) on the last line. When true, attempts to make the wrapped lines more equal in length.  Default: true
//   size = font size (decimal number). See the [OpenSCAD documentation](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Text) for this the following parameters.
//   font = The name of the font that should be used, including an optional style parameter. Default: `"Liberation Sans:style=Bold"` (for OpenSCAD builds before 2021-08-16, default is `"Liberation Mono:style=Bold"`)
//   spacing = Factor to increase/decrease the character spacing. Default: 1.0
//   direction = Direction of the text flow, "ltr" (left-to-right), "rtl" (right-to-left). This function does not support "ttb" (top-to-bottom), or "btt" (bottom-to-top). Default: "ltr"
//   language = Two-letter language code for the text. Default: "en"
//   script = The script of the text. Default: "latin"
//   charwidth = monospace character width to use for OpenSCAD builds prior to 2021-08-16. If not set, the value is calculated as 83.35% of the font size using font "Liberation Mono:style=Bold". Setting this in later builds results in an error. Default: undef
// Example: Basic textwrap of a single long string to fit within 240 units. Because line length optimization is enabled by default, the resulting lines have roughly equal length, although significantly narrower than 240 units.
//   sample = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, \
//   sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
//   textwidth = 240;
//   textarray = textwrap(sample, textwidth, font="Liberation Serif");
//   /*
//   textarray contains one paragraph of four lines roughly equal in size:
//   [
//       [
//           "Lorem ipsum dolor sit amet,",
//           "consectetur adipiscing elit, sed",
//           "do eiusmod tempor incididunt ut",
//           "labore et dolore magna aliqua."
//       ]
//   ]
//   */
// Example: Here is the same thing but with optimization disabled. The lines are as wide as can fit within 240 units for the specified font (and default `size=10`), with a lone word by itself on the last line.
//   sample = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, \
//   sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
//   textwidth = 240;
//   textarray = textwrap(sample, textwidth, font="Liberation Serif", optimize=false);
//   /*
//   textarray is one paragraph of four lines consuming the maximum width:
//   [
//       [
//           "Lorem ipsum dolor sit amet, consectetur",
//           "adipiscing elit, sed do eiusmod tempor",
//           "incididunt ut labore et dolore magna",
//           "aliqua."
//       ]
//   ]
//   */
// Example: Here is a longer string with a space between two newlines (`\n \n`) inserted to create paragraphs separated by a blank line. In this case, the optimization tries to maintain equal margins for both paragraphs, and sacrifices the length of the last line of the first paragraph to avoid the second paragraph wrapping to another line.
//   sample = "Lorem ipsum dolor sit amet, consectetur adipiscing \
//   elit, sed do eiusmod tempor incididunt ut labore et dolore magna \
//   aliqua.\n \nUt enim ad minim veniam, quis nostrud exercitation \
//   ullamco laboris nisi ut aliquip ex ea commodo consequat.";
//   textwidth = 240;
//   textarray = textwrap(sample, textwidth, font="Liberation Serif");
//   echo(textarray);
//   /*
//   textarray contains one paragraph with four lines of roughly equal length:
//   [
//       // first paragraph
//       [
//           "Lorem ipsum dolor sit amet,",
//           "consectetur adipiscing elit, sed do",
//           "eiusmod tempor incididunt ut labore et",
//           "dolore magna aliqua."
//       ],
//       // second paragraph is a blank line
//       [ "" ],
//       // third paragraph
//       [
//           "Ut enim ad minim veniam, quis nostrud",
//           "exercitation ullamco laboris nisi ut",
//           "aliquip ex ea commodo consequat."
//       ]
//   ]
//   */

function textwrap(string, width, optimize=true, size=10, font, spacing=1, direction="ltr", language="en", script="latin", charwidth, _fdata) =
assert(version_num()<20210816 || is_undef(charwidth), "Parameter charwidth cannot be specified for OpenSCAD builds dated after 2021-08-16.")
assert(is_def(width), "Width units must be specified.")
let(
    fontname = is_def(font) ? font
        : version_num()>=20210816 ? "Liberation Sans:style=Bold"
        : "Liberation Mono:style=Bold",
    gd = is_undef(_fdata) ? _glyphdata(fontname) * (size/10) : _fdata,
    charwid = version_num()>=20210816 ? undef : is_def(charwidth) ? charwidth : gd[1],
    spc = is_def(charwid) ? charwid
        : textmetrics(text=" ", size=size, font=fontname, direction=direction, language=language, script=script, spacing=spacing).advance[0],
    words = [
        for(p=str_split(string, "\n", false)) let(
            line = list_remove_values(str_split(str_strip(p," \t\r\n"), " \t"), "", all=true)
            ) len(line)==0 ? [""] : line
    ],
    wlens = [
        for(p=words) [
            for(w=p) is_def(charwid)
            ? len(w)*charwid + spc // only for old builds of OpenSCAD
            : textmetrics(text=w, size=size, font=fontname, direction=direction, language=language, script=script, spacing=spacing).advance[0]
                + spc // all words must have a trailing space; EOL is accounted for later
        ]
    ],
    maxwordwid = max(flatten(wlens)) - spc // length of longest word in text
) assert(maxwordwid <= width, "A word width exceeds the specified width.")
// Create the array line_indexes with same paragraph structure as words.
// Each line of wrapped text is represented by an array of [start,end] pairs,
// with start and end pointing to indexes in cumlen, which is a cumulative list
// of line lengths at the end of each word, and also has the same paragraph structure.
let(
    cumlen = [ for(wl=wlens) cumsum(wl) ],
    npara = len(words),
    line_indexes = [ for(cl=cumlen) _getlines(width, spc, cl, len(cl)) ],
    maxlinewid=_get_lines_maxwid(line_indexes, spc, cumlen),
    final_line_indexes = optimize
    ? _wrap_optimize(len(flatten(line_indexes)), maxwordwid, line_indexes, maxlinewid-0.01, spc, cumlen)
    : line_indexes,
    nlines = len(line_indexes)
) // output an array of paragraphs containing lists of wordwrapped strings
//echo(str("maxlines=", len(flatten(line_indexes)), " minwid=", maxwordwid, " final _get_lines_maxwid=", maxlinewid, " final=", _get_lines_maxwid(final_line_indexes, spc, cumlen)))
[   for(i=[0:nlines-1]) let(li=final_line_indexes[i]) [
        for(j=[0:len(li)-1]) str_join(slice(words[i], li[j][0], li[j][1]), " ")
    ]
];

/// Private function: _wrap_optimize(), called by textwrap()
/// Recursively find minimum wrap width in all paragraphs represented by line_indexes
/// such that the total number of lines of wrapped text does not increase.
/// Arguments:
///   maxlines = total number of lines not to exceed
///   minwid = minimum wrap width allowable (length of longest word)
///   line_indexes = array of [start,end] pairs, with start and end pointing to indexes in cumlen parameter
///   reqwid = requested wrap width
///   spc = length of a space
///   cumlen = cumulative list of line lengths with same paragraph structure as line_indexes
///   iter = maximum number of recursions allowed
function _wrap_optimize(maxlines, minwid, line_indexes, reqwid, spc, cumlen, iter=50) =
//echo(str("lines=", len(flatten(line_indexes))," reqwid=", reqwid, " initialwid=",_get_lines_maxwid(line_indexes, spc, cumlen), " iter=",iter))
let(
    new_li = [ for(cl=cumlen) _getlines(reqwid, spc, cl, len(cl)) ],
    nlines = len(flatten(new_li)),
    newreqwid = _get_lines_maxwid(new_li, spc, cumlen) - 0.01
)
iter<=0 || nlines>maxlines || newreqwid<=minwid ? line_indexes
: _wrap_optimize(maxlines, minwid, new_li, newreqwid, spc, cumlen, iter-1);


/// Private function: _getlines(), called by wraptext() and _wrap_optimize()
/// "Greedy" word-wrap, returns a list of text strings that fit within the specified width.
/// Arguments:
///   width = width in which to fit text
///   spc = width of a space character
///   cl = array of cumulative line lengths in a single paragraph
///   nwords = number of words total
/// The parameters istart and res are maintained internally.
function _getlines(width, spc, cl, nwords, istart=0, res=[]) =
istart >= nwords ? res
: let(
    prevlinelen = istart>0 ? cl[istart-1] : 0,
    lastindx = _bsearch_lowindex(width+prevlinelen+spc, cl, nwords, istart, nwords-1)
) _getlines(width, spc, cl, nwords, lastindx+1, concat(res, [[istart,lastindx]]));

/// Private function: _bsearch_lowindex(), binary search called by _getlines()
/// Return the index of the element in ordered_list of length n that is less than or equal to value.
/// The parameters low and high should initially be set to 0 and n-1, respectively.
function _bsearch_lowindex(value, ordered_list, n, low, high) =
high < low ? -1
: let(mid = low + floor(0.5*(high-low)))
    mid >= n-1 ? n-1 :
    (ordered_list[mid] <= value && value < ordered_list[min(mid+1,n-1)] ? mid
    : (ordered_list[mid] > value
        ? _bsearch_lowindex(value, ordered_list, n, low, mid-1)
        : _bsearch_lowindex(value, ordered_list, n, mid+1, high))
    );

/// Private function: _get_lines_maxwid(), called by textwrap() and _wrap_optimize()
/// Return the maximum width of the lines represented by line_indexes, which contains array indexes pointing into cumlen, a list of cumulative lengths at end of each word.
function _get_lines_maxwid(line_indexes, spc, cumlen) =
let(widths = [
    for(i=[0:len(line_indexes)-1])
        for(j = [0:len(line_indexes[i])-1])
            cumlen[i][line_indexes[i][j][1]] - (j>0 ? cumlen[i][line_indexes[i][j-1][1]] : 0)
]) max(widths) - spc; // all words have a trailing space, so subtract EOL trailing space


// Module: array_text()
// Synopsis: Render an array of text as an attachable 2D block using the specified font characteristics.
// SynTags: Geom
// Topics: Attachments, Text
// See Also: textwrap()
// Usage:
//   array_text(textarray, width, [line_spacing=], ...);
// Usage: With attachments
//   array_text(textarray, width, [line_spacing=], ...) [ATTACHMENTS];
// Description:
//   Creates a 2D geometry of the array of text strings, using the given line spacing and font specifications.
//   The font parameters work the same as with OpenSCAD's builtin text() command.
//   The `valign` parameter is not used because it is not relevant for fitting multi-line text inside a bounding box.
//   You would use the `anchor` parameter to set the origin of the block to position it.
// Arguments:
//   textarray = An array of text strings to display. The array may be a simple list of strings, or a list of paragraphs as returned from `textwrap()`, with each paragraph being a list of strings.
//   ---
//   line_spacing = the proportion of font interline height to use for line spacing. The interline height accounts for the nominal extents of ascenders and descenders in the font glyphs. The actual character size is typically about 72% of the interline height. Default: 1.0
//   size = font size (decimal number). See the [OpenSCAD documentation](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Text) for this and following parameters. Default: 10
//   font = The name of the font that should be used, including an optional style parameter. Default: `"Liberation Sans:style=Bold"` (for OpenSCAD builds before 2021-08-16, the default is `"Liberation Mono:style=Bold"`)
//   halign = The horizontal alignment for the text within its bounding box. Possible values are "left", "center" and "right". Default: "left"
//   spacing = Factor to change the character spacing. Default: 1.0
//   direction = Direction of the text flow, "ltr" (left-to-right), "rtl" (right-to-left). This function does not support "ttb" (top-to-bottom), or "btt" (bottom-to-top). Default: "ltr"
//   language = Two-letter language code for the text. Default: "en"
//   script = The script of the text. Default: "latin"
//   $fn = used for subdividing the curved path segments.
//   anchor = Translate so anchor point is at origin (0,0,0). See [anchor](attachments.scad#subsection-anchor).  Default: `BOTTOM+LEFT`
//   spin = Rotate this many degrees around the Z axis after anchor. See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(3D,Med): Wrap some text and extrude the resulting array in 3D.
//   string = "Go placidly amid the noise and haste, \
//   and remember what peace there may be in silence.";
//   fontname = "Lucida Serif:style=Bold Italic";
//   textarray = textwrap(string, width=130, font=fontname);
//   color("lightblue") linear_extrude(4) array_text(textarray, font=fontname);

module array_text(textarray, line_spacing=1, size=10, font, halign="left", spacing=1, direction="ltr", language="en", script="latin", anchor=BOTTOM+LEFT, spin=0) {
    assert(direction=="ltr" || direction=="rtl", "Only directions 'ltr' and 'rtl' are supported.");
    lines = flatten(textarray);
    nlines = len(lines);
    fontname = is_def(font) ? font
        : version_num()>=20210816 ? "Liberation Sans:style=Bold"
        : "Liberation Mono:style=Bold";
    gd = _glyphdata(fontname) * (size/10);
    lineht = gd[0];
    bbox = textarray_boundingbox(lines, line_spacing, size, fontname, spacing, gd);
    height = bbox[1];
    width = bbox[0];
    ank = anchor[1]==0 && anchor[2] != 0 ? [anchor[0], anchor[2]] : [anchor[0], anchor[1]];
    xoff = -width/2 * (1+ank[0]);
    yoff = height/2 * (1-ank[1]);
    rotate([0,0,spin]) translate([xoff + (halign=="right" ? width : halign=="center" ? width/2 : 0), yoff-size]) {
        for(i=[0:nlines-1]) translate([0,-i*lineht*line_spacing+gd[3]])
            _text(lines[i], size=size, font=fontname, halign=halign, valign="baseline", spacing=spacing, direction=direction, language=language, script=script);
    }
}

/// Private function: _glyphdata(), called by textwrap(), array_text(), and textarray_boundingbox()
/// Get font data, used for positioning lines of text in bounding box.
function _glyphdata(fontname) =
// textmetrics() added to OpenSCAD on 2021-08-16 in https://github.com/openscad/openscad/pull/3684
    version_num() >= 20210816
? let(
    fm = fontmetrics(10, fontname),
    tmN = textmetrics("N", 10, fontname)
) [
    fm.interline,       // line height
    tmN.advance[0],     // monospace N width (here only for index compatibility)
    fm.nominal.ascent,  // nominal char height from baseline
    fm.nominal.descent  // nominal char descent from baseline
    
] : [ // For OpenSCAD older than 2021-08-16
    15.7335,    // line height from fontmetrics 'interline'
    8.3347,     // glyph width of "Liberation Mono:style=Bold" N from textmetrics 'advance'
    11.5628,    // glyph height from baseline
    -4.1707     // descent from baseline
];


// Function: textarray_boundingbox()
// Synopsis: Returns the bounding box dimensions of an array of text given the line spacing and font specifications.
// Topics: Text
// See Also: textwrap(), array_text()
// Usage:
//   bbox = textarray_boundingbox((string, line_spacing, size, font, spacing);
// Description:
//   Returns the bounding box dimensions of an array of text strings (paragraphs or simple list) given the line spacing and font specifications. While only `text_array` is required, you must pass any font specification if you use any value other than the default values.
// Arguments:
//   textarray = An array of text strings to display. The array may be a simple list of strings, or a list of paragraphs as returned from `textwrap()`, with each paragraph being a list of strings.
//   ---
//   line_spacing = the proportion of font interline height to use for line spacing. Default: 1.0
//   size = font size (decimal number). See the [OpenSCAD documentation](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Text) for this and following parameters. Default: 10
//   font = The name of the font that should be used, including an optional style parameter. Default: "Liberation Sans:style=Bold" (for OpenSCAD builds before 2021-08-16, default is "Liberation Mono:style=Bold")
//   spacing = Factor to increase/decrease the character spacing. Default: 1.0
// Example(2D,Med): This example demonstrates several things at once. The text is wrapped using the default font and size. The original requested width of 280 units is the yellow rectangle, and anchored to it are the wrapped text displayed by `array_text()` in black, and the bounding box of the wrapped text in green.
//   sample = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, \
//   sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n \n\
//   Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris \
//   nisi ut aliquip ex ea commodo consequat.";
//   textwidth = 280;
//   textarray = textwrap(sample, textwidth);
//   bbox = textarray_boundingbox(textarray);
//   cube([textwidth, bbox[1], 1]) attach(TOP,BOT) {
//       color("palegreen") cube(point3d(bbox,1));
//       color("black") linear_extrude(2) array_text(textarray, anchor=CENTER);
//   }
function textarray_boundingbox(textarray, line_spacing=1, size=10, font, spacing=1, gd) =
let(
    fontname = is_def(font) ? font
        : version_num()>=20210816 ? "Liberation Sans:style=Bold"
        : "Liberation Mono:style=Bold",
    fdata = is_undef(gd) ? _glyphdata(fontname) * (size/10) : gd,
    sl = flatten(textarray),
    width = _stringlist_width(sl, fdata, size, fontname, spacing),
    height = len(sl)*line_spacing*fdata[0]
) [width, height];

/// Private function: _stringlist_width(), called by textarray_boundingbox()
/// Recursively find maximum width in CAD units (not characters) of array of text strings
/// sl = string list
/// gd = glyph data
/// size, font, spacing = font specs
function _stringlist_width(sl, gd, size, font, spacing, width=0, i=0) =
i>=len(sl)
? width
: let(
    strwid = version_num() < 20210816 ? len(sl[i])*gd[1] : textmetrics(sl[i], size, font, spacing=spacing).advance[0]
)
_stringlist_width(sl, gd, size, font, spacing, max(width, strwid), i+1);



// Section: 3D Text
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
//   printing), so if you want points you will need to perform a suitable unit conversion.
//   In addition, the OpenSCAD font system has a bug: if you specify size=s you will
//   instead get a font whose size is s/0.72.  For many fonts this means the size of
//   capital letters will be approximately equal to s, because it is common for fonts to
//   use about 70% of their height for the ascenders in the font.  To get the customary
//   font size, you should multiply your desired size by 0.72.
//   .
//   To find the fonts that you have available in your OpenSCAD installation,
//   go to the Help menu and select "Font List".


// Module: text3d()
// Synopsis: Creates an attachable 3d text block.
// SynTags: Geom
// Topics: Attachments, Text
// See Also: path_text(), text() 
// Usage:
//   text3d(text, [h], [size], [font], [language=], [script=], [direction=], [atype=], [anchor=], [spin=], [orient=]);
// Description:
//   Creates a 3D text block that supports anchoring and single-parameter attachment to attachable objects.  You cannot attach children to text.
// Arguments:
//   text = Text to create.
//   h / height / thickness = Extrusion height for the text.  Default: 1
//   size = The font will be created at this size divided by 0.72.   Default: 10
//   font = Font to use.  Default: "Liberation Sans" (standard OpenSCAD default)
//   ---
//   spacing = The relative spacing multiplier between characters.  Default: `1.0`
//   direction = The text direction.  `"ltr"` for left to right.  `"rtl"` for right to left. `"ttb"` for top to bottom. `"btt"` for bottom to top.  Default: `"ltr"`
//   language = The language the text is in.  Default: `"en"`
//   script = The script the text is in.  Default: `"latin"`
//   atype = Change vertical center between "baseline" and "ycenter".  Default: "baseline"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"baseline"`
//   center = Center the text.  Equivalent to `atype="center", anchor=CENTER`.  Default: false
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
module text3d(text, h, size=10, font, spacing=1.0, direction="ltr", language="en", script="latin",
              height, thickness, atype, center=false,
              anchor, spin=0, orient=UP) {
    no_children($children);
    h = one_defined([h,height,thickness],"h,height,thickness",dflt=1);
    assert(is_undef(atype) || in_list(atype,["ycenter","baseline"]), "atype must be \"ycenter\" or \"baseline\"");
    assert(is_bool(center));
    assert(is_undef($attach_to),"text3d() does not support parent-child anchor attachment with two parameters");
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
            _color($color) {
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
//   by path_normals()).  Note that this means that if the center of curvature switches sides the text will flip upside down.
//   If you want text on such a path you must supply your own normal or top vector.
//   .
//   Text appears starting at the beginning of the path, so if the 3D path moves right to left
//   then a left-to-right reading language will display in the wrong order. (For a 2D path text will appear upside down.)
//   The text for a 3D path appears positioned to be read from "outside" of the curve (from a point on the other side of the
//   curve from the center of curvature).  If you need the text to read properly from the inside, you can set reverse to
//   true to flip the text, or supply your own normal.
//   .
//   If you do not have the experimental textmetrics feature enabled then you must specify the space for the letters
//   using lettersize, which can be a scalar or array.  You will have the easiest time getting good results by using
//   a monospace font such as "Liberation Mono".  Note that even with text metrics, spacing may be different because path_text()
//   doesn't do kerning to adjust positions of individual glyphs.  Also if your font has ligatures they won't be used.
//   .
//   By default letters appear centered on the path.  The offset can be specified to shift letters toward the reader (in
//   the direction of the normal).
//   .
//   You can specify your own normal by setting `normal` to a direction or a list of directions.  Your normal vector should
//   point toward the reader.  You can also specify
//   top, which directs the top of the letters in a desired direction.  If you specify your own directions and they
//   are not perpendicular to the path then the direction you specify will take priority and the
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
//   printing), so if you want points you will need to perform a suitable unit conversion.
//   In addition, the OpenSCAD font system has a bug: if you specify size=s you will
//   instead get a font whose size is s/0.72.  For many fonts this means the size of
//   capital letters will be approximately equal to s, because it is common for fonts to
//   use about 70% of their height for the ascenders in the font.  To get the customary
//   font size, you should multiply your desired size by 0.72.
//   .
//   To find the fonts that you have available in your OpenSCAD installation,
//   go to the Help menu and select "Font List".
// Arguments:
//   path = path to place the text on
//   text = text to create
//   size = The font will be created at this size divided by 0.72.   
//   thickness / h / height = thickness of letters (not allowed for 2D path)
//   font = Font to use.  Default: "Liberation Sans" (standard OpenSCAD default)
//   ---
//   lettersize = scalar or array giving size of letters
//   center = center text on the path instead of starting at the first point.  Default: false
//   offset = distance to shift letters "up" (towards the reader).  Not allowed for 2D path.  Default: 0
//   normal = direction or list of directions pointing towards the reader of the text.  Not allowed for 2D path.
//   top = direction or list of directions pointing toward the top of the text
//   reverse = reverse the letters if true.  Not allowed for 2D path.  Default: false
//   textmetrics = if set to true and lettersize is not given then use the experimental textmetrics feature.  You must be running a dev snapshot that includes this feature and have the feature turned on in your preferences.  Default: false
//   valign = align text to the path using "top", "bottom", "center" or "baseline".  You can also adjust position with a numerical offset as in "top-5" or "bottom+2".  This only works with textmetrics enabled.  You can give a simple numerical offset, which will be relative to the baseline and works even without textmetrics.  Default: "baseline"
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
// Example(3D,Med,NoScales): This sine wave wrapped around the cylinder has a twisting normal that produces wild letter layout.  We fix it with a custom normal which is different at every path point.
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
  dummy2=assert(is_path(path,[2,3]),"Must supply a 2d or 3d path")
         assert(num_defined([normal,top])<=1, "Cannot define both \"normal\" and \"top\"")
         assert(all_positive([size]), "Must give positive text size");
  dim = len(path[0]);
  normalok = is_undef(normal) || is_vector(normal,3) || (is_path(normal,3) && len(normal)==len(path));
  topok = is_undef(top) || is_vector(top,dim) || (dim==2 && is_vector(top,3) && top[2]==0)
                        || (is_path(top,dim) && len(top)==len(path));
  dummy4 = assert(dim==3 || !any_defined([thickness,h,height]), "Cannot give a thickness or height with 2d path")
           assert(dim==3 || !reverse, "Reverse not allowed with 2d path")
           assert(dim==3 || offset==0, "Cannot give offset with 2d path")
           assert(dim==3 || is_undef(normal), "Cannot define \"normal\" for a 2d path, only \"top\"")
           assert(normalok,"\"normal\" must be a vector or path compatible with the given path")
           assert(topok,"\"top\" must be a vector or path compatible with the given path");
  thickness = one_defined([thickness,h,height],"thickness,h,height",dflt=1);
  normal = is_vector(normal) ? repeat(normal, len(path))
         : is_def(normal) ? normal
         : undef;

  top = is_vector(top) ? repeat(dim==2?point2d(top):top, len(path))
         : is_def(top) ? top
         : undef;

  kern = force_list(kern, len(text)-1);
  dummy3 = assert(is_list(kern) && len(kern)==len(text)-1, "kern must be a scalar or list whose length is len(text)-1");

  lsize = is_def(lettersize) ? force_list(lettersize, len(text))
        : textmetrics ? [for(letter=text) let(t=textmetrics(letter, font=font, size=size)) t.advance[0]]
        : assert(false, "textmetrics disabled: Must specify letter size");
  lcenter = convolve(lsize,[1,1]/2)+[0,each kern,0] ;
  textlength = sum(lsize)+sum(kern);

  ascent = !textmetrics ? undef
         : textmetrics(text, font=font, size=size).ascent;
  descent = !textmetrics ? undef
          : textmetrics(text, font=font, size=size).descent;

  vadjustment = is_num(valign) ? -valign
              : !textmetrics ? assert(valign=="baseline","valign requires textmetrics support") 0
              : let(
                     table = [
                              ["baseline", 0],
                              ["top", -ascent],
                              ["bottom", descent],
                              ["center", (descent-ascent)/2]
                             ],
                     match = [for(i=idx(table)) if (starts_with(valign,table[i][0])) i]
                )
                assert(len(match)==1, "Invalid valign value")
                table[match[0]][1] - parse_num(substr(valign,len(table[match[0]][0])));

  dummy1 = assert(textlength<=path_length(path),"Path is too short for the text");

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
                 str("Specified top direction parallel to path at character ",i))
          assert(usetop || !approx(tangent*normpts[i],norm(normpts[i])*norm(tangent)),
                 str("Specified normal direction parallel to path at character ",i));
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
            ) left(lsize[0]/2) {
                text(text[i], font=font, size=size, language=language, script=script);
            }
        }
      }
    }
    union();
  }
}


