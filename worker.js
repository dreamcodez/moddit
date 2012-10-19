#!/usr/local/bin/node

//var stdin = process.openStdin();
//stdin.on('data', function(chunk) { console.log("Got chunk", chunk); })

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

process.stdout.on('error', shutdown_on_epipe);
process.stdin.on('error', shutdown_on_epipe);

setInterval(function(){ process.stdout.write('3:foo'); }, 2000);

