//////////////////////////////////////////////////////////////////////
// LibFile: strings.scad
//   String manipulation and formatting functions.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Data Management
// FileSummary: String manipulation functions.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

_BOSL2_STRINGS = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: strings.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;

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
//   len = length of substring, or omit it to get the rest of the string.  If len is zero or less then the empty string is returned.
// Example:
//   s1=substr("abcdefg",3,3);     // Returns "def"
//   s2=substr("abcdefg",2);       // Returns "cdefg"
//   s3=substr("abcdefg",len=3);   // Returns "abc"
//   s4=substr("abcdefg",[2,4]);   // Returns "cde"
//   s5=substr("abcdefg",len=-2);  // Returns ""
function substr(str, pos=0, len=undef) =
    assert(is_string(str))
    is_list(pos) ? _substr(str, pos[0], pos[1]-pos[0]+1) 
  : len == undef ? _substr(str, pos, len(str)-pos) 
                 : _substr(str,pos,len);

function _substr(str,pos,len) =
    assert(pos>=0,"\npos value for substr() must be nonnegative.")
    len <= 0 || pos>=len(str) ? ""
  :
    chr([for(i=[pos:1:min(pos+len-1,len(str)-1)]) ord(str[i])]);
                              

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
//   Searches `str` for `pattern` and returns the index or indices of the matches. Strings and lists
//   are accepted; list patterns are compared by element equality.
//   By default `str_find()` returns the index of the first match in `str`.  If `last` is true then it returns the index of the last match.
//   For an empty pattern, the first match is at zero and the last is at `len(str)`. 
//   If `start` is set then the search begins at index start, working either forward and backward from that position.  If you set `start`
//   and `last` is true then the search finds the pattern if it begins at index `start`. If no match exists, returns `undef`.
//   .
//   If you set `all` to true then `str_find()` returns all of the matches as a list, or an empty list if there are no matches.
//   You cannot set `start` in this case.  The empty string matches every index position.
// Arguments:
//   str = String or list to search.
//   pattern = String or list pattern to search for
//   ---
//   last = set to true to return the last match. Default: false
//   all = set to true to return all matches as a list.  Overrides last.  Default: false
//   start = index where the search starts. Cannot be combined with `all=true`.
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
//   j=str_find("abc123def123", "123", start=8, last=true);  // Returns 3
//   k=str_find("abc123def123abc","123",all=true);   // Returns [3,9]
//   l=str_find("abc123def123abc","b",all=true);     // Returns [1,13]
//   m=str_find("abc123def123abc","1234",all=true);  // Returns []
//   n=str_find("abc","",all=true);                  // Returns [0,1,2]
//   o=str_find("abd{{bz}}fij", "{{b}}", all=true);  // returns []

function str_find(str,pattern,start=undef,last=false,all=false) =
    assert(_is_liststr(str), "\nstr must be a string or list.")
    assert(_is_liststr(pattern), "\npattern must be a string or list.")
    assert(!all || is_undef(start), "\nCannot combine start with all=true.")
    all? _str_find_all(str,pattern) :
    let( start = first_defined([start,last?len(str)-len(pattern):0]) )
    len(pattern)==0? start :
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
/*
function _str_find_all(str,pattern) =
    pattern == "" ? count(len(str)) :
    [for(i=[0:1:len(str)-len(pattern)]) if (substr_match(str,i,pattern)) i];
*/
/// More efficient _str_find_all, tested about 4X-7X faster than the version prior to September 2026.
/// Improves with less occurrences of pattern in str, or if first char of pattern is sparse in str.
function _str_find_all(str, pattern) =
    let(n = len(str), m = len(pattern))
    m == 0 ? count(n)
    : m > n ? [] : let( // get candidate test positions based on OpenSCAD search()
        candidates = is_string(str) && is_string(pattern)
            ? search(pattern[0], str, num_returns_per_match=0)[0]
            : [for (i=[0:1:n-m]) if (str[i]==pattern[0]) i]
    ) is_undef(candidates) ? []
    : m==1 ? candidates
    : let(m1=m-1) [ for(p = candidates)
        if (p<=n-m && str[p+m1] == pattern[m1]) // test last char before the rest of the pattern
            if(m==2 || _substr_match_recurse(str,p+1,pattern,m1,1)) p ];



