# Formatting Comments for Docs

Documentation and example images are generated automatically from source code comments by the `scripts/docs_gen.py` script.  Not all comments are added to the wiki.  Just those comment blocks starting with certain keywords:

- `// LibFile: NAME`
- `// Section: NAME`
- `// Constant: NAME`
- `// Function: NAME`
- `// Module: NAME`
- `// Function&Module: NAME`

## LibFile:

LibFile blocks can be followed by multiple lines that can be added as markdown text after the header. Indentation is important, as it denotes the end of block.

```
// LibFile: foo.scad
//   You can have several lines of markdown formatted text here.
//   You just need to make sure that each line is indented, with
//   at least three spaces after the comment marker.  You can
//   denote a paragraph break with a comment line with three
//   trailing spaces, or just a period.
//   .
//   The end of the block is denoted by a line without a comment.
```

## Includes:

Include blocks contain code that all examples in the file should show and use.  This is generally used for `include <file>` and `use <file>` commands.  Indentation is important.  Less than three spaces indent denotes the end of the block

```
// Includes:
//   include <BOSL2/std.scad>
//   use <foo.scad>
```

## CommonCode:

CommonCode blocks can be used to denote code that can be shared between all of the Figure and Example blocks in the file, without being shown itself.  Indentation is important.  Less than three spaces indent denotes the end of the block

```
// CommonCode:
//   module text3d(text, h=0.01, size=3) {
//       linear_extrude(height=h, convexity=10) {
//           text(text=text, size=size, valign="center", halign="center");
//       }
//   }
```

## Section:

Section blocks can be followed by multiple lines that can be added as markdown text after the header. Indentation is important, as it denotes the end of block.

Sections can also include Figures; images generated from code that is not shown in a code block.

```
// Section: Foobar
//   You can have several lines of markdown formatted text here.
//   You just need to make sure that each line is indented, with
//   at least three spaces after the comment marker.  You can
//   denote a paragraph break with a comment line with three
//   trailing spaces, or just a period.
//   .
//   The end of the block is denoted by a line without a comment.
//   or a line that is unindented after the comment.
// Figure: Figure description
//   cylinder(h=100, d1=75, d2=50);
//   up(100) cylinder(h=100, d1=50, d2=75);
// Figure(Spin): Animated figure that spins to show all faces.
//   cube([10,100,50], center=true);
//   cube([100,10,30], center=true);
```

## Module:/Function:/Function&Module:/Constant:

Module, Function, and Constant docs blocks all have a similar specific format.  Most sub-blocks are optional, except the Module/Function/Constant line, and the Description block.

Valid sub-blocks are:

- `Status: DEPRECATED, use blah instead.` - Optional, used to denote deprecation.
- `Usage: Optional Usage Title` - Optional.  Multiple allowed.  Followed by an indented block of usage patterns.  Optional arguments should be in braces like `[opt]`.  Alternate args should be separated by a vertical bar like `r|d`. 
- `Description:` - Can be single-line or a multi-line block of the description.
- `Figure: Optional Figure Title` - Optional.  Multiple allowed.  Followed by a multi-line code block used to create a figure image.  The code will not be shown.  All figures will follow the Description block.
- `Returns:` - Can be single-line or a multi-line block, describing the return value of this function.
- `Custom: Foo` - Creates a text block labeled `Foo:` followed by the given multi-line block of text.
- `Arguments:` - Denotes start of an indented block of argument descriptions.  Each line has the argument name, a space, an equals, another space, then the description for the argument all on one line. Like `arg = The argument description`.  If you really need to explain an argument in longer form, explain it in the Description.  If an argument line is just `---`, then the arguments table is split into two tables, with the positional arguments before the `---` and arguments that should always be passed by name after.
- `Side Effects:` - Denotes the start of a block describing the side effects, such as `$special_var`s that are set.
- `Extra Anchors:` - Denotes the start of an indented block of available non-standard named anchors for a part.
- `Topics: Topic1, Topic2, Topic2, etc.` - Lets you list topics related to this fuction or module.
- `Example:` - Denotes the beginning of a multi-line example code block.
- `Examples:` - Denotes the beginning of a block of examples, where each line will be shows as a separate example with a separate image if needed.

