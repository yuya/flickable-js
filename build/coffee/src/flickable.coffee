define [
  "../src/helper"
], (Helper) ->
  do (global = this, document = this.document) ->
    "use strict"

    class Flickable
      constructor: (el, opts = {}) ->
        @el = el
        @helper = new Helper()
        @support = @helper.checkSupport()
        @events =
          touchStart: if @support.touch then "touchstart" else "mousedown"
          touchMove: if @support.touch then "touchmove" else "mousemove"
          touchEnd: if @support.touch then "touchend" else "mouseup"

        console.log @support.touch
        console.log @support.transform3d

        if typeof @el is "string"
          @el = document.querySelector(el)
        else if not @el
          throw new Error("Element Not Found")

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

        @el.addEventListener(@events.touchStart, @, false)

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

      _checkSupport: ->
        hasTransform3d = @helper.hasProp([
            "perspectiveProperty"
            "WebkitPerspective"
            "MozPerspective"
            "msPerspective"
            "OPerspective"
        ])
        hasTransform = @helper.hasProp([
            "transformProperty"
            "WebkitTransform"
            "MozTransform"
            "msTransform"
            "OTransform"
        ])
        hasTransition = @helper.hasProp([
            "transitionProperty"
            "WebkitTransitionProperty"
            "MozTransitionProperty"
            "msTransitionProperty"
            "OTransitionProperty"
        ])

        return {
            touch: "ontouchstart" of global
            transform3d: hasTransform3d
            transform: hasTransform
            transition: hasTransition
            cssAnimation: do ->
              if hasTransform3d or hasTransform and hasTransition
                true
              else
                false
        }