// Function: substr_match()
// Synopsis: Returns true if the string `pattern` matches the string `str`.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   bool = substr_match(str,start,pattern);
// Description:
//   Returns true if `pattern` matches `str` starting at `str[start]`. Strings and lists are
//   accepted; list patterns are compared by element equality. If the input is too short for the pattern, or
//   `start` is out of bounds – either negative or beyond the end of the
//   string – then substr_match returns false.
// Arguments:
//   str = String or list to search
//   start = Starting index for search in str
//   pattern = String or list pattern to search for
// Example:
//   a=substr_match("abcde",2,"cd");   // Returns true
//   b=substr_match("abcde",2,"cx");   // Returns false
//   c=substr_match("abcde",2,"cdef"); // Returns false
//   d=substr_match("abcde",-2,"cd");  // Returns false
//   e=substr_match("abcde",19,"cd");  // Returns false
//   f=substr_match("abc",1,"");       // Returns true

//    This is carefully optimized for speed.  Precomputing the length
//    cuts run time in half when the string is long.  Two other string
//    comparison methods were slower.
function substr_match(str,start,pattern) =
     assert(_is_liststr(str), "\nstr must be a string or list.")
     assert(_is_liststr(pattern), "\npattern must be a string or list.")
     start<0 || len(str)-start <len(pattern)? false
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
// Synopsis: Splits a string at delimiter characters.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   string_list = str_split(str, sep, [keep_nulls]);
// Description:
//   Breaks an input string into substrings using single character deliminters.  If keep_nulls is true
//   then two sequential separator characters produce an empty string in the output list.  If keep_nulls is false
//   then no empty strings are included in the output list.
//   .
//   If sep is a single string then each character in sep is treated as a delimiting character and the input string is
//   split at every delimiting character.  Empty strings can occur whenever two delimiting characters are sequential.
//   If sep is a list, each entry is a set of delimiter characters for each successive split.  The first
//   occurrence of any character in any entry defines a splitting point.  Then the next string is used to provide delimiters
//   for the next split and so on.  Delimiters are always single characters: a list of strings does **not** provide multi-character
//   delimiting strings, so "<=" always means either "<" or "=" can be deliminters and never that the string "<=" is sought as a delimiter.  
//   Characters within each separator string should be distinct.
//   If keep_nulls is true then the output length is equal to `len(sep)+1`, possibly with trailing null strings
//   if the string runs out before the separator list.
// Arguments:
//   str = String to split.
//   sep = A set of delimiter characters, or a list of character sets used for successive splits.
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
        end = pos==[] ? len(str) : min(pos)
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
// Synopsis: Joins a list of strings into a single string.
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
//   it strips only the leading or trailing characters respectively. If you set start
//   or end to false then it strips only the trailing or leading characters.
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
//   padded = str_pad(str, length, [char], [left]);
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
  assert(is_str(char) && len(char)==1, "\nchar must be a single character string.")
  assert(is_bool(left))
  let(
    padding = chr(repeat(ord(char),length-len(str)))
  )
  left ? str(padding,str) : str(str,padding);



// Function: str_replace()
// Synopsis: Replace all occurrences of the specified substring in a string with another string.
// Topics: Strings
// See Also: str_find(), substr_match(), str_replace_char()
// Usage:
//   newstr = str_replace(str, search, replace);
// Description:
//   Replace every occurence of `search` in the input string
//   with the string `replace`, which can be any string.
//   .
// Arguments:
//   str = string to process
//   search = substring to search for
//   replace = string that replaces all copies of `search`
// Example:
//   s1 = str_replace("abcdefgabcdefg","bc","XYZ");     // Returns: "aXYZdefgaXYZdefg"

