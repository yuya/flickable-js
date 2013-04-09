define ->
  do (global = this, document = this.document) ->
    class Helper
      constructor: ->
        @div = document.createElement("div")
        @prefixes = ["webkit", "moz", "o", "ms"]
        @saveProp = {}

      getPage: (event, page) ->
        # タッチイベントがある
        if event.changedTouches
          event.changedTouches[0][page]
        # タッチイベントがない
        else
          event[page]

      hasProp: (props) ->
        if props instanceof Array
          for prop in props
            @div.style[prop] isnt undefined
        else
          return null

      setStyle: (style, prop, val) ->
        _saveProp = @saveProp[prop]

        if _saveProp
          style[_saveProp] = val
        else if style[prop] isnt undefined
          saveProp[prop] = prop
          style[prop] = val
        else
          for prefix in @prefixes
            _prop = @ucFirst(prefix) + @ucFirst(prop)

            if style[_prop] isnt undefined
              @saveProp[prop] = _prop
              style[_prop] = val

              return true

      getCSSVal: (prop) ->
        if typeof prop isnt "string"
          return null
        # transform とかデフォで対応してるんだったらそれを使う
        else if @div.style[prop] isnt undefined
          return prop
        # prefix つきじゃないとダメなら優しく prefix つけてあげる
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


