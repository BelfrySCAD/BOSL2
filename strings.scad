//////////////////////////////////////////////////////////////////////
// LibFile: strings.scad
//   String manipulation and formatting functions.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: String Operations

// Function: substr()
// Usage:
//   substr(str, [pos], [len])
// Description:
//   Returns a substring from a string start at position `pos` with length `len`, or 
//   if `len` isn't given, the rest of the string.  
// Arguments:
//   str = string to operate on
//   pos = starting index of substring, or vector of first and last position.  Default: 0
//   len = length of substring, or omit it to get the rest of the string.  If len is less than zero the emptry string is returned.  
// Example:
//   substr("abcdefg",3,3);     // Returns "def"
//   substr("abcdefg",2);       // Returns "cdefg"
//   substr("abcdefg",len=3);   // Returns "abc"
//   substr("abcdefg",[2,4]);   // Returns "cde"
//   substr("abcdefg",len=-2);  // Returns ""
function substr(str, pos=0, len=undef) =
    is_list(pos) ? _substr(str, pos[0], pos[1]-pos[0]+1) :
    len == undef ? _substr(str, pos, len(str)-pos) :
    _substr(str,pos,len);

function _substr(str,pos,len,substr="") = 
    len <= 0 || pos>=len(str) ? substr :
    _substr(str, pos+1, len-1, str(substr, str[pos]));


// Function: suffix()
// Usage:
//   suffix(str,len)
// Description:
//   Returns the last `len` characters from the input string `str`.
//   If `len` is longer than the length of `str`, then the entirety of `str` is returned.
// Arguments:
//   str = The string to get the suffix of.
//   len = The number of characters of suffix to get.
function suffix(str,len) =
    len>=len(str)? str : substr(str, len(str)-len,len);


// Function: str_join()
// Usage:
//   str_join(list, [sep])
// Description:
//   Returns the concatenation of a list of strings, optionally with a
//   separator string inserted between each string on the list.
// Arguments:
//   list = list of strings to concatenate
//   sep = separator string to insert.  Default: ""
// Example:
//   str_join(["abc","def","ghi"]);        // Returns "abcdefghi"
//   str_join(["abc","def","ghi"], " + ");  // Returns "abc + def + ghi"
function str_join(list,sep="",_i=0, _result="") =
    _i >= len(list)-1 ? (_i==len(list) ? _result : str(_result,list[_i])) :
    str_join(list,sep,_i+1,str(_result,list[_i],sep));


// Function: downcase()
// Usage:
//   downcase(str)
// Description:
//   Returns the string with the standard ASCII upper case letters A-Z replaced
//   by their lower case versions.
// Arguments:
//   str = String to convert.
// Example:
//   downcase("ABCdef");   // Returns "abcdef"
function downcase(str) =
    str_join([for(char=str) let(code=ord(char)) code>=65 && code<=90 ? chr(code+32) : char]);


// Function: upcase()
// Usage:
//   upcase(str)
// Description:
//   Returns the string with the standard ASCII lower case letters a-z replaced
//   by their upper case versions.
// Arguments:
//   str = String to convert.
// Example:
//   upcase("ABCdef");   // Returns "ABCDEF"
function upcase(str) =
    str_join([for(char=str) let(code=ord(char)) code>=97 && code<=122 ? chr(code-32) : char]);


// Function: str_int()
// Usage:
//   str_int(str, [base])
// Description:
//   Converts a string into an integer with any base up to 16.  Returns NaN if 
//   conversion fails.  Digits above 9 are represented using letters A-F in either
//   upper case or lower case.  
// Arguments:
//   str = String to convert.
//   base = Base for conversion, from 2-16.  Default: 10
// Example:
//   str_int("349");        // Returns 349
//   str_int("-37");        // Returns -37
//   str_int("+97");        // Returns 97
//   str_int("43.9");       // Returns nan
//   str_int("1011010",2);  // Returns 90
//   str_int("13",2);       // Returns nan
//   str_int("dead",16);    // Returns 57005
//   str_int("CEDE", 16);   // Returns 52958
//   str_int("");           // Returns 0
function str_int(str,base=10) =
    str==undef ? undef :
    len(str)==0 ? 0 : 
    let(str=downcase(str))
    str[0] == "-" ? -_str_int_recurse(substr(str,1),base,len(str)-2) :
    str[0] == "+" ?  _str_int_recurse(substr(str,1),base,len(str)-2) :
    _str_int_recurse(str,base,len(str)-1);

