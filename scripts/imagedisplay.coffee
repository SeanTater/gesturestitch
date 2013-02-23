
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
        for image_url in imlist
            console.log("loading #{image_url}")
            $("<img>").attr({src: image_url}).appendTo(@box)

im_disp = new ImageDisplay()
im_disp.getImageList()
