
class Image
    constructor: (args)->
        # Create a new Image
        # Only uses URLs now but it should be extensible to other ways of construction
        @url = args.url
        @parent = args.parent

        @element = $("<img>").attr(src: args.url, class: "Image")
        @wrapper = $("<div class='Image_wrapper' />")

        @element.appendTo(@wrapper)
        @wrapper.appendTo(@parent.box)
    
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
