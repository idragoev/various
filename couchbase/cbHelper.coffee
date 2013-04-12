fs = require "fs"
util = require "util"
nconf = require "nconf"
http = require "http"

nconf.argv()

throw "--ip not specified." unless nconf.get "ip"
throw "--port not specified." unless nconf.get "port"

command = nconf.get "cmd"
throw "--cmd not specified." unless command

reqOptions = {
  hostname: nconf.get "ip"
  port: nconf.get "port"
  }

sendGetRequest = (path, body, callback = ->) ->
  reqOptions.path = path
  reqOptions.method = "GET"
  
  reqResult = ""
  req = http.request reqOptions, (res) ->
    res.setEncoding "utf8"
    res.on "data", (chunk) ->        
      reqResult += chunk

    res.on "end", (chunk) -> 
      reqResult += chunk if chunk
      views = JSON.parse reqResult
      callback views

  req.on "error", (e) ->
    throw e

  req.end()

sendPutRequest = (path, body, callback = ->) ->
  reqOptions.path = path
  reqOptions.method = "PUT"
  
  reqResult = ""
  req = http.request reqOptions, (res) ->
    res.setEncoding "utf8"
    #throw "Error " + res.statusCode if res.statusCode != 201
    
    res.on "data", (chunk) ->
      reqResult += chunk

    res.on "end", (chunk) -> 
      reqResult += chunk if chunk
      callback JSON.parse(reqResult)

  req.on "error", (e) ->
    throw e

  req.setHeader "Content-Type", "application/json"
  req.write JSON.stringify(body)
  req.end()

switch command
  when "getViews"
    sourceBucket = nconf.get "bucket"
    throw "--bucket not specified" unless sourceBucket    

    path = util.format "/pools/default/buckets/%s/ddocs", sourceBucket
    sendGetRequest path, null, (res) ->
      result = []
      for d in res.rows
        r = {
          id: d.doc.meta.id
          json: d.doc.json
          }
        result.push r

      console.log JSON.stringify result

  when "addViews"
    reqOptions.auth = util.format("%s:%s", nconf.get("usr"), nconf.get("pwd"))

    file = nconf.get "file"
    console.log "Reading file %s", file
    views = JSON.parse(fs.readFileSync file, "utf8")

    for view in views
      path = util.format "/%s/%s", nconf.get("bucket"), view.id
      sendPutRequest path, view.json
    
  else console.error "Command '%s' is not supported.", command
