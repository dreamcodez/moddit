#!node_modules/.bin/livescript

jade   = require 'jade'
stylus = require 'stylus'
wu     = require './worker-util'

commands =
  stylus : (job, next) ->
    stylus.render(job.input, next)

handle-job = (job_json, next) ->
  job = JSON.parse(job_json)
  if cmd = commands[job.command]
    cmd(job, next)
  else
    next(new Error "unknown job command: #{job.command}")

wu.init(handle-job)

