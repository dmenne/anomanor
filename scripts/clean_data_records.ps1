# https://stackoverflow.com/a/38497025/229794
 $targetFolder = "..\..\..\anomanor_data\anomanor\data\records"
 $fileList = "deletelist.txt"

 Remove-Item $TargetFolder\* -Recurse -Include (Get-Content deletelist.txt) -Verbose