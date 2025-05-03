//////////////////////////////////////////////////////////////////////
// LibFile: strings.scad
//   String manipulation and formatting functions.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Data Management
// FileSummary: String manipulation functions.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


function _is_liststr(s) = is_list(s) || is_str(s);


// Section: Extracting substrings

// Function: substr()
// Synopsis: Returns a substring from a string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   newstr = substr(str, [pos], [len]);
// Description:
//   Returns a substring from a string start at position `pos` with length `len`, or
//   if `len` isn't given, the rest of the string.
// Arguments:
//   str = string to operate on
//   pos = starting index of substring, or vector of first and last position.  Default: 0
//   len = length of substring, or omit it to get the rest of the string.  If len is zero or less then the emptry string is returned.
// Example:
//   s1=substr("abcdefg",3,3);     // Returns "def"
//   s2=substr("abcdefg",2);       // Returns "cdefg"
//   s3=substr("abcdefg",len=3);   // Returns "abc"
//   s4=substr("abcdefg",[2,4]);   // Returns "cde"
//   s5=substr("abcdefg",len=-2);  // Returns ""
function substr(str, pos=0, len=undef) =
    assert(is_string(str))
    is_list(pos) ? _substr(str, pos[0], pos[1]-pos[0]+1) :
    len == undef ? _substr(str, pos, len(str)-pos) :
    _substr(str,pos,len);

function _substr(str,pos,len,substr="") =
    len <= 0 || pos>=len(str) ? substr :
    _substr(str, pos+1, len-1, str(substr, str[pos]));


// Function: suffix()
// Synopsis: Returns the last few characters of a string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   newstr = suffix(str,len);
// Description:
//   Returns the last `len` characters from the input string `str`.
//   If `len` is longer than the length of `str`, then the entirety of `str` is returned.
// Arguments:
//   str = The string to get the suffix of.
//   len = The number of characters of suffix to get.
function suffix(str,len) =
    len>=len(str)? str : substr(str, len(str)-len,len);


// Section: String Searching


// Function: str_find()
// Synopsis: Finds a substring in a string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   ind = str_find(str,pattern,[last=],[all=],[start=]);
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
//   ---
//   last = set to true to return the last match. Default: false
//   all = set to true to return all matches as a list.  Overrides last.  Default: false
//   start = index where the search starts
// Example:
//   a=str_find("abc123def123abc","123");   // Returns 3
//   b=str_find("abc123def123abc","b");     // Returns 1
//   c=str_find("abc123def123abc","1234");  // Returns undef
//   d=str_find("abc","");                  // Returns 0
//   e=str_find("abc123def123", "123", start=4);     // Returns 9
//   f=str_find("abc123def123abc","123",last=true);  // Returns 9
//   g=str_find("abc123def123abc","b",last=true);    // Returns 13
//   h=str_find("abc123def123abc","1234",last=true); // Returns undef
//   i=str_find("abc","",last=true);                 // Returns 3
//   j=str_find("abc123def123", "123", start=8, last=true));  // Returns 3
//   k=str_find("abc123def123abc","123",all=true);   // Returns [3,9]
//   l=str_find("abc123def123abc","b",all=true);     // Returns [1,13]
//   m=str_find("abc123def123abc","1234",all=true);  // Returns []
//   n=str_find("abc","",all=true);                  // Returns [0,1,2]
function str_find(str,pattern,start=undef,last=false,all=false) =
    assert(_is_liststr(str), "str must be a string or list")
    assert(_is_liststr(pattern), "pattern must be a string or list")
    all? _str_find_all(str,pattern) :
    let( start = first_defined([start,last?len(str)-len(pattern):0]) )
    pattern==""? start :
    last? _str_find_last(str,pattern,start) :
    _str_find_first(str,pattern,len(str)-len(pattern),start);

function _str_find_first(str,pattern,max_sindex,sindex) =
    sindex<=max_sindex && !substr_match(str,sindex, pattern)?
        _str_find_first(str,pattern,max_sindex,sindex+1) :
        (sindex <= max_sindex ? sindex : undef);

function _str_find_last(str,pattern,sindex) =
    sindex>=0 && !substr_match(str,sindex, pattern)?
        _str_find_last(str,pattern,sindex-1) :
        (sindex >=0 ? sindex : undef);

function _str_find_all(str,pattern) =
    pattern == "" ? count(len(str)) :
    [for(i=[0:1:len(str)-len(pattern)]) if (substr_match(str,i,pattern)) i];

