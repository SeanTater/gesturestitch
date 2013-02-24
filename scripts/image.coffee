window.gs = {} if not gs?

class gs.Image
    constructor: (args)->
        # Create a new Image
        # Only uses URLs now but it should be extensible to other ways of construction
        @url = args.url
        @parent = args.parent

        # Create image, wrapper
        @element = $("<img />").attr(src: args.url, class: "Image")
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
        new gs.Canvas(@element[0])
    
    ## Interface
    select: ->
        # Show the user that this image has been selected
        @wrapper.css("border-color": "red", background: "#f99")
    
    deselect: ->
        # Show the user this image is deselected
        @wrapper.css("border-color": "black", background: "#fff")