function _str_int_recurse(str,base,i) =
    let(
        digit = search(str[i],"0123456789abcdef"),
        last_digit = digit == [] || digit[0] >= base ? (0/0) : digit[0]
    ) i==0 ? last_digit : 
    _str_int_recurse(str,base,i-1)*base + last_digit;


// Function: str_float()
// Usage:
//   str_float(str)
// Description:
//   Converts a string to a floating point number.  Returns NaN if the
//   conversion fails.
// Arguments:
//   str = String to convert.
// Example:
//   str_float("44");       // Returns 44
//   str_float("3.4");      // Returns 3.4
//   str_float("-99.3332"); // Returns -99.3332
//   str_float("3.483e2");  // Returns 348.3
//   str_float("-44.9E2");  // Returns -4490
//   str_float("7.342e-4"); // Returns 0.0007342
//   str_float("");         // Returns 0
function str_float(str) =
    str==undef ? undef :
    len(str) == 0 ? 0 :
    in_list(str[1], ["+","-"]) ? (0/0) : // Don't allow --3, or +-3
    str[0]=="-" ? -str_float(substr(str,1)) :
    str[0]=="+" ?  str_float(substr(str,1)) :
    let(esplit = str_split(str,"eE") )
    len(esplit)==2 ? str_float(esplit[0]) * pow(10,str_int(esplit[1])) :
    let( dsplit = str_split(str,["."]))
    str_int(dsplit[0])+str_int(dsplit[1])/pow(10,len(dsplit[1]));


// Function: str_frac()
// Usage:
//   str_frac(str,[mixed],[improper],[signed])
// Description:
//   Converts a string fraction to a floating point number.  A string fraction has the form `[-][# ][#/#]` where each `#` is one or more of the
//   digits 0-9, and there is an optional sign character at the beginning. 
//   The full form is a sign character and an integer, followed by exactly one space, followed by two more
//   integers separated by a "/" character.  The leading integer and 
//   space can be omitted or the trailing fractional part can be omitted.  If you set `mixed` to false then the leading integer part is not
//   accepted and the input must include a slash.  If you set `improper` to false then the fractional part must be a proper fraction, where
//   the numerator is smaller than the denominator.  If you set `signed` to false then the leading sign character is not permitted.
//   The empty string evaluates to zero.  Any invalid string evaluates to NaN.    
// Arguments:
//   str = String to convert.
//   mixed = set to true to accept mixed fractions, false to reject them.  Default: true  
//   improper = set to true to accept improper fractions, false to reject them.  Default: true
//   signed = set to true to accept a leading sign character, false to reject.  Default: true  
// Example:
//   str_frac("3/4");     // Returns 0.75
//   str_frac("-77/9");   // Returns -8.55556
//   str_frac("+1/3");    // Returns 0.33333
//   str_frac("19");      // Returns 19
//   str_frac("2 3/4");   // Returns 2.75
//   str_frac("-2 12/4"); // Returns -5
//   str_frac("");        // Returns 0
//   str_frac("3/0");     // Returns inf
//   str_frac("0/0");     // Returns nan
//   str_frac("-77/9",improper=false);   // Returns nan
//   str_frac("-2 12/4",improper=false); // Returns nan
//   str_frac("-2 12/4",signed=false);   // Returns nan
//   str_frac("-2 12/4",mixed=false);    // Returns nan
//   str_frac("2 1/4",mixed=false);      // Returns nan
function str_frac(str,mixed=true,improper=true,signed=true) =
    str == undef ? undef :
    len(str)==0 ? 0 :
    signed && str[0]=="-" ? -str_frac(substr(str,1),mixed=mixed,improper=improper,signed=false) :
    signed && str[0]=="+" ?  str_frac(substr(str,1),mixed=mixed,improper=improper,signed=false) :
    mixed ? (                      
        !in_list(str_find(str," "), [undef,0]) || is_undef(str_find(str,"/"))? (
            let(whole = str_split(str,[" "]))
            _str_int_recurse(whole[0],10,len(whole[0])-1) + str_frac(whole[1], mixed=false, improper=improper, signed=false)
        ) : str_frac(str,mixed=false, improper=improper)
    ) : (
        let(split = str_split(str,"/"))
        len(split)!=2 ? (0/0) :
        let(
            numerator =  _str_int_recurse(split[0],10,len(split[0])-1),
            denominator = _str_int_recurse(split[1],10,len(split[1])-1)
        ) !improper && numerator>=denominator? (0/0) :
        denominator<0 ? (0/0) : numerator/denominator
    );