Modules blocks will generate images for each example or figure block. Function and Constant blocks will only generate images for example blocks if they have `2D` or `3D` tags.  Example and figure blocks can have tags added by putting then inside parentheses before the colon.  Ie: `Examples(BigFlatSpin):` or `Figure(2D):`.

The full set of optional example tags are:

- `2D`: Orient camera in a top-down view for showing 2D objects.
- `3D`: Orient camera in an oblique view for showing 3D objects. Used to force an Example sub-block to generate an image in Function and Constant blocks.
- `NORENDER`: Don't generate an image for this example, but show the example text.
- `Hide`: Don't show example text or image.  This can be used to generate images to be manually displayed in markdown text blocks.
- `Small`: Make the image small sized.  (The default)
- `Med`: Make the image medium sized.
- `Big`: Make the image big sized.
- `Huge`: Make the image huge sized.
- `Spin`: Animate camera orbit around the `[0,1,1]` axis to display all sides of an object.
- `FlatSpin`: Animate camera orbit around the Z axis, above the XY plane.
- `FR`: Force full rendering from OpenSCAD, instead of the normal preview.
- `Edges`: Highlight face edges.

Indentation is important, as it denotes the end of sub-block.

```
// Module: foo()
// Status: DEPRECATED, use BLAH instead.
// Usage: Optional Usage Description
//   foo(foo, bar, [qux]);
//   foo(bar, baz, [qux]);
// Usage: Another Optional Usage Description
//   foo(foo, flee, flie, [qux])
// Description: Short description.
// Description:
//   A longer, multi-line description.  If multiple description blocks exist,
//   they are all are added together.  You can use most *markdown* notation
//   as well.  You can have paragraph breaks by having a line with just a
//   period, like this:
//   .
//   You can end multi-line blocks by un-indenting the next
//   line, or by using a comment with no spaces like this:
//
// Figure: Figure description
//   cylinder(h=100, d1=75, d2=50);
//   up(100) cylinder(h=100, d1=50, d2=75);
// Figure(Spin): Animated figure that spins to show all faces.
//   cube([10,100,50], center=true);
//   cube([100,10,30], center=true);
//
// Returns: A description of the return value.
//
// Custom: Custom Block Title
//   Multi-line text to be shown in the custom block.
//
// Arguments:
//   foo = This is the description of the first positional argument, foo.  All on one line.
//   bar = This is the description of the second positional argument, bar.  All on one line.
//   baz = This is the description of the third positional argument, baz.  All on one line.
//   ---
//   qux = This is the description of the named argument qux.  All on one line.
//   flee = This is the description of the named argument flee.  All on one line.
// Side Effects:
//   `$floo` gets set to the floo value.
// Extra Anchors:
//   "blawb" = An anchor at the blawb point of the part, oriented upwards.
//   "fewble" = An anchor at the fewble connector of the part, oriented back yowards Y+.
// Topics: Fubar, Barbie, Bazil
// Examples: Each line below gets its own example block and image.
//   foo(foo="a", bar="b");
//   foo(foo="b", baz="c");
// Example: Multi-line example.
//   --$vpr = [55,0,120]; // Lines starting with `--` aren't shown in docs example text.
//   lst = [
//       "multi-line examples",
//       "are shown in one block",
//       "with a single image.",
//   ];
//   foo(lst, 23, "blah");
// Example(2D): Example to show as 2D top-down rendering.
//   foo(foo="b", baz="c", qux=true);
// Example(Spin): Example orbiting the [0,1,1] axis.
//   foo(foo="b", baz="c", qux="full");
// Example(FlatSpin): Example orbiting the Z axis from above.
//   foo(foo="b", baz="c", qux="full2");
```



