window.gs = {} if not gs?

class gs.Canvas
    constructor: (uimage)->
        # Read/write-able two dimensional surface for manipulating pixel data
        @element = $("<canvas>")
        @uelement = @element[0]
        @width = @uelement.width = uimage.width
        @height = @uelement.height = uimage.height

        # Create a plain 2d context (could use WebGL too)
        @context = @uelement.getContext("2d")
        @context.drawImage(uimage, 0, 0)

        # Make pixel access more convenient
        @image_data = @context.getImageData(0, 0, @width, @height)
        console.log("pixels: #{@image_data}")
        @pixels = @image_data.data

    save: ->
        # Save the pixels to the canvas
        # TODO: find out if @image_data.data = @pixels is necessary
        @content.putImageData(@image_data, 0, 0)

    features: ->
        # Use JSFeat to find features
        color_image = new jsfeat.matrix_t(@width, @height, jsfeat.U8_t | jsfeat.C4_t, @pixels)
        gray_image = new jsfeat.matrix_t(@width, @height, jsfeat.U8_t | jsfeat.C1_t, @pixels)
        jsfeat.imgproc.grayscale(color_image.data, gray_image.data)
        # Boilerplate code used by JSFeat (there are possibly-more-advanced algorithms)
        
        # threshold on difference between intensity of the central pixel 
        # and pixels of a circle around this pixel
        jsfeat.fast_corners.set_threshold(20) # threshold=20
         
        # Preallocate point2d_t array
        corners = [ new jsfeat.point2d_t(0,0,0,0) for i in [0...@width*@height] ]
         
        # perform detection
        # returns the number of detected corners
        count = jsfeat.fast_corners.detect(gray_image.data, corners, 3) # border = 3
        
        {corners:corners, count:count}