// Function: str_num()
// Usage:
//   str_num(str)
// Description:
//   Converts a string to a number.  The string can be either a fraction (two integers separated by a "/") or a floating point number.
//   Returns NaN if the conversion fails.
// Example:
//   str_num("3/4");    // Returns 0.75
//   str_num("3.4e-2"); // Returns 0.034
function str_num(str) =
    str == undef ? undef :
    let( val = str_frac(str) )
    val == val ? val :
    str_float(str);


// Function: str_split()
// Usage:
//   str_split(str, sep, [keep_nulls])
// Description:
//   Breaks an input string into substrings using a separator or list of separators.  If keep_nulls is true
//   then two sequential separator characters produce an empty string in the output list.  If keep_nulls is false
//   then no empty strings are included in the output list.
//   .
//   If sep is a single string then each character in sep is treated as a delimiting character and the input string is
//   split at every delimiting character.  Empty strings can occur whenever two delimiting characters are sequential.
//   If sep is a list of strings then the input string is split sequentially using each string from the list in order. 
//   If keep_nulls is true then the output will have length equal to `len(sep)+1`, possibly with trailing null strings
//   if the string runs out before the separator list.  
// Arguments:
//   str = String to split.
//   sep = a string or list of strings to use for the separator
//   keep_nulls = boolean value indicating whether to keep null strings in the output list.  Default: true
// Example:
//   str_split("abc+def-qrs*iop","*-+");     // Returns ["abc", "def", "qrs", "iop"]
//   str_split("abc+*def---qrs**iop+","*-+");// Returns ["abc", "", "def", "", "", "qrs", "", "iop", ""]
//   str_split("abc      def"," ");          // Returns ["abc", "", "", "", "", "", "def"]
//   str_split("abc      def"," ",keep_nulls=false);  // Returns ["abc", "def"]
//   str_split("abc+def-qrs*iop",["+","-","*"]);     // Returns ["abc", "def", "qrs", "iop"]
//   str_split("abc+def-qrs*iop",["-","+","*"]);     // Returns ["abc+def", "qrs*iop", "", ""]
function str_split(str,sep,keep_nulls=true) =
    !keep_nulls ? _remove_empty_strs(str_split(str,sep,keep_nulls=true)) :
    is_list(sep) ? _str_split_recurse(str,sep,i=0,result=[]) :
    let( cutpts = concat([-1],sort(flatten(search(sep, str,0))),[len(str)]))
    [for(i=[0:len(cutpts)-2]) substr(str,cutpts[i]+1,cutpts[i+1]-cutpts[i]-1)];

function _str_split_recurse(str,sep,i,result) =
    i == len(sep) ? concat(result,[str]) :
    let(
        pos = search(sep[i], str),
        end = pos==[] ? len(str) : pos[0]
    )
    _str_split_recurse(
        substr(str,end+1),
        sep, i+1,
        concat(result, [substr(str,0,end)])
    );

function _remove_empty_strs(list) =
    list_remove(list, search([""], list,0)[0]);


// _str_cmp(str,sindex,pattern)
//    returns true if the string pattern matches the string
//    starting at index position sindex in the string.
//
//    This is carefully optimized for speed.  Precomputing the length
//    cuts run time in half when the string is long.  Two other string
//    comparison methods were slower.  
function _str_cmp(str,sindex,pattern) =
    len(str)-sindex <len(pattern)? false :
    _str_cmp_recurse(str,sindex,pattern,len(pattern));

function _str_cmp_recurse(str,sindex,pattern,plen,pindex=0,) = 
    pindex < plen && pattern[pindex]==str[sindex] ? _str_cmp_recurse(str,sindex+1,pattern,plen,pindex+1): (pindex==plen);


