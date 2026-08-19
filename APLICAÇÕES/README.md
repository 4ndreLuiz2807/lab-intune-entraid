<img src="https://raw.githubusercontent.com/4ndreLuiz2807/lab-intune-entraid/refs/heads/main/APLICA%C3%87%C3%95ES/banner.svg" alt="Banner" width="100%" />

# Microsoft Intune --- Win32 Application Deployment

> Repositório destinado à padronização, documentação e armazenamento de
> pacotes para **deploy de aplicações Win32 através do Microsoft
> Intune**.

Este repositório funciona como ponto central para os softwares
corporativos distribuídos pelo **Microsoft Intune**, reunindo
instaladores, scripts PowerShell, regras de detecção, arquivos de
configuração e documentação necessária para implantação e manutenção dos
aplicativos.

------------------------------------------------------------------------

## 🎯 Objetivo

O objetivo é manter um padrão único para o ciclo de vida das aplicações
Win32:

``` text
Aplicação
    ↓
Preparação dos arquivos
    ↓
Scripts de instalação/desinstalação
    ↓
Empacotamento .intunewin
    ↓
Microsoft Intune
    ↓
Intune Management Extension
    ↓
Dispositivo Windows
    ↓
Detecção e validação
```

Cada software deve possuir sua própria pasta e documentação, permitindo
identificar rapidamente como ele é instalado, removido, detectado e
atualizado.

------------------------------------------------------------------------

## 📦 Estrutura do repositório

Estrutura recomendada:

``` text
Intune-Win32-Apps/
│
├── README.md
│
├── SAP-GUI/
│   ├── README.md
│   ├── Source/
│   │   ├── instalador.exe
│   │   ├── Install.ps1
│   │   └── Uninstall.ps1
│   └── Detection/
│       └── Detect.ps1
│
├── Google-Chrome/
│   ├── README.md
│   ├── Source/
│   └── Detection/
│
├── 7-Zip/
│   ├── README.md
│   ├── Source/
│   └── Detection/
│
└── <Aplicacao>/
    ├── README.md
    ├── Source/
    └── Detection/
```

------------------------------------------------------------------------

## 🗂️ Padrão de cada aplicação

Cada software deve possuir, quando aplicável:

``` text
<Application>/
├── README.md
│
├── Source/
│   ├── setup.exe / setup.msi
│   ├── Install.ps1
│   ├── Uninstall.ps1
│   └── arquivos auxiliares
│
└── Detection/
    └── Detect.ps1
```

### `README.md`

Documentação específica da aplicação, contendo:

-   Nome e versão;
-   Tipo de instalador;
-   Parâmetros silenciosos;
-   Comando de instalação no Intune;
-   Comando de desinstalação;
-   Regra de detecção;
-   Requisitos;
-   Arquivos adicionais;
-   Logs;
-   Procedimentos de troubleshooting.

### `Source`

Contém tudo que precisa ser incluído no pacote `.intunewin`, como:

``` text
setup.exe
setup.msi
Install.ps1
Uninstall.ps1
.xml
.ini
.json
.dll
```

### `Detection`

Contém scripts utilizados pelo Intune para determinar se a aplicação
está instalada corretamente.

------------------------------------------------------------------------

# 🚀 Processo de deploy

## 1. Preparar a aplicação

Crie uma pasta exclusiva:

``` text
C:\Intune\<Aplicacao>\Source
```

Exemplo:

``` text
C:\Intune\MinhaAplicacao\Source\
├── setup.exe
├── Install.ps1
└── Uninstall.ps1
```

------------------------------------------------------------------------

## 2. Validar instalação silenciosa

Antes do empacotamento, valide o instalador e seus parâmetros
silenciosos.

Exemplo:

``` powershell
Start-Process `
    -FilePath ".\setup.exe" `
    -ArgumentList "/silent" `
    -Wait `
    -PassThru
```

Os scripts destinados ao Intune devem funcionar sem interação do
usuário.

------------------------------------------------------------------------

## 3. Utilizar `$PSScriptRoot`

Para arquivos incluídos no mesmo pacote, utilize:

``` powershell
$Installer = Join-Path $PSScriptRoot "setup.exe"
```

Evite caminhos absolutos ou compartilhamentos de rede durante a
instalação.

------------------------------------------------------------------------

## 4. Gerar o `.intunewin`

Utilize o **Microsoft Win32 Content Prep Tool
(`IntuneWinAppUtil.exe`)**.

Exemplo:

``` cmd
IntuneWinAppUtil.exe -c "C:\Intune\MinhaAplicacao\Source" -s "Install.ps1" -o "C:\Intune\Output"
```

No modo interativo:

