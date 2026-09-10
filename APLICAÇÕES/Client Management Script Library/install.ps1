# ============================================================
# HP Client Management Script Library - Intune
# Install.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$AppName       = "HP Client Management Script Library"
$Installer     = "hp-cmsl-1.9.0.exe"
$TargetVersion = [version]"1.9.0"

$LogFolder = "C:\ProgramData\HP-CMSL"
$LogFile   = "$LogFolder\Install.log"

# Criar pasta de logs
if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

function Write-Log {

    param(
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "$Timestamp - $Message" |
        Out-File -FilePath $LogFile -Append -Encoding UTF8
}

try {

    Write-Log "=================================================="
    Write-Log "Iniciando instalação do $AppName"
    Write-Log "Versão alvo: $TargetVersion"
    Write-Log "Executando como: $env:USERNAME"
    Write-Log "=================================================="

    # ---------------------------------------------------------
    # Validar PowerShell
    # ---------------------------------------------------------

    if ($PSVersionTable.PSVersion -lt [version]"5.1") {

        Write-Log "ERRO: PowerShell 5.1 ou superior é obrigatório."

        exit 1
    }

    Write-Log "PowerShell detectado: $($PSVersionTable.PSVersion)"

    # ---------------------------------------------------------
    # Verificar se já está instalado
    # ---------------------------------------------------------

    $InstalledModules =
        Get-Module -ListAvailable -Name "HP.*" -ErrorAction SilentlyContinue

    $ExistingVersion =
        $InstalledModules |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($ExistingVersion) {

        Write-Log "CMSL detectado. Módulo: $($ExistingVersion.Name)"
        Write-Log "Versão detectada: $($ExistingVersion.Version)"

        if ([version]$ExistingVersion.Version -ge $TargetVersion) {

            Write-Log "Versão instalada já atende ao requisito."
            Write-Log "Instalação não necessária."

            exit 0
        }
    }

    # ---------------------------------------------------------
    # Localizar instalador
    # ---------------------------------------------------------

    $InstallerPath = Join-Path $PSScriptRoot $Installer

    if (-not (Test-Path $InstallerPath)) {

        Write-Log "ERRO: Instalador não encontrado:"
        Write-Log $InstallerPath

        exit 1
    }

    Write-Log "Instalador encontrado: $InstallerPath"

    # ---------------------------------------------------------
    # Instalação silenciosa
    # ---------------------------------------------------------

    $Arguments = @(
        "/SP-"
        "/VERYSILENT"
        "/SUPPRESSMSGBOXES"
        "/NORESTART"
        "/LOG=`"$LogFolder\HP-CMSL-Setup.log`""
    )

    Write-Log "Iniciando instalação silenciosa..."

    $Process = Start-Process `
        -FilePath $InstallerPath `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru `
        -WindowStyle Hidden

    Write-Log "Setup finalizado com ExitCode: $($Process.ExitCode)"

    if ($Process.ExitCode -notin @(0,3010)) {

        Write-Log "ERRO: Instalador retornou código inesperado."

        exit $Process.ExitCode
    }

    # ---------------------------------------------------------
    # Atualizar sessão
    # ---------------------------------------------------------

    Start-Sleep -Seconds 5

    # ---------------------------------------------------------
    # Validação
    # ---------------------------------------------------------

    $CMSLModules =
        Get-Module `
            -ListAvailable `
            -Name "HP.*" `
            -ErrorAction SilentlyContinue

    if (-not $CMSLModules) {

        Write-Log "ERRO: Nenhum módulo HP CMSL foi encontrado após instalação."

        exit 1
    }

    $DetectedVersion =
        $CMSLModules |
        Sort-Object Version -Descending |
        Select-Object -First 1

    Write-Log "Módulo detectado: $($DetectedVersion.Name)"
    Write-Log "Versão detectada: $($DetectedVersion.Version)"

    if ([version]$DetectedVersion.Version -lt $TargetVersion) {

        Write-Log "ERRO: versão instalada inferior à versão esperada."

        exit 1
    }

    # ---------------------------------------------------------
    # Teste adicional do CMSL
    # ---------------------------------------------------------

    try {

        Import-Module HP.ClientManagement -ErrorAction Stop

        Write-Log "HP.ClientManagement importado com sucesso."

    }
    catch {

        Write-Log "AVISO: HP.ClientManagement não pôde ser importado."
        Write-Log $_.Exception.Message
    }

    Write-Log "=================================================="
    Write-Log "HP CMSL instalado com sucesso."
    Write-Log "=================================================="

    if ($Process.ExitCode -eq 3010) {
        exit 3010
    }

    exit 0

}
catch {

    Write-Log "ERRO NÃO TRATADO:"
    Write-Log $_.Exception.Message

    exit 1
}