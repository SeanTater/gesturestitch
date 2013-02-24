
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
