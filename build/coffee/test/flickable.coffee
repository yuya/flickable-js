expect  = chai.expect

describe "Flickable Class", ->
  fl = null

  initElement = (element) ->
    length = 5

    while length
      item = document.createElement "div"
      item.style.float = "left"
      item.style.width = "100px"
      element.appendChild(item)
      length--

    sandbox.appendChild(element)

  beforeEach (done) =>
    el      = document.createElement("div")
    sandbox = document.getElementById("sandbox")

    initElement(el)
    fl = new window.Flickable el, {}
    done()

  afterEach (done) =>
    fl.destroy()
    sandbox.innerHTML = ""
    done()

  describe "constructor", ->
    it "初期化時に対象の DOM が指定されてないとプンプン丸", ->
      (expect -> new window.Flickable()).to.throw(Error)

    it "String が渡されたら優しく QuerySelector してあげるおじさん", ->
      ojisan    = document.createElement("div")
      ojisan.id = "ojisan"
      sandbox.appendChild(ojisan)

      (expect -> new window.Flickable("#ojisan")).to.not.throw(Error)
  describe ".refresh()", ->
    it "初期化時に渡した要素の子が5つだから maxPoint 的には 4", ->
      expect(fl.maxPoint).to.equal(4)

    it "子要素の幅が 100px だから 100 が Number で返ってくる", ->
      expect(fl.distance).to.equal(100)
  describe ".hasPrev()", ->
    it "2番目に移動した (moveToPoint(1)) からまだ左にスワイプおｋ", ->
      fl.moveToPoint(1)
      expect(fl.hasPrev()).to.be.true

    it "1番目に移動した (moveToPoint(0)) からもう左にスワイプできません", ->
      fl.moveToPoint(0)
      expect(fl.hasPrev()).to.be.false
  describe ".hasNext()", ->
    it "3番目に移動した (moveToPoint(2)) からまだ右にスワイプおｋ", ->
      fl.moveToPoint(2)
      expect(fl.hasNext()).to.be.true

    it "5番目に移動した (moveToPoint(4)) からもう右にスワイプできません", ->
      fl.moveToPoint(4)
      expect(fl.hasNext()).to.be.false
  describe ".toPrev()", ->
    it "toPrev() したら currentPoint が 1 -> 0 になる", ->
      fl.moveToPoint(1)
      expect(fl.currentPoint).to.equal(1)
      fl.toPrev()
      expect(fl.currentPoint).to.equal(0)

    it "currentPoint が 0 のときに toPrev() しても実行されない", ->
      expect(fl.currentPoint).to.equal(0)
      fl.toPrev()
      expect(fl.currentPoint).to.equal(0)
  describe ".toNext()", ->
    it "toNext() したら currentPoint が 0 -> 1 になる", ->
      expect(fl.currentPoint).to.equal(0)
      fl.toNext()
      expect(fl.currentPoint).to.equal(1)

    it "currentPoint が 4 のときに toNext() しても実行されない", ->
      fl.moveToPoint(4)
      expect(fl.currentPoint).to.equal(4)
      fl.toNext()
      expect(fl.currentPoint).to.equal(4)
  describe ".moveToPoint()", ->
    context "loop オプション無効（デフォルト）のとき", ->
      it "実際の小要素数より大きい値（10）を入れてもガン無視して currentPoint は 4 を返す", ->
        fl.moveToPoint(10)
        expect(fl.currentPoint).to.equal(4)

      it "マイナス値（-1）とか入れてもガン無視して currentPoint は 0 を返す", ->
        fl.moveToPoint(-1)
        expect(fl.currentPoint).to.equal(0)

    # context "loop オプション有効のとき", ->
      # el      = document.createElement("div")
      # sandbox = document.getElementById("sandbox")

      # initElement(el)
      # fl = new window.Flickable el, 
      #   loop: true
      #   disableTouch: true

      # it "maxPoint と同じ 4 を指定すると currentPoint は 0 になる", ->
      #   fl.moveToPoint(5)
      #   window.setTimeout ->
      #     expect(fl.currentPoint).to.equal(0)
      #   , 100
