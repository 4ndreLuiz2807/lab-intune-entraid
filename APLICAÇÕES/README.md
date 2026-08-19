# Microsoft Intune --- Win32 Applications

Este diretório centraliza os pacotes, scripts e arquivos de configuração
utilizados para distribuição de **aplicações Win32 através do Microsoft
Intune**.

> **Objetivo:** manter um padrão simples, rastreável e reutilizável para
> empacotamento, instalação, desinstalação e detecção de aplicações
> corporativas.

![Banner --- Microsoft Intune Win32 Applications](lab-intune-entraid/APLICAÇÕES)

## Estrutura recomendada

``` text
Win32-Apps/
├── README.md
├── assets/
│   └── intune-win32-banner.png
├── SAP-GUI/
│   ├── Source/
│   │   ├── sap.exe
│   │   ├── Install-SAP.ps1
│   │   └── Uninstall-SAP.ps1
│   ├── Detection/
│   │   └── Detect-SAP.ps1
│   └── README.md
└── <Aplicacao>/
    ├── Source/
    │   ├── <instalador>
    │   ├── Install.ps1
    │   └── Uninstall.ps1
    ├── Detection/
    │   └── Detect.ps1
    └── README.md
```

## Padrão de cada aplicação

Cada aplicação deve possuir, sempre que aplicável:

-   **Instalador** --- `.exe`, `.msi` ou dependências necessárias.
-   **Install.ps1** --- instalação silenciosa.
-   **Uninstall.ps1** --- remoção silenciosa.
-   **Detect.ps1** --- regra de detecção personalizada do Intune.
-   **README.md** --- documentação específica do pacote.
-   **Arquivos de configuração** --- XML, JSON, INI ou demais arquivos
    necessários.

## Empacotamento `.intunewin`

Utilize o **Microsoft Win32 Content Prep Tool
(`IntuneWinAppUtil.exe`)**.

``` cmd
IntuneWinAppUtil.exe -c "C:\Intune\SAP-GUI\Source" -s "Install-SAP.ps1" -o "C:\Intune\Output"
```

O parâmetro `-s` define o arquivo principal, mas **todo o conteúdo da
pasta informada em `-c` é incluído no `.intunewin`**.

## Configuração no Intune

**Instalação**

``` text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Install.ps1"
```

**Desinstalação**

``` text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Uninstall.ps1"
```

**Install behavior:** `System`

Para detecção, utilize **Use a custom detection script** e envie o
`Detect.ps1`.

## Regras para scripts

1.  Executar silenciosamente e sem interação do usuário.
2.  Funcionar no contexto `NT AUTHORITY\SYSTEM`.
3.  Retornar `exit 0` em caso de sucesso.
4.  Retornar código diferente de `0` em caso de falha.
5.  Criar logs persistentes, preferencialmente em
    `C:\ProgramData\<Empresa>\Logs\`.
6.  Utilizar `$PSScriptRoot` para instaladores e dependências incluídos
    no pacote.
7.  Não depender de unidades mapeadas do usuário.
8.  Nunca armazenar senhas, tokens ou credenciais no repositório.

Exemplo:

``` powershell
$Installer = Join-Path $PSScriptRoot "setup.exe"
```

## Padrão de detecção

``` powershell
$App = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "Nome da Aplicacao*" } |
    Select-Object -First 1

if ($App) {
    Write-Output "Aplicacao detectada: $($App.DisplayName)"
    exit 0
}

exit 1
```

## Logs e troubleshooting

Logs próprios dos pacotes:

``` text
C:\ProgramData\<Empresa>\Logs\
```

Logs do Intune Management Extension:

``` text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\
```

Arquivos úteis: `AppWorkload.log`, `IntuneManagementExtension.log` e
`AgentExecutor.log`.

## Convenção de nomes

``` text
Install-<Aplicacao>.ps1
Uninstall-<Aplicacao>.ps1
Detect-<Aplicacao>.ps1
```

Exemplo: `Install-SAP.ps1`, `Uninstall-SAP.ps1` e `Detect-SAP.ps1`.

## Checklist antes do deploy

-   Instalação silenciosa testada localmente.
-   Instalação validada em contexto SYSTEM.
-   Desinstalação testada.
-   Regra de detecção validada.
-   Logs funcionando.
-   Instalador e dependências presentes em `Source`.
-   Nenhuma informação sensível incluída.
-   `.intunewin` recriado após alterações.
-   Aplicação validada em grupo piloto antes da implantação geral.

## Fluxo

``` text
Source
  ↓
IntuneWinAppUtil
  ↓
.intunewin
  ↓
Microsoft Intune
  ↓
Intune Management Extension
  ↓
Install.ps1
  ↓
Aplicação
  ↓
Detect.ps1
  ↓
Sucesso / Falha
```

## Observação

Esta subpasta é destinada a **aplicações Win32 (`.intunewin`)
gerenciadas pelo Microsoft Intune**. Cada aplicação deve permanecer
isolada em sua própria pasta para facilitar versionamento, atualização,
troubleshooting e manutenção.
