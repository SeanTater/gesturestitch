window.gs = {} if not gs?

class Pixels extends jsfeat.matrix_t
    pixel: (x, y, value)->
        # Safeguards
        throw "X #{x} out of bounds" unless 0 <= x < @cols
        throw "Y #{y} out of bounds" unless 0 <= y < @rows
        
        # Locate..
        location = y * @cols
        location += x
        location *= @channel

        # Get or set
        if value?
            return @data[location...location+@channel] = @data
        else
            return @data[location...location+@channel]
    
    box: (x1, y1, x2, y2, value) ->
        # Naive implementation: this could be faster
        cols = x2-x1
        rows = y2-y1
        if value?
            # Set 
            for x in [x1...x2]
                for y in [y1...y2]
                    this.pixel(x, y, value.pixel(x, y))
            return this
        else
            # Get
            box = new Pixels(cols, rows, @type)
            for x in [x1...x2]
                for y in [y1...y2]
                    box.pixel(x, y, this.pixel(x, y))
            return box

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
            @uimage = @image[0]
            # Reference counting for deleting an image after deleting all its copies
            ref = @image.data("ref") ? 0
            ref++
            @image.data("ref", ref)
            this.setupCanvas()
            this.scatter()

        # Tell the world
        gs.Image.all.push(this)

    @all: []
    
    display: (element)->
        # Nest the element (either <img> or <canvas>), and place in document
        if @main?
            @main.remove()
        @main = element
        # Insert into DOM
        @main.appendTo(@wrapper)
        @wrapper.appendTo(@parent.box)
        # Fix context menu
        @main.on("contextmenu", $.proxy(this.handleMenuEvent, this))

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

        throw "Can't display a 0 size image" if @numel == 0
        
        # Create a plain 2d context (could use WebGL too)
        @context = @ucanvas.getContext("2d")
        # Draw image on the canvas
        @context.drawImage(@uimage, 0, 0)
        
        # Now that the image is drawn, we should be able to replace the original image
        this.display(@canvas)
        
        # Make pixel access more convenient
        @image_data = @context.getImageData(0, 0, @width, @height)

    unlink: ->
        # Remove image only if it is original
        ref = @image.data("ref") - 1 
        @image.data("ref", ref)
        @image.remove() if ref == 0
        # But remove the wrapper either way
        @wrapper.remove()
    
    save: ->
        # Save the pixels to the canvas
        # TODO: find out if @image_data.data = @pixels is necessary
        this.setupCanvas()
        @context.putImageData(@image_data, 0, 0)
    
    revert: ->
        # Draw the image on the canvas
        this.setupCanvas()
        ref = @image.data("ref") - 1 
        @image.data("ref", ref)
        @image.remove() if ref == 0

        @context.drawImage(@uimage, 0, 0)
    
    brighten: ->
        # Simple effect to demonstrate pixel manipulation
        this.setupCanvas()
        i = @numel*4
        while --i > 0
            @image_data.data[i] = @image_data.data[i] * 2 % 256
        return

    render_corners: (corners, image, step) ->
        pixel = (0xff << 24) | (0x00 << 16) | (0xff << 8) | 0x00
        for i in [i..corners.length]
            x = corners[i].x
            y = corners[i].y
            offset = (x + y * step)
            image[offset] = pixel
            image[offset-1] = pixel
            image[offset+1] = pixel
            image[offset-step] = pixel
            image[offset+step] = pixel
    
    features: ->
        this.setupCanvas()

        # Create output corner array
        corners = []
        i = @width*@height # This is the absolute upper limit (i/1000 is more typical)
        while --i >= 0
            corners[i] = new jsfeat.point2d_t(0,0,0,0)

        # Convert image to grayscale  
        img_u8 = new jsfeat.matrix_t(@width, @height, jsfeat.U8_t | jsfeat.C1_t)
        imageData = this.context.getImageData(0, 0, @width, @height)
        jsfeat.imgproc.grayscale(this.image_data.data, img_u8.data)

        # Blur
        jsfeat.imgproc.box_blur_gray(img_u8, img_u8, 2, 0)

        # Detect
        count = jsfeat.yape06.detect(img_u8, corners)

        # Render result back to canvas
        #data_u32 = new Uint32Array(imageData.data.buffer)
        #this.render_corners(corners, count, data_u32, @width)
        console.log("" + count + " features")
        corners[0...count]

    match: (features)->
        # Naive feature matching using SSE

    
    
    ## Interface
    handleMenuEvent: (event)->
        event.preventDefault()
        gs.ImageMenu.show(this, event) 

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
