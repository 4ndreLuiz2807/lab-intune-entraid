$imagem = 'C:\WallpaperBiomil\Biomil.jpg'
$marcador = 'C:\WallpaperBiomil\versao.txt'
$versaoEsperada = '1.0.0'

if (
    (Test-Path -LiteralPath $imagem -PathType Leaf) -and
    (Test-Path -LiteralPath $marcador -PathType Leaf) -and
    ((Get-Content -LiteralPath $marcador -Raw).Trim() -eq $versaoEsperada)
) {
    Write-Output "Wallpaper Biomil $versaoEsperada instalado"
    exit 0
}

exit 1