// Function: substr_match()
// Synopsis: Returns true if the string `pattern` matches the string `str`.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage
//   bool = substr_match(str,start,pattern);
// Description:
//   Returns true if the string `pattern` matches the string `str` starting
//   at `str[start]`.  If the string is too short for the pattern, or
//   `start` is out of bounds – either negative or beyond the end of the
//   string – then substr_match returns false.
// Arguments:
//   str = String to search
//   start = Starting index for search in str
//   pattern = String pattern to search for
// Example:
//   a=substr_match("abcde",2,"cd");   // Returns true
//   b=substr_match("abcde",2,"cx");   // Returns false
//   c=substr_match("abcde",2,"cdef"); // Returns false
//   d=substr_match("abcde",-2,"cd");  // Returns false
//   e=substr_match("abcde",19,"cd");  // Returns false
//   f=substr_match("abc",1,"");       // Returns true

//
//    This is carefully optimized for speed.  Precomputing the length
//    cuts run time in half when the string is long.  Two other string
//    comparison methods were slower.
function substr_match(str,start,pattern) =
     assert(_is_liststr(str), "str must be a string or list")
     assert(_is_liststr(pattern), "pattern must be a string or list")
     len(str)-start <len(pattern)? false
   : _substr_match_recurse(str,start,pattern,len(pattern));

function _substr_match_recurse(str,sindex,pattern,plen,pindex=0,) =
    pindex < plen && pattern[pindex]==str[sindex]
       ? _substr_match_recurse(str,sindex+1,pattern,plen,pindex+1)
       : (pindex==plen);


// Function: starts_with()
// Synopsis: Returns true if the string starts with a given substring.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//    bool = starts_with(str,pattern);
// Description:
//    Returns true if the input string (or list) `str` starts with the specified string (or list) pattern, `pattern`.
//    Otherwise returns false.  (If `str` is not a string or list then always returns false.)
// Arguments:
//   str = String to search.
//   pattern = String pattern to search for.
// Example:
//   b1=starts_with("abcdef","abc");  // Returns true
//   b2=starts_with("abcdef","def");  // Returns false
//   b3=starts_with("abcdef","");     // Returns true
function starts_with(str,pattern) = _is_liststr(str) && substr_match(str,0,pattern);


// Function: ends_with()
// Synopsis: Returns true if the string ends with a given substring.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//    bool = ends_with(str,pattern);
// Description:
//    Returns true if the input string (or list) `str` ends with the specified string (or list) pattern, `pattern`.
//    Otherwise returns false.  (If `str` is not a string or list then always returns false.)
// Arguments:
//   str = String to search.
//   pattern = String pattern to search for.
// Example:
//   b1=ends_with("abcdef","def");  // Returns true
//   b2=ends_with("abcdef","de");   // Returns false
//   b3=ends_with("abcdef","");     // Returns true
function ends_with(str,pattern) = _is_liststr(str) && substr_match(str,len(str)-len(pattern),pattern);



// Function: str_split()
// Synopsis: Splits a longer string wherever a given substring occurs.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   string_list = str_split(str, sep, [keep_nulls]);
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
//   s1=str_split("abc+def-qrs*iop","*-+");     // Returns ["abc", "def", "qrs", "iop"]
//   s2=str_split("abc+*def---qrs**iop+","*-+");// Returns ["abc", "", "def", "", "", "qrs", "", "iop", ""]
//   s3=str_split("abc      def"," ");          // Returns ["abc", "", "", "", "", "", "def"]
//   s4=str_split("abc      def"," ",keep_nulls=false); // Returns ["abc", "def"]
//   s5=str_split("abc+def-qrs*iop",["+","-","*"]);     // Returns ["abc", "def", "qrs", "iop"]
//   s6=str_split("abc+def-qrs*iop",["-","+","*"]);     // Returns ["abc+def", "qrs*iop", "", ""]
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



// Section: String modification


// Function: str_join()
// Synopsis: Joints a list of strings into a single string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   str = str_join(list, [sep]);
// Description:
//   Returns the concatenation of a list of strings, optionally with a
//   separator string inserted between each string on the list.
// Arguments:
//   list = list of strings to concatenate
//   sep = separator string to insert.  Default: ""
// Example:
//   s1=str_join(["abc","def","ghi"]);         // Returns "abcdefghi"
//   s2=str_join(["abc","def","ghi"], " + ");  // Returns "abc + def + ghi"
function str_join(list,sep="",_i=0, _result="") =
    assert(is_list(list))
    _i >= len(list)-1 ? (_i==len(list) ? _result : str(_result,list[_i])) :
    str_join(list,sep,_i+1,str(_result,list[_i],sep));




