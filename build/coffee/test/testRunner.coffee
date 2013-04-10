require.config
  paths:
    zepto: "../lib/zepto"
    mocha: "../lib/mocha"
    chai:  "../lib/chai"
    sinon: "../lib/sinon"
  shim:
    zepto:
      exports: "$"
    mocha:
      init: ->
        @mocha.setup("bdd")
        return @mocha
      exports: "Mocha"
    chai:
      exports: "Chai"
    # sinon:
    #   exports: "Sinon"
  waitSeconds: 180
  baseUrl: "/"
  urlArgs: do ->
    new Date().getTime()

require [
  # libs
  "mocha"
  "chai"

  # test files
  "test/helper"
  "test/flickable"
], (Mocha, Chai) ->
  Mocha.run()
