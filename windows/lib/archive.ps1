$filepath = (Get-ChildItem $args[0]).FullName
$filedir = (Get-ChildItem $args[0]).DirectoryName
$filename = (Get-ChildItem $args[0]).Name
$calle = (Get-ChildItem $args[1]).FullName
$needle = $args[2]
$tmp = $env:TEMP + "\_" + (Get-Random) + "\" + "$filename"
#$tmp = $env:TEMP + "\" + (Get-Random) + (Split-Path "$filedir" -noQualifier) + "\" + "$filename"
#$tmp = "$filedir" + "\__" + "$filename"
#Expand-Archive -Path $filepath -DestinationPath $tmp
New-Item -Path "$tmp" -ItemType Directory 2> $null
.\lib\7z.exe x -y "-o$($tmp)" $filepath > $null
Get-ChildItem -Recurse "$tmp" | % { echo $_.Name }
& $calle $tmp $needle
Remove-Item -path "$tmp" -recurse -Force