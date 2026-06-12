//////////////////////////////////////////////////////////////////////
// LibFile: write.scad
//   Advanced 3D text module with auto-sizing, word wrapping, multi-line
//   support, and full BOSL2 attachment integration.  Replaces the basic
//   text3d() for cases that need typographic control: fitting text into
//   a box, paragraph layout, alignment, and baseline anchoring.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/write.scad>
// FileGroup: Basic Modeling
// FileSummary: Advanced 3D text with auto-sizing, wrapping, and alignment.
//////////////////////////////////////////////////////////////////////

_BOSL2_WRITE = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: write.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;


use <builtins.scad>


// Section: Font Size Utilities


// Function: get_font_size()
// Synopsis: Converts between font size units (em, cap_height, OpenSCAD size).
// SynTags: Val
// Topics: Text, Typography
// See Also: write()
// Usage:
//   size = get_font_size([font_size=], [em_size=], [cap_height=]);
// Description:
//   Converts between different font sizing conventions and returns the
//   OpenSCAD `size` parameter value.  You can specify exactly one of
//   `font_size`, `em_size`, or `cap_height`.
//   .
//   OpenSCAD's native text size has a known quirk: the actual em square
//   is `size / 0.72`.  This means that `font_size` (the traditional
//   typographic point size) equals `openscad_size * 0.72`.
//   .
//   - `font_size`: Traditional point-like size. Converted with the 0.72 factor.
//   - `em_size`: The em square side length.  Equal to `openscad_size / 0.72`.
//   - `cap_height`: Approximate capital letter height.  Assumes cap height
//     is ~70% of em (typical for most Latin fonts).  Adjust the `cap_ratio`
//     parameter if your font differs.
// Arguments:
//   ---
//   font_size = Traditional typographic size (points-like).
//   em_size = Em square size (font design box).
//   cap_height = Desired capital letter height.
//   cap_ratio = Ratio of cap height to em size. Default: 0.7
// Example:
//   sz = get_font_size(font_size=12);  // => 12 / 0.72 = 16.667
//   sz = get_font_size(em_size=10);    // => 10 * 0.72 = 7.2
//   sz = get_font_size(cap_height=5);  // => 5 / 0.7 / 0.72 ≈ 9.92
function get_font_size(font_size, em_size, cap_height, cap_ratio=0.7) =
    assert(num_defined([font_size, em_size, cap_height]) == 1,
           "\nExactly one of font_size, em_size, or cap_height must be specified.")
    assert(is_undef(cap_ratio) || (is_finite(cap_ratio) && cap_ratio > 0 && cap_ratio <= 1),
           "\ncap_ratio must be a number between 0 and 1.")
    !is_undef(font_size) ?
        assert(is_finite(font_size) && font_size > 0, "\nfont_size must be positive.")
        font_size / 0.72
    : !is_undef(em_size) ?
        assert(is_finite(em_size) && em_size > 0, "\nem_size must be positive.")
        em_size * 0.72
    : // cap_height
        assert(is_finite(cap_height) && cap_height > 0, "\ncap_height must be positive.")
        cap_height / cap_ratio / 0.72;


// Section: 3D Text


