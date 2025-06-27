#!/bin/bash

INDEX="company"
DB="localhost:9200"

for csv in www/*.csv ftp/*.csv smb-all/*.csv smb-new/*.csv nfs/*.csv rsync/*.csv
do echo "$csv"
	/opt/crawl/opensearch.py "$DB" -i "$INDEX" -import "$csv"
	rm "$csv"
done
