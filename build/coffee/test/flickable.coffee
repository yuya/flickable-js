"use strict"
expect = chai.expect

describe "Helper Class", ->
  helper = new Helper()

  describe ".getPage()", ->
    el = $("<div>")
    moveEvent = if "ontouchstart" in window then "touchmove" else "mousemove"

    it "click イベントが発火しただけだし pageX は 0 が返ってくる", ->
      el.on "click", (event) ->
        expect(helper.getPage(event, "pageX")).to.equal(0)
      el.click()
    it "#{moveEvent} イベントが発火しただけだし pageY は 0 が返ってくる", ->
      el.on moveEvent, (event) ->
        expect(helper.getPage(event, "pageY")).to.equal(0)
      el.click()
    it "全く関係ない load イベントとかで取得しようとしても undefined とかじゃね シラネ", ->
      evt = document.createEvent("Event")
      evt.initEvent("load", false, false)

      expect(helper.getPage(evt, "pageX")).to.be.a("undefined")

  describe ".hasProp()", ->
    it "先行実装な CSS Property の配列を渡すと存在するかチェケラする。今どき transform ならあるよね", ->
      props = [
        "transformProperty"
        "WebkitTransform"
        "MozTransform"
        "OTransform"
        "msTransform"
      ]
      expect(helper.hasProp(props)).to.be.true

    it "svgMatrixZ とかいうイミフな String を渡したら当然 false が返ってくる", ->
      prop = "svgMatrixZ"
      expect(helper.hasProp(prop)).to.be.false
    it "Array でも String でもないのを渡されても困るので TypeError を投げる", ->
      (expect -> helper.hasProp(undefined)).to.throw(TypeError)

  describe ".setStyle()", ->
    el = document.createElement("div")

    beforeEach (done) ->
      el.removeAttribute("style")
      helper.saveProp = {}
      done()

    it ("display: none; を追加したから style=\"diplay: none;\" ってなってるはず"), ->
      helper.setStyle(el,
        display: "block"
      )
      expect(el.getAttribute("style")).to.equal("display: block;")
    it ("プロパティ複数指定したら、指定した順番に style 属性に入ってるはず"), ->
      helper.setStyle(el,
        display: "none"
        width: "100px"
        height: "100px"
        margin: "0px auto"
      )
      expect(el.getAttribute("style")).to.equal("display: none; width: 100px; height: 100px; margin: 0px auto;")
    it ("prefix が必要なやつはプロパティはよしなに prefix つけて、よしなに纏めてくれるはず"), ->
      helper.setStyle(el,
        width: "100px"
        height: "100px"
        transform: "translate(0, 0)"
        transitionTimingFunction: "ease"
        transitionDuration: "0ms"
      )
      expect(el.getAttribute("style")).to.equal("width: 100px; height: 100px; -webkit-transform: translate(0, 0); transition: 0ms ease; -webkit-transition: 0ms ease;")

  describe ".getCSSVal()", ->
    it "仮に webkit だとしたら、transform を入れると \"-webkit-transform\" が返ってくる", ->
      expect(helper.getCSSVal("transform")).to.be.a("string")
      expect(helper.getCSSVal("transform")).to.equal("-webkit-transform")
    it "width とか prefix なしで余裕なプロパティいれるとありのまま木の実ナナで返ってくる", ->
      expect(helper.getCSSVal("width")).to.be.a("string")
      expect(helper.getCSSVal("width")).to.equal("width")
    it "うっかり配列とか入れたら TypeError 投げつけて激おこプンプン丸", ->
      (expect -> helper.getCSSVal([1..3])).to.throw(TypeError)

  describe ".ucFirst()", ->
    it "\"webkitTransform\" とか渡すと \"WebkitTransform\" で返ってくる", ->
      expect(helper.ucFirst("webkitTransform")).to.be.a("string")
      expect(helper.ucFirst("webkitTransform")).to.equal("WebkitTransform")
    it "String だけどアルファベットじゃない君 (\"123\") はありのままの君", ->
      expect(helper.ucFirst("123")).to.be.a("string")
      expect(helper.ucFirst("123")).to.equal("123")
    it "String じゃないものだったら TypeError 投げる", ->
      (expect -> helper.ucFirst([1..3])).to.throw(TypeError)

  describe ".triggerEvent()", ->
    el = document.createElement("div")

    it "hoge イベントでも意味なく発火させてみる", ->
      eventName = "hoge"
      @event    = null
      firedFlag = false

      el.addEventListener eventName, (event) =>
        @event    = event
        firedFlag = true
      , false
      helper.triggerEvent(el, eventName, true, false)

      expect(@event.type).to.equal(eventName)
      expect(@event.bubbles).to.be.true
      expect(@event.cancelable).to.be.false
      expect(@event.data).to.be.a("undefined")
      expect(firedFlag).to.be.true

    it "event 発火と同時にひっさげた data がちゃんと取得できるかな", ->
      eventName = "dataTest"
      @event    = null
      firedFlag = false

      el.addEventListener eventName, (event) =>
        @event    = event
        firedFlag = true
      , false
      helper.triggerEvent el, eventName, true, false,
        id: 300
        name: "山田太郎"
        hasYaruki: null

      expect(@event.type).to.equal(eventName)
      expect(@event.bubbles).to.be.true
      expect(@event.cancelable).to.be.false

      expect(@event.id).to.equal(300)
      expect(@event.name).to.equal("山田太郎")
      expect(@event.hasYaruki).to.be.null

      expect(firedFlag).to.be.true

    it "対象となる要素の指定がちゃんとされてないと Error を投げる", ->
      eventName = "errTest"
      @event    = null
      firedFlag = false

      el.addEventListener eventName, (event) =>
        @event    = event
        firedFlag = true
      , false
      (expect -> helper.triggerEvent("el", eventName, true, false)).to.throw(Error) 

  describe ".checkBrowser()", ->
    # UserAgent を偽装するヘルパ
    spoofUserAgent = (ua) ->
      _navigator = window.navigator
      window.navigator = new Object()
      window.navigator.__proto__ = _navigator
      window.navigator.__defineGetter__ "userAgent", ->
        return ua

    describe "iOS 6.1.3 で試してみました", ->
      spoofUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_3 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10B329")

      it "name: \"ios\" が返ってくる", ->
        expect(helper.checkBrowser().name).to.be.a("string")
        expect(helper.checkBrowser().name).to.equal("ios")
      it "version: 6.1 が返ってくる", ->
        expect(helper.checkBrowser().version).to.be.a("number")
        expect(helper.checkBrowser().version).to.equal(6.1)
      it "特にレガシーなわけでもないので isLegacy: false が返ってくる", ->
        expect(helper.checkBrowser().isLegacy).to.be.false

    describe "Android 4.0.2 で試してみました", ->
      before ->
        spoofUserAgent("Mozilla/5.0 (Linux; U; Android 4.0.2; en-us; Galaxy Nexus Build/ICL53F) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30")

      it "name: \"android\" が返ってくる", ->
        expect(helper.checkBrowser().name).to.be.a("string")
        expect(helper.checkBrowser().name).to.equal("android")
      it "version: 4 が返ってくる", ->
        expect(helper.checkBrowser().version).to.be.a("number")
        expect(helper.checkBrowser().version).to.equal(4)
      it "特にレガシーなわけでもないので isLegacy: false が返ってくる", ->
        expect(helper.checkBrowser().isLegacy).to.be.false

    describe "Android 2.3.6 で試してみました", ->
      before ->
        spoofUserAgent("Mozilla/5.0 (Linux; U; Android 2.3.6; en-us; Nexus S Build/GRK39F) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1")

      it "name: \"android\" が返ってくる", ->
        expect(helper.checkBrowser().name).to.be.a("string")
        expect(helper.checkBrowser().name).to.equal("android")
      it "version: 2.3 が返ってくる", ->
        expect(helper.checkBrowser().version).to.be.a("number")
        expect(helper.checkBrowser().version).to.equal(2.3)
      it "Android 2.x とかレガシーでとてもク◯ソなので isLegacy: true が返ってくる", ->
        expect(helper.checkBrowser().isLegacy).to.be.true

  describe ".checkSupport()", ->
    hasTouch = helper.checkSupport().touch

    describe "WebKit 前提でございやんす", ->
      if hasTouch
        it "タッチイベントもってるから touch: true が返ってくる", ->
          expect(helper.checkSupport().touch).to.be.true
      else
        it "タッチイベントもってないから touch: false が返ってくる", ->
          expect(helper.checkSupport().touch).to.be.false
      it "天下の WebKit さんなら Transform3d くらい対応してるはず", ->
        expect(helper.checkSupport().transform3d).to.be.true
      it "Transform3d に対応してる、すなわち cssAnimation: true が返ってくる", ->
        expect(helper.checkSupport().cssAnimation).to.be.true

  describe ".checkTouchEvents()", ->
    hasTouch = helper.checkSupport().touch

    if hasTouch
      describe "タッチイベント持っていますね", ->
        it "なもんで start: \"touchstart\" が返ってくる", ->
          expect(helper.checkTouchEvents().start).to.equal("touchstart")
        it "なもんで move: \"touchmove\" が返ってくる", ->
          expect(helper.checkTouchEvents().move).to.equal("touchmove")
        it "なもんで end: \"touchend\" が返ってくる", ->
          expect(helper.checkTouchEvents().end).to.equal("touchend")
    else
      describe "タッチイベント持ってませんね", ->
        it "なもんで start: \"mousedown\" が返ってくる", ->
          expect(helper.checkTouchEvents().start).to.equal("mousedown")
        it "なもんで move: \"mousemove\" が返ってくる", ->
          expect(helper.checkTouchEvents().move).to.equal("mousemove")
        it "なもんで end: \"mouseup\" が返ってくる", ->
          expect(helper.checkTouchEvents().end).to.equal("mouseup")
      
