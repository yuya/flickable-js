do (global = this, document = this.document) ->
  "use strict"

  class Flickable
    constructor: (el, opts = {}) ->
      @el = el

      if typeof @el is "string"
        @el = document.querySelector(el)
      else if not @el
        throw new Error("Element Not Found")

      isTouch = 'ontouchstart' in global
      touchStartEvent = if isTouch then "touchstart" else "mousedown"
      touchMoveEvent  = if isTouch then "touchmove" else "mousemove"
      touchEndEvent   = if isTouch then "touchend" else "mouseup"

      # Set Options
      opts = opts || {}
      @distance = if not opts.distance then null else opts.distance
      @maxPoint = if not opts.maxPoint then null else opts.maxPoint

      opts.transition = opts.transition || {}
      @transition =
        duration: if not opts.transition["duration"] then "330ms" else opts.transition["duration"]
        timingFunction: if not opts.transition["timingFunction"] then "cubic-bezier(0, 0, 0, 0.25, 1)" else opts.transition["timingFunction"]

      @currentPoint = 0
      @currentX = 0

      @el.addEventListener(touchStartEvent, @, false)

      return @

    handleEvent: (event) ->
      switch event.typeof
        when touchStartEvent
          @_touchStart(event)
        when touchMoveEvent
          @_touchMove(event)
        when touchEndEvent
          @_touchEnd(event)
        when "click"
          @_click(event)

    refresh: ->

    _touchStart: (event) ->

    _touchMove: (event) ->

    _touchEnd: (event) ->

    _click: (event) ->
      event.stopPropagation()
      event.preventDefault()

      return


  global.Flickable = Flickable



