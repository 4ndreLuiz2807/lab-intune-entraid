$ErrorActionPreference = "Stop"

$MsiPath = Join-Path $PSScriptRoot "QGIS-OSGeo4W-3.44.13-1.msi"

Write-Output "Instalando QGIS..."

$Process = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i `"$MsiPath`" /qn /norestart" `
    -Wait `
    -PassThru

if ($Process.ExitCode -notin @(0, 3010, 1641)) {
    Write-Error "Falha na instalacao do QGIS. ExitCode: $($Process.ExitCode)"
    exit $Process.ExitCode
}

Write-Output "QGIS instalado. Procurando executavel..."

$QgisExe = Get-ChildItem `
    -Path "$env:ProgramFiles\QGIS*" `
    -Filter "qgis.exe" `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $QgisExe) {
    $QgisExe = Get-ChildItem `
        -Path "$env:ProgramFiles\QGIS*" `
        -Filter "qgis-bin.exe" `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

if (-not $QgisExe) {
    Write-Error "QGIS foi instalado, mas o executavel nao foi encontrado."
    exit 1
}

Write-Output "Executavel encontrado: $($QgisExe.FullName)"

$DesktopPath = "C:\Users\Public\Desktop"
$ShortcutPath = Join-Path $DesktopPath "QGIS.lnk"

$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = $QgisExe.FullName
$Shortcut.WorkingDirectory = $QgisExe.DirectoryName
$Shortcut.IconLocation = "$($QgisExe.FullName),0"
$Shortcut.Description = "QGIS"

$Shortcut.Save()

Write-Output "Atalho criado: $ShortcutPath"

if (Test-Path $ShortcutPath) {
    Write-Output "Deploy concluido."
    exit 0
}

Write-Error "Falha ao criar o atalho."
exit 1