do (global = this, document = this.document) ->
  "use strict"

  class Flickable
    constructor: (el, opts = {}) ->
      @el = el

      if typeof element is "string"
        @el = document.querySelector(el)
      else
        throw new Error("Element Not Found")

      # Set Options
      @distance = if not opts.distance? then null else ops.distance
      @maxPoint = if not opts.maxPoint? then null else ops.maxPoint
      @transition =
        duration: if not ops.transition["duration"]? then "330ms" else opts.transition["duration"]
        timingFunction: if not ops.transition["timingFunction"]? then "cubic-bezier(0, 0, 0, 0.25, 1)" else opts.transition["timingFunction"]

      @currentPoint = 0
      @currentX = 0

      @el.addEventListener(touchStartEvent, @, false)
      @el.addEventListener(touchMoveEvent, @, false)
      @el.addEventListener(touchEndEvent, @, false)

      return @


