window.gs = {} if not gs?

class gs.Image
    constructor: (args)->
        # Create a new Image
        if args.url
            # Create an Image from a url
            @url = args.url
            @element = $("<img />").attr(src: args.url, class: "Image")
        else if args.canvas
            # Or from an existing Canvas
            @url = null
            @element = args.canvas.element
            @element.attr(class: "Image")

        # Create image        
        @wrapper = $("<div class='Image_wrapper' />")

        # Nest image, place in document
        @element.appendTo(@wrapper)
        @wrapper.appendTo(gs.ImageDisplay.box)

        # Don't place the image until there is something in it
        # Self is to carry "this" across the closure
        self = this
        @element.load(-> self.scatter())

        # Tell the world
        gs.Image.all.push(this)

    @all: []

    canvas: ->
        # Return a new canvas with this image
        # This can be cached if necessary
        new gs.Canvas(@element[0])
    
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
