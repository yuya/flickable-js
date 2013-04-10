require.config
  waitSeconds: 180
  baseUrl: "/"
  urlArgs: do ->
    new Date().getTime()

require [
  "src/helper"
  "src/flickable"
], (Helper, Flickable) ->

  div = document.createElement("div")

  console.log Helper
  console.log Flickable
  flickable = new Flickable(div, {})

