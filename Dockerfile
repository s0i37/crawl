FROM debian:12

WORKDIR /opt/crawl

RUN apt update && \
apt install -y --no-install-recommends ca-certificates git sudo tmux iproute2 procps nano less tree iputils-ping locales ldap-utils bind9-host nmap netcat-openbsd cron && \
apt install -y --no-install-recommends wget curl file sqlite3 cifs-utils python3 python3-pip xz-utils && \
apt install -y --no-install-recommends lynx uchardet catdoc unzip python3-pdfminer p7zip-full && \
apt install -y --no-install-recommends maildir-utils mpack libemail-outlook-message-perl libemail-sender-perl binwalk && \
apt install -y --no-install-recommends graphicsmagick-imagemagick-compat tesseract-ocr tesseract-ocr-eng tesseract-ocr-rus ffmpeg smbclient && \
rm /usr/lib/python3.11/EXTERNALLY-MANAGED && \
pip3 install vosk && \
wget https://github.com/radareorg/radare2/releases/download/5.8.8/radare2-5.8.8-static.tar.xz -O /tmp/radare2.tar.xz && tar xvf /tmp/radare2.tar.xz -C /opt/ && rm /tmp/radare2.tar.xz && ln -s /opt/r2-static/usr/bin/rabin2 /usr/local/bin/rabin2

COPY bin bin
COPY cron cron
COPY www www
COPY spider.sh .
COPY crawl.sh .
COPY save_images.sh .
COPY import.sh .
COPY search.sh .
COPY opensearch.py .
COPY crawlme crawlme

RUN apt install -y --no-install-recommends nodejs npm openjdk-17-jre && \
pip3 install opensearch-py colorama && \
cd www/ && npm install && npm install -g bower && bower --allow-root install && mv bower_components static && cd - && \
wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.11.0/opensearch-2.11.0-linux-x64.tar.gz -O /tmp/opensearch.tar.gz && tar xvf /tmp/opensearch.tar.gz -C /opt/ && rm /tmp/opensearch.tar.gz

RUN useradd -s /bin/bash -g users -N -M -d /opt/crawl user && \
chown -R user:users /opt/ && \
chmod +w /etc/sudoers && echo 'user    ALL=(root) NOPASSWD: ALL' >> /etc/sudoers && chmod -w /etc/sudoers

RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
dpkg-reconfigure --frontend=noninteractive locales

ENV LANG ru_RU.UTF-8

EXPOSE 8080 9200
ENTRYPOINT ["tmux"]