/// Tested to be 2 orders of magnitude faster than using a version with substr().
function str_replace(str, search, replace) =
    assert(is_string(str) && is_string(search) && is_string(replace),
        "\nAll arguments of str_replace() must be strings.")
    let(sn = len(search))
    sn == 0 ? str
    : let(
        n       = len(str),
        pos_all = str_find(str, search, all=true), // all=true forces use of internal OpenSCAD search() for efficiency
        np1 = len(pos_all)
    ) np1 == 0 ? str
    : let(
        pos = [
            for (j = 0, last_end = 0;
                 j < np1;
                 last_end = (pos_all[j] >= last_end) ? pos_all[j] + sn : last_end,
                 j = j + 1)
                if (pos_all[j] >= last_end) pos_all[j]
        ],
        np = len(pos),
        rcodes = [for (c = replace) ord(c)], // manipulate a list rather than a string
        codes = [ // build out a list
            for (i = 0, mi = 0, matched = (0 < np && pos[0] == 0);
                 i < n;
                 mi      = matched ? mi + 1 : mi,
                 i       = matched ? i + sn  : i + 1,
                 matched = (mi < np && pos[mi] == i))   // uses the just-updated mi, i
                if (matched) each rcodes
                else ord(str[i])
        ]
    ) chr(codes); // quick conversion of unicode list back to a string


// Function: str_replace_char()
// Synopsis: Replace specified character in a string with a string.
// Topics: Strings
// See Also: suffix(), str_find(), substr_match(), starts_with(), ends_with(), str_split(), str_join(), str_strip()
// Usage:
//   newstr = str_replace_char(str, char, replace);
// Description:
//   Replace every occurence of `char` (a single character string) in the input string
//   with the string `replace`, which can be any string.
// Arguments:
//   str = string to process
//   char = single character string to search for
//   replace = string that replaces all copies of `char`
// Example:
//   s1 = str_replace_char("abcdcba","c","_123_");     // Returns: "ab_123_d_123_ba"
//   s2 = str_replace_char(" s t r i n g ", " ", "");  // Returns: "string"

function str_replace_char(str,char,replace) =
   assert(is_str(str))
   assert(is_str(char) && len(char)==1, "\nSearch pattern 'char' must be a single character string.")
   assert(is_str(replace))
   str_join([for(c=str) c==char ? replace : c]);



// Function: str_collapse_char()
// Synopsis: Collapse a specific repeating character in a string.
// Topics: Strings
// See Also: str_strip()
// Usage:
//   newstr = str_collapse_char(str, [char]);
// Description:
//  Collapse any repeated sequences of a specified character in the input string into a single character.
//  This is useful to collapse multiple sequental spaces in a string that spans multiple indented lines in your source code.
// Arguments:
//   str = string to process
//   char = single character string to search for repetitions. Default: space character
// Example:
//   s1 = str_collapse_char("a-b--c---d----e", "-");  // Returns: "a-b-c-d-e"
//   
//   st = "abc
//         def
//         xyz";  // parsed as "abc      def      xyz"
//   s2 = str_collapse_char(st);                      // Returns: "abc def xyz"

function str_collapse_char(str, char=" ") =
    assert(is_str(str))
    assert(is_str(char) && len(char)==1, "\nSearch pattern 'char' must be a single character string.")
    let(oc = ord(char), n=len(str)-1)
        chr([for(i=[0:1:n]) let(c=ord(str[i]))
            if (c!=oc || i==0 || ord(str[i-1])!=c) c]);



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
    chr([for(char=str) let(code=ord(char)) code>=65 && code<=90 ? code+32 : code]);


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
    chr([for(char=str) let(code=ord(char)) code>=97 && code<=122 ? code-32 : code]);


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
  is_undef(charset)? chr(rand_int(48,122,n,seed))
                   : chr([for(i=rand_int(0,len(charset)-1,n,seed)) ord(charset[i])]);



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
//   base = Integer base for conversion, from 2-16.  Default: 10
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
    assert(is_int(base) && base>=2 && base<=16, "\nbase must be an integer from 2 to 16.")
    str==undef ? undef
  : assert(is_str(str))
    len(str)==0 ? 0
  : let(str=downcase(str))
    str[0] == "-" ? -_parse_int_recurse(substr(str,1),base,len(str)-2)
  : str[0] == "+" ?  _parse_int_recurse(substr(str,1),base,len(str)-2)
  : _parse_int_recurse(str,base,len(str)-1);

