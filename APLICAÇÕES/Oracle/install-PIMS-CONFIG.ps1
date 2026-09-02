# ============================================================
# ORACLE / PIMCS - CONFIGURACAO FINAL
# Microsoft Intune Win32 App
#
# Configura:
# - BDE / IDAPI32.CFG
# - SQLORA8.DLL
# - WIN.INI
# - Arquivos .REG
# - PATH do sistema
# ============================================================

$ErrorActionPreference = "Stop"

# ============================================================
# CAMINHOS
# ============================================================

$LogDir  = "C:\ProgramData\PIMSDeploy"
$LogFile = "$LogDir\ConfigPIMS.log"

$BDEPath = "C:\Program Files (x86)\Common Files\Borland Shared\BDE"

$SourceSQLORA = Join-Path $PSScriptRoot "sqlora8.dll"

$SourceIDAPI = Join-Path $PSScriptRoot "Config\BDE\IDAPI32.CFG"

$SourceWinINI = Join-Path $PSScriptRoot "Config\Windows\win.ini"

$RegFolder = Join-Path $PSScriptRoot "reg"

$DestinationSQLORA = Join-Path $BDEPath "sqlora8.dll"
$DestinationIDAPI  = Join-Path $BDEPath "IDAPI32.CFG"

$DestinationWinINI = "C:\Windows\win.ini"

# ============================================================
# CRIAR DIRETORIO DE LOG
# ============================================================

if (!(Test-Path $LogDir)) {

    New-Item `
        -Path $LogDir `
        -ItemType Directory `
        -Force |
        Out-Null
}

# ============================================================
# LOG
# ============================================================

function Write-Log {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "$Time - $Message" |
        Out-File `
            -FilePath $LogFile `
            -Append `
            -Encoding UTF8

    Write-Host "$Time - $Message"
}

# ============================================================
# ADICIONAR AO PATH DO SISTEMA
# ============================================================

