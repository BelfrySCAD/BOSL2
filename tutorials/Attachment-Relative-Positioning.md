[Prev: Basic Positioning](Tutorial-Attachment-Basic-Positioning)

# Relative Positioning: Placing Children using position(), align(), and attach()

Relative positioning is one of the most useful and powerful features
in the BOSL2 library.  In BOSL2 you can make an object a child of
another object.  When you do this, the child object is positioned
relative to its parent.  The simplest result is that the child appears
so that its anchor point coincides with the center of the parent.

Three modules enable you to position the child relative to the parent
in more useful ways:

* position() places the child so its anchor point is positioned at a chosen anchor point on the parent. 
* align() can place the child on a face **without changing its orientation** so that the child is aligned with one of the edges or corners of that face
* attach() can places the child on a face like stacking blocks, so that the a designated face of the child mates with the chosen face on the parent.  It also has support for alignment to the edges and corners of the face.

Relative positioning means that since objects are positioned relative
to other objects, you do not need to keep track of absolute positions
and orientations of objects in your model.  This makes models simpler,
more intuitive, and easier to maintain.

[Next: Using position()](Tutorial-Attachment-Position)
