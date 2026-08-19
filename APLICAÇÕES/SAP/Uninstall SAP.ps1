[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$LogFolder = "C:\ProgramData\Bioaroeira\Logs"
$LogFile   = "$LogFolder\SAP-Uninstall.log"

if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
}

Start-Transcript -Path $LogFile -Append

Write-Host "========================================="
Write-Host "       DESINSTALACAO SAP GUI"
Write-Host "========================================="

# ============================================================
# LOCALIZAR SAP
# ============================================================

$SAP = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -like "SAP GUI for Windows 8.00*"
    } |
    Select-Object -First 1

if (!$SAP) {

    Write-Host "SAP GUI nao esta instalado."

    Stop-Transcript
    exit 0
}

Write-Host "SAP encontrado:"
Write-Host $SAP.DisplayName

Write-Host "UninstallString:"
Write-Host $SAP.UninstallString

# ============================================================
# MSI
# ============================================================

if ($SAP.PSChildName -match "^\{.*\}$") {

    $ProductCode = $SAP.PSChildName

    Write-Host "Product Code encontrado:"
    Write-Host $ProductCode

    $Process = Start-Process `
        -FilePath "msiexec.exe" `
        -ArgumentList "/x $ProductCode /qn /norestart" `
        -Wait `
        -PassThru

    Write-Host "Codigo de retorno: $($Process.ExitCode)"
}

# ============================================================
# UNINSTALL STRING EXE
# ============================================================

elseif ($SAP.UninstallString) {

    $Command = $SAP.UninstallString

    Write-Host "Executando desinstalador registrado..."

    if ($Command -match '^"([^"]+)"(.*)$') {

        $Exe  = $Matches[1]
        $Args = $Matches[2].Trim()

    }
    else {

        $Parts = $Command.Split(" ",2)

        $Exe = $Parts[0]

        if ($Parts.Count -gt 1) {
            $Args = $Parts[1]
        }
        else {
            $Args = ""
        }
    }

    Write-Host "Executavel:"
    Write-Host $Exe

    Write-Host "Argumentos:"
    Write-Host $Args

    $Process = Start-Process `
        -FilePath $Exe `
        -ArgumentList $Args `
        -Wait `
        -PassThru

    Write-Host "Codigo de retorno: $($Process.ExitCode)"
}

else {

    Write-Error "Nao foi encontrado comando de desinstalacao."

    Stop-Transcript
    exit 1
}

# ============================================================
# VALIDAR
# ============================================================

Start-Sleep -Seconds 10

$Check = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -like "SAP GUI for Windows 8.00*"
    }

if (!$Check) {

    Write-Host "SAP GUI removido com sucesso."

    Stop-Transcript
    exit 0
}

Write-Error "SAP GUI ainda esta instalado."

Stop-Transcript
exit 1