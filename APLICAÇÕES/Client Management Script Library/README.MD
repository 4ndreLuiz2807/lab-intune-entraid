
# HP Client Management Script Library (HP CMSL) via Microsoft Intune

Este projeto documenta o processo de empacotamento e implantação do **HP Client Management Script Library (HP CMSL)** através do **Microsoft Intune**, utilizando o formato **Win32 App (`.intunewin`)**.

O objetivo é realizar uma instalação silenciosa, controlada pelo Intune, com:

- instalação em contexto **SYSTEM**;
- instalação silenciosa;
- logs locais;
- detecção automática;
- suporte à desinstalação;
- validação da versão instalada;
- troubleshooting de falhas de implantação.

---

## Visão geral

Fluxo utilizado:

```text
Microsoft Intune
      |
      v
HP-CMSL.intunewin
      |
      v
install.ps1
      |
      v
hp-cmsl-1.9.0.exe
      |
      v
Instalação silenciosa
      |
      v
HP.ClientManagement
      |
      v
detect.ps1
      |
      +--> Detectado   = Sucesso
      |
      +--> Não detectado = Falha / Retry
```

---

# 1. Pré-requisitos

Antes de iniciar, tenha disponível:

- Microsoft Intune;
- Microsoft Intune Management Extension;
- Microsoft Win32 Content Prep Tool;
- instalador do HP CMSL;
- PowerShell 5.1 ou superior;
- dispositivo Windows compatível.

Neste projeto foi utilizado:

```text
HP Client Management Script Library 1.9.0
```

Instalador:

```text
hp-cmsl-1.9.0.exe
```

---

# 2. Estrutura do projeto

Crie uma pasta para o pacote.

Exemplo:

```text
C:\Deploy\HP CMSL Deploy\HP-CMSL
```

A estrutura deve ficar exatamente assim:

```text
HP-CMSL\
│
├── hp-cmsl-1.9.0.exe
├── install.ps1
├── uninstall.ps1
└── detect.ps1
```

> **Importante:** o instalador `.exe` deve estar no mesmo diretório do `install.ps1`.

Antes de empacotar, valide com:

```cmd
dir "C:\Deploy\HP CMSL Deploy\HP-CMSL"
```

Resultado esperado:

```text
detect.ps1
hp-cmsl-1.9.0.exe
install.ps1
uninstall.ps1
```

---

# 3. Script de instalação

Arquivo:

```text
install.ps1
```

Exemplo utilizado:

```powershell
$ErrorActionPreference = "Stop"

$AppName       = "HP Client Management Script Library"
$TargetVersion = [version]"1.9.0"

$LogFolder = "C:\ProgramData\HP-CMSL"
$LogFile   = "$LogFolder\Install.log"

if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param([string]$Message)

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "$Timestamp - $Message" |
        Out-File -FilePath $LogFile -Append -Encoding UTF8
}

try {

    Write-Log "=================================================="
    Write-Log "Iniciando instalacao do $AppName"
    Write-Log "Versao alvo: $TargetVersion"
    Write-Log "Executando como: $env:USERNAME"
    Write-Log "=================================================="

    if ($PSVersionTable.PSVersion -lt [version]"5.1") {
        Write-Log "ERRO: PowerShell 5.1 ou superior e obrigatorio."
        exit 1
    }

    Write-Log "PowerShell detectado: $($PSVersionTable.PSVersion)"

    # Localiza automaticamente o instalador HP CMSL
    $InstallerFile = Get-ChildItem -Path $PSScriptRoot -Filter "hp-cmsl*.exe" |
        Select-Object -First 1

    if (-not $InstallerFile) {

        Write-Log "ERRO: Instalador HP CMSL nao encontrado em:"
        Write-Log $PSScriptRoot

        Get-ChildItem $PSScriptRoot | ForEach-Object {
            Write-Log "Arquivo encontrado: $($_.Name)"
        }

        exit 1
    }

    $InstallerPath = $InstallerFile.FullName

    Write-Log "Instalador encontrado:"
    Write-Log $InstallerPath

    $Arguments = @(
        "/SP-"
        "/VERYSILENT"
        "/SUPPRESSMSGBOXES"
        "/NORESTART"
    )

    Write-Log "Iniciando instalacao silenciosa..."

    $Process = Start-Process `
        -FilePath $InstallerPath `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru `
        -WindowStyle Hidden

    Write-Log "Setup finalizado com ExitCode: $($Process.ExitCode)"

    if ($Process.ExitCode -notin @(0,3010)) {
        Write-Log "ERRO: Instalador retornou codigo inesperado."
        exit $Process.ExitCode
    }

    Start-Sleep -Seconds 5

    $Module = Get-Module -ListAvailable HP.ClientManagement |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $Module) {
        Write-Log "ERRO: HP.ClientManagement nao foi encontrado apos a instalacao."
        exit 1
    }

    Write-Log "HP.ClientManagement detectado."
    Write-Log "Versao instalada: $($Module.Version)"

    if ([version]$Module.Version -lt $TargetVersion) {
        Write-Log "ERRO: Versao instalada inferior a versao requerida."
        exit 1
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

    Write-Log "ERRO:"
    Write-Log $_.Exception.Message

    exit 1
}
```

---

# 4. Parâmetros silenciosos

Foram utilizados os seguintes parâmetros:

```text
/SP-
/VERYSILENT
/SUPPRESSMSGBOXES
/NORESTART
```

Objetivo:

| Parâmetro | Função |
|---|---|
| `/SP-` | Remove prompts iniciais |
| `/VERYSILENT` | Executa sem interface gráfica |
| `/SUPPRESSMSGBOXES` | Evita caixas de diálogo |
| `/NORESTART` | Impede reinicialização automática |

---

# 5. Script de detecção

Arquivo:

```text
detect.ps1
```

Conteúdo:

```powershell
$TargetVersion = [version]"1.9.0"