// Function: str_strip()
// Synopsis: Strips given leading and trailing characters from a string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   str = str_strip(s,c,[start],[end]);
// Description:
//   Takes a string `s` and strips off all leading and/or trailing characters that exist in string `c`.
//   By default strips both leading and trailing characters.  If you set start or end to true then
//   it will strip only the leading or trailing characters respectively.  If you set start
//   or end to false then it will strip only the trailing or leading characters.
// Arguments:
//   s = The string to strip leading or trailing characters from.
//   c = The string of characters to strip.
//   start = if true then strip leading characters
//   end = if true then strip trailing characters
// Example:
//   s1=str_strip("--##--123--##--","#-");  // Returns: "123"
//   s2=str_strip("--##--123--##--","-");   // Returns: "##--123--##"
//   s3=str_strip("--##--123--##--","#");   // Returns: "--##--123--##--"
//   s4=str_strip("--##--123--##--","#-",end=true);   // Returns: "--##--123"
//   s5=str_strip("--##--123--##--","-",end=true);    // Returns: "--##--123--##"
//   s6=str_strip("--##--123--##--","#",end=true);    // Returns: "--##--123--##--"
//   s7=str_strip("--##--123--##--","#-",start=true); // Returns: "123--##--"
//   s8=str_strip("--##--123--##--","-",start=true);  // Returns: "##--123--##--"
//   s9=str_strip("--##--123--##--","#",start=true);  // Returns: "--##--123--##--"

function _str_count_leading(s,c,_i=0) =
    (_i>=len(s)||!in_list(s[_i],[each c]))? _i :
    _str_count_leading(s,c,_i=_i+1);

function _str_count_trailing(s,c,_i=0) =
    (_i>=len(s)||!in_list(s[len(s)-1-_i],[each c]))? _i :
    _str_count_trailing(s,c,_i=_i+1);

function str_strip(s,c,start,end) =
  let(
      nstart = (is_undef(start) && !end) ? true : start,
      nend = (is_undef(end) && !start) ? true : end,
      startind = nstart ? _str_count_leading(s,c) : 0,
      endind = len(s) - (nend ? _str_count_trailing(s,c) : 0)
  )
  substr(s,startind, endind-startind);



// Function: str_pad()
// Synopsis: Pads a string to a given length.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
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
// Example:
//   s1=str_pad("hello", 10, "*");            // Returns: "hello*****"
//   s2=str_pad("hello", 10, "*", left=true); // Returns: "*****hello"

function str_pad(str,length,char=" ",left=false) =
  assert(is_str(str))
  assert(is_str(char) && len(char)==1, "char must be a single character string")
  assert(is_bool(left))
  let(
    padding = str_join(repeat(char,length-len(str)))
  )
  left ? str(padding,str) : str(str,padding);



// Function: str_replace_char()
// Synopsis: Replace specified character in a string with a string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   newstr = str_replace_char(str, char, replace);
// Description:
//   Replace every occurence of `char` (a single character string) in the input string
//   with the string `replace` which can be any string.
// Arguments:
//   str = string to process
//   char = single character string to search for
//   replace = string that replaces all copies of `char`
// Example:
//   s1 = str_replace_char("abcdcba","c","_123_");     // Returns: "ab123d123ba"
//   s2 = str_replace_char(" s t r i n g ", " ", "");  // Returns: "string"

function str_replace_char(str,char,replace) =
   assert(is_str(str))
   assert(is_str(char) && len(char)==1, "Search pattern 'char' must be a single character string")
   assert(is_str(replace))
   str_join([for(c=str) c==char ? replace : c]);


// Function: downcase()
// Synopsis: Lowercases all characters in a string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip(), upcase(), downcase()
// Usage:
//   newstr = downcase(str);
// Description:
//   Returns the string with the standard ASCII upper case letters A-Z replaced
//   by their lower case versions.
// Arguments:
//   str = String to convert.
// Example:
//   s=downcase("ABCdef");   // Returns "abcdef"
function downcase(str) =
    assert(is_string(str))
    str_join([for(char=str) let(code=ord(char)) code>=65 && code<=90 ? chr(code+32) : char]);


