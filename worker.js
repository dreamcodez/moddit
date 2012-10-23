#!/usr/local/bin/node

var async  = require('async');
var stylus = require('stylus');

function send(jobid, errcode, msg) {
  var frame = jobid + ' ' + errcode + ' ' + msg;
  //console.log(frame.length + ':' + frame);
  process.stdout.write(frame.length + ':' + frame);
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
  stylus: function(jobid, job, cb) {
    stylus.render(job.input, function(err, css) {
      if(err) {
        send(jobid, 1, err.stack);
      }
      else if(!css) {
        send(jobid, 1, (new Error('empty stylus response')).stack);
      }
      else {
        send(jobid, 0, css);
      }
      cb();
    });
  }
};

function handle_frame(frame, cb) {
  var res = parse_job(frame);
  var jobid = res[0];
  var job = res[1];
  var command = commands[job.command];
  command(jobid, job, cb);
}

var _buf = "";
var _queue = [];
function handleQueueLoop() {
  function next() {
    process.nextTick(handleQueueLoop);
  }

  // process 4 at a time before yielding to scheduler
  var frames = _queue.slice(0, 4);
  _queue = _queue.slice(4);

  if(_queue.length) {
    async.forEach(frames, handle_frame, next);
  }
  else {
    async.forEach(frames, handle_frame);
  }
}

function handle_stdin(chunk) {
  var res = parse_netstrings(chunk.toString());
  var frames = res[0];
  var newbuf = res[1];

  _queue = _queue.concat(frames);

  // ready for next invocation
  _buf = newbuf;

  process.nextTick(handleQueueLoop);
}

process.stdout.on('error', shutdown_on_epipe);
process.stdin.on('error', shutdown_on_epipe);

process.stdin.on('data', handle_stdin)

process.openStdin();

// heartbeat
setInterval(function(){ process.stdout.write('2:hb'); }, 8000);

