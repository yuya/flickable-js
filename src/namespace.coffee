root = window ? global ? this

root.namespace = (namespace, fn) ->
  klass   = fn()
  context = root

  for token in namespace.split(".")
    context[token] ?= {}
    context = context[token]

  context[klass.name] = klass
