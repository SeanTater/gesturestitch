class gs.BoundsError
    constructor: (@message)->
    toString: ->@message

# TODO: Could this be joined with Pixels.pixel? Can we make it efficient enough for that?
class gs.Transform
    constructor: (@matrix)->
        # jsfeat has matrix_t but it seems too complicated for what we need.
        @matrix ?= [[1.0, 0.0, 0.0],
                    [0.0, 1.0, 0.0]
                    [0.0, 0.0, 1.0]]

    multiply: (trans)->
        # As many rows as us, as many columns as them.
        # TODO: should probably rewrite to take advantage of only having 3x3 matrices
        rows = @matrix.length
        columns = trans.matrix[0].length
        
        adds = @matrix[0].length
        throw "Invalid size for matrix multiplication" unless @matrix[0].length == trans.matrix.length
        
        new gs.Transform(for row_i in [0...rows]
            for column_i in [0...columns]
                sum = 0
                for part in [0...adds]
                    sum += @matrix[row_i][part] * trans.matrix[part][column_i]
                sum
            )
    
    coord: (point)->
        # This should be pretty efficient. It will be run a lot of times.
        { # The odd indentation is to avoid auto-poetry
            x: (@matrix[0][0] * point.x + @matrix[0][1] * point.y + @matrix[0][2]),
            y: (@matrix[1][0] * point.x + @matrix[1][1] * point.y + @matrix[1][2])
        }

    getTranslation: -> {x: -@matrix[0][2], y: -@matrix[1][2]}
    
    translate: (point)->
        # Eventually we should handle floating point locations (but that requires interpolation)
        new gs.Transform([[1, 0, -point.x|0],
                       [0, 1, -point.y|0], 
                       [0, 0, 1]]).multiply(this)

    rotate: (radians)->
        new gs.Transform([Math.cos(radians), Math.sin(radians), 0],
                      [-Math.sin(radians), Math.cos(radians), 0],
                      [0, 0, 1]).multiply(this)
    
    scale: (factors)->
        new gs.Transform([[factors.x, 0, 0],
                       [0, factors.y, 0],
                       [0, 0, 1]]).multiply(this)
         

