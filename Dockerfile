FROM debian:11

WORKDIR /opt/crawl

RUN apt update && \
apt install -y --no-install-recommends sudo tmux iproute2 nano less iputils-ping locales ldap-utils bind9-host nmap netcat-openbsd && \
apt install -y --no-install-recommends wget curl file sqlite3 cifs-utils python3 python3-pip xz-utils && \
apt install -y --no-install-recommends lynx uchardet catdoc unzip python3-pdfminer p7zip-full && \
apt install -y --no-install-recommends maildir-utils mpack libemail-outlook-message-perl libemail-sender-perl binwalk && \
apt install -y --no-install-recommends graphicsmagick-imagemagick-compat tesseract-ocr tesseract-ocr-eng tesseract-ocr-rus ffmpeg && \
pip3 install vosk && \
wget https://github.com/radareorg/radare2/releases/download/5.8.8/radare2-5.8.8-static.tar.xz -O /tmp/radare2.tar.xz && tar xvf /tmp/radare2.tar.xz -C /opt/ && rm /tmp/radare2.tar.xz && ln -s /opt/r2-static/usr/bin/rabin2 /usr/local/bin/rabin2

COPY bin bin
COPY cron cron
COPY www www
COPY spider.sh .
COPY crawl.sh .
COPY import.sh .
COPY search.sh .
COPY opensearch.py .

RUN apt install -y --no-install-recommends nodejs npm openjdk-17-jre && \
pip3 install opensearch-py colorama && \
cd www/ && npm install && cd - && \
wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.11.0/opensearch-2.11.0-linux-x64.tar.gz -O /tmp/opensearch.tar.gz && tar xvf /tmp/opensearch.tar.gz -C /opt/ && rm /tmp/opensearch.tar.gz && \
echo 'deb https://http.kali.org/kali kali-rolling main non-free contrib' >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED444FF07D8D0BF6 && apt update && apt -y --no-install-recommends install crackmapexec

RUN echo 'LANG="ru_RU.UTF-8"' > /etc/default/locale && \
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8 && \
locale-gen && \
echo 241 | dpkg-reconfigure locales && \
echo "LANG=ru_RU.UTF-8" > /etc/default/locale && \
useradd -s /bin/bash -g users -N -M -d /opt/crawl user && \
chown -R user.users /opt/ && \
chmod +w /etc/sudoers && echo 'user    ALL=(root) NOPASSWD: ALL' >> /etc/sudoers && chmod -w /etc/sudoers

EXPOSE 8080
