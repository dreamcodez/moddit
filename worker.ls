#!node_modules/.bin/livescript

fs     = require \fs
jade   = require \jade
stylus = require \stylus
wu     = require './worker-util'

commands =
  jade: (job, next) ->
    locals = job.locals or {}

    if job.input
      jade.render(job.input, locals, next)
    else if job.file
      jade.renderFile(job.file, locals, next)
    else
      next(new Error 'jade command must specify input or file')
  stylus: (job, next) ->
    locals = job.locals or {}
    apply-locals = (styl) ->
      for k, v of locals
        styl.define(k, v)

    if job.input
      styl = stylus(job.input)
      apply-locals(styl)
      styl.render(next)
    else if job.file
      input = fs.read-file-sync(job.file).to-string!
      styl = stylus(input)
      apply-locals(styl)
      styl.render(next)
    else
      next(new Error 'stylus command must specify input or file')

handle-job = (job_json, next) ->
  job = JSON.parse(job_json)
  if cmd = commands[job.command]
    cmd(job, next)
  else
    next(new Error "unknown job command: #{job.command}")

wu.run(handle-job)

