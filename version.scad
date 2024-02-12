//////////////////////////////////////////////////////////////////////
// LibFile: version.scad
//   File that provides functions to manage versioning.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Data Management
// FileSummary: Parse and compare semantic versions.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


BOSL_VERSION = [2,0,716];


// Section: BOSL Library Version Functions


// Function: bosl_version()
// Synopsis: Returns the BOSL2 version as a list.
// Topics: Versioning
// See Also: bosl_version_num(), bosl_version_str(), bosl_required()
// Usage:
//   ver = bosl_version();
// Description:
//   Returns a list with three integer elements, [MAJOR,MINOR,REV],
//   representing the Major, Minor, and Build Revision numbers.
//   For example, version 2.1.43 will be returned as `[2,1,43]`.
function bosl_version() = BOSL_VERSION;


// Function: bosl_version_num()
// Synopsis: Returns the BOSL2 version as a float.
// Topics: Versioning
// See Also: bosl_version(), bosl_version_str(), bosl_required()
// Usage:
//   ver = bosl_version_num();
// Description:
//   Returns a floating point number of the version, formatted like M.mmrrrr where M is the major version number,
//   each m is a zero-padded digit of the minor version number, and each r is a zero-padded digit of the build
//   revision number.  For example, version 2.1.43 will be returned as `2.010043`.
function bosl_version_num() = version_to_num(BOSL_VERSION);


// Function: bosl_version_str()
// Synopsis: Returns the BOSL2 version as a string.
// Topics: Versioning
// See Also: bosl_version(), bosl_version_num(), bosl_required()
// Usage:
//   ver = bosl_version_str();
// Description:
//   Returns a string of the version, formatted like "MAJOR.MINOR.REV".
//   For example, version 2.1.43 will be returned as `"2.1.43"`.
function bosl_version_str() = version_to_str(BOSL_VERSION);


// Module: bosl_required()
// Synopsis: Asserts that the current version of the library is at least the given version.
// Topics: Versioning
// See Also: version_to_num(), version_to_str(), version_to_list(), version_cmp()
// Usage:
//   bosl_required(version);
// Description:
//   Given a version as a list, number, or string, asserts that the currently installed BOSL library is at least the given version.
// Arguments:
//   version = version required
module bosl_required(version) {
    no_children($children);
    assert(
        version_cmp(bosl_version(), version) >= 0,
        str(
            "BOSL ", bosl_version_str(), " is installed, but BOSL ",
            version_to_str(version), " or better is required."  
        )
    );
}


// Section: Generic Version Functions

function _version_split_str(x, _i=0, _out=[], _num=0) =
    _i>=len(x)? concat(_out,[_num]) :
    let(
        cval = ord(x[_i]) - ord("0"),
        numend = cval<0 || cval>9,
        _out = numend? concat(_out, [_num]) : _out,
        _num = numend? 0 : (10*_num + cval)
    )
    _version_split_str(x, _i=_i+1, _out=_out, _num=_num);


// Function: version_to_list()
// Synopsis: Splits a version into a list of integer version parts.
// Topics: Versioning
// See Also: version_to_num(), version_to_str(), version_cmp(), bosl_required()
// Usage:
//   ver = version_to_list(x);
// Description:
//   Given a version string, number, or list, returns the list of version integers [MAJOR,MINOR,REVISION].
// Arguments:
//   x = version to convert
// Example:
//   v1 = version_to_list("2.1.43");  // Returns: [2,1,43]
//   v2 = version_to_list(2.120234);  // Returns: [2,12,234]
//   v3 = version_to_list([2,3,4]);   // Returns: [2,3,4]
//   v4 = version_to_list([2,3,4,5]); // Returns: [2,3,4]
function version_to_list(version) =
    is_list(version)? [default(version[0],0), default(version[1],0), default(version[2],0)] :
    is_string(version)? _version_split_str(version) :
    is_num(version)? [floor(version), floor(version*100%100), floor(version*1000000%10000+0.5)] :
    assert(is_num(version) || is_vector(version) || is_string(version)) 0;


// Function: version_to_str()
// Synopsis: Coerces a version into a standard version string.
// Topics: Versioning
// See Also: version_to_num(), version_to_list(), version_cmp(), bosl_required()
// Usage:
//   str = version_to_str(version);
// Description:
//   Takes a version string, number, or list, and returns the properly formatter version string for it.
// Arguments:
//   version = version to convert
// Example:
//   v1 = version_to_str([2,1,43]);  // Returns: "2.1.43"
//   v2 = version_to_str(2.010043);  // Returns: "2.1.43"
//   v3 = version_to_str(2.340789);  // Returns: "2.34.789"
//   v4 = version_to_str("2.3.89");  // Returns: "2.3.89"
function version_to_str(version) =
    let(version = version_to_list(version))
    str(version[0],".",version[1],".",version[2]);


// Function: version_to_num()
// Synopsis: Coerces a version into a standard version float.
// Topics: Versioning
// See Also: version_cmp(), version_to_str(), version_to_list(), bosl_required()
// Usage:
//   str = version_to_num(version);
// Description:
//   Takes a version string, number, or list, and returns the properly formatter version number for it.
// Arguments:
//   version = version to convert
// Example:
//   v1 = version_to_num([2,1,43]);   // Returns: 2.010043
//   v2 = version_to_num([2,34,567]); // Returns: 2.340567
//   v3 = version_to_num(2.120567);   // Returns: 2.120567
//   v4 = version_to_num("2.6.79");   // Returns: 2.060079
function version_to_num(version) =
    let(version = version_to_list(version))
    (version[0]*1000000 + version[1]*10000 + version[2])/1000000;


// Function: version_cmp()
// Synopsis: Compares two versions.
// Topics: Versioning
// See Also: version_to_num(), version_to_str(), version_to_list(), bosl_required()
// Usage:
//   cmp = version_cmp(a,b);
// Description:
//   Given a pair of versions, in any combination of string, integer, or list, compares them, and returns the relative value of them.
//   Returns an integer <0 if a<b.  Returns 0 if a==b.  Returns an integer >0 if a>b.
// Example:
//   cmp1 = version_cmp(2.010034, "2.1.33");  // Returns: >0
//   cmp2 = version_cmp(2.010034, "2.1.34");  // Returns: 0
//   cmp3 = version_cmp(2.010034, "2.1.35");  // Returns: <0
function version_cmp(a,b) =
    let(
        a = version_to_list(a),
        b = version_to_list(b),
        cmps = [for (i=[0:1:2]) if(a[i]!=b[i]) a[i]-b[i]]
    ) cmps==[]? 0 : cmps[0];


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
