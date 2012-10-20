#!/usr/local/bin/node

var stylus = require('stylus');

function send(jobid, errcode, msg) {
  var frame = jobid + ' ' + errcode + ' ' + msg;
  console.log(frame.length + ':' + frame);
}

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
function rparse_netstrings(frames, buf) {
  var pieces = buf.split(':');

  if(pieces.length < 2) {
    return [frames, buf];
  }
  else {
    var len = parseInt(pieces[0]);
    var rest = pieces.slice(1).join(':');
    var new_frame = rest.slice(0, len);
    var new_buf = rest.slice(len);
    var new_frames = frames.concat([new_frame]);
    return rparse_netstrings(new_frames, new_buf);
  }
}

function parse_netstrings(buf) {
  return rparse_netstrings([], buf);
}

function parse_job(frame) {
  var pieces = frame.split(' ');
  var jobid = parseInt(pieces[0]);
  var msg = pieces.slice(1).join(' ');
  return [jobid, JSON.parse(msg)];
}

var commands = {
  stylus: function(jobid, job) {
    stylus.render(job.input, function(err, css) {
      if(err) {
        send(jobid, 1, err.stack);
      }
      else {
        send(jobid, 0, css);
      }
    });
  }
};

function handle_frame(frame) {
  var res = parse_job(frame);
  var jobid = res[0];
  var job = res[1];
  var command = commands[job.command];
  command(jobid, job);
}

var _buf = "";
function handle_stdin(chunk) {
  var res = parse_netstrings(chunk.toString());
  var frames = res[0];
  var newbuf = res[1];
  console.warn({frames: frames});
  frames.map(handle_frame);

  // ready for next invocation
  _buf = newbuf;
}

process.stdout.on('error', shutdown_on_epipe);
process.stdin.on('error', shutdown_on_epipe);

process.stdin.on('data', handle_stdin)

process.openStdin();

//setInterval(function(){ process.stdout.write('3:foo'); }, 2000);

