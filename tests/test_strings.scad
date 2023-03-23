include <../std.scad>
include <../strings.scad>


module test_upcase() {
    assert(upcase("") == "");
    assert(upcase("ABCDEFGHIJKLMNOPQRSTUVWXYZ") == "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    assert(upcase("abcdefghijklmnopqrstuvwxyz") == "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    assert(upcase("1234567890!@#$%^&*()") == "1234567890!@#$%^&*()");
    assert(upcase("_+-=[]\\{}|;':\",./<>?`~") == "_+-=[]\\{}|;':\",./<>?`~");
}
test_upcase();


module test_downcase() {
    assert(downcase("") == "");
    assert(downcase("ABCDEFGHIJKLMNOPQRSTUVWXYZ") == "abcdefghijklmnopqrstuvwxyz");
    assert(downcase("abcdefghijklmnopqrstuvwxyz") == "abcdefghijklmnopqrstuvwxyz");
    assert(downcase("1234567890!@#$%^&*()") == "1234567890!@#$%^&*()");
    assert(downcase("_+-=[]\\{}|;':\",./<>?`~") == "_+-=[]\\{}|;':\",./<>?`~");
}
test_downcase();

module test_substr_match(){
     assert(substr_match("abcde",2,"cd")); 
     assert(!substr_match("abcde",2,"cx"));
     assert(!substr_match("abcde",2,"cdef"));
     assert(!substr_match("abcde",-2,"cd"));
     assert(!substr_match("abcde",19,"cd"));
     assert(substr_match("abc",1,""));
     assert(!substr_match("",0,"a"));
     assert(substr_match("",0,""));
}


module test_starts_with() {
    assert(!starts_with("", "abc"));
    assert(!starts_with("", "123"));
    assert(!starts_with("defabc", "abc"));
    assert(!starts_with("123def", "def"));
    assert(!starts_with("def123def", "123"));
    assert(starts_with("abcdef", "abc"));
    assert(starts_with("abcabc", "abc"));
    assert(starts_with("123def", "123"));
}
test_starts_with();


module test_ends_with() {
    assert(!ends_with("", "abc"));
    assert(!ends_with("", "123"));
    assert(!ends_with("abcdef", "abc"));
    assert(ends_with("defabc", "abc"));
    assert(ends_with("abcabc", "abc"));
    assert(ends_with("def123", "123"));
}
test_ends_with();


module test_format_int() {
    assert(format_int(0,6) == "000000");
    assert(format_int(3,6) == "000003");
    assert(format_int(98765,6) == "098765");
    assert(format_int(-3,6) == "-000003");
    assert(format_int(-98765,6) == "-098765");
}
test_format_int();


module test_format_fixed() {
    assert(format_fixed(-PI*100,8) == "-314.15926536");
    assert(format_fixed(-PI,8) == "-3.14159265");
    assert(format_fixed(-3,8) == "-3.00000000");
    assert(format_fixed(3,8) == "3.00000000");
    assert(format_fixed(PI*100,8) == "314.15926536");
    assert(format_fixed(PI,8) == "3.14159265");
    assert(format_fixed(0,8) == "0.00000000");
    assert(format_fixed(-PI*100,3) == "-314.159");
    assert(format_fixed(-PI,3) == "-3.142");
    assert(format_fixed(-3,3) == "-3.000");
    assert(format_fixed(3,3) == "3.000");
    assert(format_fixed(PI*100,3) == "314.159");
    assert(format_fixed(PI,3) == "3.142");
}
test_format_fixed();


module test_format_float() {
    assert(format_float(-PI*100,8) == "-314.15927");
    assert(format_float(-PI,8) == "-3.1415927");
    assert(format_float(-3,8) == "-3");
    assert(format_float(3,8) == "3");
    assert(format_float(PI*100,8) == "314.15927");
    assert(format_float(PI,8) == "3.1415927");
    assert(format_float(0,8) == "0");
    assert(format_float(-PI*100,3) == "-314");
    assert(format_float(-PI,3) == "-3.14");
    assert(format_float(-3,3) == "-3");
    assert(format_float(3,3) == "3");
    assert(format_float(PI*100,3) == "314");
    assert(format_float(PI,3) == "3.14");
}
test_format_float();


module test_is_digit() {
    for (i=[32:126]) {
        if (i>=ord("0") && i <=ord("9")) {
            assert(is_digit(chr(i)));
        } else {
            assert(!is_digit(chr(i)));
        }
    }
    assert(!is_digit("475B3"));
    assert(is_digit("478"));
}
test_is_digit();


module test_is_hexdigit() {
    for (i=[32:126]) {
        if (
            (i>=ord("0") && i <=ord("9")) ||
            (i>=ord("A") && i <=ord("F")) ||
            (i>=ord("a") && i <=ord("f"))
        ) {
            assert(is_hexdigit(chr(i)));
        } else {
            assert(!is_hexdigit(chr(i)));
        }
    }
}
test_is_hexdigit();


module test_is_letter() {
    for (i=[32:126]) {
        if (
            (i>=ord("A") && i <=ord("Z")) ||
            (i>=ord("a") && i <=ord("z"))
        ) {
            assert(is_letter(chr(i)));
        } else {
            assert(!is_letter(chr(i)));
        }
    }
}
test_is_letter();


module test_is_lower() {
    for (i=[32:126]) {
        if (
            (i>=ord("a") && i <=ord("z"))
        ) {
            assert(is_lower(chr(i)));
        } else {
            assert(!is_lower(chr(i)));
        }
    }
    assert(is_lower("abcdefghijklmnopqrstuvwxyz"));
    assert(!is_lower("ABCDEFGHIJKLMNOPQRSTUVWXYZ"));
    assert(!is_lower("abcdefghijKlmnopqrstuvwxyz"));
    assert(!is_lower("abcdefghijklmnopqrstuvwxyZ"));
}
test_is_lower();


module test_is_upper() {
    for (i=[32:126]) {
        if (
            (i>=ord("A") && i <=ord("Z"))
        ) {
            assert(is_upper(chr(i)));
        } else {
            assert(!is_upper(chr(i)));
        }
    }
    assert(is_upper("ABCDEFGHIJKLMNOPQRSTUVWXYZ"));
    assert(!is_upper("abcdefghijklmnopqrstuvwxyz"));
    assert(!is_upper("ABCDEFGHIJkLMNOPQRSTUVWXYZ"));
    assert(!is_upper("ABCDEFGHIJKLMNOPQRSTUVWXYz"));
}
test_is_upper();


module test_parse_float() {
    assert(parse_float("3.1416") == 3.1416);
    assert(parse_float("-3.1416") == -3.1416);
    assert(parse_float("3.000") == 3.0);
    assert(parse_float("-3.000") == -3.0);
    assert(parse_float("3") == 3.0);
    assert(parse_float("0") == 0.0);
}
test_parse_float();


module test_parse_frac() {
    assert(parse_frac("") == 0);
    assert(parse_frac("1/2") == 1/2);
    assert(parse_frac("+1/2") == 1/2);
    assert(parse_frac("-1/2") == -1/2);
    assert(parse_frac("7/8") == 7/8);
    assert(parse_frac("+7/8") == 7/8);
    assert(parse_frac("-7/8") == -7/8);
    assert(parse_frac("1 1/2") == 1 + 1/2);
    assert(parse_frac("+1 1/2") == 1 + 1/2);
    assert(parse_frac("-1 1/2") == -(1 + 1/2));
    assert(parse_frac("768 3/4") == 768 + 3/4);
    assert(parse_frac("+768 3/4") == 768 + 3/4);
    assert(parse_frac("-768 3/4") == -(768 + 3/4));
    assert(parse_frac("19") == 19);
    assert(parse_frac("+19") == 19);
    assert(parse_frac("-19") == -19);
    assert(parse_frac("3/0") == INF);
    assert(parse_frac("-3/0") == -INF);
    assert(is_nan(parse_frac("0/0")));
    assert(is_nan(parse_frac("-77/9", improper=false)));
    assert(is_nan(parse_frac("-2 12/4",improper=false))); 
    assert(is_nan(parse_frac("-2 12/4",signed=false)));   
    assert(is_nan(parse_frac("-2 12/4",mixed=false)));    
    assert(is_nan(parse_frac("2 1/4",mixed=false)));
    assert(is_nan(parse_frac("2", mixed=false)));
}
test_parse_frac();


module test_parse_num() {
    assert(parse_num("") == 0);
    assert(parse_num("1/2") == 1/2);
    assert(parse_num("+1/2") == 1/2);
    assert(parse_num("-1/2") == -1/2);
    assert(parse_num("7/8") == 7/8);
    assert(parse_num("+7/8") == 7/8);
    assert(parse_num("-7/8") == -7/8);
    assert(parse_num("1 1/2") == 1 + 1/2);
    assert(parse_num("+1 1/2") == 1 + 1/2);
    assert(parse_num("-1 1/2") == -(1 + 1/2));
    assert(parse_num("768 3/4") == 768 + 3/4);
    assert(parse_num("+768 3/4") == 768 + 3/4);
    assert(parse_num("-768 3/4") == -(768 + 3/4));
    assert(parse_num("19") == 19);
    assert(parse_num("+19") == 19);
    assert(parse_num("-19") == -19);
    assert(parse_num("3/0") == INF);
    assert(parse_num("-3/0") == -INF);
    assert(parse_num("3.14159") == 3.14159);
    assert(parse_num("-3.14159") == -3.14159);
    assert(is_nan(parse_num("0/0")));
}
test_parse_num();


module test_parse_int() {
    assert(parse_int("0") == 0);
    assert(parse_int("3") == 3);
    assert(parse_int("7655") == 7655);
    assert(parse_int("+3") == 3);
    assert(parse_int("+7655") == 7655);
    assert(parse_int("-3") == -3);
    assert(parse_int("-7655") == -7655);
    assert(parse_int("ffff",16) == 65535);
}
test_parse_int();


module test_str_join() {
    assert(str_join(["abc", "D", "ef", "ghi"]) == "abcDefghi");
    assert(str_join(["abc", "D", "ef", "ghi"], "--") == "abc--D--ef--ghi");
}
test_str_join();


module test_str_split() {
    assert(str_split("abc-def+ghi-jkl", "-") == ["abc","def+ghi","jkl"]);
    assert(str_split("abc-def+ghi-jkl", "-+") == ["abc","def","ghi","jkl"]);
    assert(str_split("abc--def-ghi", "-", true) == ["abc","","def","ghi"]);
    assert(str_split("abc--def-ghi", "-", false) == ["abc","def","ghi"]);
    assert(str_split("abc-+def-ghi", "-+", true) == ["abc","","def","ghi"]);
    assert(str_split("abc-+def-ghi", "-+", false) == ["abc","def","ghi"]);
}
test_str_split();


module test_str_strip() {
    assert(str_strip("abcdef", " ") == "abcdef");
    assert(str_strip(" abcdef", " ") == "abcdef");
    assert(str_strip("  abcdef", " ") == "abcdef");
    assert(str_strip("abcdef ", " ") == "abcdef");
    assert(str_strip("abcdef  ", " ") == "abcdef");
    assert(str_strip(" abcdef  ", " ") == "abcdef");
    assert(str_strip("  abcdef  ", " ") == "abcdef");
    assert(str_strip("abcdef", " ",start=true) == "abcdef");
    assert(str_strip(" abcdef", " ",start=true) == "abcdef");
    assert(str_strip("  abcdef", " ",start=true) == "abcdef");
    assert(str_strip("abcdef ", " ",start=true) == "abcdef ");
    assert(str_strip("abcdef  ", " ",start=true) == "abcdef  ");
    assert(str_strip(" abcdef  ", " ",start=true) == "abcdef  ");
    assert(str_strip("  abcdef  ", " ",start=true) == "abcdef  ");
    assert(str_strip("abcdef", " ",end=true) == "abcdef");
    assert(str_strip(" abcdef", " ",end=true) == " abcdef");
    assert(str_strip("  abcdef", " ",end=true) == "  abcdef");
    assert(str_strip("abcdef ", " ",end=true) == "abcdef");
    assert(str_strip("abcdef  ", " ",end=true) == "abcdef");
    assert(str_strip(" abcdef  ", " ",end=true) == " abcdef");
    assert(str_strip("  abcdef  ", " ",end=true) == "  abcdef");
    assert(str_strip("123abc321","12") == "3abc3");
    assert(str_strip("123abc321","12",start=true,end=true) == "3abc3");
    assert(str_strip("123abc321","12",start=true,end=false) == "3abc321");    
    assert(str_strip("123abc321","12",start=false,end=false) == "123abc321");    
    assert(str_strip("123abc321","12",start=false,end=true) == "123abc3");    
    assert(str_strip("123abc321","12",start=false) == "123abc3");    
    assert(str_strip("123abc321","12",start=true) == "3abc321");    
    assert(str_strip("123abc321","12",end=false) == "3abc321");
    assert(str_strip("123abc321","12",end=true) == "123abc3");
    assert(str_strip("abcde","abcde")=="");
    assert(str_strip("","abc")=="");
}
test_str_strip();


module test_substr() {
    assert(substr("abcdefg",3,3) == "def");
    assert(substr("abcdefg",2) == "cdefg");
    assert(substr("abcdefg",len=3) == "abc");
    assert(substr("abcdefg",[2,4]) == "cde");
    assert(substr("abcdefg",len=-2) == "");
}
test_substr();


module test_suffix() {
    assert(suffix("abcdefghi",0) == "");
    assert(suffix("abcdefghi",1) == "i");
    assert(suffix("abcdefghi",2) == "hi");
    assert(suffix("abcdefghi",3) == "ghi");
    assert(suffix("abcdefghi",6) == "defghi");
    assert(suffix("abc",4) == "abc");
}
test_suffix();


module test_str_find() {
    assert(str_find("abc123def123abc","123") == 3);
    assert(str_find("abc123def123abc","b") == 1);
    assert(str_find("abc123def123abc","1234") == undef);
    assert(str_find("abc","") == 0);
    assert(str_find("abc123def123", "123", start=4) == 9);
    assert(str_find("abc123def123abc","123",last=true) == 9);
    assert(str_find("abc123def123abc","b",last=true) == 13);
    assert(str_find("abc123def123abc","1234",last=true) == undef);
    assert(str_find("abc","",last=true) == 3);
    assert(str_find("abc123def123", "123", start=8, last=true) == 3);
    assert(str_find("abc123def123abc","123",all=true) == [3,9]);
    assert(str_find("abc123def123abc","b",all=true) == [1,13]);
    assert(str_find("abc123def123abc","1234",all=true) == []);
    assert(str_find("abc","",all=true) == [0,1,2]);
}
test_str_find();


module test_format() {
    assert(format("The value of {} is {:.14f}.", ["pi", PI]) == "The value of pi is 3.14159265358979.");
    assert(format("The value {1:f} is known as {0}.", ["pi", PI]) == "The value 3.141593 is known as pi.");
    assert(format("We use a very small value {1:.6g} as {0}.", ["EPSILON", EPSILON]) == "We use a very small value 1e-9 as EPSILON.");
    assert(format("{:-5s}{:i}{:b}", ["foo", 12e3, 5]) == "foo  12000true");
    assert(format("{:-10s}{:.3f}", ["plecostamus",27.43982]) == "plecostamus27.440");
    assert(format("{:-10.9s}{:.3f}", ["plecostamus",27.43982]) == "plecostam 27.440");
}
test_format();


/*
module test_echofmt() {
}
test_echofmt();
*/


module test_str_pad() {
   assert_equal(str_pad("abc",5,"x"), "abcxx");
   assert_equal(str_pad("abc",5), "abc  ");
   assert_equal(str_pad("abc",5,"x",left=true), "xxabc");
   assert_equal(str_pad("", 5, "x"), "xxxxx");
   assert_equal(str_pad("", 5, "x", left=true), "xxxxx");
}   
test_str_pad();

module test_str_replace_char() {
   assert_equal(str_replace_char("abcabc", "b", "xyz"), "axyzcaxyzc");
   assert_equal(str_replace_char("abcabc", "b", ""), "acac");
   assert_equal(str_replace_char("", "b", "xyz"), "");
   assert_equal(str_replace_char("acdacd", "b", "xyz"), "acdacd");   
}
test_str_replace_char();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
