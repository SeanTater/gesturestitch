
class ImageDisplay
    getImageList = ->
        $.getJSON("images/list", {}, this.processImageList)
    
    processImageList = (imlist)->
        @image_list = ()
        for 