// Function: str_find()
// Usage:
//   str_find(str,pattern,[last],[all],[start])
// Description:
//   Searches input string `str` for the string `pattern` and returns the index or indices of the matches in `str`.
//   By default `str_find()` returns the index of the first match in `str`.  If `last` is true then it returns the index of the last match.
//   If the pattern is the empty string the first match is at zero and the last match is the last character of the `str`.
//   If `start` is set then the search begins at index start, working either forward and backward from that position.  If you set `start`
//   and `last` is true then the search will find the pattern if it begins at index `start`.  If no match exists, returns `undef`.
//   If you set `all` to true then `str_find()` returns all of the matches in a list, or an empty list if there are no matches.
// Arguments:
//   str = String to search.
//   pattern = string pattern to search for
//   last = set to true to return the last match. Default: false
//   all = set to true to return all matches as a list.  Overrides last.  Default: false  
//   start = index where the search starts
// Example:
//   str_find("abc123def123abc","123");   // Returns 3
//   str_find("abc123def123abc","b");     // Returns 1
//   str_find("abc123def123abc","1234");  // Returns undef
//   str_find("abc","");                  // Returns 0
//   str_find("abc123def123", "123", start=4);     // Returns 9
//   str_find("abc123def123abc","123",last=true);  // Returns 9
//   str_find("abc123def123abc","b",last=true);    // Returns 13
//   str_find("abc123def123abc","1234",last=true); // Returns undef
//   str_find("abc","",last=true);                 // Returns 3
//   str_find("abc123def123", "123", start=8, last=true));  // Returns 3
//   str_find("abc123def123abc","123",all=true);   // Returns [3,9]
//   str_find("abc123def123abc","b",all=true);     // Returns [1,13]
//   str_find("abc123def123abc","1234",all=true);  // Returns []
//   str_find("abc","",all=true);                  // Returns [0,1,2]
function str_find(str,pattern,start=undef,last=false,all=false) =
    all? _str_find_all(str,pattern) :
    let( start = first_defined([start,last?len(str)-len(pattern):0]) )
    pattern==""? start :
    last? _str_find_last(str,pattern,start) :
    _str_find_first(str,pattern,len(str)-len(pattern),start);

function _str_find_first(str,pattern,max_sindex,sindex) = 
    sindex<=max_sindex && !_str_cmp(str,sindex, pattern)?
        _str_find_first(str,pattern,max_sindex,sindex+1) :
        (sindex <= max_sindex ? sindex : undef);

function _str_find_last(str,pattern,sindex) = 
    sindex>=0 && !_str_cmp(str,sindex, pattern)?
        _str_find_last(str,pattern,sindex-1) :
        (sindex >=0 ? sindex : undef);

function _str_find_all(str,pattern) =
    pattern == "" ? count(len(str)) :
    [for(i=[0:1:len(str)-len(pattern)]) if (_str_cmp(str,i,pattern)) i];


// Function: starts_with()
// Usage:
//    starts_with(str,pattern)
// Description:
//    Returns true if the input string `str` starts with the specified string pattern, `pattern`.
//    Otherwise returns false.   
// Arguments:
//   str = String to search.
//   pattern = String pattern to search for.
// Example:
//   starts_with("abcdef","abc");  // Returns true
//   starts_with("abcdef","def");  // Returns false
//   starts_with("abcdef","");     // Returns true
function starts_with(str,pattern) = _str_cmp(str,0,pattern);


// Function: ends_with()
// Usage:
//    ends_with(str,pattern)
// Description:
//    Returns true if the input string `str` ends with the specified string pattern, `pattern`.
//    Otherwise returns false. 
// Arguments:
//   str = String to search.
//   pattern = String pattern to search for.
// Example:
//   ends_with("abcdef","def");  // Returns true
//   ends_with("abcdef","de");   // Returns false
//   ends_with("abcdef","");     // Returns true
function ends_with(str,pattern) = _str_cmp(str,len(str)-len(pattern),pattern);


function _str_count_leading(s,c,_i=0) =
    (_i>=len(s)||!in_list(s[_i],[each c]))? _i :
    _str_count_leading(s,c,_i=_i+1);

function _str_count_trailing(s,c,_i=0) =
    (_i>=len(s)||!in_list(s[len(s)-1-_i],[each c]))? _i :
    _str_count_trailing(s,c,_i=_i+1);


// Function: str_strip_leading()
// Usage:
//   str_strip_leading(s,c);
// Description:
//   Takes a string `s` and strips off all leading characters that exist in string `c`.
// Arguments:
//   s = The string to strip leading characters from.
//   c = The string of characters to strip.
// Example:
//   str_strip_leading("--##--123--##--","#-");  // Returns: "123--##--"
//   str_strip_leading("--##--123--##--","-");  // Returns: "##--123--##--"
//   str_strip_leading("--##--123--##--","#");  // Returns: "--##--123--##--"
function str_strip_leading(s,c) = substr(s,pos=_str_count_leading(s,c));


