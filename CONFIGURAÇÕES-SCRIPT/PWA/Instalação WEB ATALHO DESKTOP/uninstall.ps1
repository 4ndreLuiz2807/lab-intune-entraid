# ============================================================
# HelpDesk Bio - TomTicket
# Desinstalacao
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$CompanyRoot = "C:\ProgramData\Bioaroeira"
$BasePath = "$CompanyRoot\HelpDesk"

$ShortcutPath = "C:\Users\Public\Desktop\HelpDesk - Bio.url"

$LogPath = "$CompanyRoot\HelpDesk-Bio-uninstall.log"

function Write-Log {

    param(
        [string]$Message
    )

    if (-not (Test-Path $CompanyRoot)) {

        New-Item `
            -Path $CompanyRoot `
            -ItemType Directory `
            -Force |
            Out-Null
    }

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "[$Time] $Message" |
        Out-File `
            -FilePath $LogPath `
            -Append `
            -Encoding UTF8
}

Write-Log "Inicio da desinstalacao."

# Remover atalho

if (Test-Path $ShortcutPath) {

    Remove-Item `
        -Path $ShortcutPath `
        -Force

    Write-Log "Atalho removido."
}

# Remover pasta do aplicativo

if (Test-Path $BasePath) {

    Remove-Item `
        -Path $BasePath `
        -Recurse `
        -Force

    Write-Log "Pasta do aplicativo removida."
}

# Validacao

if (
    (-not (Test-Path $ShortcutPath)) -and
    (-not (Test-Path $BasePath))
) {

    Write-Log "Desinstalacao concluida."

    Write-Output "HelpDesk Bio removido."

    exit 0
}

Write-Log "Falha na desinstalacao."

exit 1