function _parse_int_recurse(str,base,i) =
    i<0 ? NAN :
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
    str=="" ? 0
  : let(
        negative = str[0]=="-",
        body = negative || str[0]=="+" ? substr(str,1) : str,
        esplit = str_split(body,"eE"),
        dsplit = str_split(esplit[0],"."),
        whole = dsplit[0],
        frac = len(dsplit)==2 ? dsplit[1] : "",
        exponent = len(esplit)==2 ? esplit[1] : "0"
    )
    len(esplit)>2 || len(dsplit)>2 || exponent=="" ||
    (whole=="" && frac=="") ||
    (whole!="" && !is_digit(whole)) || (frac!="" && !is_digit(frac)) ? NAN :
    (negative ? -1 : 1) *
        (parse_int(whole) + parse_int(frac)/pow(10,len(frac))) * pow(10,parse_int(exponent));


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
    str==undef ? undef
  : assert(is_str(str))
    str=="" ? 0
  : let(
        has_sign = str[0]=="-" || str[0]=="+",
        sgn = str[0]=="-" ? -1 : 1,
        body = has_sign ? substr(str,1) : str,
        whole = str_split(body," ")
    )
    (!signed && has_sign) || body=="" || len(whole)>2 ? NAN :
    len(whole)==2 ?
        (!mixed || !is_digit(whole[0]) || whole[1]=="" ? NAN :
         sgn * (parse_int(whole[0]) + parse_frac(whole[1],mixed=false,improper=improper,signed=false))) :
    let(parts = str_split(body,"/"))
    len(parts)==1 ? (mixed && is_digit(body) ? sgn*parse_int(body) : NAN) :
    len(parts)!=2 || !is_digit(parts[0]) || !is_digit(parts[1]) ? NAN :
    let(numerator=parse_int(parts[0]), denominator=parse_int(parts[1]))
    !improper && numerator>=denominator ? NAN :
    sgn * numerator/denominator;


// Function: parse_num()
// Synopsis: Parse a float from a decimal or fraction string.
// Topics: Strings
// See Also: parse_int(), parse_float(), parse_frac(), parse_num()
// Usage:
//   num = parse_num(str);
// Description:
//   Converts a string to a number. The string can be a fraction (two integers separated by a "/" like "3/4"), a mixed fraction (an integer followed
//   by a space and then a fraction like "4 2/3"), or a floating point number.
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
//   format_int(-123456789012345); // Returns "-123456789012345"
//   format_int(12,3);             // Returns 012

function format_int(i,mindigits=1) =
    assert(is_finite(i), "\nInput must be a finite number.")
    assert(is_int(mindigits) && mindigits>=0, "\nmindigits must be a nonnegative integer.")
    i<0 ? str("-", format_int(-i,mindigits)) :
    let(i=floor(i))
    i==0 ? chr([for (j=[0:1:max(1,mindigits)-1]) 48]) :
    let(e=_str_decimal_parts(i)[0])
    chr([
          for (j=[0:1:mindigits-e-2]) 48,
          for (j=[e:-1:0]) 48+(floor(i/pow(10,j)%10))
        ]);


/// Return the decimal exponent and a significand in [1,10), without
/// overflowing the normalization factor for very small finite inputs.
function _str_decimal_parts(f) =
    let(
        e = floor(log(f)),
        m = e < -300 ? (f*1e300)/pow(10,e+300)
          : e > 300 ? (f/1e300)/pow(10,e-300)
          : f/pow(10,e)
    )
    m>=10 ? [e+1,m/10] : m<1 ? [e-1,m*10] : [e,m];


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
//   digits = Nonnegative number of digits after the decimal to show. Zero omits the decimal point. Default: 6

function format_fixed(f,digits=6) =
    assert(is_int(digits) && digits>=0, "\ndigits must be a nonnegative integer.")
    is_list(f)? str("[",str_join(sep=", ", [for (g=f) format_fixed(g,digits=digits)]),"]") :
    str(f)=="nan"? "nan" :
    str(f)=="inf"? "inf" :
    f<0? str("-",format_fixed(-f,digits=digits)) :
    assert(is_num(f))
    let(
        sc = pow(10,digits),
        whole = floor(f),
        part = floor((f-whole)*sc + 0.5),
        carry = part>=sc ? 1 : 0
    )
    assert(is_finite(sc), "\nRequested precision is too large.")
    str(format_int(whole+carry), digits==0 ? "" : str(".",format_int(carry ? 0 : part,digits)));


