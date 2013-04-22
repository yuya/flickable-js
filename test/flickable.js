describe("Flickable Class", function() {
  var fl, initElement,
    _this = this;

  fl = null;
  initElement = function(element) {
    var item, length;

    length = 5;
    while (length) {
      item = document.createElement("div");
      item.style.float = "left";
      item.style.width = "100px";
      element.appendChild(item);
      length--;
    }
    return sandbox.appendChild(element);
  };
  beforeEach(function(done) {
    var el, sandbox;

    el = document.createElement("div");
    sandbox = document.getElementById("sandbox");
    initElement(el);
    fl = new window.Flickable(el, {});
    return done();
  });
  afterEach(function(done) {
    fl.destroy();
    sandbox.innerHTML = "";
    return done();
  });
  describe("constructor", function() {
    it("初期化時に対象の DOM が指定されてないとプンプン丸", function() {
      return (expect(function() {
        return new window.Flickable();
      })).to.throwError();
    });
    return it("String が渡されたら優しく QuerySelector してあげるおじさん", function() {
      var ojisan;

      ojisan = document.createElement("div");
      ojisan.id = "ojisan";
      sandbox.appendChild(ojisan);
      return (expect(function() {
        return new window.Flickable("#ojisan");
      })).to.not.throwError();
    });
  });
  describe(".refresh()", function() {
    it("初期化時に渡した要素の子が5つだから maxPoint 的には 4", function() {
      return expect(fl.maxPoint).to.equal(4);
    });
    return it("子要素の幅が 100px だから 100 が Number で返ってくる", function() {
      return expect(fl.distance).to.equal(100);
    });
  });
  describe(".hasPrev()", function() {
    it("2番目に移動した (moveToPoint(1)) からまだ左にスワイプおｋ", function() {
      fl.moveToPoint(1);
      return expect(fl.hasPrev()).to.be["true"];
    });
    return it("1番目に移動した (moveToPoint(0)) からもう左にスワイプできません", function() {
      fl.moveToPoint(0);
      return expect(fl.hasPrev()).to.be["false"];
    });
  });
  describe(".hasNext()", function() {
    it("3番目に移動した (moveToPoint(2)) からまだ右にスワイプおｋ", function() {
      fl.moveToPoint(2);
      return expect(fl.hasNext()).to.be["true"];
    });
    return it("5番目に移動した (moveToPoint(4)) からもう右にスワイプできません", function() {
      fl.moveToPoint(4);
      return expect(fl.hasNext()).to.be["false"];
    });
  });
  describe(".toPrev()", function() {
    it("toPrev() したら currentPoint が 1 -> 0 になる", function() {
      fl.moveToPoint(1);
      expect(fl.currentPoint).to.equal(1);
      fl.toPrev();
      return expect(fl.currentPoint).to.equal(0);
    });
    return it("currentPoint が 0 のときに toPrev() しても実行されない", function() {
      expect(fl.currentPoint).to.equal(0);
      fl.toPrev();
      return expect(fl.currentPoint).to.equal(0);
    });
  });
  describe(".toNext()", function() {
    it("toNext() したら currentPoint が 0 -> 1 になる", function() {
      expect(fl.currentPoint).to.equal(0);
      fl.toNext();
      return expect(fl.currentPoint).to.equal(1);
    });
    return it("currentPoint が 4 のときに toNext() しても実行されない", function() {
      fl.moveToPoint(4);
      expect(fl.currentPoint).to.equal(4);
      fl.toNext();
      return expect(fl.currentPoint).to.equal(4);
    });
  });
  return describe(".moveToPoint()", function() {
    return context("loop オプション無効（デフォルト）のとき", function() {
      it("実際の小要素数より大きい値（10）を入れてもガン無視して currentPoint は 4 を返す", function() {
        fl.moveToPoint(10);
        return expect(fl.currentPoint).to.equal(4);
      });
      return it("マイナス値（-1）とか入れてもガン無視して currentPoint は 0 を返す", function() {
        fl.moveToPoint(-1);
        return expect(fl.currentPoint).to.equal(0);
      });
    });
  });
});
