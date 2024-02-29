var http = require("http")
var url = require("url")
var static = require("serve-static")("./static", {'index':[]})

function start(route, handle)
{
	http.createServer( function(request, response) {
		static( request, response, function() {
			if(! route( handle, request, response ) )
			{
				response.writeHead(404, {"Content-Type": "text/plain"})
				response.end("Not Found")
			}
		} )
	} ).listen( 8080 )
}

exports.start = start