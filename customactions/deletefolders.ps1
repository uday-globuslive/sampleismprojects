#$installdir = "C:\Program Files (x86)\testfolder"
#$installdir = Get-Property -Name INSTALLDIR
$installdir = Get-Property -Name CustomActionData


#Removed all files and subfolders but not from config folder
get-childitem -Path $installdir -Recurse | Select -ExpandProperty FullName | Where {$_ -notlike $($installdir+"config*") } | Remove-Item -force -recurse


$directoryInfo = Get-ChildItem $installdir | Measure-Object
if ($directoryInfo.count -eq 0)
{
	Remove-Item $installdir -force -recurse
}