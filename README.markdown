### KaptureCache

Kapture cache is a multi-level http cache.  It relies on a simple (memory
based) cache stood up by a core data persistance layer.  It includes
collision detection, if you make multiple requests to the same url in a
short timeline it will pause until the inital request completes.


At the moment KaptureCache does not ever delete any data.  This should
be fixed shortly via an additional ttl argument.

Having trouble?  Email me.
