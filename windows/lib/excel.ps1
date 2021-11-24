$filename = (Get-ChildItem $args[0]).FullName
$excel = New-Object -ComObject Excel.Application
#$excel.visible = $true
$xls = $excel.Workbooks.Open($filename, $false, $true)
foreach($sheet in $xls.sheets)
{
	$out = "sheet: " + $sheet.name
	echo $out
}
for($s = 1; $s -le $xls.Sheets.Count; $s++)
{
  $sheet = $xls.Sheets.Item($s)
  $rows = $sheet.UsedRange.Rows.Count
  $cols = $sheet.UsedRange.Columns.Count
  for($row = 1; $row -le $rows; $row++)
  {
    for($col = 1; $col -le $cols; $col++)
    {
      $cell = $sheet.Cells.Item($row,$col)
      if($cell)
      {
        echo $cell.Text;
      }
    }
  }
  $sheet = $null
}
$xls.Close($false)
$excel.Quit()
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($cell)
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($xls)
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel)
