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

      setStyle: (style, prop, val) ->
        _saveProp = @saveProp[prop]

        if _saveProp
          style[_saveProp] = val
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
          browser: browserName
          version: browserVersion
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
          touch:        "ontouchstart" of global
          transform3d:  hasTransform3d
          transform:    hasTransform
          transition:   hasTransition
          cssAnimation: do ->
            if hasTransform3d or hasTransform and hasTransition
              true
            else
              false
        }


