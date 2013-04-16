do (global = this, document = this.document, helper = new Flickable.Helper()) ->

  class Flickable
    constructor: (element, opts = {}) ->
      @el      = element
      @opts    = opts
      @helper  = helper
      @browser = @helper.checkBrowser()
      @support = @helper.checkSupport()
      @events  = @helper.checkTouchEvents()

      if typeof element is "string"
        @el = document.querySelector(element)
      else if not @el
        throw new Error("Element Not Found")

      # Set Options
      @opts.use3d        = if @opts.disable3d then false else @support.transform3d
      @opts.useJsAnimate = false
      @opts.disableTouch = @opts.disableTouch or false
      @opts.disable3d    = @opts.disable3d    or false
      @opts.autoPlay     = @opts.autoPlay     or false
      @opts.interval     = @opts.interval     or 6600
      @opts.loop         = @opts.loop         or if @opts.autoPlay then true else false
      @opts.transition   = @opts.transition   or {}
      @opts.transition   =
        timingFunction:  @opts.transition["timingFunction"] or "cubic-bezier(0.23, 1, 0.32, 1)"
        duration:        do =>
          @opts.transition["duration"] or if @browser.isLegacy then "200ms" else "330ms"

      # Variable Params
      @currentPoint = if @opts.currentPoint is undefined and @opts.loop then 1 else @opts.currentPoint or 0
      @maxPoint     = @currentX   = @maxX       = 0
      # @currentPoint = @maxPoint   = @currentX   = @maxX         = 0
      @gestureStart = @moveReady  = @scrolling  = @didCloneNode = false

      @startTime    = @timerId    =
      @basePageX    = @startPageX = @startPageY = @distance     = null

      if @support.cssAnimation
        @helper.setStyle @el,
          transitionProperty:       @helper.getCSSVal("transform")
          transitionDuration:       "0ms"
          transitionTimingFunction: @opts.transition["timingFunction"]
          transform:                @_getTranslate(0)
      else
        @helper.setStyle @el,
          position: "relative"
          left:     "0px"

      if @support.eventListener
        document.addEventListener "gesturestart", =>
          @gestureStart = true
        , false
        document.addEventListener "gestureend",   =>
          @gestureStart = false
        , false

      global.addEventListener "blur",  =>
        @_clearAutoPlay()
      , false
      global.addEventListener "focus", =>
        @_startAutoPlay()
      , false

      @el.addEventListener(@events.start, @, false)

      if @opts.autoPlay then @_startAutoPlay()
      if @opts.loop     then @_cloneNode()

      @refresh()

    handleEvent: (event) ->
      switch event.type
        when @events.start
          @_touchStart(event)
        when @events.move
          @_touchMove(event)
        when @events.end
          @_touchEnd(event)
        when "click"
          @_click(event)

    refresh: ->
      @_setTotalWidth()

      getMaxPoint = =>
        childNodes = @el.childNodes
        itemLength = 0

        for node, i in childNodes
          if node.nodeType is 1 then itemLength++

        if itemLength > 0 then itemLength--

        return itemLength

      @maxPoint     = if @opts.maxPoint is undefined then getMaxPoint()                     else @opts.maxPoint
      @distance     = if @opts.distance is undefined then @el.scrollWidth / (@maxPoint + 1) else @opts.distance
      @maxX         = -@distance * @maxPoint

      @moveToPoint()

    hasPrev: ->
      @currentPoint > 0

    hasNext: ->
      @currentPoint < @maxPoint

    toPrev: ->
      if not @hasPrev() then return
      @moveToPoint(@currentPoint - 1)

    toNext: ->
      if not @hasNext() then return
      @moveToPoint(@currentPoint + 1) 

    moveToPoint: (point = @currentPoint, duration = @opts.transition["duration"]) ->
      beforePoint   = @currentPoint
      @currentPoint = if point < 0 then 0 else if point > @maxPoint then @maxPoint else parseInt(point, 10)

      if @support.cssAnimation
        @helper.setStyle @el,
          transitionDuration: duration
      else
        @opts.useJsAnimate = true

      @_setX(- @currentPoint * @distance, duration)

      if (beforePoint isnt @currentPoint)
        @helper.triggerEvent(@el, "flpointmove", true, false)
        if @opts.loop then @_loop()

    _setX: (x, duration = @opts.transition["duration"]) ->
      @currentX = x

      if @support.cssAnimation and not @browser.isLegacy
        @helper.setStyle @el,
          transform: @_getTranslate(x)
      else if @opts.useJsAnimate
        @_jsAnimate(x, duration)
      else
        @el.style.left = "#{x}px"

    _touchStart: (event) ->
      if @opts.disableTouch or @gestureStart then return

      if @opts.loop
        if @currentPoint is @maxPoint
          @moveToPoint(1, 0)
        else if @currentPoint is 0
          @moveToPoint(@maxPoint - 1, 0)

      @el.addEventListener(@events.move,     @, false)
      document.addEventListener(@events.end, @, false)

      if not @events.touch then event.preventDefault()

      if @support.cssAnimation
        @helper.setStyle @el,
          transitionDuration: "0ms"
      else
        @opts.useJsAnimate = false

      @scrolling  = true
      @moveReady  = false

      @startPageX = @helper.getPage(event, "pageX")
      @startPageY = @helper.getPage(event, "pageY")
      @basePageX  = @startPageX

      @directionX = 0
      @startTime  = event.timeStamp

      @helper.triggerEvent(@el, "fltouchstart", true, false)

    _touchMove: (event) ->
      if @opts.autoPlay then @_clearAutoPlay() 
      if not @scrolling or @gestureStart then return

      pageX = @helper.getPage(event, "pageX")
      pageY = @helper.getPage(event, "pageY")

      if @moveReady
        event.preventDefault()
        event.stopPropagation()

        distX = pageX - @basePageX
        newX  = @currentX + distX

        if newX >= 0 or newX < @maxX then newX = Math.round(@currentX + distX / 3)

        @directionX = if distX is 0 then @directionX else if distX > 0 then -1 else 1
        isPrevent   = not @helper.triggerEvent @el, "fltouchmove", true, true,
          delta:     distX
          direction: @directionX

        if isPrevent
          @_touchAfter 
            moved:         false
            originalPoint: @currentPoint
            newPoint:      @currentPoint
            cancelled:     true
        else
          @_setX(newX)

      else
        deltaX = Math.abs(pageX - @startPageX)
        deltaY = Math.abs(pageY - @startPageY)

        if deltaX > 5
          event.preventDefault()
          event.stopPropagation()
          @moveReady = true
          @el.addEventListener("click", @, true)
        else if deltaY > 5
          @scrolling = false

      @basePageX = pageX
      if @opts.autoPlay then @_startAutoPlay()       

    _touchEnd: (event) ->
      @el.removeEventListener(@events.move, @, false)
      document.removeEventListener(@events.end, @, false)

      if not @scrolling then return

      newPoint = do =>
        point = -@currentX / @distance
        if @directionX > 0 then Math.ceil(point) else if @directionX < 0 then Math.floor(point) else Math.round(point)

      if newPoint < 0
        newPoint = 0
      else if newPoint > @maxPoint
        newPoint = @maxPoint

      @_touchAfter
        moved:         newPoint isnt @currentPoint
        originalPoint: @currentPoint
        newPoint:      newPoint
        cancelled:     false

      @moveToPoint(newPoint)

    _touchAfter: (params) ->
      @scrolling = false
      @moveReady = false

      global.setTimeout =>
        @el.removeEventListener("click", @, true)
      , 200

      @helper.triggerEvent(@el, "fltouchend", true, false, params)

    _click: (event) ->
      event.stopPropagation()
      event.preventDefault()

    _getTranslate: (x) ->
      if @opts.use3d then "translate3d(#{x}px, 0, 0)" else "translate(#{x}px, 0)"

    _cloneNode: ->
      childNodes = @el.childNodes
      itemAry    = []

      if not @opts.loop or @didCloneNode then return

      for node in childNodes
        if node.nodeType is 1 then itemAry.push(node)

      firstItem = itemAry.shift()
      lastItem  = itemAry.pop()

      @el.insertBefore(lastItem.cloneNode(true), firstItem)
      @el.appendChild(firstItem.cloneNode(true))

      @didCloneNode = true

    _startAutoPlay: ->
      if not @opts.autoPlay then return

      toNextFn = => @toNext()
      interval = @opts.interval

      do =>
        @timerId = global.setInterval(toNextFn, interval)

    _clearAutoPlay: ->
      global.clearInterval(@timerId)

    _setTotalWidth: ->
      childNodes = @el.childNodes
      itemAry    = if childNodes.length isnt 0 then [] else [@el]

      for node in childNodes
        if node.nodeType is 1 then itemAry.push(node)

      itemWidth  = @helper.getWidth(itemAry[0])
      totalWidth = itemWidth * itemAry.length 

      @el.style.width = "#{totalWidth}px"

    # 毎回コストかかってる感じなのでチューニングしたい
    _loop: ->
      lastPoint = @maxPoint - 1
      clearTime = @opts.interval / 2
      smartLoop = =>
        if @currentPoint is @maxPoint
          @moveToPoint(1, 0)
        else if (@currentPoint is 0)
          @moveToPoint(lastPoint, 0)
      transitionEndEventName = @helper.getTransitionEndEventName()

      if transitionEndEventName isnt undefined
        @el.addEventListener(transitionEndEventName, smartLoop, false)
        global.setTimeout =>
          @el.removeEventListener(transitionEndEventName, smartLoop, false)
        , clearTime
      else
        timerId = smartLoop
        global.clearTimeout ->
          smartLoop()
        , clearTime

    _jsAnimate: (x, duration = @opts.transition["duration"]) ->
      begin    = +new Date()
      from     = parseInt(@el.style.left, 10)
      to       = x
      duration = parseInt(duration, 10)
      easing   = (time, duration) ->
        -(time /= duration) * (time - 2)
      timer    = global.setInterval ->
        time = new Date() - begin

        if time > duration
          global.clearInterval(timer)
          now = to
        else
          pos = easing(time, duration)
          now = pos * (to - from) + from

        @el.style.left = "#{now}px"
      , 10

    destroy: ->
      @el.removeEventListener(@events.start, @, false)

  global.Flickable = Flickable
