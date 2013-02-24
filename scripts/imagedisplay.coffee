# Convention:
# @_    = private
# @u    = unwrapped (DOM element)

class Canvas
    constructor: (uimage)->
        # Read/write-able two dimensional surface for manipulating pixel data
        @uelement = $("<canvas>")[0]
        @uelement.width = uimage.width
        @uelement.height = uimage.height

        # Create a plain 2d context (could use WebGL too)
        @context = @uelement.getContext("2d")
        @context.drawImage(uimage, 0, 0)

        # Make pixel access more convenient
        @image_data = @context.getImageData(0, 0, uimage.width, uimage.height)
        @pixels = @image_data.data
    
    save: ->
        # Save the pixels to the canvas
        # TODO: find out if @image_data.data = @pixels is necessary
        @content.putImageData(@image_data, 0, 0)
        

class Image
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
    
    canvas: ->
        # Return a new canvas with this image
        # This can be cached if necessary
        new Canvas(@element[0])
         
    select: ->
        # Show the user that this image has been selected
        @wrapper.css("border-color": "red", background: "#f99")
    
    deselect: ->
        # Show the user this image is deselected
        @wrapper.css("border-color": "black", background: "#fff")

class ImageDisplay
    constructor: ->
        # Initialize and load a grid (or other layout) of images
        @box = $("#desktop")
    
    getImageList: ->
        # Normally this would be by XHR but local can't use XHR
        # $.getJSON("images/list", {}, this.processImageList)
        this.processImageList([
            'images/jumping.jpg',
            'images/jumping_dad.jpg',
            'images/jumping_kid.jpg',
            'images/tigers.jpg'])
    
    processImageList: (imlist)->
        # Load each of the images (by url) from a list
        @image_list = []
        for url in imlist
            image = new Image(url: url, parent: this)

$(->
    # Load the images when the page finishes
    im_disp = new ImageDisplay()
    im_disp.getImageList()
)
