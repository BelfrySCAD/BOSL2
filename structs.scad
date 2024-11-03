//////////////////////////////////////////////////////////////////////
// LibFile: structs.scad
//   This file provides manipulation of "structs".  A "struct" is a data structure that
//   associates arbitrary keys with values and allows you to get and set values
//   by key.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Data Management
// FileSummary: Structure/Dictionary Manipulation
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: struct operations
//
// A struct is a data structure that associates arbitrary keys (of any type) with values (of any type).
// Structures are implemented as lists of [key, value] pairs.
//
// An empty list `[]` is an empty structure and can be used wherever a structure input is required.

// Function: struct_set()
// Synopsis: Sets one or more key-value pairs in a struct.
// Topics: Data Structures, Dictionaries
// See Also: struct_set(), struct_remove(), struct_val(), struct_keys(), echo_struct(), is_struct()
// Usage:
//   struct2 = struct_set(struct, key, value, [grow=]);
//   struct2 = struct_set(struct, [key1, value1, key2, value2, ...], [grow=]);
// Description:
//   Sets the key(s) in the structure to the specified value(s), returning a new updated structure.  If a
//   key exists its value is changed, otherwise the key is added to the structure.  If `grow=false` then
//   it is an error to set a key not already defined in the structure.  If you specify the same key twice
//   that is also an error.  Note that key order will change when you change a key's value.
// Arguments:
//   struct = input structure.
//   key = key to set or list of key,value pairs to set
//   value = value to set the key to (when giving a single key and value)
//   ---
//   grow = Set to true to allow structure to grow, or false for new keys to generate an error.  Default: true
// Example: Create a struct containing just one key-value pair
//   some_struct = struct_set([], "answer", 42);
//   // 'some_struct' now contains a single value, 42, under one key, "answer".
// Example: Create a struct containing more than one key-value pair. Note that keys and values need not be the same type.
//   some_struct = struct_set([], ["answer", 42, 2, "two", "quote", "What a nice day"]);
//   // 'some struct' now contains these key-value pairs:
//   // answer: 42
//   // 2: two
//   // quote: What a nice day
function struct_set(struct, key, value, grow=true) =
  is_def(value) ? struct_set(struct,[key,value],grow=grow)
  :
  assert(is_list(key) && len(key)%2==0, "[key,value] pair list is not a list or has an odd length")
  let(
      new_entries = [for(i=[0:1:len(key)/2-1]) [key[2*i], key[2*i+1]]],
      newkeys = column(new_entries,0),
      indlist = search(newkeys, struct,0,0),
      badkeys = grow ? (search([undef],new_entries,1,0)[0] != [] ? [undef] : [])
                     : [for(i=idx(indlist)) if (is_undef(newkeys[i]) || len(indlist[i])==0) newkeys[i]],
      ind = flatten(indlist),
      dupfind = search(newkeys, new_entries,0,0),
      dupkeys = [for(i=idx(dupfind)) if (len(dupfind[i])>1) newkeys[i]]
  )
  assert(badkeys==[], str("Unknown or bad key ",_format_key(badkeys[0])," in struct_set"))
  assert(dupkeys==[], str("Duplicate key ",_format_key(dupkeys[0])," for struct"))
  concat(list_remove(struct,ind), new_entries);

function _format_key(key) = is_string(key) ? str("\"",key,"\""): key;

// Function: struct_remove()
// Synopsis: Removes one or more keys from a struct.
// Topics: Data Structures, Dictionaries
// See Also: struct_set(), struct_remove(), struct_val(), struct_keys(), echo_struct(), is_struct()
// Usage:
//   struct2 = struct_remove(struct, key);
// Description:
//   Remove key or list of keys from a structure.  If you want to remove a single key which is a list
//   you must pass it as a singleton list, or struct_remove will attempt to remove the listed items as keys.
//   If you list the same item multiple times for removal it will be removed without error.
// Arguments:
//   struct = input structure
//   key = a single key or list of keys to remove.
function struct_remove(struct, key) =
   !is_list(key) ? struct_remove(struct, [key]) :
    let(ind = search(key, struct))
    list_remove(struct, [for(i=ind) if (i!=[]) i]);


// Function: struct_val()
// Synopsis: Returns the value for an key in a struct.
// Topics: Data Structures, Dictionaries
// See Also: struct_set(), struct_remove(), struct_val(), struct_keys(), echo_struct(), is_struct()
// Usage:
//   val = struct_val(struct, key, default);
// Description:
//   Returns the value for the specified key in the structure, or default value if the key is not present
// Arguments:
//   struct = input structure
//   key = key whose value to return
//   default = default value to return if key is not present.  Default: undef
function struct_val(struct, key, default=undef) =
    assert(is_def(key),"key is missing")
    let(ind = search([key],struct)[0])
    ind == [] ? default : struct[ind][1];


// Function: struct_keys()
// Synopsis: Returns a list of keys for a struct.
// Topics: Data Structures, Dictionaries
// See Also: struct_set(), struct_remove(), struct_val(), struct_keys(), echo_struct(), is_struct()
// Usage:
//   keys = struct_keys(struct);
// Description:
//   Returns a list of the keys in a structure
// Arguments:
//   struct = input structure
function struct_keys(struct) = column(struct,0);


// Function&Module: echo_struct()
// Synopsis: Echoes the struct to the console in a formatted manner.
// Topics: Data Structures, Dictionaries
// See Also: struct_set(), struct_remove(), struct_val(), struct_keys(), echo_struct(), is_struct()
// Usage:
//   echo_struct(struct, [name]);
//   foo = echo_struct(struct, [name]);
// Description:
//   Displays a list of structure keys and values, one pair per line, for easier reading.
// Arguments:
//   struct = input structure
//   name = optional structure name to list at the top of the output.  Default: ""
function echo_struct(struct,name="") =
    let( keylist = [for(entry=struct) str("  ",entry[0],": ",entry[1],"\n")])
    echo(str("\nStructure ",name,"\n",str_join(keylist)))
    undef;

module echo_struct(struct,name="") {
    no_children($children);
    dummy = echo_struct(struct,name);
}


// Function: is_struct()
// Synopsis: Returns true if the value is a struct.
// Topics: Data Structures, Dictionaries
// See Also: struct_set(), struct_remove(), struct_val(), struct_keys(), echo_struct(), is_struct()
// Usage:
//   bool = is_struct(struct);
// Description:
//   Returns true if the input is a list of pairs, false otherwise.
function is_struct(x) =
    is_list(x) && [for (xx=x) if(!(is_list(xx) && len(xx)==2)) 1] == [];


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
