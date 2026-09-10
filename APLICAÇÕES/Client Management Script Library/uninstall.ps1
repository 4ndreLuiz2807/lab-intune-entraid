# ============================================================
# HP CMSL - Intune
# uninstall.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$LogFolder = "C:\ProgramData\HP-CMSL"
$LogFile   = "$LogFolder\Uninstall.log"

if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

function Write-Log {

    param([string]$Message)

    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" |
        Out-File $LogFile -Append -Encoding UTF8
}

try {

    Write-Log "Iniciando remoção do HP CMSL."

    $UninstallKeys = @(

        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

    )

    $App =
        Get-ItemProperty $UninstallKeys -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -like "*HP Client Management Script Library*"
        } |
        Select-Object -First 1

    if (-not $App) {

        Write-Log "HP CMSL não encontrado."
        exit 0
    }

    Write-Log "Aplicativo encontrado: $($App.DisplayName)"
    Write-Log "Versão: $($App.DisplayVersion)"

    $UninstallString = $App.UninstallString

    Write-Log "UninstallString: $UninstallString"

    # Remover aspas
    $UninstallExe = $UninstallString.Trim('"')

    # Caso existam argumentos registrados
    if ($UninstallExe -match '^"([^"]+)"') {

        $UninstallExe = $Matches[1]

    }

    if (-not (Test-Path $UninstallExe)) {

        # Tentar extrair apenas o executável
        $UninstallExe =
            ($UninstallString -replace '"','').Split(".exe")[0] + ".exe"
    }

    if (-not (Test-Path $UninstallExe)) {

        Write-Log "ERRO: desinstalador não encontrado."

        exit 1
    }

    Write-Log "Executando: $UninstallExe"

    $Process = Start-Process `
        -FilePath $UninstallExe `
        -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" `
        -Wait `
        -PassThru `
        -WindowStyle Hidden

    Write-Log "ExitCode: $($Process.ExitCode)"

    if ($Process.ExitCode -notin @(0,3010)) {
        exit $Process.ExitCode
    }

    Write-Log "Remoção concluída."

    exit 0

}
catch {

    Write-Log $_.Exception.Message

    exit 1
}