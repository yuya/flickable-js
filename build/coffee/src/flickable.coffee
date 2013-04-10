do (root = this, factory = (window, documentd) ->
  NS = "Flickable"

  class Helper
    constructor: ->
      @div      = document.createElement("div")
      @prefixes = ["webkit", "moz", "o", "ms"]
      @saveProp = {}

    getPage: (event, page) ->
      if event.changedTouches
        event.changedTouches[0][page]
      else
        event[page]

    hasProp: (props) ->
      if props instanceof Array
        for prop in props
          if @div.style[prop] isnt undefined then return true
        return false
      else if typeof props is "string"
        if @div.style[prop] isnt undefined then true else false
      else
        return null

    setStyle: (element, styles) ->
      style       = element.style
      hasSaveProp = @saveProp[prop]

      set = (style, prop, val) =>
        if hasSaveProp
          style[hasSaveProp] = val
        else if style[prop] isnt undefined
          @saveProp[prop] = prop
          style[prop]     = val
        else
          for prefix in @prefixes
            _prop = @ucFirst(prefix) + @ucFirst(prop)

            # @prefixes とマッチした
            if style[_prop] isnt undefined
              @saveProp[prop] = _prop
              style[_prop]    = val

              return true
          return false

      for prop of styles
        set(style, prop, styles[prop])

    getCSSVal: (prop) ->
      if typeof prop isnt "string"
        return null
      # transform とかデフォで対応してるんだったらそれを使う
      else if @div.style[prop] isnt undefined
        return prop
      # prefix つきじゃないとダメなら優しく prefix をつけてあげる
      else
        for prefix in @prefixes
          _prop = @ucFirst(prefix) + @ucFirst(prop)

          if @div.style[_prop] isnt undefined
            ret = "-#{prefix}-#{prop}"
        return ret

    ucFirst: (str) ->
      if typeof str is "string"
        str.charAt(0).toUpperCase() + str.substr(1)
      else
        return null

    triggerEvent: (element, type, bubbles, cancelable, data) ->
      event = document.createEvent("Event")
      event.initEvent(type, bubbles, cancelable)

      if data
        for d of data
          event[d] = data[d]

      element.dispatchEvent(event)

    checkBrowser: ->
      ua      = window.navigator.userAgent.toLowerCase()
      ios     = ua.match(/(?:iphone\sos|ip[oa]d.*os)\s([\d_]+)/)
      android = ua.match(/(android)\s+([\d.]+)/)

      # browserName = do ->
      #   if !!ios
      #     return "ios"
      #   else if !!android
      #     return "android"
      #   else
      #     return "pc"
      browserName    = if !!ios then "ios" else if !!android then "android" else "pc"
      browserVersion = do ->
        if not ios and not android then return null

        parseFloat((ios or android).pop().split(/\D/).join("."))

      return {
        name:     browserName
        version:  browserVersion
        isLegacy: !!android and browserVersion < 3
      }

    checkSupport: ->
      hasTransform3d = @hasProp([
          "perspectiveProperty"
          "WebkitPerspective"
          "MozPerspective"
          "msPerspective"
          "OPerspective"
      ])
      hasTransform = @hasProp([
          "transformProperty"
          "WebkitTransform"
          "MozTransform"
          "msTransform"
          "OTransform"
      ])
      hasTransition = @hasProp([
          "transitionProperty"
          "WebkitTransitionProperty"
          "MozTransitionProperty"
          "msTransitionProperty"
          "OTransitionProperty"
      ])

      return {
        touch:         "ontouchstart"     of window
        eventListener: "addEventListener" of window
        transform3d:   hasTransform3d
        transform:     hasTransform
        transition:    hasTransition
        cssAnimation: if hasTransform3d or hasTransform and hasTransition then true else false
      }
    checkEvents: ->
      hasTouch = @checkSupport.touch

      return {
        start: if hasTouch then "touchstart" else "mousedown"
        move:  if hasTouch then "touchmove"  else "mousemove"
        end:   if hasTouch then "touchend"   else "mouseup"
      }

  class Flickable
    constructor: (element, opts = {}) ->
      @el      = element
      @opts    = opts
      @helper  = new Helper()
      @browser = @helper.checkBrowser()
      @support = @helper.checkSupport()
      @events  = @helper.checkEvents()

      if typeof @el is "string"
        @el = document.querySelector(@el)
      else if not @el
        throw new Error("Element Not Found")

      # Set Options
      @distance     = @opts.distance or null
      @maxPoint     = @opts.maxPoint or null

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
        duration:       do =>
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

      @refresh()
      @el.addEventListener(@events.start, @, false)

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
      @maxPoint = do =>
        if @maxPoint is null
          childNodes = @el.childNodes
          itemLength = 0

          for node, i in childNodes
            if node.nodeType is 1 then itemLength++

          if itemLength > 0 then itemLength--

          return itemLength
        else
          @maxPoint
      @distance = if @distance is null then @el.scrollWidth / (@maxPoint + 1) else @distance
      @maxX     = "-#{@distance * @maxPoint}"

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

      @_setX(- @currentPoint * @distance, duration)

      if (beforePoint isnt @currentPoint)
        @helper.triggerEvent(@el, "flpointmove", true, false)

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

      @el.addEventListener(@events.move,     @, false)
      document.addEventListener(@events.end, @, false)

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
        newX  = @currentX + distX

        if newX >= 0 or newX < @maxX then newX = Math.round(@currentX + distX / 3)

        @directionX = if distX is 0 then @directionX else if distX > 0 then -1 else 1
        isPrevent   = not @helper.triggerEvent(@el, "fltouchmove", true, true,
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

      window.setTimeout =>
        @el.removeEventListener("click", @, true)
      , 200

      @helper.triggerEvent(@el, "fltouchend", true, false, params)

    _click: (event) ->
      event.stopPropagation()
      event.preventDefault()

    _getTranslate: (x) ->
      if @opts.use3d then "translate3d(#{x}px, 0, 0)" else "translate(#{x}px, 0)"

    _jsAnimate: (x, duration = @opts.transition["duration"]) ->
      begin    = +new Date()
      from     = parseInt(@el.style.left, 10)
      to       = x
      duration = parseInt(duration, 10)
      easing   = (time, duration) ->
        "-#{(time /= duration) * (time - 2)}"
      timer    = setInterval ->
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
      @el.removeEventListener(@events.start, @, false)

  window["Helper"] = Helper
  window[NS]       = Flickable

) ->
  # AMD
  if typeof define is "function" and define.amd
    define(NS, [], ->
      factory(root, root.document)
      root[NS]
    )
  # Browser global scope
  else
    factory(root, root.document)