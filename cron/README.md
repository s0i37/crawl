## Continuous crawling

```
sudo apt install ldap-utils bind9-host nmap netcat-openbsd smbclient
```

```
JAVA_LIBRARY_PATH=/opt/opensearch/plugins/opensearch-knn/lib /opt/opensearch/bin/opensearch -Ehttp.host=0.0.0.0
cd /opt/crawl/www && while sleep 1; do node index.js ; done
```

`/opt/crawl/opensearch.py localhost:9200 -i $INDEX -init`

```
# /etc/init.d/cron start
$ crontab -e
20 11 * * * tmux new-session -d -s targets -c '/opt/crawl/cron' 'timeout $[10*60] ./targets.sh'
30 11 * * * tmux new-session -d -s scan -c '/opt/crawl/cron' 'timeout $[1*3600] ./scan.sh'
30 12 * * * tmux new-session -d -s www -c '/opt/crawl/cron' 'timeout $[8*3600] ./www.sh'
30 12 * * * tmux new-session -d -s ftp -c '/opt/crawl/cron' 'timeout $[8*3600] ./ftp.sh'
30 12 * * * tmux new-session -d -s smb -c '/opt/crawl/cron' 'timeout $[8*3600] ./smb.sh'
30 01 * * * tmux new-session -d -s import -c '/opt/crawl/cron' 'timeout $[5*3600] ./import.sh'
#30 06 * * 1 tmux new-session -d -s clean -c '/opt/crawl/cron' './clean.sh'
```
