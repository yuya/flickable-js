// Generated by CoffeeScript 1.6.2
require.config({
  paths: {
    zepto: "../lib/zepto",
    mocha: "../lib/mocha",
    chai: "../lib/chai",
    sinon: "../lib/sinon"
  },
  shim: {
    zepto: {
      exports: "$"
    },
    mocha: {
      init: function() {
        this.mocha.setup("bdd");
        return this.mocha;
      },
      exports: "Mocha"
    },
    chai: {
      exports: "Chai"
    }
  },
  waitSeconds: 180,
  baseUrl: "/",
  urlArgs: (function() {
    return new Date().getTime();
  })()
});

require(["mocha", "chai", "test/helper", "test/flickable"], function(Mocha, Chai) {
  return Mocha.run();
});