function Add-SystemPath {

    param(
        [Parameter(Mandatory = $true)]
        [string]$PathToAdd
    )

    Write-Log "Validando PATH: $PathToAdd"

    $MachinePath = [Environment]::GetEnvironmentVariable(
        "Path",
        [EnvironmentVariableTarget]::Machine
    )

    if ([string]::IsNullOrWhiteSpace($MachinePath)) {
        $MachinePath = ""
    }

    $CurrentPaths = $MachinePath -split ";" |
        ForEach-Object {
            $_.Trim().TrimEnd("\")
        } |
        Where-Object {
            $_
        }

    $NormalizedPath = $PathToAdd.Trim().TrimEnd("\")

    $Exists = $CurrentPaths |
        Where-Object {
            $_ -ieq $NormalizedPath
        }

    if ($Exists) {

        Write-Log "PATH ja configurado: $PathToAdd"
        return
    }

    if ([string]::IsNullOrWhiteSpace($MachinePath)) {

        $NewPath = $PathToAdd

    }
    else {

        $NewPath = $MachinePath.TrimEnd(";") + ";" + $PathToAdd
    }

    [Environment]::SetEnvironmentVariable(
        "Path",
        $NewPath,
        [EnvironmentVariableTarget]::Machine
    )

    Write-Log "PATH adicionado: $PathToAdd"
}

# ============================================================
# INICIO
# ============================================================

try {

    Write-Log "================================================"
    Write-Log "INICIO - CONFIGURACAO PIMCS"
    Write-Log "Executando como: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
    Write-Log "PSScriptRoot: $PSScriptRoot"
    Write-Log "================================================"


    # ========================================================
    # 1 - VALIDAR BDE
    # ========================================================

    Write-Log "Validando instalacao do BDE..."

    if (!(Test-Path $BDEPath)) {

        throw "BDE nao encontrado em: $BDEPath"
    }

    Write-Log "BDE encontrado: $BDEPath"


    # ========================================================
    # 2 - VALIDAR SQLORA8.DLL
    # ========================================================

    Write-Log "Validando arquivo sqlora8.dll..."

    if (!(Test-Path $SourceSQLORA)) {

        throw "sqlora8.dll nao encontrado no pacote: $SourceSQLORA"
    }


    # ========================================================
    # 3 - COPIAR SQLORA8.DLL
    # ========================================================

    Write-Log "Copiando sqlora8.dll para o BDE..."

    Copy-Item `
        -Path $SourceSQLORA `
        -Destination $DestinationSQLORA `
        -Force

    if (!(Test-Path $DestinationSQLORA)) {

        throw "Falha ao copiar sqlora8.dll para o BDE."
    }

    Write-Log "sqlora8.dll copiado com sucesso."


    # ========================================================
    # 4 - CONFIGURAR IDAPI32.CFG
    # ========================================================

    if (Test-Path $SourceIDAPI) {

        Write-Log "IDAPI32.CFG encontrado no pacote."

        if (Test-Path $DestinationIDAPI) {

            $IDAPIBackup = Join-Path `
                $LogDir `
                "IDAPI32-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').CFG"

            Write-Log "Criando backup do IDAPI32.CFG..."

            Copy-Item `
                -Path $DestinationIDAPI `
                -Destination $IDAPIBackup `
                -Force

            Write-Log "Backup criado: $IDAPIBackup"
        }

        Write-Log "Aplicando IDAPI32.CFG..."

        Copy-Item `
            -Path $SourceIDAPI `
            -Destination $DestinationIDAPI `
            -Force

        Write-Log "IDAPI32.CFG aplicado."

    }
    else {

        Write-Log "AVISO: IDAPI32.CFG nao encontrado no pacote."
        Write-Log "Mantendo IDAPI32.CFG existente do BDE."

        if (!(Test-Path $DestinationIDAPI)) {

            throw "Nenhum IDAPI32.CFG disponivel."
        }
    }


    # ========================================================
    # 5 - CONFIGURAR WIN.INI
    # ========================================================

    if (!(Test-Path $SourceWinINI)) {

        throw "win.ini nao encontrado no pacote: $SourceWinINI"
    }

    if (Test-Path $DestinationWinINI) {

        $WinINIBackup = Join-Path `
            $LogDir `
            "win-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').ini"

        Write-Log "Criando backup do win.ini..."

        Copy-Item `
            -Path $DestinationWinINI `
            -Destination $WinINIBackup `
            -Force

        Write-Log "Backup criado: $WinINIBackup"
    }

    Write-Log "Aplicando win.ini..."

    Copy-Item `
        -Path $SourceWinINI `
        -Destination $DestinationWinINI `
        -Force

    Write-Log "win.ini aplicado com sucesso."


    # ========================================================
    # 6 - IMPORTAR ARQUIVOS .REG
    # ========================================================

    if (Test-Path $RegFolder) {

        $RegFiles = Get-ChildItem `
            -Path $RegFolder `
            -Filter "*.reg" `
            -File `
            -ErrorAction SilentlyContinue

        foreach ($RegFile in $RegFiles) {

            Write-Log "Importando registro: $($RegFile.Name)"

            $Process = Start-Process `
                -FilePath "reg.exe" `
                -ArgumentList @(
                    "import"
                    "`"$($RegFile.FullName)`""
                ) `
                -Wait `
                -PassThru `
                -WindowStyle Hidden

            Write-Log "REG ExitCode: $($Process.ExitCode)"

            if ($Process.ExitCode -ne 0) {

                throw "Falha ao importar $($RegFile.Name). ExitCode: $($Process.ExitCode)"
            }
        }

        if (!$RegFiles) {

            Write-Log "Nenhum arquivo .reg encontrado."
        }

    }
    else {

        Write-Log "Pasta REG nao encontrada. Ignorando importacao de registro."
    }


    # ========================================================
    # 7 - VARIAVEIS DE AMBIENTE
    # ========================================================

    Write-Log "Configurando PATH do sistema..."

    Add-SystemPath "I:\Deploy"

    Add-SystemPath "I:\Deploy\Axis2c\lib"


    # ========================================================
    # 8 - ATUALIZAR PATH DO PROCESSO ATUAL
    # ========================================================

    $env:Path = `
        [Environment]::GetEnvironmentVariable(
            "Path",
            [EnvironmentVariableTarget]::Machine
        )


    # ========================================================
    # 9 - VALIDACOES FINAIS
    # ========================================================

    Write-Log "Iniciando validacoes finais..."

    if (!(Test-Path $DestinationSQLORA)) {

        throw "Validacao falhou: sqlora8.dll nao encontrado."
    }

    if (!(Test-Path $DestinationIDAPI)) {

        throw "Validacao falhou: IDAPI32.CFG nao encontrado."
    }

    if (!(Test-Path $DestinationWinINI)) {

        throw "Validacao falhou: win.ini nao encontrado."
    }


    # ========================================================
    # VALIDAR PATH
    # ========================================================

    $MachinePath = [Environment]::GetEnvironmentVariable(
        "Path",
        [EnvironmentVariableTarget]::Machine
    )

    $PathArray = $MachinePath -split ";" |
        ForEach-Object {
            $_.Trim().TrimEnd("\")
        }

    if (
        !($PathArray | Where-Object { $_ -ieq "I:\Deploy" })
    ) {

        throw "Validacao falhou: I:\Deploy nao encontrado no PATH."
    }

    if (
        !($PathArray | Where-Object { $_ -ieq "I:\Deploy\Axis2c\lib" })
    ) {

        throw "Validacao falhou: I:\Deploy\Axis2c\lib nao encontrado no PATH."
    }


    # ========================================================
    # 10 - CRIAR MARKER
    # ========================================================

    $Marker = Join-Path $LogDir "ConfigPIMS.done"

    @"
PIMCS Configuration
Status=Installed
Date=$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
SQLORA8=$DestinationSQLORA
IDAPI32=$DestinationIDAPI
WININI=$DestinationWinINI
PATH1=I:\Deploy
PATH2=I:\Deploy\Axis2c\lib
"@ |
        Set-Content `
            -Path $Marker `
            -Encoding ASCII `
            -Force


    # ========================================================
    # SUCESSO
    # ========================================================

    Write-Log "================================================"
    Write-Log "CONFIGURACAO PIMCS CONCLUIDA COM SUCESSO"
    Write-Log "================================================"

    exit 0
}
catch {

    Write-Log "================================================"
    Write-Log "ERRO NA CONFIGURACAO PIMCS"
    Write-Log "ERRO: $($_.Exception.Message)"
    Write-Log "================================================"

    Remove-Item `
        "$LogDir\ConfigPIMS.done" `
        -Force `
        -ErrorAction SilentlyContinue

    exit 1
}