# ============================================================
# HelpDesk Bio - TomTicket
# Instalacao via Microsoft Intune
# ============================================================

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURACOES
# ============================================================

$AppName = "HelpDesk - Bio"

$Url = "https://bioaroeira.tomticket.com/helpdesk"

$CompanyRoot = "C:\ProgramData\Bioaroeira"
$BasePath = "$CompanyRoot\HelpDesk"

$IconName = "HelpDesk.ico"

$IconPath = Join-Path $BasePath $IconName
$DetectionFile = Join-Path $BasePath "installed.txt"

$ShortcutPath = "C:\Users\Public\Desktop\$AppName.url"

$LogPath = "$CompanyRoot\HelpDesk-Bio-install.log"

# ============================================================
# FUNCAO DE LOG
# ============================================================

function Write-Log {

    param(
        [string]$Message
    )

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "[$Time] $Message" |
        Out-File `
            -FilePath $LogPath `
            -Append `
            -Encoding UTF8
}

try {

    # ========================================================
    # CRIAR PASTAS
    # ========================================================

    New-Item `
        -Path $CompanyRoot `
        -ItemType Directory `
        -Force |
        Out-Null

    New-Item `
        -Path $BasePath `
        -ItemType Directory `
        -Force |
        Out-Null

    Write-Log "Inicio da instalacao."

    # ========================================================
    # VALIDAR URL
    # ========================================================

    if ([string]::IsNullOrWhiteSpace($Url)) {
        throw "URL do TomTicket nao configurada."
    }

    Write-Log "URL configurada: $Url"

    # ========================================================
    # LOCALIZAR ICONE NO PACOTE
    # ========================================================

    $SourceIcon = Join-Path $PSScriptRoot $IconName

    Write-Log "Diretorio do script: $PSScriptRoot"
    Write-Log "Procurando icone: $SourceIcon"

    if (-not (Test-Path $SourceIcon)) {

        throw "Arquivo $IconName nao encontrado dentro do pacote."
    }

    # ========================================================
    # COPIAR ICONE
    # ========================================================

    Copy-Item `
        -Path $SourceIcon `
        -Destination $IconPath `
        -Force

    if (-not (Test-Path $IconPath)) {

        throw "Falha ao copiar o icone para $IconPath."
    }

    Write-Log "Icone copiado para: $IconPath"

    # ========================================================
    # REMOVER ATALHO ANTIGO
    # ========================================================

    if (Test-Path $ShortcutPath) {

        Remove-Item `
            -Path $ShortcutPath `
            -Force `
            -ErrorAction SilentlyContinue

        Write-Log "Atalho antigo removido."
    }

    # ========================================================
    # CRIAR ATALHO URL
    # ========================================================

    $ShortcutContent = @"
[InternetShortcut]
URL=$Url
IconFile=$IconPath
IconIndex=0
"@

    Set-Content `
        -Path $ShortcutPath `
        -Value $ShortcutContent `
        -Encoding ASCII `
        -Force

    if (-not (Test-Path $ShortcutPath)) {

        throw "Falha ao criar o atalho."
    }

    Write-Log "Atalho criado: $ShortcutPath"

    # ========================================================
    # CRIAR ARQUIVO DE DETECCAO
    # ========================================================

    $DetectionContent = @"
Application=HelpDesk Bio
Status=Installed
URL=$Url
Icon=$IconPath
InstallDate=$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

    Set-Content `
        -Path $DetectionFile `
        -Value $DetectionContent `
        -Encoding UTF8 `
        -Force

    if (-not (Test-Path $DetectionFile)) {

        throw "Falha ao criar arquivo de deteccao."
    }

    Write-Log "Arquivo de deteccao criado: $DetectionFile"

    # ========================================================
    # VALIDACAO FINAL
    # ========================================================

    $ShortcutExists = Test-Path $ShortcutPath
    $IconExists = Test-Path $IconPath
    $DetectionExists = Test-Path $DetectionFile

    Write-Log "Atalho existe: $ShortcutExists"
    Write-Log "Icone existe: $IconExists"
    Write-Log "Arquivo de deteccao existe: $DetectionExists"

    if (
        $ShortcutExists -and
        $IconExists -and
        $DetectionExists
    ) {

        Write-Log "Instalacao concluida com sucesso."

        Write-Output "HelpDesk Bio instalado com sucesso."

        exit 0
    }

    throw "Falha na validacao final."
}
catch {

    $ErrorMessage = $_.Exception.Message

    Write-Log "ERRO: $ErrorMessage"

    Write-Error $ErrorMessage

    exit 1
}