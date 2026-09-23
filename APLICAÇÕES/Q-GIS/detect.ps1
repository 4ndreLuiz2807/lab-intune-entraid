Get-ChildItem "C:\Program Files\QGIS*" `
-Filter "qgis*.exe" `
-Recurse `
-ErrorAction SilentlyContinue |
Select-Object FullName