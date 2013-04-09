require.config
  paths:
    zepto:    "./lib/zepto"
    domReady: "./lib/require.domReady"
    cs:       "./lib/require.cs"
    "coffee-script": "./lib/coffee-script"
    chai:     "./lib/chai"
    sinon:    "./lib/sinon"
    mocha:    "./lib/mocha"
  shim:
    zepto:
      exports: "$"
    sinon:
      exports: "sinon"
    # mocha:
    #   init: ->
    #     @mocha.setup("bdd")
    #     return @mocha
  waitSeconds: 180
  baseUrl: "/"
  urlArgs: do ->
    new Date().getTime()

require [
  "chai"
  "sinon"
  "mocha"
], (chai, sinon) ->

  # Mocha
  mocha.setup("bdd")

  console.log "hoge"

  require [
    # "cs!./test/helper"
    "./test/helper"
  ], () ->

    console.log "hoge"
    # console.log Helper

    mocha.run()

  return