// Function: upcase()
// Synopsis: Uppercases all characters in a string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip(), upcase(), downcase()
// Usage:
//   newstr = upcase(str);
// Description:
//   Returns the string with the standard ASCII lower case letters a-z replaced
//   by their upper case versions.
// Arguments:
//   str = String to convert.
// Example:
//   s=upcase("ABCdef");   // Returns "ABCDEF"
function upcase(str) =
    assert(is_string(str))
    str_join([for(char=str) let(code=ord(char)) code>=97 && code<=122 ? chr(code-32) : char]);


// Section: Random strings

// Function: rand_str()
// Synopsis: Create a randomized string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip(), upcase(), downcase()
// Usage:
//    str = rand_str(n, [charset], [seed]);
// Description:
//    Produce a random string of length `n`.  If you give a string `charset` then the
//    characters of the random string are drawn from that list, weighted by the number
//    of times each character appears in the list.  If you do not give a character set
//    then the string is generated with characters ranging from "0" to "z" (based on
//    character code).
// Arguments:
//    n = number of characters to produce
//    charset = string to draw the characters from.  Default: characters from "0" to "z".
//    seed = random number seed
function rand_str(n, charset, seed) =
  is_undef(charset)? str_join([for(c=rand_int(48,122,n,seed)) chr(c)])
                   : str_join([for(i=rand_int(0,len(charset)-1,n,seed)) charset[i]]);



// Section: Parsing strings into numbers

// Function: parse_int()
// Synopsis: Parse an integer from a string.
// Topics: Strings
// See Also: parse_int(), parse_float(), parse_frac(), parse_num()
// Usage:
//   num = parse_int(str, [base])
// Description:
//   Converts a string into an integer with any base up to 16.  Returns NaN if
//   conversion fails.  Digits above 9 are represented using letters A-F in either
//   upper case or lower case.
// Arguments:
//   str = String to convert.
//   base = Base for conversion, from 2-16.  Default: 10
// Example:
//   parse_int("349");        // Returns 349
//   parse_int("-37");        // Returns -37
//   parse_int("+97");        // Returns 97
//   parse_int("43.9");       // Returns nan
//   parse_int("1011010",2);  // Returns 90
//   parse_int("13",2);       // Returns nan
//   parse_int("dead",16);    // Returns 57005
//   parse_int("CEDE", 16);   // Returns 52958
//   parse_int("");           // Returns 0
function parse_int(str,base=10) =
    str==undef ? undef
  : assert(is_str(str))
    len(str)==0 ? 0
  : let(str=downcase(str))
    str[0] == "-" ? -_parse_int_recurse(substr(str,1),base,len(str)-2)
  : str[0] == "+" ?  _parse_int_recurse(substr(str,1),base,len(str)-2)
  : _parse_int_recurse(str,base,len(str)-1);

function _parse_int_recurse(str,base,i) =
    let(
        digit = search(str[i],"0123456789abcdef"),
        last_digit = digit == [] || digit[0] >= base ? (0/0) : digit[0]
    ) i==0 ? last_digit :
    _parse_int_recurse(str,base,i-1)*base + last_digit;


// Function: parse_float()
// Synopsis: Parse a float from a string.
// Topics: Strings
// See Also: parse_int(), parse_float(), parse_frac(), parse_num()
// Usage:
//   num = parse_float(str);
// Description:
//   Converts a string to a floating point number.  Returns NaN if the
//   conversion fails.
// Arguments:
//   str = String to convert.
// Example:
//   parse_float("44");       // Returns 44
//   parse_float("3.4");      // Returns 3.4
//   parse_float("-99.3332"); // Returns -99.3332
//   parse_float("3.483e2");  // Returns 348.3
//   parse_float("-44.9E2");  // Returns -4490
//   parse_float("7.342e-4"); // Returns 0.0007342
//   parse_float("");         // Returns 0
function parse_float(str) =
    str==undef ? undef
  : assert(is_str(str))
    len(str) == 0 ? 0
  : in_list(str[1], ["+","-"]) ? (0/0)  // Don't allow --3, or +-3
  : str[0]=="-" ? -parse_float(substr(str,1))
  : str[0]=="+" ?  parse_float(substr(str,1))
  : let(esplit = str_split(str,"eE") )
    len(esplit)==2 ? parse_float(esplit[0]) * pow(10,parse_int(esplit[1]))
  : let( dsplit = str_split(str,["."]))
    parse_int(dsplit[0])+parse_int(dsplit[1])/pow(10,len(dsplit[1]));


