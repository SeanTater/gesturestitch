window.gs = {} if not gs?

class gs.Image
    ###
        Somewhat full-featured Image
        : brighten()
            A simple effect to demonstrate pixel manipulation. (Use save() afterward)
        : display()
            Changes which element is shown (<img> or <canvas>)
        : features()
            Searches for 2d corners
        : place()
            Move the image around the ImageDisplay
        : scatter()
            place() and spin() the image randomly around the ImageDisplay
        : select() and deselect()
            Changes the style for user feedback
        : spin()
            Rotate the image (only in display, same in pixel manipulation)
    ###
    constructor: (args)->
        # Create a new Image
        @image = $("<img />")
        @uimage = @image[0]
        
        # @parent is to remove cyclic dependencies
        # you can use "this" from ImageDisplay before its fully defined
        # but you can't for gs.ImageDisplay
        @parent = args.parent
        
        # Create the picture frame and put the image in it
        @wrapper = $("<div class='Image_wrapper' />")
        this.display(@image)
        
        if args.url
            # Create an Image from a url
            @url = @image.attr(src: args.url, class: "Image")
            # Don't place the image until there is something in it
            # self is to carry "this" across the closure
            self = this
            @image.load(-> self.scatter())
            
        else if args.image
            #NOTE: Right now you can only copy canvasses images
            # @image is a /reference/ (so when copying images you have the same <image>)
            @image = args.image.image
            this.setupCanvas()

        # Tell the world
        gs.Image.all.push(this)

    @all: []
    
    display: (element)->
        # Nest the element (either <img> or <canvas>), and place in document
        if @main?
            @main.remove()
        @main = element
        @main.appendTo(@wrapper)
        @wrapper.appendTo(@parent.box)

    setupCanvas: ->
        # Setup the canvas for this image (when it loads)
        # Indempotent: run this whenever you need to use canvas to ensure it exists
        return if @canvas?
        # Read/write-able two dimensional surface for manipulating pixel data
        @canvas = $("<canvas>")
        @ucanvas = @canvas[0]
        
        @width = @ucanvas.width = @uimage.width
        @height = @ucanvas.height = @uimage.height
        @numel = @width * @height
        
        # Create a plain 2d context (could use WebGL too)
        @context = @ucanvas.getContext("2d")
        # Draw image on the canvas
        this.revert()
        
        # Now that the image is drawn, we should be able to replace the original image
        this.display(@canvas)
        
        # Make pixel access more convenient
        @image_data = @context.getImageData(0, 0, @width, @height)
    
    ## Canvas-related functions
    save: ->
        # Save the pixels to the canvas
        # TODO: find out if @image_data.data = @pixels is necessary
        this.setupCanvas()
        @context.putImageData(@image_data, 0, 0)
    
    revert: ->
        # Draw the image on the canvas
        @context.drawImage(@uimage, 0, 0)
    
    brighten: ->
        # Simple effect to demonstrate pixel manipulation
        this.setupCanvas()
        i = @numel*4
        while --i > 0
            @image_data.data[i] = @image_data.data[i] * 2 % 256


    features: ->
        # Use JSFeat to find features
        this.setupCanvas()
        #color_image = new jsfeat.matrix_t(@width, @height, jsfeat.U8_t | jsfeat.C4_t, @pixels)
        gray_image = new jsfeat.matrix_t(@width, @height, jsfeat.U8_t | jsfeat.C1_t)
        jsfeat.imgproc.grayscale(@image_data.data, gray_image.data)
        console.log(gray_image.data)
        # Boilerplate code used by JSFeat (there are possibly-more-advanced algorithms)
        
        # threshold on difference between intensity of the central pixel 
        # and pixels of a circle around this pixel
        jsfeat.fast_corners.set_threshold(5) # threshold=5, (was 20)
         
        # Preallocate point2d_t array
        corners = [ new jsfeat.point2d_t(0,0,0,0) for i in [0...@width*@height] ]
         
        # perform detection
        # returns the number of detected corners
        count = jsfeat.fast_corners.detect(gray_image.data, corners, 3) # border = 3
        
        {corners:corners, count:count}
    
    
    ## Interface
    place: (x, y) ->
        # Place the image on the desktop.
        # y++ lowers, y-- raises
        @wrapper.css(
            position: "absolute"
            left:  x
            top: y)

    spin: (degrees)->
        # Shortcut to set all the different rotation properties quickly
        for renderer in ['Webkit', 'Moz', 'O', 'MS', '']
            @wrapper.css("#{renderer}Transform", "rotate(#{degrees}deg)")

    scatter: ->
        # Place and spin the image to a random place on the board, even below another image (for now)
        degrees = Math.floor(Math.random() * 60) - 30
        # Keep the image from going off the board, 1.4 accounts for a diagonal
        x_limit = @parent.width - (@wrapper.width() * 1.4) 
        y_limit = @parent.height - (@wrapper.height() * 1.4)
        x = Math.floor(Math.random() * x_limit)
        y = Math.floor(Math.random() * y_limit)

        this.place(x, y)
        this.spin(degrees)
    
    select: ->
        # Show the user that this image has been selected
        @wrapper.addClass("ui-selected")
    
    deselect: ->
        # Show the user this image is deselected
        @wrapper.removeClass("ui-selected")
