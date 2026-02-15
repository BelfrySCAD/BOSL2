# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BOSL2 (Belfry OpenSCAD Library v2) is a comprehensive OpenSCAD library providing modeling tools, transformations, shapes, attachments, and parts. It requires OpenSCAD 2021.01 or later. The library is in beta status.

## Common Commands

### Running Tests

Run all regression tests:
```bash
./scripts/run_tests.sh
```

Run a single test file:
```bash
./scripts/run_tests.sh tests/test_shapes3d.scad
```

On macOS, the test runner uses `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`. On Linux, it uses `openscad` from PATH.

Tests pass when OpenSCAD exits with code 0 and produces no output. Any output or non-zero exit indicates failure.

### Checking for Tabs

```bash
./scripts/check_for_tabs.sh
```
All `.scad` files must use spaces only (no tabs). Indentation: 4 spaces.

### Documentation Validation

Requires the `openscad-docsgen` Python package (`pip install openscad-docsgen`):
```bash
openscad-docsgen -Tmf
```

### Function Coverage Analysis

```bash
python3 scripts/func_coverage.py
```

## Architecture

### Entry Point and Dependency Order

`std.scad` is the main include file. Users write `include <BOSL2/std.scad>` to get the standard library. It includes files in a specific dependency order:

`version` → `constants` → `transforms` → `distributors` → `miscellaneous` → `color` → `attachments` → `beziers` → `shapes3d` → `shapes2d` → `drawing` → `masks` → `math` → `paths` → `lists` → `comparisons` → `linalg` → `trigonometry` → `vectors` → `affine` → `coords` → `geometry` → `regions` → `strings` → `vnf` → `structs` → `rounding` → `skin` → `utility` → `partitions`

Specialized modules (gears, screws, threading, hinges, etc.) are **not** included by `std.scad` and must be included separately by users.

### Key Subsystems

- **Attachment system** (`attachments.scad`): Core mechanism for positioning children relative to parents using anchor points, without manual coordinate tracking. Most shapes support `anchor`, `spin`, and `orient` parameters.
- **VNF** (`vnf.scad`): Vertices 'N' Faces representation for polyhedra manipulation. Many functions can return VNF data via function form.
- **Paths/Regions** (`paths.scad`, `regions.scad`): 2D point-list operations for curves and polygon regions.
- **Skinning/Sweeping** (`skin.scad`): Creates 3D objects by sweeping profiles along paths.
- **Rounding** (`rounding.scad`): Edge rounding, filleting, and offset_sweep operations.

### Dual Function/Module Pattern

Many BOSL2 items exist as both OpenSCAD functions and modules (documented as `Function&Module`). The function form returns data (VNF, path, matrix), while the module form creates geometry. Example: `cube()` as a module creates a shape; as a function it returns a VNF.

### Include Guard Pattern

Each file has a guard at the top that warns if included without `std.scad`:
```openscad
_BOSL2_FILENAME = is_undef(_BOSL2_STD) && ... ?
    echo("Warning: filename.scad included without std.scad") true : true;
```

## Writing Tests

Test files go in `tests/` named `test_<module>.scad`. Pattern:
```openscad
include <../std.scad>

module test_function_name() {
    assert(function_name(args) == expected);
}
test_function_name();
```

Each test is a module containing `assert()` calls, immediately invoked after definition. Tests must produce zero output to pass.

## Documentation Format

Every public function/module must have documentation comments following the custom block syntax parsed by `openscad-docsgen`. Required blocks:

```openscad
// Function&Module: name()
// Synopsis: One-line summary.
// Topics: Topic1, Topic2
// See Also: related_func()
// Usage: As Module
//   name(arg1, arg2);
// Usage: As Function
//   result = name(arg1, arg2);
// Description:
//   Detailed description. Supports markdown.
//   Link to other items with {{other_func()}} syntax.
// Arguments:
//   arg1 = Description of arg1
//   arg2 = Description of arg2
// Example:
//   name(10, 20);
```

See `WRITING_DOCS.md` for the full documentation syntax reference. Configuration is in `.openscad_docsgen_rc`.

## Code Conventions

- Private functions/modules: prefix with underscore (`_helper_func()`)
- Public names: lowercase with underscores
- Constants: UPPERCASE (`UP`, `DOWN`, `LEFT`, `RIGHT`, `FRONT`, `BACK`)
- Special variables use `$` prefix (`$slop`, `$fn`)
- Files end with: `// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap`
- No tabs in `.scad` files; use 4-space indentation

## CI Pipeline

Pull requests run three checks:
1. **Regressions**: Runs `scripts/run_tests.sh`
2. **CheckTutorials**: Validates tutorial markdown and images
3. **CheckDocs**: Validates all documentation blocks with `openscad-docsgen -Tmf`