// Function: str_strip_trailing()
// Usage:
//   str_strip_trailing(s,c);
// Description:
//   Takes a string `s` and strips off all trailing characters that exist in string `c`.
// Arguments:
//   s = The string to strip trailing characters from.
//   c = The string of characters to strip.
// Example:
//   str_strip_trailing("--##--123--##--","#-");  // Returns: "--##--123"
//   str_strip_trailing("--##--123--##--","-");  // Returns: "--##--123--##"
//   str_strip_trailing("--##--123--##--","#");  // Returns: "--##--123--##--"
function str_strip_trailing(s,c) = substr(s,len=len(s)-_str_count_trailing(s,c));


// Function: str_strip()
// Usage:
//   str_strip(s,c);
// Description:
//   Takes a string `s` and strips off all leading or trailing characters that exist in string `c`.
// Arguments:
//   s = The string to strip leading or trailing characters from.
//   c = The string of characters to strip.
// Example:
//   str_strip("--##--123--##--","#-");  // Returns: "123"
//   str_strip("--##--123--##--","-");  // Returns: "##--123--##"
//   str_strip("--##--123--##--","#");  // Returns: "--##--123--##--"
function str_strip(s,c) = str_strip_trailing(str_strip_leading(s,c),c);


// Function: fmt_int()
// Usage:
//   fmt_int(i, [mindigits]);
// Description:
//   Formats an integer number into a string.  This can handle larger numbers than `str()`.
// Arguments:
//   i = The integer to make a string of.
//   mindigits = If the number has fewer than this many digits, pad the front with zeros until it does.  Default: 1.
// Example:
//   str(123456789012345);  // Returns "1.23457e+14"
//   fmt_int(123456789012345);  // Returns "123456789012345"
//   fmt_int(-123456789012345);  // Returns "-123456789012345"
function fmt_int(i,mindigits=1) =
    i<0? str("-", fmt_int(-i,mindigits)) :
    let(i=floor(i), e=floor(log(i)))
    i==0? str_join([for (j=[0:1:mindigits-1]) "0"]) :
    str_join(
        concat(
            [for (j=[0:1:mindigits-e-2]) "0"],
            [for (j=[e:-1:0]) str(floor(i/pow(10,j)%10))]
        )
    );


// Function: fmt_fixed()
// Usage:
//   s = fmt_fixed(f, [digits]);
// Description:
//   Given a floating point number, formats it into a string with the given number of digits after the decimal point.
// Arguments:
//   f = The floating point number to format.
//   digits = The number of digits after the decimal to show.  Default: 6
function fmt_fixed(f,digits=6) =
    assert(is_int(digits))
    assert(digits>0)
    is_list(f)? str("[",str_join(sep=", ", [for (g=f) fmt_fixed(g,digits=digits)]),"]") :
    str(f)=="nan"? "nan" :
    str(f)=="inf"? "inf" :
    f<0? str("-",fmt_fixed(-f,digits=digits)) :
    assert(is_num(f))
    let(
        sc = pow(10,digits),
        scaled = floor(f * sc + 0.5),
        whole = floor(scaled/sc),
        part = floor(scaled-(whole*sc))
    ) str(fmt_int(whole),".",fmt_int(part,digits));


// Function: fmt_float()
// Usage:
//   fmt_float(f,[sig]);
// Description:
//   Formats the given floating point number `f` into a string with `sig` significant digits.
//   Strips trailing `0`s after the decimal point.  Strips trailing decimal point.
//   If the number can be represented in `sig` significant digits without a mantissa, it will be.
//   If given a list of numbers, recursively prints each item in the list, returning a string like `[3,4,5]`
// Arguments:
//   f = The floating point number to format.
//   sig = The number of significant digits to display.  Default: 12
// Example:
//   fmt_float(PI,12);  // Returns: "3.14159265359"
//   fmt_float([PI,-16.75],12);  // Returns: "[3.14159265359, -16.75]"
function fmt_float(f,sig=12) =
    assert(is_int(sig))
    assert(sig>0)
    is_list(f)? str("[",str_join(sep=", ", [for (g=f) fmt_float(g,sig=sig)]),"]") :
    f==0? "0" :
    str(f)=="nan"? "nan" :
    str(f)=="inf"? "inf" :
    f<0? str("-",fmt_float(-f,sig=sig)) :
    assert(is_num(f))
    let(
        e = floor(log(f)),
        mv = sig - e - 1
    ) mv == 0? fmt_int(floor(f + 0.5)) :
    (e<-sig/2||mv<0)? str(fmt_float(f*pow(10,-e),sig=sig),"e",e) :
    let(
        ff = f + pow(10,-mv)*0.5,
        whole = floor(ff),
        part = floor((ff-whole) * pow(10,mv))
    )
    str_join([
        str(whole),
        str_strip_trailing(
            str_join([
                ".",
                fmt_int(part, mindigits=mv)
            ]),
            "0."
        )
    ]);


