define [
  "zepto"
  "mocha"
  "chai"
  "../src/helper"
], ($, Mocha, Chai, Helper) ->
  expect = Chai.expect

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
        expect(helper.hasProp(props)).to.be.instanceof(Array)
        expect(helper.hasProp(props)).to.contain(true)

      it "svgMatrixZ とかいうイミフな String を渡したら当然 false が返ってくる", ->
        prop = "svgMatrixZ"
        expect(helper.hasProp(prop)).to.be.false
      it "Array でも String でもないのを渡されても困るので null を返す", ->
        expect(helper.hasProp(undefined)).to.be.a("null")

    describe ".setStyle()", ->
      el = document.createElement("div")
      setStyles = (styles) ->
        style = el.style

        for prop, value of styles
          helper.setStyle(style, prop, value)

      beforeEach (done) ->
        el.removeAttribute("style")
        helper.saveProp = {}
        done()

      it ("display: none; を追加したから style=\"diplay: none;\" ってなってるはず"), ->
        # before ->
        setStyles(
          display: "block"
        )
        expect(el.getAttribute("style")).to.equal("display: block;")
      it ("プロパティ複数指定したら、指定した順番に style 属性に入ってるはず"), ->
        setStyles(
          display: "none"
          width: "100px"
          height: "100px"
          margin: "0px auto"
        )
        expect(el.getAttribute("style")).to.equal("display: none; width: 100px; height: 100px; margin: 0px auto;")
      it ("prefix が必要なやつはプロパティはよしなに prefix つけて、よしなに纏めてくれるはず"), ->
        setStyles(
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
      it "うっかり配列とか入れたら null 返して激おこプンプン丸", ->
        expect(helper.getCSSVal([1..3])).to.be.a("null")

    describe ".ucFirst()", ->
      it "String を渡すと先頭が大文字で返ってくる", ->
        expect(helper.ucFirst("webkitTransform")).to.be.a("string")
        expect(helper.ucFirst("webkitTransform")).to.equal("WebkitTransform")
      it "String だけどアルファベットじゃない君はありのままの君", ->
        expect(helper.ucFirst("123")).to.be.a("string")
        expect(helper.ucFirst("123")).to.equal("123")
      it "String じゃないものだったら null を返す", ->
        expect(helper.ucFirst([1..3])).to.be.a("null")
