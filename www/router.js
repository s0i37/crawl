var url = require("url")

function route(handle, request, response)
{
	var action = url.parse(request.url).pathname.split('/').pop()
	if( typeof handle[action] === 'function' )
	{
		console.log("route to: " + action)
		handle[action](response, request)
		return true
	}
	else
		return false
}

exports.route = route