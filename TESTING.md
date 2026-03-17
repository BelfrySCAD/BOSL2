# Testing BOSL2

BOSL2 uses the [`openscad-test`](https://pypi.org/project/openscad-test/) framework for regression testing. Tests are defined in `tests/test_*.scadtest` files — one file per BOSL2 module.

## Requirements

- OpenSCAD 2021.01 or later
- Python 3.x with `openscad-test` installed:
  ```bash
  pip install openscad-test
  ```

## Running Tests

Run all regression tests from the BOSL2 root directory:
```bash
./scripts/run_tests.sh
```

Run tests for a specific module:
```bash
openscad-test tests/test_transforms.scadtest
```

Run tests for multiple specific modules:
```bash
openscad-test tests/test_math.scadtest tests/test_lists.scadtest
```

## Writing Tests

Each `tests/test_<module>.scadtest` file contains one `[[test]]` entry per function or module being tested. Tests are written in TOML format using TOML literal multiline strings (`'''`) for the inline OpenSCAD script.

### Basic structure

```toml
[[test]]
name = "test_my_function"
script = '''
include <../std.scad>

module test_my_function() {
    assert(my_function(1, 2) == 3);
    assert_approx(my_function(1.5, 2.5), 4.0);
}
test_my_function();
'''
```

The `include <../std.scad>` path resolves relative to the `tests/` directory. For modules not included by `std.scad`, add the extra include:

```toml
[[test]]
name = "test_something"
script = '''
include <../std.scad>
include <../fnliterals.scad>

module test_something() {
    assert(something() == expected);
}
test_something();
'''
```

### Test pass/fail rules

A test **passes** when OpenSCAD exits successfully and produces:
- No `ECHO` output (use `assert()` rather than `echo()`)
- No `WARNING` output

A test **fails** if OpenSCAD exits with an error, or produces any unexpected ECHO or WARNING output.

### Useful assertion helpers (from `std.scad`)

| Helper | Use |
|--------|-----|
| `assert(expr)` | Fails if `expr` is false |
| `assert(expr, msg)` | Fails with message |
| `assert_approx(got, expected)` | Approximate equality (floating point) |
| `assert_equal(got, expected)` | Exact equality with diagnostic output |

### Helper functions and modules

If the test module needs a helper defined in the same `.scadtest` file (e.g., a shared helper used by multiple tests), define it in the `script` before the test module:

```toml
[[test]]
name = "test_my_function"
script = '''
include <../std.scad>

function my_helper(x) = x * 2;

module test_my_function() {
    assert(my_function(my_helper(3)) == 6);
}
test_my_function();
'''
```

### Advanced options

The `[[test]]` section supports these optional fields:

```toml
[[test]]
name = "test_name"
script = '''...'''
expect_success = true          # default: true; set false to expect failure
assert_echoes = ["ECHO: 42"]   # require specific ECHO output substrings
assert_no_echoes = true        # default: true
assert_warnings = ["WARNING: foo"]  # require specific WARNING substrings
assert_no_warnings = true      # default: true
set_vars = {var = "value"}     # pass -D variables to OpenSCAD
```

## Function Coverage

To check which public functions lack test coverage:

```bash
python3 scripts/func_coverage.py
```

This reports which functions in the library source files have no corresponding `test_<funcname>` entry in the `.scadtest` files.

## Test File Naming Convention

Each `tests/test_<module>.scadtest` file should test the functions and modules defined in `<module>.scad`. Each `[[test]]` entry name should match the function or module being tested:

- `name = "test_translate"` → tests `translate()` from `transforms.scad`
- `name = "test_path_length"` → tests `path_length()` from `paths.scad`
