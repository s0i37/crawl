$filepath = (Get-ChildItem $args[0]).FullName
.\lib\strings.exe /accepteula $filepath
