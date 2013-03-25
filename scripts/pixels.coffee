class gs.BoundsError
    constructor: (@message)->
    toString: ->@message

class gs.Transform
    constructor: (@matrix)->
        # jsfeat has matrix_t but it seems too complicated for what we need.
        @matrix ?= [[1.0, 0.0],
                   [0.0, 1.0]]

    multiply: (trans)->
        # As many rows as us, as many columns as them.
        # TODO: should probably rewrite to take advantage of only having 3x3 matrices
        rows = @matrix.length
        columns = trans[0].length
        
        adds = @matrix[0].length
        throw "Invalid size for matrix multiplication" unless @matrix[0].length == trans.length
        
        gs.Transform(for row_i in [0...rows]
            for column_i in [0...columns]
                sum = 0
                for part in [0...adds]
                    sum += @matrix[row][part] * trans[part][column]
                sum
            )
        

class gs.Pixels
    constructor: (args)->
        # Create a new Pixels from either an image or out of thin air

        # This is only for code clarity now. We probably don't need any other channels
        @channel = 4
        @offsetx = args.x ? 0
        @offsety = args.y ? 0
        if args.imdata?
            @imageData = args.imdata
            @cols = @imageData.width - @offsetx
            @rows = @imageData.height - @offsety
            @data = @imageData.data
            throw new BoundsError("Pixels() offset x #{@offsetx} out of bounds") unless 0 <= @offsetx < @imageData.width
            throw new BoundsError("Pixels() offset y #{@offsety} out of bounds") unless 0 <= @offsety < @imageData.height
            throw new BoundsError("Pixels() width #{@cols} out of bounds") unless 0 <= (@offsetx + @cols) <= @imageData.width
            throw new BoundsError("Pixels() height #{@rows} out of bounds") unless 0 <= (@offsety + @rows) <= @imageData.height
        else
            throw new BoundsError("Must include width and height for bounds") unless args.cols? and args.rows?
            @cols = args.cols
            @rows = args.rows
            @data = new Uint8ClampedArray(@cols * @rows * @channel)
        

        
    pixel: (x, y, value)->
        # Safeguards
        throw "Missing data" unless @data?
        throw new BoundsError("X #{x} out of bounds") unless 0 <= x < @cols
        throw new BoundsError("Y #{y} out of bounds") unless 0 <= y < @rows
        
        # Locate..
        location = (y+@offsety) * @cols
        location += (x+@offsetx)
        location *= @channel

        # Get or set
        # uses subarray because it is actually a ClampedUint8Array, which does not have slice() aka: [a...b]
        if value?
            @data.set(value, location)
            return value
        else
            return @data.subarray(location, location+@channel)
    
    box:  (x1, y1, x2, y2, value) ->
        #TODO: Naive implementation: this could be faster

        # Calculate size to create new box and to ensure sane values
        cols = x2-x1
        rows = y2-y1
        throw new BoundsError("Box origin out of bounds: #{x1}, #{y1}") unless 0 <= x1 < @cols and 0 <= y1 < @rows
        throw new BoundsError("Box extent out of bounds: #{x2}, #{y2}") unless 0 <= x2 < @cols and 0 <= y2 < @rows
        throw new BoundsError("Box width out of bounds: #{cols}") unless 0 < cols <=@cols
        throw new BoundsError("Box height out of bounds: #{rows}") unless 0 < rows <= @rows


        if value?
            # Set 
            for x in [x1...x2]
                for y in [y1...y2]
                    this.pixel(x, y, value.pixel(x-x1, y-y1))
            return this
        else
            # Get
            box = new Pixels(cols:cols, rows:rows)
            for x in [x1...x2]
                for y in [y1...y2]
                    box.pixel(x-x1, y-y1, this.pixel(x, y))
            return box
    
    region: (x, y, diameter)->
        # Get a region around a pixel
        left_top_margin = Math.floor(diameter/2)
        right_bottom_margin = Math.ceil(diameter/2)
        throw new BoundsError("Region x dimension #{x} too close to a bound") unless left_top_margin < x < (@cols - right_bottom_margin)
        throw new BoundsError("Region y dimension #{y} too close to a bound") unless left_top_margin < y < (@rows - right_bottom_margin)

        return this.box(x-left_top_margin, y-left_top_margin, x+right_bottom_margin, y+right_bottom_margin)

    # ruby-like iterators
    each: (callback)->
        # Do something with each pixel.
        # callback(x, y, value)
        #TODO: naive
        for x in [0...@cols]
            for y in [0...@rows]
                callback(x, y, this.pixel)
        return this

    filter: (callback)->
        # Filter the image with callback.
        # callback(x, y, value) => value
        # TODO: this is naive and could be faster
        for x in [0...@cols]
            for y in [0...@rows]
                this.pixel(x, y, callback(x, y, this.pixel(x, y)))
        return this
    
    sse: (other)->
        # Calculate the sum of squared error with another Pixels
        sum = 0
        for x in [0...@cols]
            for y in [0...@cols]
                this_pixel = this.pixel(x, y)
                other_pixel = other.pixel(x, y)
                for i in [0...4]
                    err = this_pixel[i] - other_pixel[i]
                    sum += err*err
        return sum

    compareHistogram: (other)->
        my_histogram = (0 for x in [0...16])
        other_histogram = (0 for x in [0...16])
        
        # FYI |0 means force coersion to int
        this.each( (x, y, value)->my_histogram[value[0]/16|0]++ )
        other.each( (x, y, value)->other_histogram[value[0]/16|0]++ )
        console.log(my_histogram)
        
        for i in [0...16]
            difference = (my_histogram[i] - other_histogram[i])
            difference * difference
