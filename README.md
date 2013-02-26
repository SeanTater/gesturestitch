gesturestitch
=============

Gesture-Initiated Image Stitcher


Overview
--------
- Runs in a web browser
- Must be on a server (not local) in order to run correctly on Chrome (cross site origin rules)
- Requires LeapMotion API + controller
- Attempts to stitch together two images when requested by user via gestures

Setup
-----
Just take a look at the [development preview](http://seantater.is-a-linux-user.org/gesturestitch)

Design Presentation
-------------------
You can find the public design presentation here:
http://goo.gl/gxRUF

Code Conventions
----------------
- @_ = private
- @u = unwrapped (DOM element)

Manifest
--------
- ImageDisplay
 - Loads image list
 - Creates Image's
 - Arranges them in a wrapper
- Image
 - Calls for image loading
 - Creates Canvas's
 - Has the image DOM element
- Canvas
 - Creates a 2d canvas for pixel manipulation
 - Provides convenient access to pixel data