class gs.Pixels
    constructor: (args)->
        # Create a new Pixels from either an image or out of thin air

        # This is only for code clarity now. We probably don't need any other channels
        @channel = 4
        @offsetx = args.x ? 0
        @offsety = args.y ? 0
        if args.imdata?
            @imageData = args.imdata
            @width = @imageData.width - @offsetx
            @height = @imageData.height - @offsety
            @data = @imageData.data
            throw new gs.BoundsError("Pixels() offset x #{@offsetx} out of bounds") unless 0 <= @offsetx < @imageData.width
            throw new gs.BoundsError("Pixels() offset y #{@offsety} out of bounds") unless 0 <= @offsety < @imageData.height
            throw new gs.BoundsError("Pixels() width #{@width} out of bounds") unless 0 <= (@offsetx + @width) <= @imageData.width
            throw new gs.BoundsError("Pixels() height #{@height} out of bounds") unless 0 <= (@offsety + @height) <= @imageData.height
        else
            throw new gs.BoundsError("Must include width and height for bounds") unless args.width? and args.height?
            @width = args.width
            @height = args.height
            @data = new Uint8ClampedArray(@width * @height * @channel)

    location: (x, y)->
        # Locate..
        index = (y+@offsety) * @width
        index += (x+@offsetx)
        index *= @channel
        index

    pixel: (x, y, value)->
        # Safeguard
        throw "Missing data" unless @data?
        throw new gs.BoundsError("X #{x} out of bounds") unless 0 <= x < @width
        throw new gs.BoundsError("Y #{y} out of bounds") unless 0 <= y < @height
        index = this.location(x, y)
        this._pixel(index, value)

    _pixel: (index, value)->
        # Get or set
        # uses subarray because it is actually a ClampedUint8Array, which does not have slice() aka: [a...b]
        if value?
            @data.set(value, index)
            return value
        else
            return @data.subarray(index, index+@channel)
    
    iter: (pt1, pt2)->
        index = this.location(pt1.x, pt1.y)
        stride = (pt2.x - pt1.x) * @channel
        step = this.location(pt1.x, pt1.y+1) - index
        end = this.location(pt2.x, pt2.y)
        stride_i = 0
        return ->
            stride_i++
            index++
            if stride_i == stride
                stride_i = 0
                index += step
            if index >= end
                return null
            return index

            
    
    box:  (x1, y1, x2, y2, value) ->
        #TODO: Naive implementation: this could be faster

        # Calculate size to create new box and to ensure sane values
        cols = x2-x1
        rows = y2-y1
        throw new gs.BoundsError("Box origin out of bounds: #{x1}, #{y1}") unless 0 <= x1 < @width and 0 <= y1 < @height
        throw new gs.BoundsError("Box extent out of bounds: #{x2}, #{y2}") unless 0 <= x2 < @width and 0 <= y2 < @height
        throw new gs.BoundsError("Box width out of bounds: #{cols}") unless 0 < cols <=@width
        throw new gs.BoundsError("Box height out of bounds: #{rows}") unless 0 < rows <= @height
        

        if value?
            # Set
            start = this.location(pt1.x, pt1.y)
            stride = (pt2.x - pt1.x) * @channel
            step = this.location(pt1.x, pt1.y+1) - index
            end = this.location(pt2.x, pt2.y)
            read_cursor = start
            write_cursor = 0
            while read_cursor < end
                value.data.set(@data.subarray(read_cursor, read_cursor+stride), write_cursor)
                read_cursor += (stride+step)
                write_cursor += stride
            
            return this
        else
            # Get
            box = new gs.Pixels(width:cols, height:rows)
            for x in [x1...x2]
                for y in [y1...y2]
                    box.pixel(x-x1, y-y1, this.pixel(x, y))
            return box
    
    region: (x, y, diameter)->
        # Get a region around a pixel
        left_top_margin = Math.floor(diameter/2)
        right_bottom_margin = Math.ceil(diameter/2)
        throw new gs.BoundsError("Region x dimension #{x} too close to a bound") unless left_top_margin < x < (@width - right_bottom_margin)
        throw new gs.BoundsError("Region y dimension #{y} too close to a bound") unless left_top_margin < y < (@height - right_bottom_margin)

        return this.box(x-left_top_margin, y-left_top_margin, x+right_bottom_margin, y+right_bottom_margin)
    
    venn: (other, ov_to_or_trans)->
        # Show the intersection and bounding boxes of two overlaid images
        # TODO: Also calculate outer
    
        toplefts = [{x:0,y:0}, ov_to_or_trans.coord({x:0, y:0})]
        toprights = [{x:@width, y:0}, ov_to_or_trans.coord({x:other.width, y:0})]
        bottomrights = [{x:@width, y:@height}, ov_to_or_trans.coord({x:other.width, y:other.height})]
        bottomlefts = [{x:0, y:@height}, ov_to_or_trans.coord({x:0, y:other.height})]
        
        # Find the intersection box in the original image's coordinate system
        inner = {
            topleft: {
                x: Math.max(toplefts[0].x, toplefts[1].x)
                y: Math.max(toplefts[0].y, toplefts[1].y) }
            topright: {
                x: Math.min(toprights[0].x, toprights[1].x)
                y: Math.max(toprights[0].y, toprights[1].y) }
            bottomleft: {
                x: Math.max(bottomlefts[0].x, bottomlefts[1].x)
                y: Math.min(bottomlefts[0].y, bottomlefts[1].y) }
            bottomright: {
                x: Math.min(bottomrights[0].x, bottomrights[1].x)
                y: Math.min(bottomrights[0].y, bottomrights[1].y) }
        }
        inner.height = inner.bottomleft.y - inner.topleft.y
        inner.width = inner.topright.x - inner.topleft.x
        
        # - Coordinate transformation matrices for intersection box -> an image
        # - All the transformations are meant to act as though you are moving the intersection box
        #    around until it is in the right place for that system
        # TODO: rotation

        # Find the intersection box in the original image's coords
        inner.to_original = new gs.Transform().translate(inner.topleft)

        # Find the intersection box in the overlay image's coords
        # This backward notation is a matter of mathmatical convention
        inner.to_overlay = ov_to_or_trans.multiply(inner.to_original)
        
        return {inner: inner}

    refine: (other, start_ov_to_or)->
        # Find the best overall location for the image using a global maximum search
        # The first implementation: a hill climber
    
        # Make a copy of the transform that we can edit
        ov_to_or = new gs.Transform().multiply(start_ov_to_or)

        actions = [
            # The move/change the overlay
            (t)->t.translate({x:1,  y:0}),
            (t)->t.translate({x:-1, y:0}),
            (t)->t.translate({x:0,  y:1}),
            (t)->t.translate({x:0,  y:-1}),
            (t)->t.scale({x:1.02, y:0}),
            (t)->t.scale({x:0.98, y:0}),
            (t)->t.scale({x:0, y:1.02}),
            (t)->t.scale({x:0, y:0.98})
        ]
        sse = (inner)->
            # Calculate the SSE of a fixed-size view of the intersection
            scaler = new gs.Transform().scale(x:16/inner.width, y:16/inner.height)
            original_scaler = scaler.multiply(inner.to_original)
            overlay_scaler = scaler.multiply(inner.to_overlay)
            sum = 0
            for x in [0...16] by 1
                for y in [0...16] by 1
                    original_pixel = original.pixel(original_scaler.coord({x:x, y:y}))
                    overlay_pixel = overlay.pixel(original_scaler.coord({x:x, y:y}))
                    for i in [0...4] by 1
                        sum += Math.pow(original_pixel[i]-overlay_pixel[i], 2)
            return sum
        
        last_move = {mat: ov_to_or, sse: sse(this.venn(other, ov_to_or).inner)}
        loop
            for action in actions
                mat = action(last_move)
                inner = this.venn(other, mat).inner
                sse = sse(inner)
                if sse < best_move.sse
                    best_move.mat = move
                    best_move.sse = sse
            if best_move.sse < last_move.sse
                last_move = best_move
            else
                break
        return last_move.mat
            
    
    merge: (other, trans)->
        # Merge two images given a specific transformation matrix
        shift = trans.getTranslation()

        # Find image extrema
        greatest_x = Math.max(shift.x + other.width, @width)
        least_x = Math.min(shift.x, 0)
        greatest_y = Math.max(shift.y + other.height, @height)
        least_y = Math.min(shift.y, 0)
         
        # Calculate new image dimensions
        new_width = greatest_x - least_x
        new_height = greatest_y - least_y
        
        # How much to move both of the images so that 0,0 is the minimum x,y
        shift_x = -least_x
        shift_y = -least_y
        trans = trans.translate({x: shift_x, y: shift_y})
        new_image = new gs.Pixels(width: new_width, height: new_height)
        # Do the simple part first: copy the first image
        for x in [0...@width]
            for y in [0...@height]
                new_image.pixel(x+shift_x, y+shift_y, this.pixel(x, y))
        # Now copy the second image using the transform
        #TODO: Improve performance
        #NOTE: This raytracing-like approach assumes every pixel in the output is a function of the second
        #      but this is not really a sane assumption (usually <25% actually overlaps)
        for x in [0...new_width]
            for y in [0...new_height]
                im2_coord = trans.coord({x:x, y:y})
                # TODO: use interpolation
                try
                    pvalue = other.pixel(im2_coord.x|0, im2_coord.y|0)
                catch err
                    continue
                new_image.pixel(x, y, pvalue)
        return new_image
    
    sse: (other)->
        # Calculate the sum of squared error with another Pixels
        sum = 0
        for x in [0...@width]
            for y in [0...@height]
                this_pixel = this.pixel(x, y)
                other_pixel = other.pixel(x, y)
                for i in [0...4]
                    err = this_pixel[i] - other_pixel[i]
                    sum += err*err
        return sum

    compareHistogram: (other)->
        my_histogram = [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
                        0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0]
        other_histogram = [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
                           0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0]
        
        # FYI |0 means force coersion to int
        for x in [0...@width] by 1
            for y in [0...@height] by 1
                my_histogram[this.pixel(x, y)[0]/16|0]++
                other_histogram[other.pixel(x, y)[0]/16|0]++
        error = 0
        for i in [0...16] by 1
            difference = (my_histogram[i] - other_histogram[i])
            difference *= difference
            error += difference
        return error
