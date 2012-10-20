var stylus = require('stylus');

var test_str = "#foo\n  color blue";

stylus.render(test_str, { filename: 'nesting.css' }, function(err, css){
  if (err) throw err;
  console.log(css);
});

