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
        
        # @parent is to remove cyclic dependencies
        # you can use "this" from ImageDisplay before its fully defined
        # but you can't for gs.ImageDisplay
        @parent = args.parent
        @onload = args.onload ? ->
        
        # Create the picture frame and put the image in it
        @wrapper = $("<div class='Image_wrapper' />").draggable().click(this.toggleSelect.bind(this))

        if args.pixels?
            @pixels = args.pixels
            @width = @pixels.width
            @height = @pixels.height
            this.setupCanvas()
            this.draw()
            this.scatter()
        else if args.url?
            # Create an Image from a url
            @image = $("<img/>")
            @uimage = @image[0]
            @image.attr(src: args.url, class: "Image")
            this.display(@image)
            # Don't place the image until there is something in it
            @image.load((->
                @width = @uimage.width
                @height = @uimage.height
                this.scatter()
                this.setupCanvas()).bind(this))
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
        
        @ucanvas.width = @width
        @ucanvas.height = @height

        throw "Can't display a 0 size image" if @width * @height == 0
        
        # Create a plain 2d context (could use WebGL too)
        @context = @ucanvas.getContext("2d")
        # Draw image on the canvas
        @context.drawImage(@uimage, 0, 0) if @uimage?
        
        # Now that the image is drawn, we should be able to replace the original image
        this.display(@canvas)
        if @uimage? 
            # Make pixel access more convenient
            @image_data = @context.getImageData(0, 0, @width, @height)
            @pixels = new gs.Pixels(imdata: @image_data)
        # Callback from elsewhere
        this.onload(this)

    unlink: ->
        # Remove the wrapper
        @wrapper.remove()
    
    save: ->
        # Save the pixels to the canvas
        this.draw(@pixels)
    
    draw: (pixels)->
        # Draw the image on the canvas
        this.setupCanvas()
        # This is inefficient but without it, you would have to merge the pixels and image classes
        i_data = @context.createImageData(@width, @height)
        i_data.data = @pixels.data
        i = @pixels.data.length
        while --i > 0
            i_data.data[i] = @pixels.data[i]
        @context.putImageData(i_data, 0, 0)

    
    brighten: ->
        # Simple effect to demonstrate pixel manipulation
        this.setupCanvas()
        for pi in [0...@pixels.data.length] by 4
            @pixels.data[pi] *= 2
        # This could be unnecessary but it makes it easier to use
        this.save()

    renderFeatures: (corners) ->
        pixel = new Uint8ClampedArray([0, 255, 0, 255])
        for i in [0...corners.length]
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
        jsfeat.imgproc.grayscale(@pixels.data, img_u8.data)

        # Blur
        #jsfeat.imgproc.box_blur_gray(img_u8, img_u8, 2, 0)

        # Detect
        #count = jsfeat.yape06.detect(img_u8, corners)
        count = jsfeat.fast_corners.detect(img_u8, corners)

        console.log("#{count} features before filtering")

        corners = corners[0...count]
        i = corners.length
        while --i >= 0
            if not (4 < corners[i].x < (@width-4))
                console.log("#{corners[i].x} failed x")
                corners[i..i] = []
            else if not (4 < corners[i].y < (@height-4))
                corners[i..i] = []
        console.log("#{corners.length} features after filtering")
        corners
   
    match: (other_image)->
        our_features = this.features()
        their_features = other_image.features()
        hs = []
        
        swap = (i1, i2)->
            temp = their_features[i1]
            their_features[i1] = their_features[i2]
            their_features[i2] = temp
            return
        pregion = (pix, point)->
            pix.region(point.x, point.y, 4)

        #TODO: handle length better
        len = Math.min(our_features.length, their_features.length)
        for start in [0...len]
            hs[start] = 1e100
            our_region = pregion(@pixels, our_features[start])
            for end in [start...len]
                their_region = pregion(other_image.pixels, their_features[end])
                test = our_region.compareHistogram(their_region)
                if test < hs[start]
                    swap(start, end)
                    hs[start] = test
        
        for index in [0...len]
            tr = $("<tr>")
            tr.append($("<td>").text(our_features[index].x))
            tr.append($("<td>").text(our_features[index].y))
            tr.append($("<td>").text(their_features[index].x))
            tr.append($("<td>").text(their_features[index].y))
            tr.append($("<td>").text(hs[index]))
            $("#statistics").append(tr)
            {
                ours: our_features[index]
                theirs: their_features[index]
                movement: new jsfeat.point2d_t(their_features[index].x - our_features[index].x, their_features[index].y - our_features[index].y)
                score: 0 # This is used in cull
            }
    
    refine: (other, transform)->
        @pixels.refine(other.pixels, transform)

    estimateTranslation: (matches)->
        # This is still limited by the fact that it can only handle translation
        max_match = matches[0]
        # This is not the fastest but it will probably be rewritten
        for m1 in matches
            for m2 in matches
                # Give features a score based on how close they are to other scores
                squared_distance = Math.pow(m1.movement.x-m2.movement.x, 2) + Math.pow(m1.movement.y-m2.movement.y, 2) + 1
                m1.score += 1/squared_distance
            if m1.score > max_match.score
                max_match = m1
        return new gs.Transform().translate(max_match.movement)

    overlay: (other, trans)->
        # TODO: stub: needs to actually take matched points into account
        new gs.Image(pixels: @pixels.merge(other.pixels, trans), parent: @parent)

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
        # Place the image on the desktop or tells you where it is.
        # y++ lowers, y-- raises
        if x?
            @wrapper.css(
                position: "absolute"
                left:  x
                top: y)
        else
            p = @wrapper.position()
            {x: p.left, y:p.top}

    spin: (degrees)->
        # Shortcut to set all the different rotation properties quickly
        for renderer in ['Webkit', 'Moz', 'O', 'MS', '']
            @wrapper.css("#{renderer}Transform", "rotate(#{degrees}deg)")

    scatter: ->
        # Place and spin the image to a random place on the board, even below another image (for now)
        degrees = Math.floor(Math.random() * 20) - 10
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
