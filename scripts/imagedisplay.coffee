
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

class ImageDisplay
    constructor: ->
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
        @image_list = []
        for url in imlist
            image = new Image(url: url, parent: this)

$(->
    im_disp = new ImageDisplay()
    im_disp.getImageList()
)
