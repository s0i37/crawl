#!/usr/bin/python3
import csv
import json
from hashlib import md5
from opensearchpy import OpenSearch
from os import path
from datetime import datetime
from colorama import Fore
import argparse


CREDS = ('admin', 'admin')
parser = argparse.ArgumentParser( description='search machine control tool' )
parser.add_argument("opensearch", type=str, default="localhost:9200", help="opensearch address (localhost:9200)")
parser.add_argument("-i", "--index", type=str, metavar="index", default="", help="index where to search")
parser.add_argument("-o", "--offset", type=int, metavar="offset", default=0, help="offset results in query")
parser.add_argument("-c", "--count", type=int, metavar="count", default=10, help="count results in query")
parser.add_argument("-init", action="store_true", help="init index")
parser.add_argument("-drop", action="store_true", help="drop index")
parser.add_argument("-copy", dest="copy_index", metavar="new_index_name", help="copy index")
parser.add_argument("-import", dest="file_import", metavar="input.csv", help="import data")
parser.add_argument("-delete", dest="file_delete", metavar="input.csv", help="delete data")
parser.add_argument("-query", metavar="query", help="search query")
parser.add_argument("-cache", metavar="cache", help="get cache of a document")
args = parser.parse_args()

host,port = args.opensearch.split(":")
client = OpenSearch(
  hosts = [{'host': host, 'port': int(port)}],
  http_compress = True,
  http_auth = CREDS,
  use_ssl = True,
  verify_certs = False,
  ssl_assert_hostname = False,
  ssl_show_warn = False
)

def indexes():
  for index in client.indices.get("*"):
    print(index, client.cat.count(index))

def info(index):
  print(json.dumps(client.indices.get_settings(index=index), indent=4))

def init(index):
  SETTINGS = {
    "mappings": {
      "properties": {
        "timestamp": { "type": "text" },
        "inurl": { "type" : "text" },
        "site": { "type" : "text" },
        "ext": { "type" : "text" },
        "intitle": { "type" : "text" },
        "intext": { "type" : "text" },
        "filetype": { "type" : "text" }
      }
    },
    "settings": {
      "analysis": {
        "analyzer": {
          "default": {
            "type": "custom",
            "tokenizer": "standard",
            "filter": ["lowercase", "russian_stop", "russian_keywords", "russian_stemmer"],
          },
          "autocomplete": {
            "type": "custom",
            "tokenizer": "standard",
            "filter": ["lowercase", "russian_stop", "russian_keywords", "russian_stemmer", "autocomplete_filter"]
          }
        },
        "filter": {
          "russian_stop": {
            "type": "stop",
            "stopwords": "_russian_"
          },
          "russian_keywords": {
            "type": "keyword_marker",
            "keywords": []
          },
          "russian_stemmer": {
            "type": "stemmer",
            "language": "russian"
          },
          "autocomplete_filter": {
            "type": "edge_ngram",
            "min_gram": 1,
            "max_gram": 20
          }
        }
      }
    }
  }

  response = client.indices.create(index, body=SETTINGS)
  print(response)

def add(index, source):
  csv.field_size_limit(2**32)
  reader = csv.reader(open(source, errors="surrogateescape"), delimiter=',', quotechar='"')
  for row in reader:
    try:
      timestamp,filepath,ext,filetype,content,*_ = row

      document = {
        "timestamp": datetime.fromtimestamp(int(timestamp)).strftime('%Y-%m-%d %H:%M:%S'),
        "inurl": filepath,
        "site": path.splitext(path.basename(source))[0],
        "ext": ext,
        "intitle": "",
        "intext": content,
        "filetype": filetype
      }

      response = client.index(
          index = index,
          id = md5(filepath.encode()).hexdigest(),
          body = document,
          refresh = True
      )
      print(response)
    except Exception as e:
      print(str(e))

def query(index, text):
  query = {
    "size": args.count,
    "from": args.offset,
    "query": {
      "query_string": {
        "query": text,
        "fields": ["inurl^100","intitle^50","intext^5"],
        "default_operator": "AND",
        "fuzziness": "AUTO",
        "analyzer": "default"
      }
    },
    "highlight": {
      "order": "score",
      "fields": {
        "*": {
          "pre_tags" : [ Fore.RED ],
          "post_tags" : [ Fore.RESET ],
          "fragment_size": 50,
          "number_of_fragments": 3
        }
      }
    }
  }

  response = client.search(
      index = index,
      body = query
  )
  for result in response['hits']['hits']:
      print("{G}{uri} {B}{cache}{R}".format(
        uri=result['highlight']['inurl'][0] if result['highlight'].get('inurl') else result['_source']['inurl'],
        cache=result['_id'],
        G=Fore.GREEN, B=Fore.LIGHTBLACK_EX, R=Fore.RESET))
      print(" ... ".join(result['highlight'].get('intext',[])))

def cache(index, _id):
  result = client.get(index='test',id=_id)
  print(result["_source"]["intext"])

def delete(index, source):
  csv.field_size_limit(2**32)
  reader = csv.reader(open(source, errors="surrogateescape"), delimiter=',', quotechar='"')
  for row in reader:
    try:
      timestamp,filepath,ext,filetype,content,*_ = row
      response = client.delete(
        index = index,
        id = md5(filepath.encode()).hexdigest(),
      )
      print(response)
    except Exception as e:
      print(str(e))

def drop(index):
  response = client.indices.delete(
      index = index
  )
  print(response)

def copy(index_src, index_dst):
  response = client.reindex(
    body = {
      "source":{"index": index_src},
      "dest":{"index": index_dst}
    }
  )
  print(response)

if args.init:
  init(index=args.index)
elif args.drop:
  drop(index=args.index)
elif args.copy_index:
  copy(index_src=args.index, index_dst=args.copy_index)
elif args.file_import:
  add(index=args.index, source=args.file_import)
elif args.file_delete:
  delete(index=args.index, source=args.file_delete)
elif args.query:
  query(index=args.index, text=args.query)
elif args.cache:
  cache(index=args.index, _id=args.cache)
else:
  if args.index:
    info(index=args.index)
  else:
    indexes()
