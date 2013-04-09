define [
  "mocha"
  "chai"
  "../src/helper"
], (Mocha, Chai, Helper) ->
  expect = Chai.expect

  describe "Helper Class", ->
    helper = new Helper()

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

      it "svgMatrixZ とかいうイミフなプロパティ達を渡したら当然 true を含まない Array が返ってくる", ->
        props = [
          "svgMatrixZ"
          "WebkitSvgMatrixZ"
          "MozSvgMatrixZ"
          "OSvgMatrixZ"
          "msMatrixZ"
        ]
        expect(helper.hasProp(props)).to.be.instanceof(Array)
        expect(helper.hasProp(props)).to.not.contain(true)
      it "Array じゃないもの渡されても困るので null を返す", ->
        expect(helper.hasProp("WebkitTransform")).to.be.a("null")

    describe ".setStyle()", ->

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
