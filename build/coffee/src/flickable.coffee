do (root = this, factory = (window, document) ->
  NS = "Flickable"

  class Helper
    constructor: ->
      @div      = document.createElement("div")
      @prefixes = ["webkit", "moz", "o", "ms"]
      @saveProp = {}

    getPage: (event, page) ->
      if event.changedTouches then event.changedTouches[0][page] else event[page]

    hasProp: (props) ->
      if props instanceof Array
        for prop in props
          if @div.style[prop] isnt undefined then return true
        return false
      else if typeof props is "string"
        if @div.style[prop] isnt undefined then true else false
      else
        throw new TypeError("Must be a Array or String")

    setStyle: (element, styles) ->
      style       = element.style
      hasSaveProp = @saveProp[prop]

      _setAttr = (style, prop, val) =>
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
        _setAttr(style, prop, styles[prop])

    getCSSVal: (prop) ->
      if typeof prop isnt "string" then throw new TypeError("Must be a String")

      # transform とかデフォで対応してるんだったらそれを使う
      if @div.style[prop] isnt undefined
        return prop
      # prefix つきじゃないとダメなら優しく prefix をつけてあげる
      else
        for prefix in @prefixes
          _prop = @ucFirst(prefix) + @ucFirst(prop)

          if @div.style[_prop] isnt undefined
            ret = "-#{prefix}-#{prop}"
        return ret

    ucFirst: (str) ->
      if typeof str isnt "string" then throw new TypeError("Must be a String")
      str.charAt(0).toUpperCase() + str.substr(1)

    triggerEvent: (element, type, bubbles, cancelable, data) ->
      if typeof element isnt "object" then throw new Error("Must be a Element")

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

      browserName    = if !!ios then "ios" else if !!android then "android" else "pc"
      browserVersion = do ->
        if not ios and not android then return null

        parseFloat((ios or android).pop().split(/\D/).join("."), 10)

      return {
        name:     browserName
        version:  browserVersion
        isLegacy: !!android and browserVersion < 3
      }

    checkSupport: ->
      hasTransform3d = @hasProp [
        "perspectiveProperty"
        "WebkitPerspective"
        "MozPerspective"
        "msPerspective"
        "OPerspective"
      ]
      hasTransform = @hasProp [
        "transformProperty"
        "WebkitTransform"
        "MozTransform"
        "msTransform"
        "OTransform"
      ]
      hasTransition = @hasProp [
        "transitionProperty"
        "WebkitTransitionProperty"
        "MozTransitionProperty"
        "msTransitionProperty"
        "OTransitionProperty"
      ]

      return {
        touch:         "ontouchstart"     of window
        eventListener: "addEventListener" of window
        transform3d:   hasTransform3d
        transform:     hasTransform
        transition:    hasTransition
        cssAnimation: if hasTransform3d or hasTransform and hasTransition then true else false
      }

    checkTouchEvents: ->
      hasTouch = @checkSupport.touch

      return {
        start: if hasTouch then "touchstart" else "mousedown"
        move:  if hasTouch then "touchmove"  else "mousemove"
        end:   if hasTouch then "touchend"   else "mouseup"
      }
 
    # インライン属性で定義された幅の取得がザルでござる〜
    # てか 要素の幅の取得、全パターン網羅するのってエグエグなんだなぁ〜
    # あー jQuery つかいたい jQuery 最高! 天才! ジーニアス! 頭いい
    getWidth: (element) ->
      if element is undefined then throw new Error("Element Not Found")

      css          = window.getComputedStyle(element)
      boxSizingVal = undefined 
      hasBoxSizing = do ->
        properties = [
          "-webkit-box-sizing"
          "-moz-box-sizing"
          "-o-box-sizing"
          "-ms-box-sizing"
          "box-sizing"
        ]

        for prop in properties
          if element.style[prop] isnt undefined
            boxSizingVal = element.style[prop]
            return true
        return false

      # if not css["width"]
      #   width = parseFloat(element.style.width.match(/\d+/), 10)
      # else if not hasBoxSizing or boxSizingVal is "content-box"
      if not hasBoxSizing or boxSizingVal is "content-box"
        styleParser = (props) ->
          value = []
          total = 0

          for prop, i in props
            if css[prop]
              value[i] = parseFloat(css[props[0]].match(/\d+/), 10)
              total += value[i]

          return total

        border  = styleParser(["border-right-width", "border-left-width"])
        padding = styleParser(["padding-right",      "padding-left"])
        width   = element.scrollWidth + border + padding;
      # else if hasBoxSizing and boxSizingVal is "border-box" or not hasBoxSizing
      else if element.scrollWidth is 0
        width = parseFloat(element.style.width.match(/\d+/), 10)

        if not element.style.boxSizing or not element.style.webkitBoxSizing
          if element.style.paddingRight then width += parseFloat(element.style.paddingRight.match(/\d+/), 10)
          if element.style.paddingLeft  then width += parseFloat(element.style.paddingLeft.match(/\d+/), 10)

        return width
      else
        width = element.scrollWidth

    getTranslate: (use3d = true, x, y = 0, z = 0) ->
      if @opts.use3d then "translate3d(#{x}px, 0, 0)" else "translate(#{x}px, 0)"

    # ブラウザのバージョンによって正しいのが取得できなかったりしそうな不安感たっぷりのメソッドである
    # なのでもうちょっといい方法あればそれにしたい
    getTransitionEndEventName: ->
      ua       = window.navigator.userAgent.toLowerCase()
      match    = /(webkit)[ \/]([\w.]+)/.exec(ua)  or
                 /(firefox)[ \/]([\w.]+)/.exec(ua) or
                 /(msie) ([\w.]+)/.exec(ua)        or
                 /(opera)(?:.*version|)[ \/]([\w.]+)/.exec(ua) or []
      browser  = match[1]
      version  = parseFloat(match[2], 10)

      if browser is "msie" and version >= 10 then browser = "modernIE"

      switch browser 
        when "webkit"
          transitionEndName = "webkitTransitionEnd"
        when "opera"
          transitionEndName = "oTransitionEnd"
        when "firefox", "modernIE"
          transitionEndName = "transitionend"
        else
          transitionEndName = undefined

  class Flickable
    constructor: (element, opts = {}) ->
      @el      = element
      @opts    = opts
      @helper  = new Helper()
      @browser = @helper.checkBrowser()
      @support = @helper.checkSupport()
      @events  = @helper.checkTouchEvents()

      if typeof @el is "string"
        @el = document.querySelector(@el)
      else if not @el
        throw new Error("Element Not Found")


      # Set Options
      @currentPoint = @currentX = @maxX = 0
      @gestureStart = @didCloneNode = false

      @distance  = @maxPoint   = @timerId    = @scrolling =
      @moveReady = @startPageX = @startPageY = @basePageX = @startTime = null

      @opts.use3d        = if @opts.disable3d then false else @support.transform3d
      @opts.useJsAnimate = false
      @opts.disableTouch = @opts.disableTouch or false
      @opts.disable3d    = @opts.disable3d    or false

      @opts.autoPlay     = @opts.autoPlay     or false
      # @opts.interval     = @opts.interval     or 6600
      # @opts.interval     = @opts.interval     or 500
      @opts.interval     = @opts.interval     or 2500
      @opts.loop         = @opts.loop         or if @opts.autoPlay then true else false

      @opts.transition   = @opts.transition   or {}
      @opts.transition   =
        timingFunction: @opts.transition["timingFunction"] or "cubic-bezier(0.23, 1, 0.32, 1)"
        duration:       do =>
          @opts.transition["duration"] or if @browser.isLegacy then "200ms" else "330ms"

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

      @maxPoint = if @opts.maxPoint is undefined then getMaxPoint() else @opts.maxPoint
      @distance = if @opts.distance is undefined then @el.scrollWidth / (@maxPoint + 1) else @opts.distance
      @maxX     = -@distance * @maxPoint

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
        @timerId = window.setInterval(toNextFn, interval)

    _clearAutoPlay: ->
      # timerId = @timerId
      window.clearInterval(@timerId)

    tmpClearAutoPlay: ->
      timerId = @timerId
      window.clearInterval(timerId)

    _setTotalWidth: ->
      childNodes = @el.childNodes
      itemAry    = []

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
        window.setTimeout =>
          @el.removeEventListener(transitionEndEventName, smartLoop, false)
        , clearTime
      else
        timerId = smartLoop
        window.clearTimeout ->
          smartLoop()
        , clearTime

    _jsAnimate: (x, duration = @opts.transition["duration"]) ->
      begin    = +new Date()
      from     = parseInt(@el.style.left, 10)
      to       = x
      duration = parseInt(duration, 10)
      easing   = (time, duration) ->
        -(time /= duration) * (time - 2)
      timer    = window.setInterval ->
        time = new Date() - begin

        if time > duration
          window.clearInterval(timer)
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
  if typeof define is "function" and define.amd is "object"
    define(NS, [], ->
      factory(root, root.document)
      root[NS]
    )
  # Browser global scope
  else
    factory(root, root.document)