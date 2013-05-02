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
        return
      else if style[prop] isnt undefined
        @saveProp[prop] = prop
        style[prop]     = val
        return
      else
        for prefix in @prefixes
          _prop = @ucFirst(prefix) + @ucFirst(prop)

          # @prefixes とマッチしたら
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
    hasTouch = @checkSupport().touch

    return {
      start: if hasTouch then "touchstart" else "mousedown"
      move:  if hasTouch then "touchmove"  else "mousemove"
      end:   if hasTouch then "touchend"   else "mouseup"
    }

  getDeviceWidth: ->
    window.innerWidth

  # インライン属性で定義された幅の取得がザルでござる〜
  # てか 要素の幅の取得、全パターン網羅するのってエグエグなんだなぁ〜
  # あー jQuery つかいたい jQuery 最高! 天才! ジーニアス! 頭いい
  getElementWidth: (element) ->
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
      return width
    # else if hasBoxSizing and boxSizingVal is "border-box" or not hasBoxSizing
    else if element.scrollWidth is 0
      width = parseFloat(element.style.width.match(/\d+/), 10)

      if not element.style.boxSizing or not element.style.webkitBoxSizing
        if element.style.paddingRight then width += parseFloat(element.style.paddingRight.match(/\d+/), 10)
        if element.style.paddingLeft  then width += parseFloat(element.style.paddingLeft.match(/\d+/), 10)

      return width
    else
      width = element.scrollWidth
      return width

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
        return "webkitTransitionEnd"
      when "opera"
        return "oTransitionEnd"
      when "firefox", "modernIE"
        return "transitionend"
      else
        return undefined

window.Flickable.Helper = Helper
