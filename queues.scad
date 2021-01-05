//////////////////////////////////////////////////////////////////////
// LibFile: queues.scad
//   Queue data structure implementation.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/queues.scad>
//////////////////////////////////////////////////////////////////////


// Section: Queue Data Structure
//   A queue is a first-in-first-out collection of items.  You can add items onto the tail of the
//   queue, or pop items off the head.  While you can treat a queue as an opaque data type, using the
//   functions below, it's simply implemented as a list.  This means that you can use any list
//   function to manipulate the queue.  The first item in the list is the head queue item.


// Function: queue_init()
// Usage:
//   queue = queue_init();
// Description:
//   Creates an empty queue/list.
// Example:
//   queue = queue_init();  // Return: []
function queue_init() = [];


// Function: queue_empty()
// Usage:
//   if (queue_empty(queue)) ...
// Description:
//   Returns true if the given queue is empty.
// Arguments:
//   queue = The queue to test if empty.
// Example:
//   queue = queue_init();
//   is_empty = queue_empty(queue);  // Returns: true
//   queue2 = queue_add(queue, "foo");
//   is_empty2 = queue_empty(queue2);  // Returns: false
function queue_empty(queue) =
    assert(is_list(queue))
    len(queue)==0;


// Function: queue_size()
// Usage:
//   depth = queue_size(queue);
// Description:
//   Returns the number of items in the given queue.
// Arguments:
//   queue = The queue to get the size of.
// Example:
//   queue = queue_init();
//   depth = queue_size(queue);  // Returns: 0
//   queue2 = queue_add(queue, "foo");
//   depth2 = queue_size(queue2);  // Returns: 1
//   queue3 = queue_add(queue2, ["bar","baz","qux"]);
//   depth3 = queue_size(queue3);  // Returns: 4
function queue_size(queue) =
    assert(is_list(queue))
    len(queue);


// Function: queue_head()
// Usage:
//   item = queue_head(queue);
//   list = queue_head(queue,n);
// Description:
//   If `n` is not given, returns the first item from the head of the queue.
//   If `n` is given, returns a list of the first `n` items from the head of the queue.
// Arguments:
//   queue = The queue/list to get item(s) from the head of.
// Example:
//   queue = [4,5,6,7,8,9];
//   item = queue_head(queue);  // Returns: 4
//   list = queue_head(queue,n=3);  // Returns: [4,5,6]
function queue_head(queue,n=undef) =
    assert(is_list(queue))
    is_undef(n)? (
        queue[0]
    ) : (
        let(queuesize = len(queue))
        assert(is_num(n))
        assert(n>=0)
        assert(queuesize>=n, "queue underflow")
        [for (i=[0:1:n-1]) queue[i]]
    );


// Function: queue_tail()
// Usage:
//   item = queue_tail(queue);
//   list = queue_tail(queue,n);
// Description:
//   If `n` is not given, returns the last item from the tail of the queue.
//   If `n` is given, returns a list of the last `n` items from the tail of the queue.
// Arguments:
//   queue = The queue/list to get item(s) from the tail of.
// Example:
//   queue = [4,5,6,7,8,9];
//   item = queue_tail(queue);  // Returns: 9
//   list = queue_tail(queue,n=3);  // Returns: [7,8,9]
function queue_tail(queue,n=undef) =
    assert(is_list(queue))
    let(queuesize = len(queue))
    is_undef(n)? (
        queue[queuesize-1]
    ) : (
        assert(is_num(n))
        assert(n>=0)
        assert(queuesize>=n, "queue underflow")
        [for (i=[0:1:n-1]) queue[queuesize-n+i]]
    );


// Function: queue_peek()
// Usage:
//   item = queue_peek(queue,[pos]);
//   list = queue_peek(queue,pos,n);
// Description:
//   If `n` is not given, returns the queue item at position `pos`.
//   If `n` is given, returns a list of the `n` queue items at and after position `pos`.
// Arguments:
//   queue = The queue to read from.
//   pos = The position of the queue item to read.  Default: 0
//   n = The number of queue items to return.  Default: undef (Return only the queue item at `pos`)
// Example:
//   queue = [2,3,4,5,6,7,8,9];
//   item = queue_peek(queue);  // Returns: 2
//   item2 = queue_peek(queue, 3);  // Returns: 5
//   list = queue_peek(queue, 4, 3);  // Returns: [6,7,8]
function queue_peek(queue,pos=0,n=undef) =
    assert(is_list(queue))
    assert(is_num(pos))
    assert(pos>=0)
    let(queuesize = len(queue))
    assert(queuesize>=pos, "queue underflow")
    is_undef(n)? (
        queue[pos]
    ) : (
        assert(is_num(n))
        assert(n>=0)
        assert(n<queuesize-pos)
        [for (i=[0:1:n-1]) queue[pos+i]]
    );


// Function: queue_add()
// Usage:
//   modified_queue = queue_add(queue,items);
// Description:
//   Adds the given `items` onto the queue `queue`.  Returns the modified queue.
// Arguments:
//   queue = The queue to modify.
//   items = A value or list of values to add to the queue.
// Example:
//   queue = [4,9,2,3];
//   queue2 = queue_add(queue,7);  // Returns: [4,9,2,3,7]
//   queue3 = queue_add(queue2,[6,1]);  // Returns: [4,9,2,3,7,6,1]
//   queue4 = queue_add(queue,[[5,8]]);  // Returns: [4,9,2,3,[5,8]]
//   queue5 = queue_add(queue,[[5,8],6,7]);  // Returns: [4,9,2,3,[5,8],6,7]
// Example: Typical Producer and Consumer
//   q2 = queue_add(q, "foo");
//   ...
//   val = queue_head(q2);
//   q3 = queue_pop(q2);
function queue_add(queue,items) =
    assert(is_list(queue))
    is_list(items)? concat(queue, items) : concat(queue, [items]);


// Function: queue_pop()
// Usage:
//   modified_queue = queue_pop(queue, [n]);
// Description:
//   Removes `n` items from the head of the queue.  Returns the modified queue.
// Arguments:
//   queue = The queue to modify.
//   n = The number of items to remove from the head of the queue.  Default: 1
// Example:
//   queue = [4,5,6,7,8,9];
//   queue2 = queue_pop(queue);  // Returns: [5,6,7,8,9]
//   queue3 = queue_pop(queue2,n=3);  // Returns: [8,9]
// Example: Typical Producer and Consumer
//   q2 = queue_add(q, "foo");
//   ...
//   val = queue_head(q2);
//   q3 = queue_pop(q2);
function queue_pop(queue,n=1) =
    assert(is_list(queue))
    assert(is_num(n))
    assert(n>=0)
    let(queuesize = len(queue))
    assert(queuesize>=n, "queue underflow")
    [for (i = [n:1:queuesize-1]) queue[i]];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
