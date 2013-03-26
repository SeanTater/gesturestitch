window.gs = {} if not gs?
jsfeat.point2d_t::toString = -> "#{@x},#{@y}"

class gs.Image
    ###
        Somewhat full-featured Image
        : brighten()
            A simple effect to demonstrate pixel manipulation.
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
        @wrapper = $("<div class='Image_wrapper' />").draggable().click(this.toggleSelect.bind(this))
        this.display(@image)

        if args.url
            # Create an Image from a url
            @url = @image.attr(src: args.url, class: "Image")
            # Don't place the image until there is something in it
            # self is to carry "this" across the closure
            self = this
            @image.load(->
                self.scatter()
                self.setupCanvas())
            
        else if args.image
            # @image is a /reference/ (so when copying images you have the same <image>)
            @image = args.image.image
            @uimage = @image[0]
            # Reference counting for deleting an image after deleting all its copies
            ref = @image.data("ref") ? 0
            ref++
            @image.data("ref", ref)
            this.setupCanvas()
            this.scatter()

        else if args.pixels
            # Note this means some images actually have no @image
            @pixels = args.pixels
            this.scatter()
            this.setupCanvas()

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
        @context.drawImage(@uimage, 0, 0) if @uimage?
        
        # Now that the image is drawn, we should be able to replace the original image
        this.display(@canvas)
        
        # Make pixel access more convenient
        @image_data = @context.getImageData(0, 0, @width, @height)
        @pixels = new gs.Pixels(imdata: @image_data)

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
        @pixels.filter(
            (x, y, pbright)->
                for vi in [0...4]
                    pbright[vi] = pbright[vi] * 2
                return pbright
            )
        # This could be unnecessary but it makes it easier to use
        this.save()

    renderFeatures: (corners) ->
        pixel = new Uint8ClampedArray([0, 255, 0, 0])
        for i in [i...corners.length]
            x = corners[i].x
            y = corners[i].y
            @pixels.pixel(x+1, y, pixel)
            @pixels.pixel(x-1, y, pixel)
            @pixels.pixel(x, y+1, pixel)
            @pixels.pixel(x, y-1, pixel)
        this.save()
    
    features: ->
        this.setupCanvas()

        # Create output corner array
        corners = []
        i = @width*@height # This is the absolute upper limit (i/1000 is more typical)
        while --i >= 0
            corners[i] = new jsfeat.point2d_t(0,0,0,0)

        # Convert image to grayscale  
        img_u8 = new jsfeat.matrix_t(@width, @height, jsfeat.U8_t | jsfeat.C1_t)
        imageData = @context.getImageData(0, 0, @width, @height)
        jsfeat.imgproc.grayscale(@image_data.data, img_u8.data)

        # Blur
        jsfeat.imgproc.box_blur_gray(img_u8, img_u8, 2, 0)

        # Detect
        count = jsfeat.yape06.detect(img_u8, corners)

        console.log("" + count + " features")
        corners[0...count]

    match: (other_image)->
        # Naive feature matching using SSE
        this.setupCanvas()
        best_matches = {}

        # These are really expensive to calculate so save them
        our_features = this.features()
        our_best = {}
        for feature in our_features
            our_best[feature] = {point:null, sse: 1e100}

        their_features = other_image.features()
        their_best = {}
        for feature in their_features
            their_best[feature] = {point:null, sse: 1e100}
        

        for our_point in our_features
            try
                our_region = @pixels.region(our_point.x, our_point.y, 8)
            catch BoundsError
                # We can't match features really close to an edge
                # It may not be a bad idea to delete the feature, but not here probably, so skip it.
                continue
            for their_point in their_features
                try
                    their_region = @pixels.region(their_point.x, their_point.y, 8)
                catch BoundsError
                    # We can't match features really close to an edge
                    # It may not be a bad idea to delete the feature, but not here probably, so skip it.
                    continue
                sse = our_region.sse(their_region)
                if sse < our_best[our_point].sse and sse < their_best[their_point].sse
                    our_best[our_point] = {point:their_point, sse:sse}
                    their_best[their_point] = {point:our_point, sse:sse}

        agreed_matches = {}
        agreed_matches.all = []
        for our_point of our_best when our_point.point isnt null
            agreed_matches[our_point] = our_best[our_point]
            agreed_matches.all.push([our_point, their_point, agreed_matches[our_point].sse])
        
        return agreed_matches
   
    overlay: (other, trans)->
        # TODO: stub: needs to actually take matched points into account
        new gs.Image(@pixels.merge(other.pixels), new gs.Transform().translate(25, 34))

    ## Interface
    handleMenuEvent: (event)->
        event.preventDefault()
        gs.ImageMenu.show(this, event)

    getCorners: ->
        # Return the coordinates of the corners of the image relative to the display
        this.setupCanvas()
        [
            [@image.style.left, @image.style.top],
            [@image.style.left + @pixels.cols, @image.style.top],
            [@image.style.left, @image.style.top + @pixels.rows],
            [@image.style.left + @pixels.cols, @image.style.top + @pixels.rows],
        ]

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
        degrees = Math.floor(Math.random() * 45) - 30
        # Keep the image from going off the board, 1.4 accounts for a diagonal
        #TODO: Something is wrong here; they're still going off the screen
        x_limit = @parent.width - (@wrapper.width() * 1.4) 
        y_limit = @parent.height - (@wrapper.height() * 1.4)
        x = Math.floor(Math.random() * x_limit)
        y = Math.floor(Math.random() * y_limit)

        this.place(x, y)
        this.spin(degrees)
    
    toggleSelect: ->
        if @wrapper.hasClass("ui-selected")
            @wrapper.removeClass("ui-selected")
            @parent.deselect(this)
        else
            @wrapper.addClass("ui-selected")
            @parent.select(this)
