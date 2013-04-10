define ->
  do (global = this, document = this.document) ->
    "use strict"

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
          if @div.style[prop] isnt undefined
            return true
          else
            return false
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
            style[prop] = val
          else
            for prefix in @prefixes
              _prop = @ucFirst(prefix) + @ucFirst(prop)

              # @prefixes とマッチした
              if style[_prop] isnt undefined
                @saveProp[prop] = _prop
                style[_prop] = val

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
        event = document.createElement("Event")
        event.initEvent(type, bubbles, cancelable)

        if data
          for d of data
            event[d] = data[d]

        element.dispatchEvent(event)

      checkBrowser: ->
        ua      = global.navigator.userAgent.toLowerCase()
        ios     = ua.match(/(?:iphone\sos|ip[oa]d.*os)\s([\d_]+)/)
        android = ua.match(/(android)\s+([\d.]+)/)

        browserName = do ->
          if !!ios
            return "ios"
          else if !!android
            return "android"
          else
            return "pc"

        browserVersion = do ->
          if not ios and not android then return null

          version = (ios or android).pop().split(/\D/).join(".")
          return parseFloat(version)

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
          touch:         "ontouchstart" of global
          eventListener: "addEventListener" of global
          transform3d:   hasTransform3d
          transform:     hasTransform
          transition:    hasTransition
          cssAnimation:  do ->
            if hasTransform3d or hasTransform and hasTransition
              true
            else
              false
        }
      checkTouchEvents: ->
        hasTouch = @checkSupport.touch

        return {
          touchStart: if hasTouch then "touchstart" else "mousedown"
          touchMove:  if hasTouch then "touchmove"  else "mousemove"
          touchEnd:   if hasTouch then "touchend"   else "mouseup"
        }
