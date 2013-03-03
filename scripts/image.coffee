window.gs = {} if not gs?

class gs.Image
    constructor: (args)->
        # Create a new Image
        if args.url
            # Create an Image from a url
            @url = args.url
            @image = $("<img />").attr(src: args.url, class: "Image")
            @uimage = @image[0]
        #TODO: Make an copy image 

        # Its conceivable you might not want it in ImageDisplay (but maybe this isn't worth it?)
        @parent = args.parent

        # Create image        
        @wrapper = $("<div class='Image_wrapper' />")

        # Nest image, place in document
        @image.appendTo(@wrapper)
        @wrapper.appendTo(@parent.box)

        # Don't place the image until there is something in it
        # Self is to carry "this" across the closure
        self = this
        @image.load(->
            self.canvas()
            self.scatter())

        # Tell the world
        gs.Image.all.push(this)

    @all: []

    setupCanvas: ->
        # Setup the canvas for this image (when it loads)
        # Read/write-able two dimensional surface for manipulating pixel data
        
        @canvas = $("<canvas>")
        @ucanvas = canvas[0]
        
        @width = ucanvas.width = uimage.width
        @height = ucanvas.height = uimage.height
        @numel = @width * @height
        
        # Create a plain 2d context (could use WebGL too)
        @context = ucanvas.getContext("2d")
        @context.drawImage(uimage, 0, 0)
        
        # Make pixel access more convenient
        @image_data = @context.getImageData(0, 0, @width, @height)
    
    ## Canvas-related functions
    
    save: ->
        # Save the pixels to the canvas
        # TODO: find out if @image_data.data = @pixels is necessary
        @context.putImageData(@image_data, 0, 0)
    
    brighten: ->
        for i in [0...@numel*4]
            @image_data.data[i] = @image_data.data[i] * 2 % 256


    features: ->
        # Use JSFeat to find features
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
        @wrapper.css("border-color": "red", background: "#f99")
    
    deselect: ->
        # Show the user this image is deselected
        @wrapper.css("border-color": "black", background: "#fff")
