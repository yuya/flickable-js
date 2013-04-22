###
  Flickable 0.1.2 (https://github.com/yhmt/flickable-js)
  Copyright (c) 2013 @yuya
  Licensed under the MIT License: http://www.opensource.org/licenses/mit-license.php
###

do (root = this, factory = (global, document) ->
  global["Flickable"] = {}
  return
) ->
  # AMD
  if typeof define is "function" and define.amd is "object"
    define("Flickable", [], ->
      factory(root, root.document)
      root["Flickable"]
    )
  # Browser global scope
  else
    factory(root, root.document)