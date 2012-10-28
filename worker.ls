#!node_modules/.bin/livescript

fs     = require \fs
jade   = require \jade
stylus = require \stylus
wu     = require './worker-util'

commands =
  jade: (job, next) ->
    if job.input
      jade.render(job.input, next)
    else if job.file
      jade.renderFile(job.file, next)
    else
      next(new Error 'jade command must specify input or file')
  stylus: (job, next) ->
    if job.input
      stylus.render(job.input, next)
    else if job.file
      stylus.render(fs.read-file-sync(job.file).to-string!, next)
    else
      next(new Error 'stylus command must specify input or file')

handle-job = (job_json, next) ->
  job = JSON.parse(job_json)
  if cmd = commands[job.command]
    cmd(job, next)
  else
    next(new Error "unknown job command: #{job.command}")

wu.run(handle-job)

