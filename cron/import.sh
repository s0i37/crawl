#!/bin/bash

INDEX="company"

for csv in *.csv
do echo $csv
	/opt/crawl/opensearch.py localhost:9200 -i $INDEX -import "$csv"
done
