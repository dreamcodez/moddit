
parse-lenstr = (str) ->
  idx = str.index-of ':'
  if idx is not -1
    rest = str.slice(idx + 1)
    len = parseInt(str.slice(0, idx))
    {len, rest}
  else
    {rest: str}

parse-netstring = (str) ->
  {len, rest} = parse-lenstr(str)
  if len
    netstr = rest.slice(0, len)
    newrest = rest.slice(len)
    {netstr, rest: newrest}
  else
    {rest: str}

parse-job = (frame) ->
  idx = frame.index-of ' '
  if idx is not -1
    job = frame.slice(idx + 1)
    jobid = parseInt(frame.slice(0, idx))
    {jobid, job}
  else
    {}

parse-netstrings = (str) ->
  rest = str
  netstrings = []
  loop
    {netstr, rest} = parse-netstring(rest)
    if netstr
      netstrings.push(netstr)
    else
      break

  {netstrings, rest}

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
      {jobid, job} = parse-job(frame)
      if jobid and job
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

