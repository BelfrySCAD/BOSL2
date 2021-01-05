//////////////////////////////////////////////////////////////////////
// LibFile: stacks.scad
//   Stack data structure implementation.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/stacks.scad>
//////////////////////////////////////////////////////////////////////


// Section: Stack Data Structure
//   A stack is a last-in-first-out collection of items.  You can push items onto the top of the
//   stack, or pop the top item off.  While you can treat a stack as an opaque data type, using the
//   functions below, it's simply implemented as a list.  This means that you can use any list
//   function to manipulate the stack.  The last item in the list is the topmost stack item.
//   The depth of an item is how far buried in the stack that item is.  An item at depth 1 is the
//   top-most stack item.  An item at depth 3 is two items below the top-most stack item.


// Function: stack_init()
// Usage:
//   stack = stack_init();
// Description:
//   Creates an empty stack/list.
// Example:
//   stack = stack_init();  // Return: []
function stack_init() = [];


// Function: stack_empty()
// Usage:
//   if (stack_empty(stack)) ...
// Description:
//   Returns true if the given stack is empty.
// Arguments:
//   stack = The stack to test if empty.
// Example:
//   stack = stack_init();
//   is_empty = stack_empty(stack);  // Returns: true
//   stack2 = stack_push(stack, "foo");
//   is_empty2 = stack_empty(stack2);  // Returns: false
function stack_empty(stack) =
    assert(is_list(stack))
    len(stack)==0;


// Function: stack_depth()
// Usage:
//   depth = stack_depth(stack);
// Description:
//   Returns the depth of the given stack.
// Arguments:
//   stack = The stack to get the depth of.
// Example:
//   stack = stack_init();
//   depth = stack_depth(stack);  // Returns: 0
//   stack2 = stack_push(stack, "foo");
//   depth2 = stack_depth(stack2);  // Returns: 1
//   stack3 = stack_push(stack2, ["bar","baz","qux"]);
//   depth3 = stack_depth(stack3);  // Returns: 4
function stack_depth(stack) =
    assert(is_list(stack))
    len(stack);


// Function: stack_top()
// Usage:
//   item = stack_top(stack);
//   list = stack_top(stack,n);
// Description:
//   If n is not given, returns the topmost item of the given stack.
//   If n is given, returns a list of the `n` topmost items.
// Arguments:
//   stack = The stack/list to get the top item(s) of.
// Example:
//   stack = [4,5,6,7];
//   item = stack_top(stack);  // Returns: 7
//   list = stack_top(stack,n=3);  // Returns: [5,6,7]
function stack_top(stack,n=undef) =
    assert(is_list(stack))
    is_undef(n)? (
        stack[len(stack)-1]
    ) : (
        let(stacksize = len(stack))
        assert(is_num(n))
        assert(n>=0)
        assert(stacksize>=n, "stack underflow")
        [for (i=[0:1:n-1]) stack[stacksize-n+i]]
    );


// Function: stack_peek()
// Usage:
//   item = stack_peek(stack,[depth]);
//   list = stack_peek(stack,depth,n);
// Description:
//   If `n` is not given, returns the stack item at depth `depth`.
//   If `n` is given, returns a list of the `n` stack items at and above depth `depth`.
// Arguments:
//   stack = The stack to read from.
//   depth = The depth of the stack item to read.  Default: 0
//   n = The number of stack items to return.  Default: undef (Return only the stack item at `depth`)
// Example:
//   stack = [2,3,4,5,6,7,8,9];
//   item = stack_peek(stack);  // Returns: 9
//   item2 = stack_peek(stack, 3);  // Returns: 7
//   list = stack_peek(stack, 6, 4);  // Returns: [4,5,6,7]
function stack_peek(stack,depth=0,n=undef) =
    assert(is_list(stack))
    assert(is_num(depth))
    assert(depth>=0)
    let(stacksize = len(stack))
    assert(stacksize>=depth, "stack underflow")
    is_undef(n)? (
        stack[stacksize-depth-1]
    ) : (
        assert(is_num(n))
        assert(n>=0)
        assert(n<=depth+1)
        [for (i=[0:1:n-1]) stack[stacksize-1-depth+i]]
    );


// Function: stack_push()
// Usage:
//   modified_stack = stack_push(stack,items);
// Description:
//   Pushes the given `items` onto the stack `stack`.  Returns the modified stack.
// Arguments:
//   stack = The stack to modify.
//   items = A value or list of values to push onto the stack.
// Example:
//   stack = [4,9,2,3];
//   stack2 = stack_push(stack,7);  // Returns: [4,9,2,3,7]
//   stack3 = stack_push(stack2,[6,1]);  // Returns: [4,9,2,3,7,6,1]
//   stack4 = stack_push(stack,[[5,8]]);  // Returns: [4,9,2,3,[5,8]]
//   stack5 = stack_push(stack,[[5,8],6,7]);  // Returns: [4,9,2,3,[5,8],6,7]
function stack_push(stack,items) =
    assert(is_list(stack))
    is_list(items)? concat(stack, items) : concat(stack, [items]);


// Function: stack_pop()
// Usage:
//   modified_stack = stack_pop(stack, [n]);
// Description:
//   Removes the `n` topmost items from the stack.  Returns the modified stack.
// Arguments:
//   stack = The stack to modify.
//   n = The number of items to remove off the top of the stack.  Default: 1
// Example:
//   stack = [4,5,6,7,8,9];
//   stack2 = stack_pop(stack);  // Returns: [4,5,6,7,8]
//   stack3 = stack_pop(stack2,n=3);  // Returns: [4,5]
function stack_pop(stack,n=1) =
    assert(is_list(stack))
    assert(is_num(n))
    assert(n>=0)
    assert(len(stack)>=n, "stack underflow")
    [for (i = [0:1:len(stack)-1-n]) stack[i]];


// Function: stack_rotate()
// Usage:
//   modified_stack = stack_rotate(stack, [n]);
// Description:
//   Rotates the top `abs(n)` stack items, and returns the modified stack.
//   If `n` is positive, then the depth `n` stack item is rotated (left) to the top.
//   If `n` is negative, then the top stack item is rotated (right) to depth `abs(n)`.
// Arguments:
//   stack = The stack to modify.
//   n = The number of stack items to rotate.  If negative, reverse rotation direction.  Default: 3
// Example:
//   stack = [4,5,6,7,8];
//   stack2 = stack_rotate(stack,3);  // Returns: [4,5,7,8,6]
//   stack3 = stack_rotate(stack2,-4);  // Returns: [4,6,5,7,8]
function stack_rotate(stack,n=3) =
    assert(is_list(stack))
    let(stacksize = len(stack))
    assert(stacksize>=n, "stack underflow")
    n>=0? concat(
        [for (i=[0:1:stacksize-1-n]) stack[i]],
        [for (i=[0:1:n-2]) stack[stacksize-n+i+1]],
        [stack[stacksize-n]]
    ) : concat(
        [for (i=[0:1:stacksize-1+n]) stack[i]],
        [stack[stacksize-1]],
        [for (i=[0:1:-n-2]) stack[stacksize+n+i]]
    );


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
