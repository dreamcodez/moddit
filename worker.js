#!/usr/local/bin/node

//var stdin = process.openStdin();
//stdin.on('data', function(chunk) { console.log("Got chunk", chunk); })

setInterval(function(){ process.stdout.write('3:foo'); }, 2000);