$Module = Get-Module -ListAvailable HP.ClientManagement |
    Sort-Object Version -Descending |
    Select-Object -First 1

if ($Module -and ([version]$Module.Version -ge $TargetVersion)) {

    Write-Output "HP CMSL $($Module.Version) instalado."
    exit 0
}

exit 1
```

A detecção considera sucesso quando:

```text
HP.ClientManagement >= 1.9.0
```

---

# 6. Script de desinstalação

Arquivo:

```text
uninstall.ps1
```

Exemplo:

```powershell
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

    Write-Log "Iniciando remocao do HP CMSL."

    $UninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $App = Get-ItemProperty $UninstallKeys -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -like "*HP Client Management Script Library*"
        } |
        Select-Object -First 1

    if (-not $App) {
        Write-Log "HP CMSL nao encontrado."
        exit 0
    }

    Write-Log "Aplicativo encontrado: $($App.DisplayName)"
    Write-Log "Versao: $($App.DisplayVersion)"

    $UninstallString = $App.UninstallString

    if ($UninstallString -match '^"([^"]+)"') {
        $UninstallExe = $Matches[1]
    }
    else {
        $UninstallExe = ($UninstallString -replace '"','').Split(".exe")[0] + ".exe"
    }

    if (-not (Test-Path $UninstallExe)) {
        Write-Log "ERRO: Desinstalador nao encontrado."
        exit 1
    }

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

    Write-Log "Remocao concluida."

    exit 0
}
catch {

    Write-Log $_.Exception.Message
    exit 1
}
```

---

# 7. Empacotamento com IntuneWinAppUtil

Ferramenta:

```text
IntuneWinAppUtil.exe
```

Exemplo de localização:

```text
C:\IntuneWinAppUtil\IntuneWinAppUtil.exe
```

Como o empacotamento foi realizado através do CMD, foi utilizado o comando em uma única linha:

```cmd
C:\IntuneWinAppUtil\IntuneWinAppUtil.exe -c "C:\Deploy\HP CMSL Deploy\HP-CMSL" -s "install.ps1" -o "C:\Deploy\Output"
```

Onde:

```text
-c = pasta de origem
-s = arquivo principal de instalação
-o = diretório de saída
```

Arquivo gerado:

```text
C:\Deploy\Output\install.intunewin
```

Opcionalmente, o arquivo pode ser renomeado para:

```text
HP-CMSL-1.9.0.intunewin
```

---

# 8. CMD x PowerShell

Durante o processo ocorreu um erro ao utilizar:

```cmd
C:\IntuneWinAppUtil\IntuneWinAppUtil.exe `
-c "C:\Deploy\HP CMSL Deploy\HP-CMSL" `
-s "install.ps1" `
-o "C:\Deploy\Output"
```

