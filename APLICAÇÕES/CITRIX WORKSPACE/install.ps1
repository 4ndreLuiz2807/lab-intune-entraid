# ============================================================
# Citrix Workspace App - Instalação via Microsoft Intune
# ============================================================

$ErrorActionPreference = "Stop"

$AppName   = "Citrix Workspace"
$Installer = Join-Path $PSScriptRoot "CitrixWorkspaceApp.exe"

$LogFolder = "C:\ProgramData\IntuneLogs"
$LogFile   = Join-Path $LogFolder "CitrixWorkspace-Install.log"

if (!(Test-Path $LogFolder)) {
    New-Item `
        -Path $LogFolder `
        -ItemType Directory `
        -Force | Out-Null
}

function Write-Log {

    param(
        [string]$Message
    )

    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" |
        Out-File `
        -FilePath $LogFile `
        -Append `
        -Encoding UTF8
}

try {

    Write-Log "================================================"
    Write-Log "Iniciando instalação do $AppName"
    Write-Log "================================================"

    if (!(Test-Path $Installer)) {

        throw "Instalador não encontrado: $Installer"

    }

    Write-Log "Instalador localizado: $Installer"

    # --------------------------------------------------------
    # Instalação silenciosa oficial Citrix
    # --------------------------------------------------------

    $Arguments = @(
        "/silent"
        "/noreboot"
    )

    Write-Log "Executando Citrix Workspace em modo silencioso..."

    $Process = Start-Process `
        -FilePath $Installer `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru

    $ExitCode = $Process.ExitCode

    Write-Log "ExitCode retornado: $ExitCode"

    if ($ExitCode -notin @(0,3010)) {

        throw "Falha durante instalação. ExitCode: $ExitCode"

    }

    # --------------------------------------------------------
    # Aguardar registro/processamento da instalação
    # --------------------------------------------------------

    Start-Sleep -Seconds 5

    # --------------------------------------------------------
    # Procurar Citrix Workspace
    # --------------------------------------------------------

    $RegistryPaths = @(

        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",

        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

    )

    $Citrix = Get-ItemProperty `
        $RegistryPaths `
        -ErrorAction SilentlyContinue |
        Where-Object {

            $_.DisplayName -match "Citrix Workspace"

        } |
        Select-Object -First 1

    if ($Citrix) {

        Write-Log "Citrix Workspace detectado."
        Write-Log "Nome: $($Citrix.DisplayName)"
        Write-Log "Versão: $($Citrix.DisplayVersion)"
        Write-Log "Publisher: $($Citrix.Publisher)"

    }
    else {

        Write-Log "AVISO: instalação retornou sucesso, mas o produto não foi localizado no registro."

    }

    if ($ExitCode -eq 3010) {

        Write-Log "Instalação concluída. Reinicialização pendente."
        exit 3010

    }

    Write-Log "Instalação concluída com sucesso."
    exit 0

}
catch {

    Write-Log "ERRO: $($_.Exception.Message)"

    exit 1
}