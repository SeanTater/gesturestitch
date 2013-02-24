gesturestitch
=============

Gesture-Initiated Image Stitcher


Overview
--------
- Runs in a web browser
- Only works correctly on Chrome when run on a server, works as only static files
- Requires LeapMotion API + controller
- Attempts to stitch together two images when requested by user via gestures 

Setup
-----
To get it up and running, you need to:
- Install a web server (any old thing will do; it only needs to run static files)
 - sudo apt-get install lighttpd
- Install coffee, to compile .coffee files into .js
 - sudo apt-get install coffeescript
- Compile coffee files
 - coffee -c scripts/*.coffee

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

