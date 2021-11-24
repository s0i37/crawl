cd path/to/crawl/linux

### Local crawling

PATH=$PATH:bin ./crawl.sh /home/ -size -10M

PATH=$PATH:bin ./grep.sh 'pass' / -size -10M

./import.sh results.csv

./search.sh results.db 's3cr3t'

### Web crawling

./spider.sh http://target.com/

cd /tmp/spider/

./crawl.sh target.com/ -size -10M

### Mails crawling

./imap.sh imap://server.com user:pass

./crawl.sh INBOX
