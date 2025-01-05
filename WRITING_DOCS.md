Documenting OpenSCAD Code
-------------------------------------------------

Documentation comment blocks are all based around a single simple syntax:

    // Block Name(Metadata): TitleText
    //   Body line 1
    //   Body line 2
    //   Body line 3

- The Block Name is one or two words, both starting with a capital letter.
- The Metadata is in parentheses.  It is optional, and can contain fairly arbitrary text, as long as it doesn't include newlines or parentheses. If the Metadata part is not given, the parentheses are optional.
- A colon `:` will always follow after the Block Name and optional Metadata.
- The TitleText will be preceded by a space ` `, and can contain arbitrary text, as long as it contains no newlines.  The TitleText part is also optional for some header blocks.
- The body will contain zero or more lines of text indented by three spaces after the comment markers.  Each line can contain arbitrary text.

So, for example, a Figure block to show a 640x480 animated GIF of a spinning shape may look like:

    // Figure(Spin,Size=640x480,VPD=444): A Cube and Cylinder.
    //   cube(80, center=true);
    //   cylinder(h=100,d=60,center=true);

Various block types don't need all of those parts, so they may look simpler:

    // Topics: Mask, Cylindrical, Attachable

Or:

    // Description:
    //   This is a description.
    //   It can be multiple lines in length.

Or:

    // Usage: Typical Usage
    //   x = foo(a, b, c);
    //   x = foo([a, b, c, ...]);

Comments blocks that don't start with a known block header are ignored and not added to output documentation.  This lets you have normal comments in your code that are not used for documentation.  If you must start a comment block with one of the known headers, then adding a single extra `/` or space after the comment marker, will make it be treated as a regular comment:

    /// File: Foobar.scad


Block Headers
=======================

File/LibFile Blocks
-------------------

All files must have either a `// File:` block or a `// LibFile:` block at the start.  This is the place to put in the canonical filename, and a description of what the file is for.  These blocks can be used interchangably, but you can only have one per file.  `// File:` or `// LibFile:` blocks can be followed by a multiple line body that are added as markdown text after the header:

    // LibFile: foo.scad
    //   You can have several lines of markdown formatted text here.
    //   You just need to make sure that each line is indented, with
    //   at least three spaces after the comment marker.  You can
    //   denote a paragraph break with a comment line with three
    //   trailing spaces, or just a period.
    //   .
    //   You can have links in this text to functions, modules, or
    //   constants in other files by putting the name in double-
    //   braces like {{cyl()}} or {{lerp()}} or {{DOWN}}.  If you want to
    //   link to another file, or section in another file you can use
    //   a manual markdown link like [Section: Cuboids](shapes.scad#section-cuboids).
    //   The end of the block is denoted by a line without a comment.

Which outputs Markdown code that renders like:

