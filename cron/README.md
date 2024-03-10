## Continuous crawling

```
sudo apt install ldap-utils bind9-host nmap netcat-openbsd
echo 'deb https://http.kali.org/kali kali-rolling main non-free contrib' >> /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED444FF07D8D0BF6
apt update
apt install crackmapexec
```

```
JAVA_LIBRARY_PATH=/opt/opensearch/plugins/opensearch-knn/lib /opt/opensearch/bin/opensearch
cd /opt/crawl/www && node index.js
```

`/opt/crawl/opensearch.py localhost:9200 -i $INDEX -init`

```
crontab -e
30 11 * * * tmux new-session -d '/opt/crawl/cron/targets.sh ; timeout 3600 /opt/crawl/cron/scan.sh ; tmux new-window -d 'timeout $[3600*8] /opt/crawl/cron/www.sh' & tmux new-window -d 'timeout $[3600*8] /opt/crawl/cron/ftp.sh' & tmux new-window -d 'timeout $[3600*8] /opt/crawl/cron/smb.sh'
0 23 * * * tmux new-session -d '/opt/crawl/cron/import.sh'
0 0 * * 1  /opt/crawl/cron/clean.sh
```
