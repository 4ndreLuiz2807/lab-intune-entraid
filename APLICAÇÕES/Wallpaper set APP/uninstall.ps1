$ErrorActionPreference = 'Stop'

$pasta = 'C:\WallpaperBiomil'

if (Test-Path -LiteralPath $pasta) {
    Remove-Item -LiteralPath $pasta -Recurse -Force
}

Write-Output 'Wallpaper Biomil removido'
exit 0