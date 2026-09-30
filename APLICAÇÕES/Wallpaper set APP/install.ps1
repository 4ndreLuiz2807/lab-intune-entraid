$ErrorActionPreference = 'Stop'

$versao = '1.0.0'
$origem = Join-Path $PSScriptRoot 'Biomil.jpg'
$pasta = 'C:\WallpaperBiomil'
$destino = Join-Path $pasta 'Biomil.jpg'
$temporario = Join-Path $pasta 'Biomil.novo.jpg'
$marcador = Join-Path $pasta 'versao.txt'

if (-not (Test-Path -LiteralPath $origem -PathType Leaf)) {
    throw "Biomil.jpg não foi encontrado junto ao install.ps1"
}

New-Item -Path $pasta -ItemType Directory -Force | Out-Null

# Copia primeiro para um arquivo temporário e depois substitui a versão anterior.
Copy-Item -LiteralPath $origem -Destination $temporario -Force
Move-Item -LiteralPath $temporario -Destination $destino -Force

# O marcador só é atualizado após a imagem ser copiada com sucesso.
Set-Content -LiteralPath $marcador -Value $versao -Encoding ASCII

Write-Output "Wallpaper Biomil $versao instalado em $destino"
exit 0