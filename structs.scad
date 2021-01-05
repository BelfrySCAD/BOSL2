//////////////////////////////////////////////////////////////////////
// LibFile: structs.scad
//   Struct/Dictionary manipulation functions.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/structs.scad>
//////////////////////////////////////////////////////////////////////


// Section: struct operations
//
// A struct is a data structure that associates arbitrary keywords (of any type) with values (of any type).
// Structures are implemented as lists of [keyword, value] pairs.
//
// An empty list `[]` is an empty structure and can be used wherever a structure input is required.

// Function: struct_set()
// Usage:
//   struct_set(struct, keyword, value, [grow])
//   struct_set(struct, [keyword1, value1, keyword2, value2, ...], [grow])
// Description:
//   Sets the keyword(s) in the structure to the specified value(s), returning a new updated structure.  If a keyword
//   exists its value is changed, otherwise the keyword is added to the structure.  If grow is set to false then
//   it is an error to set a keyword not already defined in the structure.  If you specify the same keyword twice
//   that is also an error.  If speed matters, use the first form with scalars rather than the list form: this is
//   about thirty times faster.
// Arguments:
//   struct = Input structure.
//   keyword = Keyword to set.
//   value = Value to set the keyword to.
//   grow = Set to true to allow structure to grow, or false for new keywords to generate an error.  Default: true
function struct_set(struct, keyword, value=undef, grow=true) =
    !is_list(keyword)? (
        let( ind=search([keyword],struct,1,0)[0] )
        ind==[]? (
            assert(grow,str("Unknown keyword \"",keyword))
            concat(struct, [[keyword,value]])
        ) : list_set(struct, [ind], [[keyword,value]])
    ) : _parse_pairs(struct,keyword,grow);


function _parse_pairs(spec, input, grow=true, index=0, result=undef) =
    assert(len(input)%2==0,"Odd number of entries in [keyword,value] pair list")
    let( result = result==undef ? spec : result)
    index == len(input) ? result :
    _parse_pairs(spec,input,grow,index+2,struct_set(result, input[index], input[index+1],grow));


// Function: struct_remove()
// Usage:
//   struct_remove(struct, keyword)
// Description:
//   Remove keyword or keyword list from a structure
// Arguments:
//   struct = input structure
//   keyword = a single string (keyword) or list of strings (keywords) to remove
function struct_remove(struct, keyword) =
    is_string(keyword)? struct_remove(struct, [keyword]) :
    let(ind = search(keyword, struct))
    list_remove(struct, ind);


// Function: struct_val()
// Usage:
//   struct_val(struct, keyword, default)
// Description:
//   Returns the value for the specified keyword in the structure, or default value if the keyword is not present
// Arguments:
//   struct = input structure
//   keyword = keyword whose value to return
//   default = default value to return if keyword is not present, defaults to undef
function struct_val(struct, keyword, default=undef) =
    assert(is_def(keyword),"keyword is missing")
    let(ind = search([keyword],struct)[0])
    ind == [] ? default : struct[ind][1];


// Function: struct_keys()
// Usage:
//   keys = struct_keys(struct)
// Description:
//   Returns a list of the keys in a structure
// Arguments:
//   struct = input structure
function struct_keys(struct) =
    [for(entry=struct) entry[0]];


// Function&Module: struct_echo()
// Usage:
//   struct_echo(struct, [name])
// Description:
//   Displays a list of structure keywords and values, one pair per line, for easier reading.
// Arguments:
//   struct = input structure
//   name = optional structure name to list at the top of the output.  Default: ""
function struct_echo(struct,name="") =
    let( keylist = [for(entry=struct) str("  ",entry[0],": ",entry[1],"\n")])
    echo(str("\nStructure ",name,"\n",str_join(keylist)))
    undef;

module struct_echo(struct,name="") {
    no_children($children);
    dummy = struct_echo(struct,name);
}


// Function: is_struct()
// Usage:
//   is_struct(struct)
// Description:
//   Returns true if the input has the form of a structure, false otherwise.
function is_struct(x) =
    is_list(x) && [
        for (xx=x) if(
            !is_list(xx) ||
            len(xx) != 2 ||
            !is_string(xx[0])
        ) 1
    ] == [];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
