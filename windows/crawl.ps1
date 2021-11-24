$haystack = $args[0]
$files = 0
Get-ChildItem -Path $haystack -Recurse | % {
  $files += 1
}
$i = 1
Get-ChildItem -Path $haystack -Recurse | % {
  $file = @{}
  $file.name = $_.Name
  $file.path = $_.FullName
  $file.ext = $_.Extension
  echo "[*] $($file.path)"
  $file.content = switch -regex ($file.ext) {
    '.txt|.bat|.vbs|.ps1|.reg' { Get-Content $file.path }
    '.doc*' { .\lib\word.ps1 $file.path }
    '.xls*' { .\lib\excel.ps1 $file.path }
    '.pdf' { .\lib\pdf.ps1 $file.path }
    '.zip|.7z|.tar|.gz|.gzip|.gz' { .\lib\archive.ps1 $file.path "crawl.ps1" "" }
    '.exe|.dll' { .\lib\executable.ps1 $file.path }
  }
  echo "[$i/$files] $($file.path) $($file.content)"
  $i += 1
}