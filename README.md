gesturestitch
=============

Gesture-Initiated Image Stitcher


Overview
--------
- Runs in a web browser
- Must be on a server (not local) in order to run correctly on Chrome (cross site origin rules)
- Gesture features require LeapMotion API + controller

Setup
-----
Just take a look at the [development preview](http://seantater.is-a-linux-user.org/gesturestitch)

Design Presentation
-------------------
You can find the public design presentation here:
http://goo.gl/gxRUF

Code Conventions
----------------
- @\_ = private
- @u = unwrapped (DOM element)

Code Overview
-------------
- ImageDisplay
 - Loads image list
 - Creates Images
 - Holds list of selected images
- Image
 - Loads Images
 - Creates/displays <canvas>'s
 - Creates Pixels
 - Searches for 2D corners using features()
 - Matches features using match()
- Canvas
 - Creates a 2d canvas for pixel manipulation
 - Provides convenient access to pixel data