// Function: escape_html()
// Usage:
//   echo(escape_html(s));
// Description:
//   Converts "<", ">", "&", and double-quote chars to their entity encoding so that echoing the strong will show it verbatim.
function escape_html(s) =
    str_join([
        for (c=s) 
        c=="<"? "&lt;" :
        c==">"? "&gt;" :
        c=="&"? "&amp;" :
        c=="\""? "&quot;" :
        c
    ]);


// Function: is_lower()
// Usage:
//   x = is_lower(s);
// Description:
//   Returns true if all the characters in the given string are lowercase letters. (a-z)
function is_lower(s) =
    assert(is_string(s))
    s==""? false :
    len(s)>1? all([for (v=s) is_lower(v)]) :
    let(v = ord(s[0])) (v>=ord("a") && v<=ord("z"));


// Function: is_upper()
// Usage:
//   x = is_upper(s);
// Description:
//   Returns true if all the characters in the given string are uppercase letters. (A-Z)
function is_upper(s) =
    assert(is_string(s))
    s==""? false :
    len(s)>1? all([for (v=s) is_upper(v)]) :
    let(v = ord(s[0])) (v>=ord("A") && v<=ord("Z"));


// Function: is_digit()
// Usage:
//   x = is_digit(s);
// Description:
//   Returns true if all the characters in the given string are digits. (0-9)
function is_digit(s) =
    assert(is_string(s))
    s==""? false :
    len(s)>1? all([for (v=s) is_digit(v)]) :
    let(v = ord(s[0])) (v>=ord("0") && v<=ord("9"));


// Function: is_hexdigit()
// Usage:
//   x = is_hexdigit(s);
// Description:
//   Returns true if all the characters in the given string are valid hexadecimal digits. (0-9 or a-f or A-F))
function is_hexdigit(s) =
    assert(is_string(s))
    s==""? false :
    len(s)>1? all([for (v=s) is_hexdigit(v)]) :
    let(v = ord(s[0]))
    (v>=ord("0") && v<=ord("9")) ||
    (v>=ord("A") && v<=ord("F")) ||
    (v>=ord("a") && v<=ord("f"));


// Function: is_letter()
// Usage:
//   x = is_letter(s);
// Description:
//   Returns true if all the characters in the given string are standard ASCII letters. (A-Z or a-z)
function is_letter(s) =
    assert(is_string(s))
    s==""? false :
    all([for (v=s) is_lower(v) || is_upper(v)]);


