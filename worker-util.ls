
parse-lenstr = (str) ->
  idx = str.index-of ':'
  if idx is not -1
    rest = str.slice(idx + 1)
    len = parseInt(str.slice(0, idx))
    {len, rest}

parse-netstring = (str) ->
  parsed = parse-lenstr str
  if parsed
    {len, rest} = parsed
    if rest.length >= len
      netstr = rest.slice(0, len)
      newrest = rest.slice(len)
      {netstr, rest: newrest}

parse-netstrings = (str) ->
  rest = str
  netstrings = []
  loop
    parsed = parse-netstring rest
    if parsed ~= null
      break
    else
      # reassigns the rest variable above
      {netstr, rest} = parsed
      netstrings.push(netstr)

  {netstrings, rest}

parse-job = (frame) ->
  idx = frame.index-of ' '
  if idx is not -1
    job = frame.slice(idx + 1)
    jobid = parseInt(frame.slice(0, idx))
    {jobid, job}

shutdown-on-epipe = (err) ->
  if err.errno is \EPIPE
    process.exit(0)
  else
    throw err

send = (jobid, errcode, msg) ->
  frame = "#{jobid} #{errcode} #{msg}"
  process.stdout.write(frame.length + ':' + frame)

export run = (handle-job) ->
  job-queue = []

  drain-queue = ->
    if job-queue.length
      frame = job-queue.shift()
      parsed = parse-job(frame)
      if parsed
        {jobid, job} = parsed
        handle-job job, (err, res) ->
          if err
            send jobid, 1, err
          else if not res
            send jobid, 1, new Error('empty job response')
          else
            send jobid, 0, res
        process.nextTick(drain-queue)
      else
        throw new Error "malformed job"

  handle-stdin = (chunk) ->
    {netstrings, rest} = parse-netstrings(chunk.toString())

    for ns in netstrings
      job-queue.push ns

    process.nextTick(drain-queue)

  process.stdout.on \error, shutdown-on-epipe
  process.stdin.on \error, shutdown-on-epipe
  process.stdin.on \data, handle-stdin
  process.openStdin();

  # heartbeat
  setInterval (-> process.stdout.write('2:hb')), 8000

