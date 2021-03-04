$haystack = $args[0]
$needle = $args[1]
Get-ChildItem -Path $haystack -Recurse | % {
  $file = @{}
  $file.name = $_.Name
  $file.path = $_.FullName
  $file.ext = $_.Extension
  #echo "[*] $($file.path)"
  $file.content = switch -regex ($file.ext) {
    '.txt|.bat|.vbs|.ps1' { Get-Content $file.path }
    '.doc*' { .\lib\word.ps1 $file.path }
    '.xls*' { .\lib\excel.ps1 $file.path }
    '.pdf' { .\lib\pdf.ps1 $file.path }
    '.zip' {
        $rand = (Get-Random)
        $tmp = $env:TEMP + "\" + $rand + "\" + $file.name
        Expand-Archive -Path $file.path -DestinationPath $tmp
        $grep = $PSScriptRoot + "\" + "grep.ps1"
        & $grep $tmp $needle
        Remove-Item -path $tmp -recurse
     }
  }
  if(echo $file.content $file.path | select-string $needle) {
    echo "[+] $($file.path)"
    echo $file.content | select-string $needle
  }
}