// Function: parse_frac()
// Synopsis: Parse a float from a fraction string.
// Topics: Strings
// See Also: parse_int(), parse_float(), parse_frac(), parse_num()
// Usage:
//   num = parse_frac(str,[mixed=],[improper=],[signed=]);
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
//   ---
//   mixed = set to true to accept mixed fractions, false to reject them.  Default: true
//   improper = set to true to accept improper fractions, false to reject them.  Default: true
//   signed = set to true to accept a leading sign character, false to reject.  Default: true
// Example:
//   parse_frac("3/4");     // Returns 0.75
//   parse_frac("-77/9");   // Returns -8.55556
//   parse_frac("+1/3");    // Returns 0.33333
//   parse_frac("19");      // Returns 19
//   parse_frac("2 3/4");   // Returns 2.75
//   parse_frac("-2 12/4"); // Returns -5
//   parse_frac("");        // Returns 0
//   parse_frac("3/0");     // Returns inf
//   parse_frac("0/0");     // Returns nan
//   parse_frac("-77/9",improper=false);   // Returns nan
//   parse_frac("-2 12/4",improper=false); // Returns nan
//   parse_frac("-2 12/4",signed=false);   // Returns nan
//   parse_frac("-2 12/4",mixed=false);    // Returns nan
//   parse_frac("2 1/4",mixed=false);      // Returns nan
function parse_frac(str,mixed=true,improper=true,signed=true) =
    str == undef ? undef
  : assert(is_str(str))
    len(str)==0 ? 0
  : str[0]==" " ? NAN
  : signed && str[0]=="-" ? -parse_frac(substr(str,1),mixed=mixed,improper=improper,signed=false)
  : signed && str[0]=="+" ?  parse_frac(substr(str,1),mixed=mixed,improper=improper,signed=false)
  : mixed && (str_find(str," ")!=undef || str_find(str,"/")==undef)?   // Mixed allowed and there is a space or no slash
        let(whole = str_split(str,[" "]))
        _parse_int_recurse(whole[0],10,len(whole[0])-1) + parse_frac(whole[1], mixed=false, improper=improper, signed=false)
  : let(split = str_split(str,"/"))
    len(split)!=2 ? NAN
  : let(
        numerator =  _parse_int_recurse(split[0],10,len(split[0])-1),
        denominator = _parse_int_recurse(split[1],10,len(split[1])-1)
    )
    !improper && numerator>=denominator? NAN
  : denominator<0 ? NAN
  : numerator/denominator;


// Function: parse_num()
// Synopsis: Parse a float from a decimal or fraction string.
// Topics: Strings
// See Also: parse_int(), parse_float(), parse_frac(), parse_num()
// Usage:
//   num = parse_num(str);
// Description:
//   Converts a string to a number.  The string can be either a fraction (two integers separated by a "/") or a floating point number.
//   Returns NaN if the conversion fails.
// Arguments:
//   str = string to process
// Example:
//   parse_num("3/4");    // Returns 0.75
//   parse_num("3.4e-2"); // Returns 0.034
function parse_num(str) =
    str == undef ? undef :
    assert(is_str(str))
    let( val = parse_frac(str) )
    val == val ? val :
    parse_float(str);




// Section: Formatting numbers into strings

// Function: format_int()
// Synopsis: Formats an integer into a string, with possible leading zeros.
// Topics: Strings
// See Also: format_int(), format_fixed(), format_float(), format()
// Usage:
//   str = format_int(i, [mindigits]);
// Description:
//   Formats an integer number into a string.  This can handle larger numbers than `str()`.
// Arguments:
//   i = The integer to make a string of.
//   mindigits = If the number has fewer than this many digits, pad the front with zeros until it does.  Default: 1.
// Example:
//   str(123456789012345);  // Returns "1.23457e+14"
//   format_int(123456789012345);  // Returns "123456789012345"
//   format_int(-123456789012345);  // Returns "-123456789012345"
function format_int(i,mindigits=1) =
    i<0? str("-", format_int(-i,mindigits)) :
    let(i=floor(i), e=floor(log(i)))
    i==0? str_join([for (j=[0:1:mindigits-1]) "0"]) :
    str_join(
        concat(
            [for (j=[0:1:mindigits-e-2]) "0"],
            [for (j=[e:-1:0]) str(floor(i/pow(10,j)%10))]
        )
    );


