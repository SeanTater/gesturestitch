window.gs = {} if not gs?

# Very cool, came from StackOverflow(Amir). Removes an item from an array
Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

class ImageDisplay_class
    constructor: ->
        # Initialize and load a grid (or other layout) of images
        @box = $("#desktop")
        # Unwrap
        @ubox = @box[0]
        # This is necessary for image placement later
        @width = @box.width()
        @height = @box.height()
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
        # Do some sample stuff to the canvas to see that it works
        im = gs.Image.all[0]
        im = new gs.Image(image: im, parent: gs.ImageDisplay)
        im.brighten()
        im.save()

class ImageMenu_class
    constructor: ->
        # Someone right clicked
        @menu = $("#image_menu").menu(select: $.proxy(this.select, this))
        @menu.mouseleave(-> $(this).hide())
        

    show: (image, event) ->
        @menu.css(top: event.pageY, left: event.pageX)
        @menu.show()
        @event = event
        @image = image
    
    select: (event, ui)->
        # A user selected something on the menu
        @menu.hide()
        console.log("loading...")
        switch ui.item.text()
            when "Brighten" 
                @image.brighten()
            when "Delete"
                @image.unlink()
                gs.Image.all.remove(@image) 
            when "Features"
                features = @image.features()
                @image.renderFeatures(features)
            when "Match"
                # TODO: Come up with a way to render this
                features = @image.features()
                matches = @image.match(features)
                console.log("#{features.length} features, #{matches.agreed.length} matches")
$(->
    # Load the images when the page finishes
    gs.ImageDisplay = new ImageDisplay_class()
    gs.ImageMenu = new ImageMenu_class()
    setTimeout(gs.ImageDisplay.exampleCanvas, 1000)
)
