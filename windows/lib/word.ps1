$filename = (Get-ChildItem $args[0]).FullName
$word = New-Object -ComObject Word.Application
#$word.visible = False
$doc = $word.Documents.Open($filename, $false, $true)
#echo $doc.Content.Text
foreach($paragraph in $doc.Paragraphs) {
	echo $paragraph.range.Text
}
$doc.Close()
$word.Quit()