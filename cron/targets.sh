#!/bin/bash

USER='iivanov'
PASS='password'
DOMAIN='company.org'
DC='192.168.12.6'
DNS=$DC

namespace=$(curl -s ldap://$DC | grep 'namingContexts:' | head -n 1 | awk '{print $2}')
ldapsearch -o ldif-wrap=no -E pr=10000/noprompt -D "$USER@$DOMAIN" -w "$PASS" -x -H ldap://"$DC" -b "$namespace" '(objectClass=computer)' dnshostname | grep dNSHostName | awk '{print $2}' > hosts.txt

cat hosts.txt | while read host
do host "$host" "$DNS" | grep 'has address' | awk '{print $4}'
done | sed -rn 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+./\1\.0\/24/p' | sort | uniq -c | sort -n -r | awk '{print $2}' > nets.txt
