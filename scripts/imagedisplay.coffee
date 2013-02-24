window.gs = {} if not gs?

class ImageDisplay_class
    constructor: ->
        # Initialize and load a grid (or other layout) of images
        @box = $("#desktop")
    
        # Normally this would be by XHR but local can't use XHR
        # $.getJSON("images/list", {}, this.processImageList)
        this.processImageList([
            'images/jumping.jpg',
            'images/jumping_dad.jpg',
            'images/jumping_kid.jpg',
            'images/tigers.jpg'])
        
        # This comes from jquery-ui
        # TODO: Implement the LeapMotion-based equivalent
        @box.sortable()
    
    processImageList: (imlist)->
        # Load each of the images (by url) from a list
        @image_list = []
        for url in imlist
            image = new gs.Image(url: url, parent: this)
    
    exampleCanvas: ->
        can = gs.Image.all[0].canvas()
        # Uses gs.ImageDisplay instead of this because it is used by setTimeout
        im = new gs.Image(canvas: can,  parent: gs.ImageDisplay)  


$(->
    # Load the images when the page finishes
    gs.ImageDisplay = new ImageDisplay_class()
    setTimeout(gs.ImageDisplay.exampleCanvas, 1000)
)
