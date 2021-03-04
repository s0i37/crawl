$filename = (Get-ChildItem $args[0]).FullName
$lib = $PSScriptRoot + '\BouncyCastle.Crypto.dll'
[System.Reflection.Assembly]::LoadFile((Get-ChildItem $lib).FullName) > $null
$lib = $PSScriptRoot + '\itextsharp.dll'
[System.Reflection.Assembly]::LoadFile((Get-ChildItem $lib).FullName) > $null
$pdf = [iTextSharp.text.pdf.PdfReader]::new($filename)
for ($page = 1; $page -le $pdf.NumberOfPages; $page++){
    $text = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($pdf,$page)
    Write-Output $text
}	
$pdf.Close()