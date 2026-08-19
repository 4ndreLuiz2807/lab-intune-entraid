[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$LogFolder = "C:\ProgramData\Bioaroeira\Logs"
$LogFile   = "$LogFolder\SAP-Install.log"

# Criar pasta de log imediatamente
New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null

"==================================================" | Out-File $LogFile -Append
"INICIO INSTALACAO SAP - $(Get-Date)" | Out-File $LogFile -Append
"Usuario: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" | Out-File $LogFile -Append
"PSScriptRoot: $PSScriptRoot" | Out-File $LogFile -Append
"==================================================" | Out-File $LogFile -Append

# ============================================================
# LOCALIZAR INSTALADOR
# ============================================================

$Installer = Join-Path $PSScriptRoot "sap.exe"

"Instalador esperado: $Installer" | Out-File $LogFile -Append

if (!(Test-Path $Installer)) {

    "ERRO: sap.exe nao encontrado." | Out-File $LogFile -Append

    "Arquivos encontrados no pacote:" | Out-File $LogFile -Append

    Get-ChildItem $PSScriptRoot -Force |
        Select-Object Name, Length |
        Out-String |
        Out-File $LogFile -Append

    exit 1
}

"sap.exe encontrado." | Out-File $LogFile -Append

# ============================================================
# VERIFICAR SAP EXISTENTE
# ============================================================

$SAP = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -like "SAP GUI for Windows 8.00*"
    } |
    Select-Object -First 1

if ($SAP) {

    "SAP ja instalado." | Out-File $LogFile -Append
    "Nome: $($SAP.DisplayName)" | Out-File $LogFile -Append
    "Versao: $($SAP.DisplayVersion)" | Out-File $LogFile -Append

    exit 0
}

"SAP nao encontrado. Iniciando instalacao." |
    Out-File $LogFile -Append

# ============================================================
# INSTALAR SAP
# ============================================================

try {

    "Executando: $Installer /Silent" |
        Out-File $LogFile -Append

    $Process = Start-Process `
        -FilePath $Installer `
        -ArgumentList "/Silent" `
        -Wait `
        -PassThru `
        -ErrorAction Stop

    $ExitCode = $Process.ExitCode

    "SAPSetup finalizado." |
        Out-File $LogFile -Append

    "ExitCode: $ExitCode" |
        Out-File $LogFile -Append

}
catch {

    "ERRO EXECUTANDO SAP:" |
        Out-File $LogFile -Append

    $_.Exception.Message |
        Out-File $LogFile -Append

    exit 1
}

# ============================================================
# TRATAR RETORNO
# ============================================================

switch ($ExitCode) {

    0 {
        "SAPSetup retornou sucesso." |
            Out-File $LogFile -Append
    }

    129 {
        "SAP instalado - reinicializacao recomendada." |
            Out-File $LogFile -Append
    }

    130 {
        "SAP instalado - reinicializacao solicitada." |
            Out-File $LogFile -Append
    }

    default {

        "ERRO: SAPSetup retornou codigo $ExitCode" |
            Out-File $LogFile -Append

        exit $ExitCode
    }
}

# ============================================================
# AGUARDAR REGISTRO
# ============================================================

"Aguardando 15 segundos para validacao..." |
    Out-File $LogFile -Append

Start-Sleep -Seconds 15

# ============================================================
# VALIDAR
# ============================================================

$SAP = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -like "SAP GUI for Windows 8.00*"
    } |
    Select-Object -First 1

if ($SAP) {

    "==================================================" |
        Out-File $LogFile -Append

    "SAP INSTALADO COM SUCESSO" |
        Out-File $LogFile -Append

    "Nome: $($SAP.DisplayName)" |
        Out-File $LogFile -Append

    "Versao: $($SAP.DisplayVersion)" |
        Out-File $LogFile -Append

    "==================================================" |
        Out-File $LogFile -Append

    exit 0
}

"ERRO: SAPSetup terminou mas SAP nao foi detectado." |
    Out-File $LogFile -Append

exit 1
