# https://stackoverflow.com/a/23768332/229794
$targetFolder = "D:\anomanor_onlinecache"

Get-ChildItem $targetFolder\*.png | Where{$_.Name -Match "_4.png"} | Remove-Item
Get-ChildItem $targetFolder\*.png | Where{$_.Name -Match "_2.png"} | Remove-Item
Get-ChildItem $targetFolder\*.png | Where{$_.Name -Match "_begin"} | Remove-Item