// Function: format_float()
// Synopsis: Formats a float into a string with a given number of significant digits.
// Topics: Strings
// See Also: format_int(), format_fixed(), format_float(), format()
// Usage:
//   str = format_float(f,[sig]);
// Description:
//   Formats the given floating point number `f` into a string with `sig` significant digits.
//   Strips trailing `0`s after the decimal point.  Strips trailing decimal point.
//   If possible, the number is represented in `sig` significant digits without an exponent.
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
        parts = _str_decimal_parts(f),
        e = parts[0],
        mv = sig-e-1
    )
    (e<-sig/2 || mv<0) ?
        let(mantissa = format_float(parts[1],sig=sig))
        mantissa=="10" ? str("1e",format_int(e+1)) : str(mantissa,"e",format_int(e)) :
    let(
        fixed = format_fixed(f,digits=mv),
        dot = str_find(fixed,".")
    )
    is_undef(dot) ? fixed :
    let(frac = str_strip(substr(fixed,dot+1),"0",end=true))
    str(substr(fixed,0,dot), frac=="" ? "" : str(".",frac));


/// Function: _format_matrix()
/// Usage:
///   _format_matrix(M, [sig], [sep], [eps])
/// Description:
///   Convert a numerical matrix into a matrix of strings where every column
///   is the same width so it displays in neat columns when printed.
///   Values below eps display as zero. The matrix can include nans, infs
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
       sep = is_num(sep) && sep>=0 ? chr(repeat(ord(space_figure),sep))
           : is_string(sep) ? sep
           : assert(false,"\nInvalid separator: must be a string or positive integer giving number of spaces."),
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
//   The first `}` after an opening `{` ends that placeholder. Other `}` characters are literal text;
//   an opening `{` without a closing `}` is an error.
//   Formatting placeholders have the following syntax:
//   - A leading `{` character to show the start of the placeholder.
//   - An integer index into the `vals` list to specify which value should be formatted at that place. If not given, the first placeholder uses index `0`, the second uses index `1`, etc.
//   - An optional `:` separator to indicate that what follows if a formatting specifier.  If not given, no formatting info follows.
//   - An optional `-` character to indicate that the value should be left justified if the value needs field width padding.  If not given, right justification is used.
//   - An optional `0` character to indicate that the field should be padded with `0`s.  If not given, spaces are used for padding.
//   - An optional integer field width, which the value should be padded to.  If not given, no padding is performed.
//   - An optional `.` followed by an integer precision length, for specifying how many digits to display in numeric formats.  If not give, 6 digits is assumed.
//   - An optional letter to indicate the formatting style to use. If not given, `s` is assumed, which does its generic best to format any data type.
//   - A trailing `}` character to show the end of the placeholder.
//   .
//   Formatting styles, and their effects are as follows:
//   - `s`: Converts the value to a string with `str()` to display.  This is very generic.
//   - `i` or `d`: Formats numeric values as integers.
//   - `f`: Formats numeric values with the precision number of digits after the decimal point.  NaN and Inf are shown as `nan` and `inf`.
//   - `F`: Formats numeric values with the precision number of digits after the decimal point.  NaN and Inf are shown as `NAN` and `INF`.
//   - `g`: Formats numeric values with the precision number of total significant digits.  NaN and Inf are shown as `nan` and `inf`.  Exponents are marked by `e`.
//   - `G`: Formats numeric values with the precision number of total significant digits.  NaN and Inf are shown as `NAN` and `INF`.  Exponents are marked by `E`.
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
            err = assert(found_brace, "\nUnbalanced { in format string."),
            p = i==0? [undef,parts[i]] : str_split(parts[i],["}"]),
            fmta = p[0],
            raw = p[1]
        ) each [
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
                        substr(sval, 0, min(len(sval), prec))
                    ) :
                    (typ=="d" || typ=="i")? format_int(val) :
                    typ=="b"? (val? "true" : "false") :
                    typ=="B"? (val? "TRUE" : "FALSE") :
                    typ=="f"? downcase(format_fixed(val,default(prec,6))) :
                    typ=="F"? upcase(format_fixed(val,default(prec,6))) :
                    typ=="g"? downcase(format_float(val,default(prec,6))) :
                    typ=="G"? upcase(format_float(val,default(prec,6))) :
                    assert(false,str("\nUnknown format type \"",typ,"\".")),
                padlen = max(0,wid-len(unpad)),
                padfill = chr([for (i=[0:1:padlen-1]) zero? 48 : 32]),
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
