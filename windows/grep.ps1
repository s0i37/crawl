echo "begin $PID"
$ErrorActionPreference = 'SilentlyContinue'
$TIMEOUT=15
$haystack = $args[0]
$needle = $args[1]
$files = 0
$exts = @()
$exts += @("*.doc","*.docx")
$exts += @("*.xls","*.xlsx")
$exts += @("*.pdf")
$exts += @("*.zip")
$exts += @("*.txt","*.bat","*.vbs","*.ps1","*.reg","*.cfg","*.conf","*.xml","*.log")
#$exts += @("*.exe","*.dll")
$opts = @{
  "Path" = $haystack
  "Recurse" = $true
  "Include" = $exts
}

#function highlight([String]$text){
#  $COUNT = 10
#  $words = $text.ToLower().split()
#  do
#  {
#    $match = $words.IndexOf($needle.ToLower())
#    if($match -ne -1)
#    {
#      for($i = $match-$COUNT + (($COUNT-$match + [Math]::Abs($COUNT-$match))/2); $i -lt $match+$COUNT - (($match+$COUNT-$words.Length + [Math]::Abs($match+$COUNT-$words.Length))/2); $i++)
#      {
#        if(echo $words[$i] | select-string $needle)
#        {Write-Host -NoNewLine -ForegroundColor red "$($words[$i]) "}
#        else
#        {Write-Host -NoNewLine -ForegroundColor green "$($words[$i]) "}
#      }
#      $words = $words[$i .. $words.Length]
#    }
#    Write-Host ""
#  }while($match -ne -1)
#}

Get-ChildItem @opts 2> $null | % {
  if((Get-Item $_.FullName) -isnot [System.IO.DirectoryInfo]) {
    $files += 1
  }
}
$i = 1
Get-ChildItem @opts 2> $null | % {
  if((Get-Item $_.FullName) -isnot [System.IO.DirectoryInfo]) {
    $file = @{}
    $file.name = $_.Name
    $file.path = $_.FullName
    $file.ext = $_.Extension
    $file.content = ""
    #echo "[*] $($file.path)"
    $job = $null
    switch -regex ($file.ext) {
      '.txt|.bat|.vbs|.ps1|.reg|.cfg|.conf|.xml' { $job = Start-Job -FilePath .\lib\plaintext.ps1 -argumentlist $file.path }
      '.doc*' { $job = Start-Job -FilePath .\lib\word.ps1 -argumentlist $file.path }
      '.xls*' { $job = Start-Job -FilePath .\lib\excel.ps1 -argumentlist $file.path }
      '.pdf' { $job = Start-Job -FilePath .\lib\pdf.ps1 -argumentlist $file.path -Init ([ScriptBlock]::Create("Set-Location '$pwd'")) }
      '.zip|.7z|.tar|.gz|.gzip|.gz' { $job = Start-Job -FilePath .\lib\archive.ps1 -argumentlist $file.path,"grep.ps1",$needle -Init ([ScriptBlock]::Create("Set-Location '$pwd'")) }
      '.exe|.dll' { $job = Start-Job -FilePath .\lib\executable.ps1 -argumentlist $file.path -Init ([ScriptBlock]::Create("Set-Location '$pwd'")) }
    }
    if($job)
    {
      Wait-Job -timeout $TIMEOUT $job > $null
      $file.content = Receive-Job $job
      #echo $file.content
      Stop-Job $job
      Remove-Job $job
    }
    if(echo $file.content | select-string $needle) {
      Write-Output "[+] [$i/$files] $($file.path)"
      echo $file.content | select-string -Pattern $needle
      #Write-Host -ForegroundColor green (echo $file.content | select-string -Pattern $needle)
      #highlight(echo $file.content | select-string $needle)
    }
    elseif($file.content -eq 0) {
      echo "[!] [$i/$files] $($file.path)"
    }
    elseif($i % 1 -eq 0) {
      echo "[*] [$i/$files] $($file.path)"
    }
    $i += 1
  }
}
echo 'done'