``` text
Please specify the source folder:
C:\Intune\MinhaAplicacao\Source

Please specify the setup file:
Install.ps1

Please specify the output folder:
C:\Intune\Output
```

> O arquivo informado como **Setup File** é o arquivo principal do
> pacote. Todos os arquivos existentes dentro da pasta Source serão
> incluídos no `.intunewin`.

------------------------------------------------------------------------

# ☁️ Configuração padrão no Intune

## Install command

Para aplicações controladas por PowerShell:

``` text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Install.ps1"
```

## Uninstall command

``` text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Uninstall.ps1"
```

## Install behavior

Preferencialmente:

``` text
System
```

Isso permite que a instalação seja executada pelo **Intune Management
Extension** independentemente do usuário conectado.

------------------------------------------------------------------------

# 🔎 Detecção

Cada aplicação deve possuir uma regra de detecção confiável.

Podem ser utilizadas detecções por:

-   Registro;
-   Arquivo;
-   Pasta;
-   Versão;
-   MSI Product Code;
-   Script PowerShell personalizado.

Exemplo de detecção por registro:

``` powershell
$App = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -like "Nome da Aplicacao*"
    } |
    Select-Object -First 1

if ($App) {
    Write-Output "Aplicacao detectada: $($App.DisplayName)"
    exit 0
}

exit 1
```

------------------------------------------------------------------------

# 📝 Logs

Sempre que possível, os scripts devem possuir logs próprios.

Padrão sugerido:

``` text
C:\ProgramData\<Empresa>\Logs\
```

Exemplo:

``` text
C:\ProgramData\<Empresa>\Logs\MinhaAplicacao-Install.log
```

------------------------------------------------------------------------

## Logs do Intune Management Extension

Para troubleshooting dos aplicativos Win32:

``` text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\
```

Principais arquivos:

``` text
AppWorkload.log
IntuneManagementExtension.log
AgentExecutor.log
```

O `AppWorkload.log` é especialmente útil para analisar:

``` text
Download do pacote
Extração do .intunewin
Comando de instalação
IMECache
Criação do processo
Exit Code
Resultado da instalação
```

------------------------------------------------------------------------

# 📋 Convenção de nomes

Utilize nomes claros e consistentes:

``` text
Install-<Aplicacao>.ps1
Uninstall-<Aplicacao>.ps1
Detect-<Aplicacao>.ps1
```

Exemplo:

``` text
Install-SAP.ps1
Uninstall-SAP.ps1
Detect-SAP.ps1
```

Para os pacotes:

``` text
<Aplicacao>-<Versao>.intunewin
```

------------------------------------------------------------------------

# 🔐 Segurança

Não devem ser armazenados neste repositório:

-   Senhas;
-   Tokens;
-   Chaves privadas;
-   Credenciais administrativas;
-   Segredos de aplicações;
-   Certificados privados;
-   Arquivos contendo informações sensíveis.

Também deve ser avaliado se o instalador possui restrições de
distribuição/licenciamento antes de adicioná-lo ao repositório.

------------------------------------------------------------------------

# ⚠️ Atualização de aplicações

Sempre que um arquivo existente dentro de `Source` for alterado, gere
novamente o pacote `.intunewin`.

Fluxo:

``` text
Alteração
    ↓
Teste local
    ↓
Novo .intunewin
    ↓
Atualização no Intune
    ↓
Grupo piloto
    ↓
Produção
```

------------------------------------------------------------------------

# ✅ Checklist antes do deploy

-   [ ] Instalador correto e versão validada
-   [ ] Instalação silenciosa testada
-   [ ] Script de instalação testado
-   [ ] Script de desinstalação testado
-   [ ] Execução em contexto `SYSTEM` validada
-   [ ] Regra de detecção validada
-   [ ] Logs configurados
-   [ ] Dependências incluídas em `Source`
-   [ ] Nenhuma credencial armazenada
-   [ ] `.intunewin` atualizado
-   [ ] README da aplicação atualizado
-   [ ] Deploy validado em grupo piloto

------------------------------------------------------------------------

# 📚 Aplicações

Cada subpasta deste repositório representa uma aplicação preparada para
distribuição pelo Microsoft Intune.

Consulte o `README.md` existente dentro da pasta de cada software para
obter os comandos, requisitos, parâmetros e procedimentos específicos
daquela aplicação.

------------------------------------------------------------------------

## ℹ️ Sobre este repositório

Este repositório é destinado à documentação e manutenção de **aplicações
Win32 distribuídas através do Microsoft Intune**.

A estrutura tem como objetivo facilitar:

-   Padronização dos deployments;
-   Versionamento dos scripts;
-   Troubleshooting;
-   Atualização de aplicações;
-   Documentação técnica;
-   Reutilização dos pacotes;
-   Administração do ambiente Microsoft Intune.
