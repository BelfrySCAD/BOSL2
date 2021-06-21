//////////////////////////////////////////////////////////////////////
// LibFile: version.scad
//   File that provides functions to manage versioning.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


BOSL_VERSION = [2,0,652];


// Section: BOSL Library Version Functions


// Function: bosl_version()
// Usage:
//   ver = bosl_version();
// Description:
//   Returns a list with three integer elements, [MAJOR,MINOR,REV],
//   representing the Major, Minor, and Build Revision numbers.
//   For example, version 2.1.43 will be returned as `[2,1,43]`.
function bosl_version() = BOSL_VERSION;


// Function: bosl_version_num()
// Usage:
//   ver = bosl_version_num();
// Description:
//   Returns a floating point number of the version, formatted like M.mmrrrr where M is the major version number,
//   each m is a zero-padded digit of the minor version number, and each r is a zero-padded digit of the build
//   revision number.  For example, version 2.1.43 will be returned as `2.010043`.
function bosl_version_num() = version_to_num(BOSL_VERSION);


// Function: bosl_version_str()
// Usage:
//   ver = bosl_version_str();
// Description:
//   Returns a string of the version, formatted like "MAJOR.MINOR.REV".
//   For example, version 2.1.43 will be returned as `"2.1.43"`.
function bosl_version_str() = version_to_str(BOSL_VERSION);


// Module: bosl_required()
// Usage:
//   bosl_required(x);
// Description:
//   Given a version as a list, number, or string, asserts that the currently installed BOSL library is at least the given version.
module bosl_required(target) {
    no_children($children);
    assert(
        version_cmp(bosl_version(), target) >= 0,
        str(
            "BOSL ", bosl_version_str(), " is installed, but BOSL ",
            version_to_str(target), " or better is required."  
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
// Usage:
//   ver = version_to_list(x);
// Description:
//   Given a version string, number, or list, returns the list of version integers [MAJOR,MINOR,REVISION].
// Example:
//   v1 = version_to_list("2.1.43");  // Returns: [2,1,43]
//   v2 = version_to_list(2.120234);  // Returns: [2,12,234]
//   v3 = version_to_list([2,3,4]);   // Returns: [2,3,4]
//   v4 = version_to_list([2,3,4,5]); // Returns: [2,3,4]
function version_to_list(x) =
    is_list(x)? [default(x[0],0), default(x[1],0), default(x[2],0)] :
    is_string(x)? _version_split_str(x) :
    is_num(x)? [floor(x), floor(x*100%100), floor(x*1000000%10000+0.5)] :
    assert(is_num(x) || is_vector(x) || is_string(x)) 0;


// Function: version_to_str()
// Usage:
//   str = version_to_str(x);
// Description:
//   Takes a version string, number, or list, and returns the properly formatter version string for it.
// Example:
//   v1 = version_to_str([2,1,43]);  // Returns: "2.1.43"
//   v2 = version_to_str(2.010043);  // Returns: "2.1.43"
//   v3 = version_to_str(2.340789);  // Returns: "2.34.789"
//   v4 = version_to_str("2.3.89");  // Returns: "2.3.89"
function version_to_str(x) =
    let(x = version_to_list(x))
    str(x[0],".",x[1],".",x[2]);


// Function: version_to_num()
// Usage:
//   str = version_to_num(x);
// Description:
//   Takes a version string, number, or list, and returns the properly formatter version number for it.
// Example:
//   v1 = version_to_num([2,1,43]);   // Returns: 2.010043
//   v2 = version_to_num([2,34,567]); // Returns: 2.340567
//   v3 = version_to_num(2.120567);   // Returns: 2.120567
//   v4 = version_to_num("2.6.79");   // Returns: 2.060079
function version_to_num(x) =
    let(x = version_to_list(x))
    (x[0]*1000000 + x[1]*10000 + x[2])/1000000;


// Function: version_cmp()
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