// Module: write()
// Synopsis: Creates 3D text with auto-sizing, wrapping, alignment, and attachment support.
// SynTags: Geom
// Topics: Text, Typography, 3D Printing
// See Also: text3d(), path_text(), get_font_size()
// Usage:
//   write(text, [h=], [font_size=], [font=], [width=], [height=], [box=], ...) [ATTACHMENTS];
// Description:
//   Creates 3D text with advanced typographic controls.  This module extends
//   the basic text3d() with:
//   .
//   **Auto-sizing**: When no `font_size` is given and a `box` or `width`/`height`
//   is specified, the text is automatically scaled to fit the box.
//   .
//   **Word wrapping**: When `font_size` and `width` are both given, text is
//   wrapped at word boundaries to fit within the width.
//   .
//   **Multi-line**: Text can be a string with newlines (`\n`) or an array of
//   strings, each element being a separate paragraph/line.
//   .
//   **Alignment**: Horizontal (`align`) and vertical (`valign`) alignment
//   within the bounding box.
//   .
//   **Attachment**: Full BOSL2 attachable() support with anchor/spin/orient.
//   The bounding box is used for anchor geometry.
//   .
//   Note: auto-sizing and wrapping require the `textmetrics` experimental
//   feature for accurate results.  Without it, character width is estimated
//   as `0.6 * font_size` (suitable for monospace fonts).
// Arguments:
//   text = String or array of strings to render.
//   ---
//   h = Height (thickness) of the 3D text. Default: 1
//   font_size = Typographic font size. If omitted, auto-sizes to fit box.
//   font = Font name.  Default: "Liberation Sans"
//   width = Maximum text width for wrapping/auto-sizing.
//   height = Maximum text height for auto-sizing.
//   box = 2-vector [width, height] shorthand for width and height.
//   align = Horizontal alignment: "left", "center", "right". Default: "left"
//   valign = Vertical alignment: "top", "center", "bottom", "baseline". Default: "baseline"
//   line_spacing = Line spacing multiplier (relative to font size). Default: 1.4
//   letter_space = Extra letter spacing as fraction of em. Default: 0
//   margin = Margin inside the box [x, y] or scalar. Default: 0
//   spacing = OpenSCAD text() spacing parameter. Default: 1.0
//   direction = Text direction: "ltr", "rtl", "ttb", "btt". Default: "ltr"
//   language = Text language. Default: "en"
//   script = Text script. Default: "latin"
//   anchor = Translate so anchor point is at origin. Default: `CENTER`
//   spin = Rotate this many degrees around Z axis. Default: `0`
//   orient = Vector to rotate top toward. Default: `UP`
// Example(3D): Basic text
//   write("Hello BOSL2!", font_size=10, h=2);
// Example(3D): Auto-sized to fit a box
//   write("Fit me!", box=[60,20], h=2);
// Example(3D): Multi-line with alignment
//   write(["Line 1", "Line 2", "Line 3"],
//         font_size=8, h=1, align="center");
// Example(3D): Auto-sized paragraph in a box
//   write("This is a long text that should wrap automatically within the box boundaries.",
//         box=[80,40], h=1);
module write(
    text,
    h=1,
    font_size,
    font="Liberation Sans",
    width,
    height,
    box,
    align="left",
    valign="baseline",
    line_spacing=1.4,
    letter_space=0,
    margin=0,
    spacing=1.0,
    direction="ltr",
    language="en",
    script="latin",
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    no_children($children);
    assert(is_string(text) || is_list(text), "\ntext must be a string or list of strings.");
    assert(is_finite(h) && h > 0, "\nh must be a positive number.");
    assert(is_undef(font_size) || (is_finite(font_size) && font_size > 0),
           "\nfont_size must be a positive number.");
    assert(in_list(align, ["left", "center", "right"]),
           "\nalign must be \"left\", \"center\", or \"right\".");
    assert(in_list(valign, ["top", "center", "bottom", "baseline"]),
           "\nvalign must be \"top\", \"center\", \"bottom\", or \"baseline\".");
    assert(is_undef(box) || is_vector(box, 2),
           "\nbox must be a 2-vector [width, height].");

    // Resolver box vs width/height
    _width = !is_undef(box) ? box[0] : width;
    _height = !is_undef(box) ? box[1] : height;
    _margin = is_list(margin) ? margin : [margin, margin];

    // Area util (descontando margem)
    eff_w = !is_undef(_width) ? _width - 2*_margin[0] : undef;
    eff_h = !is_undef(_height) ? _height - 2*_margin[1] : undef;

    // Converter texto para lista de linhas
    raw_lines = is_list(text) ? text
        : let(parts = str_split(text, "\n"))
          is_list(parts) ? parts : [text];

    // Estimar largura de caractere (sem textmetrics)
    _char_w_factor = 0.6;

    // Determinar font_size
    _fs = !is_undef(font_size) ? font_size
        : !is_undef(eff_w) && !is_undef(eff_h) ?
            // Auto-size: calcular tamanho que cabe no box
            let(
                // Estimar numero de linhas apos wrapping
                max_chars = max([for(l=raw_lines) len(l)]),
                // Tamanho maximo pela largura (baseado na linha mais longa)
                fs_w = eff_w / (max_chars * _char_w_factor),
                // Tamanho maximo pela altura
                n_lines = len(raw_lines),
                fs_h = eff_h / (n_lines * line_spacing),
                fs = min(fs_w, fs_h)
            ) fs
        : !is_undef(eff_w) ?
            let(
                max_chars = max([for(l=raw_lines) len(l)]),
                fs = eff_w / (max_chars * _char_w_factor)
            ) fs
        : 10;  // Tamanho padrao se nada especificado

    // OpenSCAD size (com fator 0.72)
    _osc_size = _fs / 0.72;

    // Largura estimada por caractere
    _cw = _fs * _char_w_factor;

    // Word wrapping se font_size e width sao dados
    wrapped_lines =
        !is_undef(font_size) && !is_undef(eff_w) ?
            [for(line=raw_lines) each _wrap_line(line, eff_w, _cw)]
        : raw_lines;

    n_lines = len(wrapped_lines);
    _line_h = _fs * line_spacing;
    total_text_h = n_lines * _line_h;

    // Dimensoes do bounding box para attachable
    bbox_w = !is_undef(_width) ? _width : max([for(l=wrapped_lines) len(l)]) * _cw;
    bbox_h = !is_undef(_height) ? _height : total_text_h;

    // Verificar se texto cabe (erro se nao cabe)
    if (!is_undef(eff_h) && total_text_h > eff_h + _EPSILON) {
        echo(str("WARNING: text is too tall (", total_text_h,
                 ") for the box height (", eff_h,
                 "). Try reducing font_size or increasing height."));
    }

    // Offset vertical base (posicao da primeira linha)
    y_base =
        valign == "top" ? bbox_h/2 - _margin[1] - _line_h :
        valign == "center" ? (total_text_h - _line_h) / 2 :
        valign == "bottom" ? -bbox_h/2 + _margin[1] + (n_lines-1) * _line_h :
        /* baseline */ 0;

    // Halign para OpenSCAD text()
    _ha = align;

    // Offset horizontal
    x_off =
        align == "left" ? -bbox_w/2 + _margin[0] :
        align == "right" ? bbox_w/2 - _margin[0] :
        /* center */ 0;

    attachable(anchor, spin, orient, size=[bbox_w, bbox_h, h]) {
        union() {
            for (i = [0:1:n_lines-1]) {
                _line = wrapped_lines[i];
                _y = y_base - i * _line_h;
                translate([x_off, _y, 0])
                linear_extrude(height=h, center=true)
                    _text(
                        text=_line,
                        size=_osc_size,
                        font=font,
                        halign=_ha,
                        valign="baseline",
                        spacing=spacing + letter_space,
                        direction=direction,
                        language=language,
                        script=script
                    );
            }
        }
        children();
    }
}


// Funcao auxiliar: quebra uma linha em palavras que cabem na largura
function _wrap_line(line, max_w, char_w) =
    let(
        words = str_split(line, " "),
        space_w = char_w
    )
    _wrap_words(words, max_w, char_w, space_w, 0, "", []);

// Funcao auxiliar recursiva para wrapping
function _wrap_words(words, max_w, char_w, space_w, idx, current, result) =
    idx >= len(words) ?
        // Fim: adiciona linha atual se nao vazia
        current == "" ? (len(result) == 0 ? [""] : result)
        : concat(result, [current])
    :
    let(
        word = words[idx],
        word_w = len(word) * char_w,
        cur_w = len(current) * char_w,
        // Testa se a palavra cabe na linha atual
        fits = current == "" ? true
             : (cur_w + space_w + word_w) <= max_w,
        new_current = fits ?
            (current == "" ? word : str(current, " ", word))
            : word,
        new_result = fits ? result : concat(result, [current])
    )
    _wrap_words(words, max_w, char_w, space_w, idx+1, new_current, new_result);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
