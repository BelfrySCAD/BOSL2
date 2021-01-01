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


module test_escape_html() {
    assert(escape_html("ABCDEFGHIJKLMNOPQRSTUVWXYZ") == "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    assert(escape_html("abcdefghijklmnopqrstuvwxyz") == "abcdefghijklmnopqrstuvwxyz");
    assert(escape_html("1234567890!@#$%^&*()-=_+") == "1234567890!@#$%^&amp;*()-=_+");
    assert(escape_html("[]\\{}|;':\",./<>?`~") == "[]\\{}|;':&quot;,./&lt;&gt;?`~");
}
test_escape_html();


module test_fmt_int() {
    assert(fmt_int(0,6) == "000000");
    assert(fmt_int(3,6) == "000003");
    assert(fmt_int(98765,6) == "098765");
    assert(fmt_int(-3,6) == "-000003");
    assert(fmt_int(-98765,6) == "-098765");
}
test_fmt_int();


module test_fmt_fixed() {
    assert(fmt_fixed(-PI*100,8) == "-314.15926536");
    assert(fmt_fixed(-PI,8) == "-3.14159265");
    assert(fmt_fixed(-3,8) == "-3.00000000");
    assert(fmt_fixed(3,8) == "3.00000000");
    assert(fmt_fixed(PI*100,8) == "314.15926536");
    assert(fmt_fixed(PI,8) == "3.14159265");
    assert(fmt_fixed(0,8) == "0.00000000");
    assert(fmt_fixed(-PI*100,3) == "-314.159");
    assert(fmt_fixed(-PI,3) == "-3.142");
    assert(fmt_fixed(-3,3) == "-3.000");
    assert(fmt_fixed(3,3) == "3.000");
    assert(fmt_fixed(PI*100,3) == "314.159");
    assert(fmt_fixed(PI,3) == "3.142");
}
test_fmt_fixed();


module test_fmt_float() {
    assert(fmt_float(-PI*100,8) == "-314.15927");
    assert(fmt_float(-PI,8) == "-3.1415927");
    assert(fmt_float(-3,8) == "-3");
    assert(fmt_float(3,8) == "3");
    assert(fmt_float(PI*100,8) == "314.15927");
    assert(fmt_float(PI,8) == "3.1415927");
    assert(fmt_float(0,8) == "0");
    assert(fmt_float(-PI*100,3) == "-314");
    assert(fmt_float(-PI,3) == "-3.14");
    assert(fmt_float(-3,3) == "-3");
    assert(fmt_float(3,3) == "3");
    assert(fmt_float(PI*100,3) == "314");
    assert(fmt_float(PI,3) == "3.14");
}
test_fmt_float();


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


module test_str_float() {
    assert(str_float("3.1416") == 3.1416);
    assert(str_float("-3.1416") == -3.1416);
    assert(str_float("3.000") == 3.0);
    assert(str_float("-3.000") == -3.0);
    assert(str_float("3") == 3.0);
    assert(str_float("0") == 0.0);
}
test_str_float();


module test_str_frac() {
    assert(str_frac("") == 0);
    assert(str_frac("1/2") == 1/2);
    assert(str_frac("+1/2") == 1/2);
    assert(str_frac("-1/2") == -1/2);
    assert(str_frac("7/8") == 7/8);
    assert(str_frac("+7/8") == 7/8);
    assert(str_frac("-7/8") == -7/8);
    assert(str_frac("1 1/2") == 1 + 1/2);
    assert(str_frac("+1 1/2") == 1 + 1/2);
    assert(str_frac("-1 1/2") == -(1 + 1/2));
    assert(str_frac("768 3/4") == 768 + 3/4);
    assert(str_frac("+768 3/4") == 768 + 3/4);
    assert(str_frac("-768 3/4") == -(768 + 3/4));
    assert(str_frac("19") == 19);
    assert(str_frac("+19") == 19);
    assert(str_frac("-19") == -19);
    assert(str_frac("3/0") == INF);
    assert(str_frac("-3/0") == -INF);
    assert(is_nan(str_frac("0/0")));
}
test_str_frac();


module test_str_num() {
    assert(str_num("") == 0);
    assert(str_num("1/2") == 1/2);
    assert(str_num("+1/2") == 1/2);
    assert(str_num("-1/2") == -1/2);
    assert(str_num("7/8") == 7/8);
    assert(str_num("+7/8") == 7/8);
    assert(str_num("-7/8") == -7/8);
    assert(str_num("1 1/2") == 1 + 1/2);
    assert(str_num("+1 1/2") == 1 + 1/2);
    assert(str_num("-1 1/2") == -(1 + 1/2));
    assert(str_num("768 3/4") == 768 + 3/4);
    assert(str_num("+768 3/4") == 768 + 3/4);
    assert(str_num("-768 3/4") == -(768 + 3/4));
    assert(str_num("19") == 19);
    assert(str_num("+19") == 19);
    assert(str_num("-19") == -19);
    assert(str_num("3/0") == INF);
    assert(str_num("-3/0") == -INF);
    assert(str_num("3.14159") == 3.14159);
    assert(str_num("-3.14159") == -3.14159);
    assert(is_nan(str_num("0/0")));
}
test_str_num();


module test_str_int() {
    assert(str_int("0") == 0);
    assert(str_int("3") == 3);
    assert(str_int("7655") == 7655);
    assert(str_int("+3") == 3);
    assert(str_int("+7655") == 7655);
    assert(str_int("-3") == -3);
    assert(str_int("-7655") == -7655);
    assert(str_int("ffff",16) == 65535);
}
test_str_int();


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
}
test_str_strip();


module test_str_strip_leading() {
    assert(str_strip_leading("abcdef", " ") == "abcdef");
    assert(str_strip_leading(" abcdef", " ") == "abcdef");
    assert(str_strip_leading("  abcdef", " ") == "abcdef");
    assert(str_strip_leading("abcdef ", " ") == "abcdef ");
    assert(str_strip_leading("abcdef  ", " ") == "abcdef  ");
    assert(str_strip_leading(" abcdef  ", " ") == "abcdef  ");
    assert(str_strip_leading("  abcdef  ", " ") == "abcdef  ");
}
test_str_strip_leading();


module test_str_strip_trailing() {
    assert(str_strip_trailing("abcdef", " ") == "abcdef");
    assert(str_strip_trailing(" abcdef", " ") == " abcdef");
    assert(str_strip_trailing("  abcdef", " ") == "  abcdef");
    assert(str_strip_trailing("abcdef ", " ") == "abcdef");
    assert(str_strip_trailing("abcdef  ", " ") == "abcdef");
    assert(str_strip_trailing(" abcdef  ", " ") == " abcdef");
    assert(str_strip_trailing("  abcdef  ", " ") == "  abcdef");
}
test_str_strip_trailing();


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


module test_str_format() {
    assert(str_format("The value of {} is {:.14f}.", ["pi", PI]) == "The value of pi is 3.14159265358979.");
    assert(str_format("The value {1:f} is known as {0}.", ["pi", PI]) == "The value 3.141593 is known as pi.");
    assert(str_format("We use a very small value {1:.6g} as {0}.", ["EPSILON", EPSILON]) == "We use a very small value 1e-9 as EPSILON.");
    assert(str_format("{:-5s}{:i}{:b}", ["foo", 12e3, 5]) == "foo  12000true");
    assert(str_format("{:-10s}{:.3f}", ["plecostamus",27.43982]) == "plecostamus27.440");
    assert(str_format("{:-10.9s}{:.3f}", ["plecostamus",27.43982]) == "plecostam 27.440");
}
test_str_format();


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