// Function: format_fixed()
// Synopsis: Formats a float into a string with a fixed number of decimal places.
// Topics: Strings
// See Also: format_int(), format_fixed(), format_float(), format()
// Usage:
//   s = format_fixed(f, [digits]);
// Description:
//   Given a floating point number, formats it into a string with the given number of digits after the decimal point.
// Arguments:
//   f = The floating point number to format.
//   digits = The number of digits after the decimal to show.  Default: 6
function format_fixed(f,digits=6) =
    assert(is_int(digits))
    assert(digits>0)
    is_list(f)? str("[",str_join(sep=", ", [for (g=f) format_fixed(g,digits=digits)]),"]") :
    str(f)=="nan"? "nan" :
    str(f)=="inf"? "inf" :
    f<0? str("-",format_fixed(-f,digits=digits)) :
    assert(is_num(f))
    let(
        sc = pow(10,digits),
        scaled = floor(f * sc + 0.5),
        whole = floor(scaled/sc),
        part = floor(scaled-(whole*sc))
    ) str(format_int(whole),".",format_int(part,digits));


// Function: format_float()
// Synopsis: Formats a float into a string with a given number of significant digits.
// Topics: Strings
// See Also: format_int(), format_fixed(), format_float(), format()
// Usage:
//   str = format_float(f,[sig]);
// Description:
//   Formats the given floating point number `f` into a string with `sig` significant digits.
//   Strips trailing `0`s after the decimal point.  Strips trailing decimal point.
//   If the number can be represented in `sig` significant digits without a mantissa, it will be.
//   If given a list of numbers, recursively prints each item in the list, returning a string like `[3,4,5]`
// Arguments:
//   f = The floating point number to format.
//   sig = The number of significant digits to display.  Default: 12
// Example:
//   format_float(PI,12);  // Returns: "3.14159265359"
//   format_float([PI,-16.75],12);  // Returns: "[3.14159265359, -16.75]"
function format_float(f,sig=12) =
    assert(is_int(sig))
    assert(sig>0)
    is_list(f)? str("[",str_join(sep=", ", [for (g=f) format_float(g,sig=sig)]),"]") :
    f==0? "0" :
    str(f)=="nan"? "nan" :
    str(f)=="inf"? "inf" :
    f<0? str("-",format_float(-f,sig=sig)) :
    assert(is_num(f))
    let(
        e = floor(log(f)),
        mv = sig - e - 1
    ) mv == 0? format_int(floor(f + 0.5)) :
    (e<-sig/2||mv<0)? str(format_float(f*pow(10,-e),sig=sig),"e",e) :
    let(
        ff = f + pow(10,-mv)*0.5,
        whole = floor(ff),
        part = floor((ff-whole) * pow(10,mv))
    )
    str_join([
        str(whole),
        str_strip(end=true,
            str_join([
                ".",
                format_int(part, mindigits=mv)
            ]),
            "0."
        )
    ]);


/// Function: _format_matrix()
/// Usage:
///   _format_matrix(M, [sig], [sep], [eps])
/// Description:
///   Convert a numerical matrix into a matrix of strings where every column
///   is the same width so it will display in neat columns when printed.
///   Values below eps will display as zero.  The matrix can include nans, infs
///   or undefs and the rows can be different lengths.
/// Arguments:
///   M = numerical matrix to convert
///   sig = significant digits to display.  Default: 4
//    sep = number of spaces between columns or a text string to separate columns.  Default: 1
///   eps = values smaller than this are shown as zero.  Default: 1e-9
function _format_matrix(M, sig=4, sep=1, eps=1e-9) =
   let(
       figure_dash = chr(8210),
       space_punc = chr(8200),
       space_figure = chr(8199),
       sep = is_num(sep) && sep>=0 ? str_join(repeat(space_figure,sep))
           : is_string(sep) ? sep
           : assert(false,"Invalid separator: must be a string or positive integer giving number of spaces"),
       strarr=
         [for(row=M)
             [for(entry=row)
                 let(
                     text = is_undef(entry) ? "und"
                          : !is_num(entry) ? str_join(repeat(figure_dash,2))
                          : abs(entry) < eps ? "0"             // Replace hyphens with figure dashes
                          : str_replace_char(format_float(entry, sig),"-",figure_dash),
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
                            str_pad(row[i],maxlen[i]+extra,space_figure,left=true)],sep=sep)]
    )
    padded;



