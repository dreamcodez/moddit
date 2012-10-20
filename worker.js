#!/usr/local/bin/node

function shutdown_on_epipe(err) {
  if(err) {
    if(err.errno === 'EPIPE') {
      process.exit(0);
    }
    else {
      throw err;
    }
  }
}

// returns [messages, rest]
function rparse_netstrings(messages, buf) {
  var pieces = buf.split(':');

  if(pieces.length < 2) {
    return [messages, buf];
  }
  else {
    var len = parseInt(pieces[0]);
    var rest = pieces.slice(1).join('');
    var new_msg = rest.slice(0, len);
    var new_buf = rest.slice(len);
    var new_messages = messages.concat([new_msg]);
    return rparse_netstrings(new_messages, new_buf);
  }
}

function parse_netstrings(buf) {
  return rparse_netstrings([], buf);
}

var _buf = "";
function handle_stdin(chunk) {
  var res = parse_netstrings(_buf + chunk.toString());
  var messages = res[0];
  var newbuf = res[1];
  console.warn({messages: messages});
  _buf = newbuf;
}

process.stdout.on('error', shutdown_on_epipe);
process.stdin.on('error', shutdown_on_epipe);

process.openStdin();

process.stdin.on('data', handle_stdin)

setInterval(function(){ process.stdout.write('3:foo'); }, 2000);