> ## LibFile: foo.scad
> You can have several lines of markdown formatted text here.
> You just need to make sure that each line is indented, with
> at least three spaces after the comment marker.  You can
> denote a paragraph break with a comment line with three
> trailing spaces, or just a period.
> 
> You can have links in this text to functions, modules, or
> constants in other files by putting the name in double-
> braces like [cyl()](shapes.scad#functionmodule-cyl) or [lerp()](math.scad#function-lerp) or [DOWN](constants.scad-down).  If you want to
> link to another file, or section in another file you can use
> a manual markdown link like [Section: Cuboids](shapes.scad#section-cuboids).
> The end of the block is denoted by a line without a comment.

You can use `// File:` instead of `// LibFile:`, if it seems more apropriate for your particular context:

    // File: Foobar.scad
    //   This file contains a collection of metasyntactical nonsense.

Which outputs Markdown code that renders like:

> # File: Foobar.scad
> This file contains a collection of metasyntactical nonsense.


FileGroup Block
---------------

You can specify what group of files this .scad file is a part of with the `// FileGroup:` block:

    // FileGroup: Advanced Modeling

This affects the ordering of files in Table of Contents and CheatSheet files.  This doesn't generate any output text otherwise.


FileSummary Block
-----------------

You can give a short summary of the contents of this .scad file with the `// FileSummary:` block:

    // FileSummary: Various modules to generate Foobar objects.

This summary is used when summarizing this .scad file in the Table of Contents file.  This will result in a line in the Table of Contents that renders like:

> - [Foobar.scad](Foobar.scad): Various modules to generate Foobar objects.


FileFootnotes Block
-------------------

You can specify footnotes that are appended to this .scad file's name wherever the list of files is shown, such as in the Table of Contents.  You can do this with the `// FileFootnotes:` block.  The syntax looks like:

    // FileFootnotes: 1=First Footnote; 2=Second Footnote

Multiple footnotes are separated by semicolons (`;`).  Within each footnote, you specify the footnote symbol and the footnote text separated by an equals sign (`=`).  The footnote symbol may be more than one character, like this:

    // FileFootnotes: STD=Included in std.scad

This will result in footnote markers that render like:

> - Foobar.scad<sup id="fn_std">[STD](#footnote-std "Included in std.scad")</sup>


Includes Block
--------------

To declare what code the user needs to add to their code to include or use this library file, you can use the `// Includes:` block.  You should put this right after the `// File:` or `// LibFile:` block. This code block will also be prepended to all Example and Figure code blocks before they are evaluated:

    // Includes:
    //   include <BOSL2/std.scad>
    //   include <BOSL2/gears.scad>

Which outputs Markdown code that renders like:

> **Includes:**
>
> To use, add the following lines to the beginning of your file:
>
> ```openscad
>  include <BOSL2/std.scad>
>  include <BOSL2/gears.scad>
> ```


CommonCode Block
----------------

If you have a block of code you plan to use throughout the file's Figure or Example blocks, and you don't actually want it displayed, you can use a `// CommonCode:` block like thus:

    // CommonCode:
    //   module text3d(text, h=0.01, size=3) {
    //       linear_extrude(height=h, convexity=10) {
    //           text(text=text, size=size, valign="center", halign="center");
    //       }
    //   }

This doesn't have immediately visible markdown output, but you *can* use that code in later examples:

    // Example:
    //   text3d("Foobar");


Section Block
-------------

Section blocks take a title, and an optional body that will be shown as the description of the Section.  If a body line if just a `.` (dot, period), then that line is treated as a blank line in the output:

    // Section: Foobar
    //   You can have several lines of markdown formatted text here.
    //   You just need to make sure that each line is indented, with
    //   at least three spaces after the comment marker.  You can
    //   denote a paragraph break with a comment line with three
    //   trailing spaces, or just a period.
    //   .
    //   You can have links in this text to functions, modules, or
    //   constants in other files by putting the name in double-
    //   braces like {{cyl()}} or {{lerp()}} or {{DOWN}}.  If you want to
    //   link to another file, or section in another file you can use
    //   a manual markdown link like [Section: Cuboids](shapes.scad#section-cuboids).
    //   .
    //   The end of the block is denoted by a line without a comment.
    //   or a line that is unindented after the comment.

Which outputs Markdown code that renders like:

> ## Section: Foobar
> You can have several lines of markdown formatted text here.
> You just need to make sure that each line is indented, with
> at least three spaces after the comment marker.  You can
> denote a paragraph break with a comment line with three
> trailing spaces, or just a period.
>
> You can have links in this text to functions, modules, or
> constants in other files by putting the name in double-
> braces like [cyl()](shapes.scad#functionmodule-cyl) or [lerp()](math.scad#function-lerp) or [DOWN](constants.scad-down).  If you want to
> link to another file, or section in another file you can use
> a manual markdown link like [Section: Cuboids](shapes.scad#section-cuboids).
>
> The end of the block is denoted by a line without a comment.
> or a line that is unindented after the comment.

Sections can also include Figures; images generated from code that is not shown in a code block.


Subsection Block
----------------

Subsection blocks take a title, and an optional body that will be shown as the description of the Subsection.  A Subsection must be within a declared Section.  If a body line is just a `.` (dot, period), then that line is treated as a blank line in the output:

    // Subsection: Foobar
    //   You can have several lines of markdown formatted text here.
    //   You just need to make sure that each line is indented, with
    //   at least three spaces after the comment marker.  You can
    //   denote a paragraph break with a comment line with three
    //   trailing spaces, or just a period.
    //   .
    //   You can have links in this text to functions, modules, or
    //   constants in other files by putting the name in double-
    //   braces like {{cyl()}} or {{lerp()}} or {{DOWN}}.  If you want to
    //   link to another file, or section in another file you can use
    //   a manual markdown link like [Subsection: Foo](shapes.scad#subsection-foo).
    //   .
    //   The end of the block is denoted by a line without a comment.
    //   or a line that is unindented after the comment.

Which outputs Markdown code that renders like:

> ## Subsection: Foobar
> You can have several lines of markdown formatted text here.
> You just need to make sure that each line is indented, with
> at least three spaces after the comment marker.  You can
> denote a paragraph break with a comment line with three
> trailing spaces, or just a period.
>
> You can have links in this text to functions, modules, or
> constants in other files by putting the name in double-
> braces like [cyl()](shapes.scad#functionmodule-cyl) or [lerp()](math.scad#function-lerp) or [DOWN](constants.scad-down).  If you want to
> link to another file, or section in another file you can use
> a manual markdown link like [Subsection: Foo](shapes.scad#subsection-foo).
>
> The end of the block is denoted by a line without a comment.
> or a line that is unindented after the comment.

Subsections can also include Figures; images generated from code that is not shown in a code block.


Item Blocks
-----------

Item blocks headers come in four varieties: `Constant`, `Function`, `Module`, and `Function&Module`.

The `Constant` header is used to document a code constant.  It should have a Description sub-block, and Example sub-blocks are recommended:

    // Constant: PHI
    // Description: The golden ratio phi.
    PHI = (1+sqrt(5))/2;

Which outputs Markdown code that renders like:

> ### Constant: PHI
> **Description:**
> The golden ration phi.


The `Module` header is used to document a module.  It should have a Description sub-block. It is recommended to also have Usage, Arguments, and Example/Examples sub-blocks.  The Usage sub-block body lines are also used when constructing the Cheat Sheet index file:

    // Module: cross()
    // Usage:
    //   cross(size);
    // Description:
    //   Creates a 2D cross/plus shape.
    // Arguments:
    //   size = The scalar size of the cross.
    // Example(2D):
    //   cross(size=100);
    module cross(size=1) {
        square([size, size/3], center=true);
        square([size/3, size], center=true);
    }

Which outputs Markdown code that renders like:

> ### Module: cross()
> **Usage:**
> - cross(size);
> 
> **Description:**
> Creates a 2D cross/plus shape.
> 
> **Arguments:**
> Positional Arg | What it does
> -------------------- | -------------------
> size                   | The scalar size of the cross.
> 
> **Example:**
> ```openscad
> cross(size=100);
> ```
> GENERATED IMAGE GOES HERE


The `Function` header is used to document a function.  It should have a Description sub-block. It is recommended to also have Usage, Arguments, and Example/Examples sub-blocks.  By default, Examples will not generate images for function blocks.  Usage sub-block body lines are also used when constructing the Cheat Sheet index file:

    // Function: vector_angle()
    // Usage:
    //   ang = vector_angle(v1, v2);
    // Description:
    //   Calculates the angle between two vectors in degrees.
    // Arguments:
    //   v1 = The first vector.
    //   v2 = The second vector.
    // Example:
    //   v1 = [1,1,0];
    //   v2 = [1,0,0];
    //   angle = vector_angle(v1, v2);
    //   // Returns: 45
    function vector_angle(v1,v2) =
    acos(max(-1,min(1,(vecs[0]*vecs[1])/(norm0*norm1))));

Which outputs Markdown code that renders like:

> ### Function: vector_angle()
> **Usage:**
> - ang = vector_angle(v1, v2);
> 
> **Description:**
> Calculates the angle between two vectors in degrees.
> 
> **Arguments:**
> Positional Arg | What it does
> -------------------- | -------------------
> `v1`                | The first vector.
> `v2`                | The second vector.
> 
> **Example:**
> ```openscad
> v1 = [1,1,0];
> v2 = [1,0,0];
> angle = vector_angle(v1, v2);
> // Returns: 45
> ```

The `Function&Module` header is used to document a function which has a related module of the same name.  It should have a Description sub-block.  It is recommended to also have Usage, Arguments, and Example/Examples sub-blocks. You should have Usage blocks for both calling as a function, and calling as a module.  Usage sub-block body lines are also used in constructing the Cheat Sheet index file:

    // Function&Module: oval()
    // Topics: 2D Shapes, Geometry
    // Usage: As a Module
    //   oval(rx,ry);
    // Usage: As a Function
    //   path = oval(rx,ry);
    // Description:
    //   When called as a function, returns the perimeter path of the oval.
    //   When called as a module, creates a 2D oval shape.
    // Arguments:
    //   rx = X axis radius.
    //   ry = Y axis radius.
    // Example(2D): Called as a Function
    //   path = oval(100,60);
    //   polygon(path);
    // Example(2D): Called as a Module
    //   oval(80,60);
    module oval(rx,ry) {
        polygon(oval(rx,ry));
    }
    function oval(rx,ry) =
        [for (a=[360:-360/$fn:0.0001]) [rx*cos(a),ry*sin(a)];

Which outputs Markdown code that renders like:

> ### Function&Module: oval()
> **Topics:** 2D Shapes, Geometry
>
> **Usage:** As a Module
>
> - oval(rx,ry);
>
> **Usage:** As a Function
>
> - path = oval(rx,ry);
>
> **Description:**
> When called as a function, returns the perimeter path of the oval.
> When called as a module, creates a 2D oval shape.
>
> **Arguments:**
> Positional Arg | What it does
> -------------------- | -------------------
> rx | X axis radius.
> ry | Y axis radius.
>
> **Example:** Called as a Function
>
> ```openscad
> path = oval(100,60);
> polygon(path);
> ```
> GENERATED IMAGE SHOWN HERE
>
> **Example:** Called as a Module
>
> ```openscad
> oval(80,60);
> ```
> GENERATED IMAGE SHOWN HERE

These Type blocks can have a number of sub-blocks.  Most sub-blocks are optional,  The available standard sub-blocks are:

- `// Aliases: alternatename(), anothername()`
- `// Status: DEPRECATED`
- `// Topics: Comma, Delimited, Topic, List`
- `// Usage:`
- `// Description:`
- `// Figure:` or `// Figures`
- `// Continues:`
- `// Arguments:`
- `// See Also: otherfunc(), othermod(), OTHERCONST`
- `// Example:` or `// Examples:`


Aliases Block
-------------

The Aliases block is used to give alternate names for a function, module, or
constant.  This is reflected in the indexes generated.  It looks like:

    // Aliases: secondname(), thirdname()

Which outputs Markdown code that renders like:

> **Aliases:** secondname(), thirdname()


Status Block
------------

The Status block is used to mark a function, module, or constant as deprecated:

    // Status: DEPRECATED, use foo() instead

Which outputs Markdown code that renders like:

> **Status:** DEPRECATED, use foo() instead


Topics Block
------------

The Topics block can associate various topics with the current function or module.  This can be used to make an index of Topics:

    // Topics: 2D Shapes, Geometry, Masks

Which outputs Markdown code that renders like:

> **Topics:** 2D Shapes, Geometry, Masks


Usage Block
-----------

The Usage block describes the various ways that the current function or module can be called, with the names of the arguments.  By convention, the first few arguments that can be called positionally just have their name shown.  The remaining arguments that should be passed by name, will have the name followed by an `=` (equal sign).  Arguments that are optional in the given Usage context are shown in `[` and `]` angle brackets.  Usage sub-block body lines are also used when constructing the Cheat Sheet index file:

    // Usage: As a Module
    //   oval(rx, ry, <spin=>);
    // Usage: As a Function
    //   path = oval(rx, ry, <spin=>);

Which outputs Markdown code that renders like:

> **Usage:** As a Module
> - oval(rx, ry, <spin=>);
> 
> **Usage:** As a Function
> 
> - path = oval(rx, ry, <spin=>);


Description Block
-----------------
The Description block just describes the currect function, module, or constant:

    // Descripton: This is the description for this function or module.
    //   It can be multiple lines long.  Markdown syntax code will be used
    //   verbatim in the output markdown file, with the exception of `_`,
    //   which will traslate to `\_`, so that underscores in function/module
    //   names don't get butchered.  A line with just a period (`.`) will be
    //   treated as a blank line.
    //   .
    //   You can have links in this text to functions, modules, or
    //   constants in other files by putting the name in double-
    //   braces like {{cyl()}} or {{lerp()}} or {{DOWN}}.  If you want to
    //   link to another file, or section in another file you can use
    //   a manual markdown link like [Section: Cuboids](shapes.scad#section-cuboids).

Which outputs Markdown code that renders like:

> **Description:**
> It can be multiple lines long.  Markdown syntax code will be used
> verbatim in the output markdown file, with the exception of `_`,
> which will traslate to `\_`, so that underscores in function/module
> names don't get butchered.  A line with just a period (`.`) will be
> treated as a blank line.
> 
> You can have links in this text to functions, modules, or
> constants in other files by putting the name in double-
> braces like [cyl()](shapes.scad#functionmodule-cyl) or [lerp()](math.scad#function-lerp) or [DOWN](constants.scad-down).  If you want to
> link to another file, or section in another file you can use
> a manual markdown link like [Section: Cuboids](shapes.scad#section-cuboids).


Continues Block
---------------
The Continues block can be used to continue the body text of a previous block that has been interrupted by a Figure:

    // Descripton: This is the description for this function or module.  It can be
    //   many lines long.  If you need to show an image in the middle of this text,
    //   you can use a Figure, like this:
    // Figure(2D): A circle with a square cutout.
    //   difference() {
    //       circle(d=100);
    //       square(100/sqrt(2), center=true);
    //   }
    // Continues: You can continue the description text here.  It can also be
    //   multiple lines long.  This continuation will not print a header.

Which outputs Markdown code that renders like:

> **Descripton:**
> This is the description for this function or module.  It can be
> many lines long.  If you need to show an image in the middle of this text,
> you can use a Figure, like this:
>
> **Figure 1:** A circle with a square cutout.
> GENERATED IMAGE SHOWN HERE
>
> You can continue the description text here.  It can also be
> multiple lines long.  This continuation will not print a header.
>


Arguments Block
---------------
The Arguments block creates a table that describes the positional arguments for a function or module, and optionally a second table that describes named arguments:

    // Arguments:
    //   v1 = This supplies the first vector.
    //   v2 = This supplies the second vector.
    //   ---
    //   fast = Use fast, but less comprehensive calculation method.
    //   bar = Takes an optional `bar` struct.  See {{bar()}}.
    //   dflt = Default value.

Which outputs Markdown code that renders like:

> **Arguments:**
> Positional Arg | What it Does
> -------------- | ---------------------------------
> `v1`           | This supplies the first vector. 
> `v2`           | The supplies the second vector. 
>  
> Named Arg      | What it Does
> -------------- | ---------------------------------
> `fast`         | If true, use fast, but less accurate calculation method. 
> `bar`          | Takes an optional `bar` struct.  See [bar()](foobar.scad#function-bar).
> `dflt`         | Default value.


See Also Block
--------------

The See Also block is used to give links to related functions, modules, or
constants.  It looks like:

    // See Also: relatedfunc(), similarmodule()

Which outputs Markdown code that renders like:

> **See Also:** [relatedfunc()](otherfile.scad#relatedfunc), [similarmodule()](otherfile.scad#similarmodule)


Figure Block
--------------

A Figure block generates and shows an image from a script in the multi-line body, by running it in OpenSCAD.  A Figures block (plural) does the same, but treats each line of the body as a separate Figure block:

    // Figure: Figure description
    //   cylinder(h=100, d1=75, d2=50);
    //   up(100) cylinder(h=100, d1=50, d2=75);
    // Figure(Spin,VPD=444): Animated figure that spins to show all faces.
    //   cube([10,100,50], center=true);
    //   cube([100,10,30], center=true);
    // Figures:
    //   cube(100);
    //   cylinder(h=100,d=50);
    //   sphere(d=100);

Which outputs Markdown code that renders like:

> **Figure 1:** Figure description
> GENERATED IMAGE SHOWN HERE
> 
> **Figure 2:** Animated figure that spins to show all faces.
> GENERATED IMAGE SHOWN HERE
> 
> **Figure 3:**
> GENERATED IMAGE OF CUBE SHOWN HERE
> 
> **Figure 4:**
> GENERATED IMAGE OF CYLINDER SHOWN HERE
> 
> **Figure 5:**
> GENERATED IMAGE OF SPHERE SHOWN HERE

The metadata of the Figure block can contain various directives to alter how
the image will be generated.  These can be comma separated to give multiple
metadata directives:

- `NORENDER`: Don't generate an image for this example, but show the example text.
- `Hide`: Generate, but don't show script or image.  This can be used to generate images to be manually displayed in markdown text blocks.
- `2D`: Orient camera in a top-down view for showing 2D objects.
- `3D`: Orient camera in an oblique view for showing 3D objects.
- `VPD=440`: Force viewpoint distance `$vpd` to 440.
- `VPT=[10,20,30]` Force the viewpoint translation `$vpt` to `[10,20,30]`.
- `VPR=[55,0,600]` Force the viewpoint rotation `$vpr` to `[55,0,60]`.
- `Spin`: Animate camera orbit around the `[0,1,1]` axis to display all sides of an object.
- `FlatSpin`: Animate camera orbit around the Z axis, above the XY plane.
- `Anim`: Make an animation where `$t` varies from `0.0` to almost `1.0`.
- `Frames=36`: Number of animation frames to make.
- `FrameMS=250`: Sets the number of milliseconds per frame for spins and animation.
- `FPS=8`: Sets the number of frames per second for spins and animation.
- `Small`: Make the image small sized.
- `Med`: Make the image medium sized.
- `Big`: Make the image big sized.
- `Huge`: Make the image huge sized.
- `Size=880x640`: Make the image 880 by 640 pixels in size.
- `ThrownTogether`: Render in Thrown Together view mode instead of Preview mode.
- `Render`: Force full rendering from OpenSCAD, instead of the normal Preview mode.
- `Edges`: Highlight face edges.
- `NoAxes`: Hides the axes and scales.
- `NoScales`: Hides the scale numbers along the axes.
- `ScriptUnder`: Display script text under image, rather than beside it.


Example Block
-------------

An Example block shows a script, and possibly shows an image generated from it.
The script is in the multi-line body.  The `Examples` (plural) block does
the same, but it treats eash body line as a separate Example bloc to show.
Any images, if generated, will be created by running it in OpenSCAD:

    // Example: Example description
    //   cylinder(h=100, d1=75, d2=50);
    //   up(100) cylinder(h=100, d1=50, d2=75);
    // Example(Spin,VPD=444): Animated shape that spins to show all faces.
    //   cube([10,100,50], center=true);
    //   cube([100,10,30], center=true);
    // Examples:
    //   cube(100);
    //   cylinder(h=100,d=50);
    //   sphere(d=100);

Which outputs Markdown code that renders like:

> **Example 1:** Example description
> ```openscad
> cylinder(h=100, d1=75, d2=50);
> up(100) cylinder(h=100, d1=50, d2=75);
> ```
> GENERATED IMAGE SHOWN HERE
> 
> **Example 2:** Animated shape that spins to show all faces.
> ```openscad
> cube([10,100,50], center=true);
> cube([100,10,30], center=true);
> ```
> GENERATED IMAGE SHOWN HERE
> 
> **Example 3:**
> ```openscad
> cube(100);
> ```
> GENERATED IMAGE OF CUBE SHOWN HERE
> 
> **Example 4:**
> ```openscad
> cylinder(h=100,d=50);
> ```
> GENERATED IMAGE OF CYLINDER SHOWN HERE
> 
> **Example 5:**
> ```openscad
> sphere(d=100);
> ```
> GENERATED IMAGE OF SPHERE SHOWN HERE

The metadata of the Example block can contain various directives to alter how
the image will be generated.  These can be comma separated to give multiple
metadata directives:

- `NORENDER`: Don't generate an image for this example, but show the example text.
- `Hide`: Generate, but don't show script or image.  This can be used to generate images to be manually displayed in markdown text blocks.
- `2D`: Orient camera in a top-down view for showing 2D objects.
- `3D`: Orient camera in an oblique view for showing 3D objects. Often used to force an Example sub-block to generate an image in Function and Constant blocks.
- `VPD=440`: Force viewpoint distance `$vpd` to 440.
- `VPT=[10,20,30]` Force the viewpoint translation `$vpt` to `[10,20,30]`.
- `VPR=[55,0,600]` Force the viewpoint rotation `$vpr` to `[55,0,60]`.
- `Spin`: Animate camera orbit around the `[0,1,1]` axis to display all sides of an object.
- `FlatSpin`: Animate camera orbit around the Z axis, above the XY plane.
- `Anim`: Make an animation where `$t` varies from `0.0` to almost `1.0`.
- `FrameMS=250`: Sets the number of milliseconds per frame for spins and animation.
- `Frames=36`: Number of animation frames to make.
- `Small`: Make the image small sized.
- `Med`: Make the image medium sized.
- `Big`: Make the image big sized.
- `Huge`: Make the image huge sized.
- `Size=880x640`: Make the image 880 by 640 pixels in size.
- `Render`: Force full rendering from OpenSCAD, instead of the normal preview.
- `Edges`: Highlight face edges.
- `NoAxes`: Hides the axes and scales.
- `ScriptUnder`: Display script text under image, rather than beside it.

Modules will default to generating and displaying the image as if the `3D`
directive is given.  Functions and constants will default to not generating
an image unless `3D`, `Spin`, `FlatSpin` or `Anim` is explicitly given.

If any lines of the Example script begin with `--`, then they are not shown in
the example script output to the documentation, but they *are* included in the
script used to generate the example image, without the `--`, of course:

    // Example: Multi-line example.
    //   --$fn = 72; // Lines starting with -- aren't shown in docs example text.
    //   lst = [
    //       "multi-line examples",
    //       "are shown in one block",
    //       "with a single image.",
    //   ];
    //   foo(lst, 23, "blah");


Creating Custom Block Headers
=============================

If you have need of a non-standard documentation block in your docs, you can declare the new block type using `DefineHeader:`.  This has the syntax:

    // DefineHeader(TYPE): NEWBLOCKNAME

or:

    // DefineHeader(TYPE;OPTIONS): NEWBLOCKNAME

Where NEWBLOCKNAME is the name of the new block header, OPTIONS is an optional list of zero or more semicolon-separated header options, and TYPE defines the behavior of the new block.  TYPE can be one of:

- `Generic`: Show both the TitleText and body.
- `Text`: Show the TitleText as the first line of the body.
- `Headerless`: Show the TitleText as the first line of the body, with no header line.
- `Label`: Show only the TitleText and no body.
- `NumList`: Shows TitleText, and the body lines in a numbered list.
- `BulletList`: Shows TitleText, and the body lines in a bullet list.
- `Table`: Shows TitleText, and body lines in a definition table.
- `Figure`: Shows TitleText, and an image rendered from the script in the Body.
- `Example`: Like Figure, but also shows the body as an example script.

The OPTIONS are zero or more semicolon separated options for defining the header options.  Some of them only require the option name, like `Foo`, and some have an option name and a value separated by an equals sign, like `Foo=Bar`.  There is currently only one option common to all header types:

- `ItemOnly`: Specify that the new header is only allowed as part of the documentation block for a Constant, Function, or Module.

Generic Block Type
------------------

The Generic block header type takes both title and body lines and generates a markdown block that has the block header, title, and a following body:

    // DefineHeader(Generic): Result
    // Result: For Typical Cases
    //   Does typical things.
    //   Or something like that.
    //   Refer to {{stuff()}} for more info.
    // Result: For Atypical Cases
    //   Performs an atypical thing.

Which outputs Markdown code that renders like:

> **Result:** For Typical Cases
>
> Does typical things.
> Or something like that.
> Refer to [stuff()](foobar.scad#function-stuff) for more info.
>
> **Result:** For Atypical Cases
>
> Performs an atypical thing.
>


Text Block Type
---------------

The Text block header type is similar to the Generic type, except it merges the title into the body.  This is useful for allowing single-line or multi-line blocks:

    // DefineHeader(Text): Reason
    // Reason: This is a simple reason.
    // Reason: This is a complex reason.
    //   It is a multi-line explanation
    //   about why this does what it does.
    //   Refer to {{nonsense()}} for more info.

Which outputs Markdown code that renders like:

> **Reason:**
>
> This is a simple reason.
>
> **Reason:**
>
> This is a complex reason.
> It is a multi-line explanation
> about why this does what it does.
> Refer to [nonsense()](foobar.scad#function-nonsense) for more info.
>

Headerless Block Type
---------------------

The Headerless block header type is similar to the Generic type, except it merges the title into the body, and generates no header line.

    // DefineHeader(Headerless): Explanation
    // Explanation: This is a simple explanation.
    // Explanation: This is a complex explanation.
    //   It is a multi-line explanation
    //   about why this does what it does.
    //   Refer to {{nonsense()}} for more info.

Which outputs Markdown code that renders like:

> This is a simple explanation.
>
> This is a complex explanation.
> It is a multi-line explanation
> about why this does what it does.
> Refer to [nonsense()](foobar.scad#function-nonsense) for more info.
>


Label Block Type
----------------

The Label block header type takes just the title, and shows it with the header:

    // DefineHeader(Label): Regions
    // Regions: Antarctica, New Zealand
    // Regions: Europe, Australia

Which outputs Markdown code that renders like:

> **Regions:** Antarctica, New Zealand
> **Regions:** Europe, Australia


NumList Block Type
------------------

The NumList block header type takes both title and body lines, and outputs a
numbered list block:

    // DefineHeader(NumList): Steps
    // Steps: How to handle being on fire.
    //   Stop running around and panicing.
    //   Drop to the ground.  Refer to {{drop()}}.
    //   Roll on the ground to smother the flames.

Which outputs Markdown code that renders like:

> **Steps:** How to handle being on fire.
>
> 1. Stop running around and panicing.
> 2. Drop to the ground.  Refer to [drop()](foobar.scad#function-drop).
> 3. Roll on the ground to smother the flames.
>


BulletList Block Type
---------------------

The BulletList block header type takes both title and body lines:

    // DefineHeader(BulletList): Side Effects
    // Side Effects: For Typical Uses
    //   The variable {{$foo}} gets set.
    //   The default for subsequent calls is updated.

Which outputs Markdown code that renders like:

> **Side Effects:** For Typical Uses
>
> - The variable [$foo](foobar.scad#function-foo) gets set.
> - The default for subsequent calls is updated.
>


Table Block Type
----------------

The Table block header type outputs a header block with the title, followed by one or more tables.  This is generally meant for definition lists.  The header names are given as the `Headers=` option in the DefineHeader metadata.  Header names are separated by `|` (vertical bar, or pipe) characters, and sets of headers (for multiple tables) are separated by `||` (two vertical bars).  A header that starts with the `^` (hat, or circumflex) character, will cause the items in that column to be surrounded by \`foo\` literal markers.  Cells in the body content are separated by `=` (equals signs):

    // DefineHeader(Table;Headers=^Link Name|Description): Anchors
    // Anchors: by Name
    //   "link1" = Anchor for the joiner Located at the {{BACK}} side of the shape.
    //   "a"/"b" = Anchor for the joiner Located at the {{FRONT}} side of the shape.

Which outputs Markdown code that renders like:

> **Anchors:** by Name
>
> Link Name      | Description
> -------------- | --------------------
> `"link1"`      | Anchor for the joiner at the [BACK](constants.scad#constant-back) side of the shape.
> `"a"` / `"b"`  | Anchor for the joiner at the [FRONT](constants.scad#constant-front) side of the shape.
>

You can have multiple subtables, separated by a line with only three dashes: `---`:

    // DefineHeader(Table;Headers=^Pos Arg|What it Does||^Names Arg|What it Does): Args
    // Args:
    //   foo = The foo argument.
    //   bar = The bar argument.
    //   ---
    //   baz = The baz argument.
    //   qux = The baz argument.

Which outputs Markdown code that renders like:

> **Args:**
>
> Pos Arg     | What it Does
> ----------- | --------------------
> `foo`       | The foo argument.
> `bar`       | The bar argument.
>
> Named Arg   | What it Does
> ----------- | --------------------
> `baz`       | The baz argument.
> `qux`       | The qux argument.
>


Defaults Configuration
======================

The `openscad_decsgen` script looks for an `.openscad_docsgen_rc` file in the source code directory it is run in.  In that file, you can give a few defaults for what files will be processed, and where to save the generated documentation.

---

To specify what directory to write the output documentation to, you can use the DocsDirectory block:

    DocsDirectory: wiki_dir

---

To specify what target profile to output for, use the TargetProfile block.  You must specify either `wiki` or `githubwiki` as the value:

    TargetProfile: githubwiki

---

To specify what the project name is, use the ProjectName block, like this:

    ProjectName: My Project Name

---

To specify what types of files will be generated, you can use the GenerateDocs block.  You give it a comma separated list of docs file types like this:

    GenerateDocs: Files, ToC, Index, Topics, CheatSheet, Sidebar

Where the valid docs file types are as follows:

- `Files`: Generate a documentation file for each .scad input file.  Generates Images.
- `ToC`: Generate a project-wide Table of Contents file.
- `Index`: Generate an alphabetically sorted function/module/constants index file.
- `Topics`: Generate an index file of topics, sorted alphabetically.
- `CheatSheet`: Generate a CheatSheet summary of function/module Usages.
- `Cheat`: The same as `CheatSheet`.
- `Sidebar`: Generate a \_Sidebar index of files.

---

To ignore specific files, to prevent generating documentation for them, you can use the IgnoreFiles block.   Note that the commentline prefix is not needed in the configuration file:

    IgnoreFiles:
      ignored1.scad
      ignored2.scad
      tmp_*.scad

---

To prioritize the ordering of files when generating the Table of Contents and other indices, you can use the PrioritizeFiles block:

    PrioritizeFiles:
      file1.scad
      file2.scad

---

You can also use the DefineHeader block in the config file to make custom block headers:

    DefineHeader(Text;ItemOnly): Returns
    DefineHeader(BulletList): Side Effects
    DefineHeader(Table;Headers=^Anchor Name|Position): Extra Anchors



