window.gs = {} if not gs?

class gs.Image
    constructor: (args)->
        # Create a new Image
        if args.url
            # Create an Image from a url
            @url = args.url
            @element = $("<img />").attr(src: args.url, class: "Image")
        else if args.element
            # Or from an existing element (probably a canvas)
            @element = args.element
            @element.attr(class: "Image")

        # Its conceivable you might not want it in ImageDisplay (but maybe this isn't worth it?)
        @parent = args.parent

        # Create image        
        @wrapper = $("<div class='Image_wrapper' />")

        # Nest image, place in document
        @element.appendTo(@wrapper)
        @wrapper.appendTo(@parent.box)

        # Tell the world
        gs.Image.all.push(this)

    @all: []

    canvas: ->
        # Return a new canvas with this image
        # This can be cached if necessary
        new gs.Canvas(@element)
    
    ## Interface
    select: ->
        # Show the user that this image has been selected
        @wrapper.css("border-color": "red", background: "#f99")
    
    deselect: ->
        # Show the user this image is deselected
        @wrapper.css("border-color": "black", background: "#fff")