// Function: str_format()
// Usage:
//   s = str_format(fmt, vals);
// Description:
//   Given a format string and a list of values, inserts the values into the placeholders in the format string and returns it.
//   Formatting placeholders have the following syntax:
//   - A leading `{` character to show the start of the placeholder.
//   - An integer index into the `vals` list to specify which value should be formatted at that place. If not given, the first placeholder will use index `0`, the second will use index `1`, etc.
//   - An optional `:` separator to indicate that what follows if a formatting specifier.  If not given, no formatting info follows.
//   - An optional `-` character to indicate that the value should be left justified if the value needs field width padding.  If not given, right justification is used.
//   - An optional `0` character to indicate that the field should be padded with `0`s.  If not given, spaces will be used for padding.
//   - An optional integer field width, which the value should be padded to.  If not given, no padding will be performed.
//   - An optional `.` followed by an integer precision length, for specifying how many digits to display in numeric formats.  If not give, 6 digits is assumed.
//   - An optional letter to indicate the formatting style to use.  If not given, `s` is assumed, which will do it's generic best to format any data type.
//   - A trailing `}` character to show the end of the placeholder.
//   .
//   Formatting styles, and their effects are as follows:
//   - `s`: Converts the value to a string with `str()` to display.  This is very generic.
//   - `i` or `d`: Formats numeric values as integers.
//   - `f`: Formats numeric values with the precision number of digits after the decimal point.  NaN and Inf are shown as `nan` and `inf`.
//   - `F`: Formats numeric values with the precision number of digits after the decimal point.  NaN and Inf are shown as `NAN` and `INF`.
//   - `g`: Formats numeric values with the precision number of total significant digits.  NaN and Inf are shown as `nan` and `inf`.  Mantissas are demarked by `e`.
//   - `G`: Formats numeric values with the precision number of total significant digits.  NaN and Inf are shown as `NAN` and `INF`.  Mantissas are demarked by `E`.
//   - `b`: If the value logically evaluates as true, it shows as `true`, otherwise `false`.
//   - `B`: If the value logically evaluates as true, it shows as `TRUE`, otherwise `FALSE`.
// Arguments:
//   fmt = The formatting string, with placeholders to format the values into.
//   vals = The list of values to format.
// Example(NORENDER):
//   str_format("The value of {} is {:.14f}.", ["pi", PI]);  // Returns: "The value of pi is 3.14159265358979."
//   str_format("The value {1:f} is known as {0}.", ["pi", PI]);  // Returns: "The value 3.141593 is known as pi."
//   str_format("We use a very small value {1:.6g} as {0}.", ["EPSILON", EPSILON]);  // Returns: "We use a very small value 1e-9 as EPSILON."
//   str_format("{:-5s}{:i}{:b}", ["foo", 12e3, 5]);  // Returns: "foo  12000true"
//   str_format("{:-10s}{:.3f}", ["plecostamus",27.43982]);  // Returns: "plecostamus27.440"
//   str_format("{:-10.9s}{:.3f}", ["plecostamus",27.43982]);  // Returns: "plecostam 27.440"
function str_format(fmt, vals) =
    let(
        parts = str_split(fmt,"{")
    ) str_join([
        for(i = idx(parts))
        let(
            found_brace = i==0 || [for (c=parts[i]) if(c=="}") c] != [],
            err = assert(found_brace, "Unbalanced { in format string."),
            p = i==0? [undef,parts[i]] : str_split(parts[i],"}"),
            fmta = p[0],
            raw = p[1]
        ) each [
            assert(i<99)
            is_undef(fmta)? "" : let(
                fmtb = str_split(fmta,":"),
                num = is_digit(fmtb[0])? str_int(fmtb[0]) : (i-1),
                left = fmtb[1][0] == "-",
                fmtb1 = default(fmtb[1],""),
                fmtc = left? substr(fmtb1,1) : fmtb1,
                zero = fmtc[0] == "0",
                lch = fmtc==""? "" : fmtc[len(fmtc)-1],
                hastyp = is_letter(lch),
                typ = hastyp? lch : "s",
                fmtd = hastyp? substr(fmtc,0,len(fmtc)-1) : fmtc,
                fmte = str_split((zero? substr(fmtd,1) : fmtd), "."),
                wid = str_int(fmte[0]),
                prec = str_int(fmte[1]),
                val = assert(num>=0&&num<len(vals)) vals[num],
                unpad = typ=="s"? (
                        let( sval = str(val) )
                        is_undef(prec)? sval :
                        substr(sval, 0, min(len(sval)-1, prec))
                    ) :
                    (typ=="d" || typ=="i")? fmt_int(val) :
                    typ=="b"? (val? "true" : "false") :
                    typ=="B"? (val? "TRUE" : "FALSE") :
                    typ=="f"? downcase(fmt_fixed(val,default(prec,6))) :
                    typ=="F"? upcase(fmt_fixed(val,default(prec,6))) :
                    typ=="g"? downcase(fmt_float(val,default(prec,6))) :
                    typ=="G"? upcase(fmt_float(val,default(prec,6))) :
                    assert(false,str("Unknown format type: ",typ)),
                padlen = max(0,wid-len(unpad)),
                padfill = str_join([for (i=[0:1:padlen-1]) zero? "0" : " "]),
                out = left? str(unpad, padfill) : str(padfill, unpad)
            )
            out, raw
        ]
    ]);
    

