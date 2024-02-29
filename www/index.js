var server = require("./server")
var router = require("./router")
var requestHandlers = require("./requestHandlers")

var handle = {}
handle[""] = requestHandlers.start
handle["search"] = requestHandlers.search
handle["auto"] = requestHandlers.autocomplete
handle["cache"] = requestHandlers.cache

server.start( router.route, handle )