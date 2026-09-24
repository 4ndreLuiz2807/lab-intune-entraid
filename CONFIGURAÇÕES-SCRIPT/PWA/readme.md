# Deploy de Atalho Web via Microsoft Intune

Este repositório contém um modelo para publicar um sistema web no Microsoft Intune como **Win32 App**, criando:

- atalho na Área de Trabalho pública do Windows;
- ícone personalizado `.ico`;
- arquivo de detecção em `C:\ProgramData`;
- script de instalação;
- script de desinstalação;
- script de detecção para o Intune.

O exemplo usa o **HelpDesk Bio / TomTicket**, mas pode ser reutilizado para qualquer outro sistema web.

## Estrutura do pacote

```text
HelpDesk-Bio-User/
├── install.ps1
├── uninstall.ps1
├── detect.ps1
└── HelpDesk.ico
```

> O nome do arquivo `.ico` precisa ser exatamente o mesmo informado nos scripts.

# 1. install.ps1

```powershell
$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURACOES - ALTERE ESTES CAMPOS QUANDO NECESSARIO
# ============================================================

# Nome que aparecera na Area de Trabalho
$AppName = "HelpDesk - Bio"

# URL do sistema
$Url = "https://bioaroeira.tomticket.com/helpdesk"

# Pasta principal da empresa
$CompanyRoot = "C:\ProgramData\Bioaroeira"

# Pasta interna do aplicativo
$BasePath = "$CompanyRoot\HelpDesk"

# Nome do arquivo de icone
$IconName = "HelpDesk.ico"

$IconPath = Join-Path $BasePath $IconName
$DetectionFile = Join-Path $BasePath "installed.txt"
$ShortcutPath = "C:\Users\Public\Desktop\$AppName.url"
$LogPath = "$CompanyRoot\HelpDesk-Bio-install.log"

function Write-Log {
    param([string]$Message)

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "[$Time] $Message" |
        Out-File -FilePath $LogPath -Append -Encoding UTF8
}

try {
    New-Item -Path $CompanyRoot -ItemType Directory -Force | Out-Null
    New-Item -Path $BasePath -ItemType Directory -Force | Out-Null

    Write-Log "Inicio da instalacao."

    if ([string]::IsNullOrWhiteSpace($Url)) {
        throw "URL nao configurada."
    }

    $SourceIcon = Join-Path $PSScriptRoot $IconName

    if (-not (Test-Path $SourceIcon)) {
        throw "Arquivo $IconName nao encontrado dentro do pacote."
    }

    Copy-Item -Path $SourceIcon -Destination $IconPath -Force

    if (-not (Test-Path $IconPath)) {
        throw "Falha ao copiar o icone."
    }

    if (Test-Path $ShortcutPath) {
        Remove-Item -Path $ShortcutPath -Force -ErrorAction SilentlyContinue
    }

    $ShortcutContent = @"
[InternetShortcut]
URL=$Url
IconFile=$IconPath
IconIndex=0
"@

    Set-Content -Path $ShortcutPath -Value $ShortcutContent -Encoding ASCII -Force

    if (-not (Test-Path $ShortcutPath)) {
        throw "Falha ao criar o atalho."
    }

    $DetectionContent = @"
Application=$AppName
Status=Installed
URL=$Url
Icon=$IconPath
InstallDate=$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

    Set-Content -Path $DetectionFile -Value $DetectionContent -Encoding UTF8 -Force

    if (-not (Test-Path $DetectionFile)) {
        throw "Falha ao criar arquivo de deteccao."
    }

    Write-Log "Instalacao concluida com sucesso."
    Write-Output "$AppName instalado com sucesso."
    exit 0
}
catch {
    Write-Log "ERRO: $($_.Exception.Message)"
    Write-Error $_.Exception.Message
    exit 1
}
```

# 2. uninstall.ps1

```powershell
$ErrorActionPreference = "SilentlyContinue"

# Mesmos valores usados no install.ps1
$AppName = "HelpDesk - Bio"
$CompanyRoot = "C:\ProgramData\Bioaroeira"
$BasePath = "$CompanyRoot\HelpDesk"

$ShortcutPath = "C:\Users\Public\Desktop\$AppName.url"
$LogPath = "$CompanyRoot\HelpDesk-Bio-uninstall.log"

function Write-Log {
    param([string]$Message)

    if (-not (Test-Path $CompanyRoot)) {
        New-Item -Path $CompanyRoot -ItemType Directory -Force | Out-Null
    }

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "[$Time] $Message" |
        Out-File -FilePath $LogPath -Append -Encoding UTF8
}

Write-Log "Inicio da desinstalacao."

if (Test-Path $ShortcutPath) {
    Remove-Item -Path $ShortcutPath -Force
    Write-Log "Atalho removido."
}

if (Test-Path $BasePath) {
    Remove-Item -Path $BasePath -Recurse -Force
    Write-Log "Pasta do aplicativo removida."
}

if ((-not (Test-Path $ShortcutPath)) -and (-not (Test-Path $BasePath))) {
    Write-Log "Desinstalacao concluida."
    Write-Output "$AppName removido."
    exit 0
}

Write-Log "Falha na desinstalacao."
exit 1
```

# 3. detect.ps1

