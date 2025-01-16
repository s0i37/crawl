var url = require("url")
var querystring = require("querystring")
//var elasticsearch = require("elasticsearch")
var { Client } = require('@opensearch-project/opensearch') //https://github.com/opensearch-project/opensearch-js/blob/HEAD/USER_GUIDE.md
var ejs = require("ejs")
var json = require("JSON")
var fs = require("fs")

function get_opensearch()
{
    return new Client({
        node: "https://admin:admin@localhost:9200",
        ssl: {rejectUnauthorized: false}
    })
}

function start(response)
{
    fs.readFile( "templates/index.html", "utf8", function(e,data) {
        response.writeHead(200, {"Content-Type": "text/html; charset=utf-8"})
        response.write(data)
        response.end()
    } )
}

function autocomplete(response, request)
{
    var query = querystring.parse( url.parse( request.url ).query ).q
    var index = url.parse( request.url ).pathname.split('/').slice(-2,-1)[0] || "default"
    get_opensearch().search( {
        index: index,
        body: {
            from: 0,
            size: 10,
            query: {
                query_string: {
                    query: query,
                    fields: ["inurl^100","intitle^50","intext^5"],
                    default_operator: "AND",
                    fuzziness: "AUTO",
                    analyzer: "autocomplete"
                }
            },
            highlight: {
                order: "score",
                fields: {
                    "*": {
                        pre_tags: [""],
                        post_tags: [""],
                        fragment_size: 25,
                        number_of_fragments: 1
                    }
                }
            }
        }
    } )
    .then( function(res) {
        //console.dir(res)
        var found = res.body.hits.total.value
        matches = []
        for( var i = 0; i < res.body.hits.hits.length; i++ )
            for( item in res.body.hits.hits[i].highlight )
                matches.push( res.body.hits.hits[i].highlight[item][0] )
        response.writeHead(200, {"Content-Type": "text/json"})
        response.end( json.stringify(matches) )
    } )
}

function cache(response, request)
{
    var id = querystring.parse( url.parse( request.url ).query ).id
    var index = url.parse( request.url ).pathname.split('/').slice(-2,-1)[0] || "default"
    get_opensearch().get( {
          index: index,
          id: id
        }, function (err, res) {
            //console.dir(res)
            response.writeHead(200, {"Content-Type": "text/html; charset=utf-8"})
            response.end( res.body._source.intext )
    } )
}

function search(response, request)
{
    var query = querystring.parse( url.parse( request.url ).query ).q
    var offset = parseInt( querystring.parse( url.parse( request.url ).query ).o ) || 1
    var index = url.parse( request.url ).pathname.split('/').slice(-2,-1)[0] || "default"
    var is_json = querystring.parse( url.parse( request.url ).query ).json != undefined
    var is_images = querystring.parse( url.parse( request.url ).query ).images == 1
    var count = (!is_images) ? 10 : 40
    get_opensearch().search( {
        index: index,
        body: {
            from: offset * count - count,
            size: count,
            query: {
                query_string: {
                    query: query,
                    fields: ["inurl^100","intitle^50","intext^5"],
                    default_operator: "AND",
                    fuzziness: "AUTO",
                    analyzer: "default"
                }
            },
            highlight: {
                order: "score",
                fields: {
                    "*": {
                        pre_tags: ["_b_"],
                        post_tags: ["_/b_"],
                        fragment_size: 250,
                        number_of_fragments: 3
                    }
                }
            }
        }
    } )
    .then( function(res) {
        //console.dir(res)
        var found = res.body.hits.total.value
        pages = []
        for( var i = 0; i < res.body.hits.hits.length; i++ )
        {
            var id = res.body.hits.hits[i]._id
            var relevant = res.body.hits.hits[i]._score
            var timestamp = res.body.hits.hits[i]._source.timestamp
            var title = res.body.hits.hits[i]._source.inurl.split('/').slice(-1)[0] //res.body.hits.hits[i]._source.intitle
            var url = res.body.hits.hits[i]._source.inurl
            var filetype = res.body.hits.hits[i]._source.filetype
            var href = url.split('/')[0] + '://' + url.split('/').slice(1).join('/')
            var matches = []
            for( item in res.body.hits.hits[i].highlight )
            {
                if(item == 'inurl')
                    url = res.body.hits.hits[i].highlight[item][0]
                else if(item == 'intitle')
                    title = res.body.hits.hits[i].highlight[item][0]
                else if(item == 'intext')
                    matches.push( res.body.hits.hits[i].highlight[item] )
            }
            pages.push( {
                cache: "/" + index + "/cache?id=" + id,
                title: title.replace(/_b_/g, '<b>').replace(/_\/b_/g, '</b>'),
                href: href,
                url: url.replace(/_b_/g, '<b>').replace(/_\/b_/g, '</b>'),
                filetype: filetype,
                relevant: relevant,
                timestamp: timestamp,
                matches: matches.join(" ... ").replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/_b_/g, '<b>').replace(/_\/b_/g, '</b>')
            } )
        }
        if(is_json)
        {
            response.writeHead(200, {"Content-Type": "application/json; charset=utf-8"})
            response.end(JSON.stringify(pages))
        }
        else if(is_images)
        {
            fs.readFile( "templates/images.html", "utf8", function(e,data) {
                var html = ejs.render(data, {
                    found: found,
                    query: query.includes("filetype:image") ? query : query + " filetype:image",
                    pages: pages,
                    offset: offset
                })
                response.writeHead(200, {"Content-Type": "text/html; charset=utf-8"})
                response.end(html)
            } )
        }
        else
            fs.readFile( "templates/search.html", "utf8", function(e,data) {
                var html = ejs.render(data, {
                    found: found,
                    query: query,
                    pages: pages,
                    offset: offset
                })
                response.writeHead(200, {"Content-Type": "text/html; charset=utf-8"})
                response.end(html)
            } )
    } )
}

exports.start = start
exports.search = search
exports.autocomplete = autocomplete
exports.cache = cache