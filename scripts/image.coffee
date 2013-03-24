window.gs = {} if not gs?
jsfeat.point2d_t::toString = -> "#{@x},#{@y}"

class BoundsError
    constructor: (@message)->
    toString: ->@message

class Pixels
    constructor: (args)->
        # Create a new Pixels from either an image or out of thin air

        # This is only for code clarity now. We probably don't need any other channels
        @channel = 4
        @offsetx = args.x ? 0
        @offsety = args.y ? 0
        if args.imdata?
            @imageData = args.imdata
            @cols = @imageData.width - @offsetx
            @rows = @imageData.height - @offsety
            @data = @imageData.data
            throw new BoundsError("Pixels() offset x #{@offsetx} out of bounds") unless 0 <= @offsetx < @imageData.width
            throw new BoundsError("Pixels() offset y #{@offsety} out of bounds") unless 0 <= @offsety < @imageData.height
            throw new BoundsError("Pixels() width #{@cols} out of bounds") unless 0 <= (@offsetx + @cols) <= @imageData.width
            throw new BoundsError("Pixels() height #{@rows} out of bounds") unless 0 <= (@offsety + @rows) <= @imageData.height
        else
            throw new BoundsError("Must include width and height for bounds") unless args.cols? and args.rows?
            @cols = args.cols
            @rows = args.rows
            @data = new Uint8ClampedArray(@cols * @rows * @channel)
        

        
    pixel: (x, y, value)->
        # Safeguards
        throw "Missing data" unless @data?
        throw new BoundsError("X #{x} out of bounds") unless 0 <= x < @cols
        throw new BoundsError("Y #{y} out of bounds") unless 0 <= y < @rows
        
        # Locate..
        location = (y+@offsety) * @cols
        location += (x+@offsetx)
        location *= @channel

        # Get or set
        # uses subarray because it is actually a ClampedUint8Array, which does not have slice() aka: [a...b]
        if value?
            @data.set(value, location)
            return value
        else
            return @data.subarray(location, location+@channel)
    
    box:  (x1, y1, x2, y2, value) ->
        #TODO: Naive implementation: this could be faster

        # Calculate size to create new box and to ensure sane values
        cols = x2-x1
        rows = y2-y1
        throw new BoundsError("Box origin out of bounds: #{x1}, #{y1}") unless 0 <= x1 < @cols and 0 <= y1 < @rows
        throw new BoundsError("Box extent out of bounds: #{x2}, #{y2}") unless 0 <= x2 < @cols and 0 <= y2 < @rows
        throw new BoundsError("Box width out of bounds: #{cols}") unless 0 < cols <=@cols
        throw new BoundsError("Box height out of bounds: #{rows}") unless 0 < rows <= @rows


        if value?
            # Set 
            for x in [x1...x2]
                for y in [y1...y2]
                    this.pixel(x, y, value.pixel(x-x1, y-y1))
            return this
        else
            # Get
            box = new Pixels(cols:cols, rows:rows)
            for x in [x1...x2]
                for y in [y1...y2]
                    box.pixel(x-x1, y-y1, this.pixel(x, y))
            return box
    
    region: (x, y, diameter)->
        # Get a region around a pixel
        left_top_margin = Math.floor(diameter/2)
        right_bottom_margin = Math.ceil(diameter/2)
        throw new BoundsError("Region x dimension #{x} too close to a bound") unless left_top_margin < x < (@cols - right_bottom_margin)
        throw new BoundsError("Region y dimension #{y} too close to a bound") unless left_top_margin < y < (@rows - right_bottom_margin)

        return this.box(x-left_top_margin, y-left_top_margin, x+right_bottom_margin, y+right_bottom_margin)

    # ruby-like iterators
    each: (callback)->
        # Do something with each pixel.
        # callback(x, y, value)
        #TODO: naive
        for x in [0...@cols]
            for y in [0...@rows]
                callback(x, y, this.pixel)
        return this

    filter: (callback)->
        # Filter the image with callback.
        # callback(x, y, value) => value
        # TODO: this is naive and could be faster
        for x in [0...@cols]
            for y in [0...@rows]
                this.pixel(x, y, callback(x, y, this.pixel(x, y)))
        return this
    
    sse: (other)->
        # Calculate the sum of squared error with another Pixels
        sum = 0
        this.each((x, y, value)->
            other_pixel = other.pixel(x, y)
            for i in [0...4]
                err = value[i] - other_pixel[i]
                sum += err*err
            return
        )
        return sum

    compareHistogram: (other)->
        my_histogram = (0 for x in [0...16])
        other_histogram = (0 for x in [0...16])
        
        # FYI |0 means force coersion to int
        this.each( (x, y, value)->my_histogram[value[0]/16|0]++ )
        other.each( (x, y, value)->other_histogram[value[0]/16|0]++ )
        console.log(my_histogram)
        
        for i in [0...16]
            difference = (my_histogram[i] - other_histogram[i])
            difference * difference

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
        @wrapper = $("<div class='Image_wrapper' />")
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
        @wrapper.draggable().appendTo(@parent.box)
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
        @pixels = new Pixels(imdata: @image_data)

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
        their_features = other_image.features()
        for feature in our_features.concat(their_features)
            best_matches[feature] = {point:null, sse: 1e100}
        
        for our_point in this.features()
            for their_point in other_image.features()
                try 
                    our_region = @pixels.region(our_point.x, our_point.y, 8)
                    their_region = @pixels.region(their_point.x, their_point.y, 8)
                catch BoundsError
                    # We can't match features really close to an edge
                    # It may not be a bad idea to delete the feature, but not here probably, so skip it.
                    continue
                sse = our_region.sse(their_region)
                if sse < best_matches[our_point].sse
                    best_matches[our_point] = {point:their_point, sse:sse}
                if sse < best_matches[their_point].sse
                    best_matches[their_point] = {point:our_point, sse:sse}

        # Look for features that both agree they are the best for each other
        agreed_matches = []
        for origin_loc of best_matches
            # Trick here: a point can't be a key but it can be a value
            # So compare the neighbor's neighbor to the initial _location_ key
            origin = best_matches[origin_loc]
            neighbor_loc = origin.point
            neighbor = best_matches[neighbor_loc]
            # If they agree, and the reverse entry is not already there..
            if neighbor.point == origin and not agreed_matches[neighbor_loc]?
                agreed_matches.push_back([origin, neighbor])
        
        return {best:best_matches, agreed:agreed_matches}
    
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
    
    select: ->
        # Show the user that this image has been selected
        @wrapper.addClass("ui-selected")
    
    deselect: ->
        # Show the user this image is deselected
        @wrapper.removeClass("ui-selected")
