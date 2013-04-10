define [
  "../src/helper"
], (Helper) ->
  do (global = this, document = this.document) ->
    "use strict"

    class Flickable
      constructor: (element, opts = {}) ->
        @el      = element
        @helper  = new Helper()
        @browser = @helper.checkBrowser()
        @support = @helper.checkSupport()
        @events  = @helper.checkTouchEvents()

        if typeof @el is "string"
          @el = document.querySelector(el)
        else if not @el
          throw new Error("Element Not Found")

        # Set Options
        @distance = if not opts.distance then null else opts.distance
        @maxPoint = if not opts.maxPoint then null else opts.maxPoint

        opts.transition = opts.transition || {}
        @transition =
          duration: if not opts.transition["duration"] then "330ms" else opts.transition["duration"]
          timingFunction: if not opts.transition["timingFunction"] then "cubic-bezier(0, 0, 0, 0.25, 1)" else opts.transition["timingFunction"]

        @currentPoint = 0
        @currentX = 0

        @el.addEventListener(@events.touchStart, @, false)

        return @

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

      destroy: ->
        @el.removeEventListener(@events.touchStart, @, false)

      _touchStart: (event) ->

      _touchMove: (event) ->

      _touchEnd: (event) ->

      _click: (event) ->
        event.stopPropagation()
        event.preventDefault()
