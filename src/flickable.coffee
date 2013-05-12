namespace "Flickable", -> class Core

  helper = new Flickable.Helper()

  constructor: (element, options, callback) ->
    if not element
      throw new Error("Element Not Found")
    else if typeof element is "object" and element.length
      element = element[0]

    @el      = if typeof element is "string" then document.querySelector(element) else element
    @opts    = options or {}
    @helper  = helper
    @browser = @helper.checkBrowser()
    @support = @helper.checkSupport()
    @events  = @helper.checkTouchEvents()

    # Set Options
    @opts.use3d        = if @opts.disable3d then false else @support.transform3d
    @opts.useJsAnimate = false
    @opts.disableTouch = @opts.disableTouch or false
    @opts.disable3d    = @opts.disable3d    or false
    @opts.setWidth     = @opts.setWidth     or true
    @opts.fitWidth     = @opts.fitWidth     or false
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
    @maxPoint     = @currentX   = @maxX                       = 0
    @gestureStart = @moveReady  = @scrolling  = @didCloneNode = false
    @startTime    = @timerId    =
    @basePageX    = @startPageX = @startPageY = @distance     = null

    if @support.cssAnimation and not @browser.isLegacy
      @helper.setStyle @el,
        transitionProperty:       @helper.getCSSVal("transform")
        transitionDuration:       "0ms"
        transitionTimingFunction: @opts.transition["timingFunction"]
        transform:                @_getTranslate(0)
    else if @browser.isLegacy
      @helper.setStyle @el,
        position:                 "relative"
        left:                     "0px"
        transitionProperty:       "left"
        transitionDuration:       "0ms"
        transitionTimingFunction: @opts.transition["timingFunction"]
    else
      @helper.setStyle @el,
        position: "relative"
        left:     "0px"

    if @support.eventListener
      document.addEventListener "gesturestart", =>
        @gestureStart = true
        return
      , false
      document.addEventListener "gestureend",   =>
        @gestureStart = false
        return
      , false

    if @opts.autoPlay
      @_startAutoPlay()
      window.addEventListener "blur",  =>
        @_clearAutoPlay()
      , false
      window.addEventListener "focus", =>
        @_startAutoPlay()
      , false

    if @opts.fitWidth
      eventName = if @browser.name is "pc" then "resize" else "orientationchange"
      window.addEventListener eventName, =>
        @refresh()
      , false

    @el.addEventListener(@events.start, @, false)

    if @opts.loop then @_cloneNode()

    # 任意の callback を実行
    if callback and typeof callback isnt "function"
      throw new TypeError("Must be a Function")
    else if callback
      callback()

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
    if @opts.fitWidth
      @_setTotalWidth(@helper.getDeviceWidth())
    else if @opts.setWidth
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
    unless @hasPrev() then return
    @moveToPoint(@currentPoint - 1)

  toNext: ->
    unless @hasNext() then return
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
    else if @browser.isLegacy or not @otps.useJsAnimate
      @el.style.left = "#{x}px"
      return
    else
      @_jsAnimate(x, duration)

  _touchStart: (event) ->
    if @opts.disableTouch or @gestureStart then return

    if @opts.loop
      if @currentPoint is @maxPoint
        @moveToPoint(1, 0)
      else if @currentPoint is 0
        @moveToPoint(@maxPoint - 1, 0)

    @el.addEventListener(@events.move,     @, false)
    document.addEventListener(@events.end, @, false)

    unless @support.touch then event.preventDefault()

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
    unless @scrolling or @gestureStart then return

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

    unless @scrolling then return

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

    unless @opts.loop or @didCloneNode then return

    for node in childNodes
      if node.nodeType is 1 then itemAry.push(node)

    firstItem = itemAry.shift()
    lastItem  = itemAry.pop()

    @el.insertBefore(lastItem.cloneNode(true), firstItem)
    @el.appendChild(firstItem.cloneNode(true))

    @didCloneNode = true
    return

  _startAutoPlay: ->
    unless @opts.autoPlay then return

    toNextFn = => @toNext()
    interval = @opts.interval

    do =>
      @timerId = window.setInterval(toNextFn, interval)
      return

  _clearAutoPlay: ->
    window.clearInterval(@timerId)

  _setTotalWidth: (width) ->
    if width and typeof width isnt "number" then throw new TypeError("Must be a Number")

    childNodes = @el.childNodes
    itemAry    = if childNodes.length isnt 0 then [] else [@el]

    for node in childNodes
      if node.nodeType is 1 then itemAry.push(node)

    itemWidth  = if width then width else @helper.getElementWidth(itemAry[0])
    totalWidth = itemAry.length * itemWidth

    @el.style.width = "#{totalWidth}px"
    return

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

  _jsAnimate: (x, duration) ->
    begin    = +new Date()
    from     = parseInt(@el.style.left, 10)
    to       = x
    duration = parseInt(duration, 10) or @opts.transition["duration"]
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
      return
    , 10

    return

  destroy: ->
    if @opts.autoPlay
      @_clearAutoPlay()

    @el.removeEventListener(@events.start, @, false)

window.Flickable = Flickable.Core