// Function: format()
// Synopsis: Formats multiple values into a string with a given format.
// Topics: Strings
// See Also: format_int(), format_fixed(), format_float(), format()
// Usage:
//   s = format(fmt, vals);
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
//   format("The value of {} is {:.14f}.", ["pi", PI]);  // Returns: "The value of pi is 3.14159265358979."
//   format("The value {1:f} is known as {0}.", ["pi", PI]);  // Returns: "The value 3.141593 is known as pi."
//   format("We use a very small value {1:.6g} as {0}.", ["EPSILON", EPSILON]);  // Returns: "We use a very small value 1e-9 as EPSILON."
//   format("{:-5s}{:i}{:b}", ["foo", 12e3, 5]);  // Returns: "foo  12000true"
//   format("{:-10s}{:.3f}", ["plecostamus",27.43982]);  // Returns: "plecostamus27.440"
//   format("{:-10.9s}{:.3f}", ["plecostamus",27.43982]);  // Returns: "plecostam 27.440"
function format(fmt, vals) =
    assert(is_str(fmt))
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
                num = is_digit(fmtb[0])? parse_int(fmtb[0]) : (i-1),
                left = fmtb[1][0] == "-",
                fmtb1 = default(fmtb[1],""),
                fmtc = left? substr(fmtb1,1) : fmtb1,
                zero = fmtc[0] == "0",
                lch = fmtc==""? "" : fmtc[len(fmtc)-1],
                hastyp = is_letter(lch),
                typ = hastyp? lch : "s",
                fmtd = hastyp? substr(fmtc,0,len(fmtc)-1) : fmtc,
                fmte = str_split((zero? substr(fmtd,1) : fmtd), "."),
                wid = parse_int(fmte[0]),
                prec = parse_int(fmte[1]),
                val = assert(num>=0&&num<len(vals)) vals[num],
                unpad = typ=="s"? (
                        let( sval = str(val) )
                        is_undef(prec)? sval :
                        substr(sval, 0, min(len(sval)-1, prec))
                    ) :
                    (typ=="d" || typ=="i")? format_int(val) :
                    typ=="b"? (val? "true" : "false") :
                    typ=="B"? (val? "TRUE" : "FALSE") :
                    typ=="f"? downcase(format_fixed(val,default(prec,6))) :
                    typ=="F"? upcase(format_fixed(val,default(prec,6))) :
                    typ=="g"? downcase(format_float(val,default(prec,6))) :
                    typ=="G"? upcase(format_float(val,default(prec,6))) :
                    assert(false,str("Unknown format type: ",typ)),
                padlen = max(0,wid-len(unpad)),
                padfill = str_join([for (i=[0:1:padlen-1]) zero? "0" : " "]),
                out = left? str(unpad, padfill) : str(padfill, unpad)
            )
            out, raw
        ]
    ]);



// Section: Checking character class

// Function: is_lower()
// Synopsis: Returns true if all characters in the string are lowercase.
// Topics: Strings
// See Also: is_lower(), is_upper(), is_digit(), is_hexdigit(), is_letter()
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
// Synopsis: Returns true if all characters in the string are uppercase.
// Topics: Strings
// See Also: is_lower(), is_upper(), is_digit(), is_hexdigit(), is_letter()
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
// Synopsis: Returns true if all characters in the string are decimal digits.
// Topics: Strings
// See Also: is_lower(), is_upper(), is_digit(), is_hexdigit(), is_letter()
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
// Synopsis: Returns true if all characters in the string are hexidecimal digits.
// Topics: Strings
// See Also: is_lower(), is_upper(), is_digit(), is_hexdigit(), is_letter()
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
// Synopsis: Returns true if all characters in the string are letters.
// Topics: Strings
// See Also: is_lower(), is_upper(), is_digit(), is_hexdigit(), is_letter()
// Usage:
//   x = is_letter(s);
// Description:
//   Returns true if all the characters in the given string are standard ASCII letters. (A-Z or a-z)
function is_letter(s) =
    assert(is_string(s))
    s==""? false :
    all([for (v=s) is_lower(v) || is_upper(v)]);





// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
