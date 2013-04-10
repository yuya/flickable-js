define [
  "../src/helper"
], (Helper) ->
  do (global = this, document = this.document) ->
    "use strict"

    class Flickable
      constructor: (element, opts = {}) ->
        @el      = element
        @opts    = opts
        @helper  = new Helper()
        @browser = @helper.checkBrowser()
        @support = @helper.checkSupport()
        @events  = @helper.checkTouchEvents()

        if typeof @el is "string"
          @el = document.querySelector(el)
        else if not @el
          throw new Error("Element Not Found")

        # Set Options
        @distance     = @opts.distance or null
        @maxPoint     = @opts.maxPoint or null

        # @currentPoint = 0
        # @currentX     = 0
        # @maxX         = 0

        # @scrolling    = null
        # @moveReady    = null
        # @startPageX   = null
        # @startPageY   = null
        # @basePageX    = null
        # @startTime    = null

        @currentPoint = @currentX  = @maxX       = 0
        @scrolling    = @moveReady = @startPageX = @startPageY = @basePageX = @startTime = null
        @gestureStart = false

        @opts.use3d        = if @opts.disable3d then false else @support.transform3d
        @opts.useJsAnimate = false

        @opts.disableTouch = @opts.disableTouch or false
        @opts.disable3d    = @opts.disable3d    or false

        @opts.transition   = @opts.transition   or {}
        @opts.transition   =
          timingFunction: @opts.transition["timingFunction"] or "cubic-bezier(0.23, 1, 0.32, 1)"
          duration:       do ->
            @opts.transition["duration"] or if @browser.isLegacy then "200ms" else "330ms"

        if @support.cssAnimation
          @helper.setStyle(@el,
            transitionProperty:       @helper.getCSSVal("transform")
            transitionDuration:       "0ms"
            transitionTimingFunction: @opts.transition["timingFunction"]
            transform:                @_getTranslate(0)
          )
        else
          @helper.setStyle(@el,
            position: "relative"
            left:     "0px"
          )

        if @support.eventListener
          document.addEventListener "gesturestart", => @gestureStart = true
          document.addEventListener "gestureend",   => @gestureStart = false

        @el.addEventListener(@events.touchStart, @, false)
        @refresh()

      handleEvent: (event) ->
        switch event.typeof
          when @events.touchStart
            @_touchStart(event)
          when @events.touchMove
            @_touchMove(event)
          when @events.touchEnd
            @_touchEnd(event)
          when "click"
            @_click(event)

      refresh: ->
        @maxPoint = do =>
          if @maxPoint is null
            childNodes = @el.childNodes
            itemLength = 0

            for node in childNodes
              if node.nodeType is 1 then itemLength++

            if itemLength > 0 then itemLength--
          else
            @maxPoint
        @distance = do =>
          if @distance is null
            @el.scrollWidth / (@maxPoint + 1)
          else
            @distance
        @maxX = "-#{@distance * @maxPoint}"

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
        beforePoint = @currentPoint

        if point < 0
          @currentPoint = 0
        else if point > @maxPoint
          @currentPoint = @maxPoint
        else
          @currentPoint = parseInt(point, 10)

        if @support.cssAnimation
          @helper.setStyle(@el,
            transitionDuration: duration
          )
        else
          @opts.useJsAnimate = true

        @_setX("-#{@currentPoint * @distance}", duration)

        # TODO: ここに moveend 的なカスタムイベントを発火させる処理

      _setX: (x, duration = @opts.transition["duration"]) ->
        @currentX = x

        if @support.cssAnimation
          @helper.setStyle(@el,
            transform: @_getTranslate(x)
          )
        else if @opts.useJsAnimate
          @_jsAnimate(x, duration)
        else
          @el.style.left = "#{x}px"

      _touchStart: (event) ->
        if @opts.disableTouch or @gestureStart then return

        @el.addEventListener(@events.touchMove,     @, false)
        document.addEventListener(@events.touchEnd, @, false)

        if not @events.touch then event.preventDefault()

        if @support.cssAnimation
          @helper.setStyle(@el,
            transitionDuration: "0ms"
          )
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
        if not @scrolling or @gestureStart then return

        pageX = @helper.getPage(event, "pageX")
        pageY = @helper.getPage(event, "pageY")

        if @moveReady
          event.preventDefault()
          event.stopPropagation()

          distX = pageX - @basePageX
          newX = @currentX + distX

          if newX >= 0 or newX < @maxX then newX = Math.round(@currentX + distX / 3)

          @directionX = do =>
            if distX is 0
              @directionX
            else
              if distX > 0 then -1 else 1

          isPrevent = not helper.triggerEvent(@el, "fltouchmove", true, true,
            delta:     distX
            direction: @directionX
          )

          if isPrevent
            @_touchAfter(
              moved:         false
              originalPoint: @currentPoint
              newPoint:      @currentPoint
              cancelled:     true
            )
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

      _touchEnd: (event) ->
        @el.removeEventListener(@events.touchMove, @, false)
        document.removeEventListener(@events.touchEnd, @, false)

        if not @scrolling then return

        newPoint = do =>
          point = -@currentX / @distance

          if @directionX > 0
            Math.ceil(point)
          else if @directionX < 0
            Math.floor(point)
          else
            Math.round(point)

        if newPoint < 0
          newPoint = 0
        else if newPoint > @maxPoint
          newPoint = @maxPoint

        @_touchAfter(
          moved:         newPoint isnt @currentPoint
          originalPoint: @currentPoint
          newPoint:      newPoint
          cancelled:     false
        )

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

      _jsAnimate: (x, duration = @opts.transition["duration"]) ->
        begin = +new Date()
        from = parseInt(@el.style.left, 10)
        to = x
        duration = parseInt(duration, 10)
        easing = (time, duration) ->
          "-#{(time /= duration) * (time - 2)}"
        timer = setInterval ->
          time = new Date() - begin

          if time > duration
            clearInterval(timer)
            now = to
          else
            pos = easing(time, duration)
            now = pos * (to - from) + from

          @el.style.left = "#{now}px"
        , 10

      destroy: ->
        @el.removeEventListener(@events.touchStart, @, false)