Isso ocorreu porque o comando estava sendo executado no **CMD**.

O caractere:

```text
`
```

é utilizado pelo PowerShell para quebra de linha.

No CMD, deve-se usar o comando em uma única linha:

```cmd
C:\IntuneWinAppUtil\IntuneWinAppUtil.exe -c "C:\Deploy\HP CMSL Deploy\HP-CMSL" -s "install.ps1" -o "C:\Deploy\Output"
```

Ou utilizar `^` para continuar o comando:

```cmd
C:\IntuneWinAppUtil\IntuneWinAppUtil.exe ^
-c "C:\Deploy\HP CMSL Deploy\HP-CMSL" ^
-s "install.ps1" ^
-o "C:\Deploy\Output"
```

---

# 9. Criando o aplicativo Win32 no Intune

Acesse:

```text
Microsoft Intune Admin Center
>
Apps
>
Windows
>
Add
>
Windows app (Win32)
```

Selecione:

```text
HP-CMSL-1.9.0.intunewin
```

---

# 10. Informações do aplicativo

Sugestão:

```text
Name:
HP Client Management Script Library

Publisher:
HP Inc.

Version:
1.9.0

Category:
IT / Drivers e Firmware
```

---

# 11. Comando de instalação no Intune

Utilizado:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\install.ps1"
```

---

# 12. Comando de desinstalação no Intune

Utilizado:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\uninstall.ps1"
```

---

# 13. Install behavior

Configure:

```text
Install behavior:
System
```

Isso faz com que a instalação seja executada através do contexto da máquina.

Durante os testes, foi possível confirmar esse comportamento através do log:

```text
Executando como: NOME-DO-COMPUTADOR$
```

O `$` no final indica a conta de computador utilizada no contexto SYSTEM.

---

# 14. Device restart behavior

Configure:

```text
Device restart behavior:
No specific action
```

Os códigos tratados pelo script são:

```text
0
3010
```

Onde:

```text
0    = instalação concluída
3010 = instalação concluída, reinicialização necessária
```

---

# 15. Requirements

Sugestão:

```text
Operating system architecture:
64-bit

Minimum operating system:
Windows 10 22H2
```

Dependendo do ambiente, esses requisitos podem ser adaptados.

---

# 16. Detection Rules

Selecione:

```text
Rules format:
Use a custom detection script
```

Envie:

```text
detect.ps1
```

Configure:

```text
Run script as 32-bit process on 64-bit clients:
No

Enforce script signature check:
No
```

---

# 17. Logs da instalação

O script cria seus próprios logs em:

```text
C:\ProgramData\HP-CMSL\
```

Principal:

```text
C:\ProgramData\HP-CMSL\Install.log
```

Para consultar:

```powershell
Get-Content "C:\ProgramData\HP-CMSL\Install.log"
```

Log de desinstalação:

```text
C:\ProgramData\HP-CMSL\Uninstall.log
```

Consulta:

```powershell
Get-Content "C:\ProgramData\HP-CMSL\Uninstall.log"
```

---

# 18. Logs do Microsoft Intune Management Extension

Os principais logs do Intune estão em:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Para visualizar as últimas linhas:

```powershell
Get-Content "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Tail 100
```

Também pode ser utilizado:

```powershell
Get-Content "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log" -Tail 100
```

---

# 19. Problema encontrado durante a implantação

Na primeira tentativa, o Intune apresentou falha de instalação.

O log criado pelo `install.ps1` mostrou:

```text
ERRO: Instalador não encontrado:

C:\WINDOWS\IMECache\<APP-ID>\hp-cmsl-1.9.0.exe
```

Também não existia:

```text
C:\ProgramData\HP-CMSL\HP-CMSL-Setup.log
```

Isso indicava que o executável do HP CMSL nunca chegou a ser iniciado.

---

# 20. Causa

O `install.ps1` estava sendo executado normalmente pelo Intune, porém não encontrava:

```text
hp-cmsl-1.9.0.exe
```

no diretório extraído pelo Intune Management Extension.

Ou seja:

```text
Download do .intunewin = OK

Execução do install.ps1 = OK

Contexto SYSTEM = OK

