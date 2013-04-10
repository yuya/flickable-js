define [
  "zepto"
  "mocha"
  "chai"
  "../src/flickable"
], ($, Mocha, Chai, Flickable, ) ->
  do (global = this, document = this.document) ->
    "use strict"
    expect = Chai.expect

    el = $("<div>")[0]
    flickable = new Flickable(el)

    console.log Flickable
    console.log flickable