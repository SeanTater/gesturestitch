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
#            'images/jumping.jpg',
#            'images/jumping_dad.jpg',
            'images/jumping_kid.jpg',
#            'images/tigers.jpg',
            'images/yard-left.jpg',
#            'images/yard-right.jpg',
            'images/building_vertical.jpg',
#            'images/building_horizontal.jpg'
            ])
        
        $("#button-match").click(this.match.bind(this))
        @selected_images = []
    
    processImageList: (imlist)->
        # Load each of the images (by url) from a list
        @image_list = []
        for url in imlist
            image = new gs.Image(url: url, parent: this)
   
    load:(url)->
        new gs.Image(url: url, parent: this)
    
    exampleCanvas: ->
        # Do some sample stuff to the canvas to see that it works
        im = gs.Image.all[0]
        #im.setupCanvas()
        #im = new gs.Image(pixels: im.pixels, parent: gs.ImageDisplay)
        im.brighten()
        im.save()

    select: (image)->
        @selected_images.push(image)
        # Limit to two images
        if @selected_images.length == 3
            @selected_images[0].toggleSelect()

    deselect: (image)->
        # we made up remove()
        @selected_images.remove(image)

    match: (state)->
        # This is a really /really terrible/ software pattern
        # but I don't want to break this up into functions for every step
        # it makes no sense that way.
        switch state
            when undefined
                state= {n: 0, me: this.match, first: @selected_images[0], second: @selected_images[1]}
                if @selected_images.length != 2
                    $("#status").text("Need two images to match.")
                    return
                $("#status").text("Matching image features (be patient)...")
            when 1
                state.matches = first.match(state.second)
                $("#status").text("Estimating image translation...")
            when 2
                state.translation = state.first.estimateTranslation(state.matches)
                $("#status").text("Refining image transformation...")
            when 3
                state.translation = state.first.refine(state.second, state.translation)
                $("#status").text("Overlaying image..")
            when 4
                @selected_images[1].overlay(@selected_images[0], new gs.Transform().translate(state.translation))
                $("#status").text("#{state.matches.length} matches found, centered on #{state.translation}")
        state.n++
        setTimeout(me, 0, state)



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
                # Debugging info
                $("<p>#{features.length} features detected.</p>").dialog()

$(->
    # Load the images when the page finishes
    gs.ImageDisplay = new ImageDisplay_class()
    gs.ImageMenu = new ImageMenu_class()
    #setTimeout(gs.ImageDisplay.exampleCanvas, 1000)
)
