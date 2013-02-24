      
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