Localização do instalador = FALHA
```

---

# 21. Correção aplicada

Foi garantido que todos os arquivos estivessem dentro da mesma pasta antes do empacotamento:

```text
HP-CMSL\
│
├── hp-cmsl-1.9.0.exe
├── install.ps1
├── uninstall.ps1
└── detect.ps1
```

Além disso, o script foi melhorado para procurar automaticamente o executável:

```powershell
$InstallerFile = Get-ChildItem -Path $PSScriptRoot -Filter "hp-cmsl*.exe" |
    Select-Object -First 1
```

Dessa forma, o script não depende exclusivamente de:

```text
hp-cmsl-1.9.0.exe
```

e pode localizar versões futuras, como:

```text
hp-cmsl-1.9.1.exe
hp-cmsl-2.0.0.exe
```

desde que o restante da lógica de versão também seja revisado.

---

# 22. Reempacotamento após a correção

Após corrigir a estrutura, o pacote foi gerado novamente:

```cmd
C:\IntuneWinAppUtil\IntuneWinAppUtil.exe -c "C:\Deploy\HP CMSL Deploy\HP-CMSL" -s "install.ps1" -o "C:\Deploy\Output"
```

O novo `.intunewin` foi enviado novamente para o Intune.

---

# 23. Validação local

Antes de distribuir para produção, é recomendado testar localmente.

Entre na pasta:

```powershell
cd "C:\Deploy\HP CMSL Deploy\HP-CMSL"
```

Execute:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\install.ps1"
```

Depois valide:

```powershell
Get-Module -ListAvailable HP.ClientManagement
```

Também é possível consultar todos os módulos HP:

```powershell
Get-Module -ListAvailable -Name "HP.*" |
    Select-Object Name,Version,Path
```

---

# 24. Validando o CMSL instalado

Após a implantação, execute:

```powershell
Get-Module -ListAvailable HP.ClientManagement
```

Ou:

```powershell
Get-Module -ListAvailable -Name "HP.*"
```

O módulo deve aparecer instalado.

Exemplo de comandos que podem ser utilizados posteriormente:

```powershell
Import-Module HP.ClientManagement
```

```powershell
Get-HPBIOSVersion
```

```powershell
Get-HPBIOSSettings
```

---

# 25. Checklist para produção

Antes de atribuir o aplicativo para vários dispositivos:

- [ ] Instalador HP CMSL presente no pacote;
- [ ] `install.ps1` presente;
- [ ] `uninstall.ps1` presente;
- [ ] `detect.ps1` presente;
- [ ] `.intunewin` recriado após alterações;
- [ ] Install behavior configurado como `System`;
- [ ] instalação testada em dispositivo piloto;
- [ ] detecção validada;
- [ ] logs validados;
- [ ] desinstalação testada;
- [ ] grupo piloto utilizado antes da distribuição geral.

---

# 26. Configuração final utilizada

```text
Application:
HP Client Management Script Library 1.9.0

Type:
Windows app (Win32)

Install command:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\install.ps1"

Uninstall command:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\uninstall.ps1"

Install behavior:
System

Restart behavior:
No specific action

Detection:
Custom detection script

Detection script:
detect.ps1

Run as 32-bit:
No

Signature check:
No
```

---

# Conclusão

A implantação do **HP Client Management Script Library através do Microsoft Intune** permite centralizar e automatizar a instalação dos módulos HP utilizados em tarefas de gerenciamento de endpoints.

O principal aprendizado durante a implantação foi validar não apenas o comando configurado no Intune, mas também o conteúdo efetivamente incluído no `.intunewin`.

O Intune Management Extension conseguiu:

```text
Baixar o pacote
        |
        v
Extrair o conteúdo
        |
        v
Executar install.ps1 como SYSTEM
        |
        v
Localizar o HP CMSL
        |
        v
Executar instalação silenciosa
        |
        v
Validar HP.ClientManagement
        |
        v
Registrar instalação como concluída
```

Com esse modelo, o CMSL passa a fazer parte do catálogo corporativo de aplicações administradas pelo Microsoft Intune.

---

## Tecnologias utilizadas

- Microsoft Intune
- Microsoft Intune Management Extension
- PowerShell
- HP Client Management Script Library
- Microsoft Win32 Content Prep Tool
- Windows 10 / Windows 11

---

## Autor

**André Luiz**

Infraestrutura de TI | Microsoft Intune | Entra ID | Windows | PowerShell
