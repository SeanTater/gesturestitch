
class ImageDisplay
    constructor = ->
        @box = $("desktop")
    
    getImageList = ->
        $.getJSON("images/list", {}, this.processImageList)
    
    processImageList = (imlist)->
        @image_list = []
        for image_url in imlist
            image = $("<img>").attr({src: image_url})
            @box.append(image)

ImageDisplay().getImageList()