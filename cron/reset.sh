#!/bin/bash

rm www/.*.sess
rm ftp/.*.sess
rm smb-all/.*.sess
rm nfs/.*.sess
rm rsync/.*.sess

rm -r www/http www/https
rm -r ftp/ftp
rm -r smb-all/smb
rm -r nfs/nfs
rm -r rsync/rsync
