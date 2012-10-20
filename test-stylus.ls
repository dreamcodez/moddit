stylus = require \stylus

test-str = "\#foo\n  color blue"

stylus.render test-str, (err, css) ->
  if err then throw err
  console.log css