```powershell
# ALTERE caso a pasta do sistema seja diferente
$DetectionFile = "C:\ProgramData\Bioaroeira\HelpDesk\installed.txt"

if (Test-Path $DetectionFile) {
    Write-Output "Application detected"
    exit 0
}

exit 1
```

## Onde alterar para outro sistema

As principais variáveis ficam no início do `install.ps1`:

```powershell
$AppName = "Nome do Sistema"
$Url = "https://url-do-sistema"
$CompanyRoot = "C:\ProgramData\NomeDaEmpresa"
$BasePath = "$CompanyRoot\NomeDoSistema"
$IconName = "NomeDoSistema.ico"
```

Exemplo para SAP Web:

```powershell
$AppName = "SAP Web"
$Url = "https://sap.exemplo.com"
$CompanyRoot = "C:\ProgramData\Bioaroeira"
$BasePath = "$CompanyRoot\SAP-Web"
$IconName = "SAP-Web.ico"
```

Exemplo para Portal RH:

```powershell
$AppName = "Portal RH"
$Url = "https://rh.exemplo.com"
$CompanyRoot = "C:\ProgramData\Bioaroeira"
$BasePath = "$CompanyRoot\Portal-RH"
$IconName = "Portal-RH.ico"
```

Depois ajuste os mesmos nomes/pastas em `uninstall.ps1` e `detect.ps1`.

## Atenção ao nome do ícone

Se o pacote contém:

```text
HelpDesk.ico
```

o script precisa usar:

```powershell
$IconName = "HelpDesk.ico"
```

Evite misturar:

```text
HelpDesk.ico
HelpDesk-Bio.ico
helpdesk.ico
```

## Teste local

```powershell
cd C:\Intune\HelpDesk-Bio-User

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Valide:

```powershell
Test-Path "C:\Users\Public\Desktop\HelpDesk - Bio.url"
Test-Path "C:\ProgramData\Bioaroeira\HelpDesk\HelpDesk.ico"
Test-Path "C:\ProgramData\Bioaroeira\HelpDesk\installed.txt"
```

Esperado:

```text
True
True
True
```

Teste a detecção:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\detect.ps1
$LASTEXITCODE
```

Esperado:

```text
Application detected
0
```

# Empacotamento com IntuneWinAppUtil

```powershell
C:\Intune\Tools\IntuneWinAppUtil.exe `
-c "C:\Intune\HelpDesk-Bio-User" `
-s "install.ps1" `
-o "C:\Intune\Output"
```

# Configuração no Microsoft Intune

Crie:

```text
Apps
→ Windows
→ Add
→ Windows app (Win32)
```

## Install command

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1
```

## Uninstall command

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File uninstall.ps1
```

## Install behavior

```text
System
```

## Detection rule

Escolha:

```text
Use a custom detection script
```

Envie `detect.ps1` e configure:

```text
Run script as 32-bit process on 64-bit clients: No
Enforce script signature check: No
```

# Logs

Instalação:

```text
C:\ProgramData\Bioaroeira\HelpDesk-Bio-install.log
```

Desinstalação:

```text
C:\ProgramData\Bioaroeira\HelpDesk-Bio-uninstall.log
```

Consulta:

```powershell
Get-Content "C:\ProgramData\Bioaroeira\HelpDesk-Bio-install.log"
```

# Troubleshooting

## Instalou, mas o Intune retorna falha

Valide:

```powershell
Test-Path "C:\ProgramData\Bioaroeira\HelpDesk\installed.txt"
```

Depois:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\detect.ps1
$LASTEXITCODE
```

Esperado:

```text
Application detected
0
```

## O ícone não aparece

Valide:

```powershell
Test-Path "C:\ProgramData\Bioaroeira\HelpDesk\HelpDesk.ico"
```

Confira o atalho:

```powershell
Get-Content "C:\Users\Public\Desktop\HelpDesk - Bio.url"
```

Esperado:

```ini
[InternetShortcut]
URL=https://bioaroeira.tomticket.com/helpdesk
IconFile=C:\ProgramData\Bioaroeira\HelpDesk\HelpDesk.ico
IconIndex=0
```

Se necessário:

```powershell
Stop-Process -Name explorer -Force
```

# Resumo das variáveis

| Variável | Função | Exemplo |
|---|---|---|
| `$AppName` | Nome exibido na Área de Trabalho | `HelpDesk - Bio` |
| `$Url` | Endereço do sistema | `https://bioaroeira.tomticket.com/helpdesk` |
| `$CompanyRoot` | Pasta principal da empresa | `C:\ProgramData\Bioaroeira` |
| `$BasePath` | Pasta do aplicativo | `C:\ProgramData\Bioaroeira\HelpDesk` |
| `$IconName` | Nome do arquivo `.ico` | `HelpDesk.ico` |

# Fluxo

```text
Microsoft Intune
      ↓
install.ps1
      ↓
Copia o ícone
      ↓
Cria o atalho .url
      ↓
Cria installed.txt
      ↓
detect.ps1
      ↓
Intune detecta o aplicativo
```

## Quando usar este modelo

Este modelo é útil quando você precisa:

- publicar sistemas web no Company Portal;
- controlar o ícone exibido na Área de Trabalho;
- criar o atalho automaticamente;
- instalar em contexto SYSTEM;
- possuir desinstalação limpa;
- usar detecção personalizada no Intune;
- reutilizar a mesma estrutura para vários sistemas.