// Function&Module: echofmt()
// Usage:
//   echofmt(fmt,vals);
// Description:
//   Formats the given `vals` with the given format string `fmt` using [`str_format()`](#str_format), and echos the resultant string.
// Arguments:
//   fmt = The formatting string, with placeholders to format the values into.
//   vals = The list of values to format.
// Example(NORENDER):
//   echofmt("The value of {} is {:.14f}.", ["pi", PI]);  // ECHO: "The value of pi is 3.14159265358979."
//   echofmt("The value {1:f} is known as {0}.", ["pi", PI]);  // ECHO: "The value 3.141593 is known as pi."
//   echofmt("We use a very small value {1:.6g} as {0}.", ["EPSILON", EPSILON]);  // ECHO: "We use a ver small value 1e-9 as EPSILON."
//   echofmt("{:-5s}{:i}{:b}", ["foo", 12e3, 5]);  // ECHO: "foo  12000true"
//   echofmt("{:-10s}{:.3f}", ["plecostamus",27.43982]);  // ECHO: "plecostamus27.440"
//   echofmt("{:-10.9s}{:.3f}", ["plecostamus",27.43982]);  // ECHO: "plecostam 27.440"
function echofmt(fmt, vals) = echo(str_format(fmt,vals));
module echofmt(fmt, vals) {
   no_children($children);
   echo(str_format(fmt,vals));
}


// Function: str_pad()
// Usage:
//   padded = str_pad(str, length, char, [left]);
// Description:
//   Pad the given string `str` with to length `length` with the specified character,
//   which must be a length 1 string.  If left is true then pad on the left, otherwise
//   pad on the right.  If the string is longer than the specified length the full string
//   is returned unchanged.  
// Arguments:
//   str = string to pad
//   length = length to pad to
//   char = character to pad with.  Default: " " (space)
//   left = if true, pad on the left side.  Default: false
function str_pad(str,length,char=" ",left=false) =
  assert(is_str(str))
  assert(is_str(char) && len(char)==1, "char must be a single character string")
  assert(is_bool(left))
  let(
    padding = str_join(repeat(char,length-len(str)))
  )
  left ? str(padding,str) : str(str,padding);


// Function: str_replace_char()
// Usage:
//   newstr = str_replace_char(str, char, replace)
// Description:
//   Replace every occurence of `char` in the input string with the string `replace` which
//   can be any string.  
function str_replace_char(str,char,replace) =
   assert(is_str(str))
   assert(is_str(char) && len(char)==1, "Search pattern 'char' must be a single character string")
   assert(is_str(replace))
   str_join([for(c=str) c==char ? replace : c]);


// Function: matrix_strings()
// Usage:
//   matrix_strings(M, [sig], [eps])
// Description:
//   Convert a numerical matrix into a matrix of strings where every column
//   is the same width so it will display in neat columns when printed.
//   Values below eps will display as zero.  The matrix can include nans, infs
//   or undefs and the rows can be different lengths.  
// Arguments:
//   M = numerical matrix to convert
//   sig = significant digits to display.  Default: 4
//   eps = values smaller than this are shown as zero.  Default: 1e-9
function matrix_strings(M, sig=4, eps=1e-9) = 
   let(
       columngap = 1,
       figure_dash = chr(8210),
       space_punc = chr(8200),
       space_figure = chr(8199),
       strarr=
         [for(row=M)
             [for(entry=row)
                 let(
                     text = is_undef(entry) ? "und"
                          : abs(entry) < eps ? "0"             // Replace hyphens with figure dashes
                          : str_replace_char(fmt_float(entry, sig),"-",figure_dash),
                     have_dot = is_def(str_find(text, "."))
                 )
                 // If the text lacks a dot we add a space the same width as a dot to
                 // maintain alignment
                 str(have_dot ? "" : space_punc, text)
             ]
         ],
       maxwidth = max([for(row=M) len(row)]),
       // Find maximum length for each column.  Some entries in a column may be missing.  
       maxlen = [for(i=[0:1:maxwidth-1])
                    max(
                         [for(j=idx(M)) i>=len(M[j]) ? 0 : len(strarr[j][i])])
                ],
       padded =
         [for(row=strarr)
            str_join([for(i=idx(row))
                            let(
                                extra = ends_with(row[i],"inf") ? 1 : 0
                            )
                            str_pad(row[i],maxlen[i]+extra+(i==0?0:columngap),space_figure,left=true)])]
    )
    padded;


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
