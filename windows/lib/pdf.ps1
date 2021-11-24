$filename = (Get-ChildItem $args[0]).FullName
$lib = $pwd.Path + '\lib\BouncyCastle.Crypto.dll'
[System.Reflection.Assembly]::LoadFile((Get-ChildItem $lib).FullName) > $null
$lib = $pwd.Path + '\lib\itextsharp.dll'
[System.Reflection.Assembly]::LoadFile((Get-ChildItem $lib).FullName) > $null
try
{
	$pdf = [iTextSharp.text.pdf.PdfReader]::new($filename)
	for ($page = 1; $page -le $pdf.NumberOfPages; $page++){
	    $text = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($pdf,$page)
	    Write-Output $text
	}
	$pdf.Close()
}
catch {}
