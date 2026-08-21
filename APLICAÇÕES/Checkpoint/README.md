# Deploy do Check Point Harmony Endpoint via Microsoft Intune

Documentação de referência para preparação, teste, empacotamento e
distribuição do **Check Point Harmony Endpoint** como aplicativo **Win32
(.intunewin)** pelo Microsoft Intune.

> **Cenário utilizado:** pacote personalizado `GRP-ADM.exe`. Antes de
> publicar em produção, valide os parâmetros silenciosos e a regra de
> detecção com a versão do instalador exportada do seu ambiente Check
> Point.

------------------------------------------------------------------------

## 1. Objetivo

Automatizar a instalação do Check Point Harmony Endpoint em dispositivos
Windows gerenciados pelo Microsoft Intune, executando o instalador em
**contexto SYSTEM**, com instalação silenciosa, logs locais e uma regra
de detecção confiável.

Fluxo:

``` text
Check Point Portal
      ↓
Exportação do pacote
      ↓
Teste local do instalador
      ↓
Criação do script install.ps1
      ↓
Empacotamento .intunewin
      ↓
Criação do Win32 App no Intune
      ↓
Detection Rule
      ↓
Assignments
      ↓
Validação e troubleshooting
```

------------------------------------------------------------------------

## 2. Pré-requisitos

-   Microsoft Intune configurado e dispositivos Windows inscritos.
-   Permissão para criar aplicativos no Intune.
-   Instalador exportado do ambiente Check Point Harmony Endpoint.
-   Microsoft Win32 Content Prep Tool (`IntuneWinAppUtil.exe`).
-   PowerShell 5.1 ou superior.
-   Máquina de teste antes da implantação em produção.
-   Executar os testes locais como Administrador.

------------------------------------------------------------------------

## 3. Estrutura de trabalho

Crie uma pasta para o pacote:

``` text
CheckPoint-Harmony-Intune\
│
├── Source\
│   ├── GRP-ADM.exe
│   ├── install.ps1
│   └── uninstall.ps1
│
├── Output\
│
└── README.md
```

Exemplo:

``` powershell
New-Item -ItemType Directory -Path "C:\Deploy\CheckPoint-Harmony-Intune\Source" -Force
New-Item -ItemType Directory -Path "C:\Deploy\CheckPoint-Harmony-Intune\Output" -Force
```

Copie `GRP-ADM.exe` para:

``` text
C:\Deploy\CheckPoint-Harmony-Intune\Source
```

------------------------------------------------------------------------

## 4. Validar o instalador manualmente

Abra o PowerShell **como Administrador** e entre na pasta:

``` powershell
Set-Location "C:\Deploy\CheckPoint-Harmony-Intune\Source"
```

Confirme:

``` powershell
Get-ChildItem
```

### 4.1 Teste de geração de MSI

Caso o pacote fornecido suporte a geração de MSI, teste:

``` powershell
.\GRP-ADM.exe /CreateMSI
```

Procure arquivos MSI:

``` powershell
Get-ChildItem -Path . -Filter *.msi -Recurse |
    Select-Object FullName, Length, LastWriteTime
```

> Se nenhum MSI for criado, não considere isso automaticamente uma falha
> do Intune. O pacote exportado pode não oferecer esse modo. Continue
> validando o comando de instalação disponibilizado para o pacote.

### 4.2 Teste do comando silencioso

Para o pacote utilizado neste projeto, o comando inicialmente testado
foi:

``` powershell
.\GRP-ADM.exe /sAll /rs /rps /msi EULA_ACCEPT=YES
```

Após o processo finalizar:

``` powershell
$LASTEXITCODE
```

Valide se algum produto Check Point foi registrado:

``` powershell
Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "Check Point|Harmony|Endpoint"
} |
Select-Object DisplayName, DisplayVersion, PSChildName, InstallLocation
```

Valide também os serviços:

``` powershell
Get-Service |
Where-Object {
    $_.DisplayName -match "Check Point|Harmony" -or
    $_.Name -match "CheckPoint|Harmony"
} |
Select-Object Name, DisplayName, Status
```

**Não publique o pacote no Intune até a instalação silenciosa funcionar
localmente.**

------------------------------------------------------------------------

## 5. Script de instalação

Crie `install.ps1` dentro da pasta `Source`:

``` powershell
$ErrorActionPreference = "Stop"

$LogDirectory = "C:\ProgramData\CheckPoint\Logs"
$LogFile = Join-Path $LogDirectory "Harmony-Install.log"
$Installer = Join-Path $PSScriptRoot "GRP-ADM.exe"

New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null

function Write-Log {
    param([string]$Message)

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

try {
    Write-Log "========== INICIO DA INSTALACAO =========="
    Write-Log "Executando como: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
    Write-Log "Diretorio do pacote: $PSScriptRoot"
    Write-Log "Instalador: $Installer"

    if (-not (Test-Path $Installer)) {
        throw "Instalador GRP-ADM.exe nao encontrado."
    }

    $Arguments = "/sAll /rs /rps /msi EULA_ACCEPT=YES"

    Write-Log "Executando: GRP-ADM.exe $Arguments"

    $Process = Start-Process `
        -FilePath $Installer `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru

    $ExitCode = $Process.ExitCode

    Write-Log "Exit Code retornado: $ExitCode"

    if ($ExitCode -in @(0, 3010, 1641)) {
        Write-Log "Instalacao finalizada com codigo aceito."
        exit $ExitCode
    }

    throw "Instalador retornou Exit Code $ExitCode"
}
catch {
    Write-Log "ERRO: $($_.Exception.Message)"
    Write-Log "========== FALHA =========="
    exit 1
}
```

O log ficará em:

``` text
C:\ProgramData\CheckPoint\Logs\Harmony-Install.log
```

------------------------------------------------------------------------

## 6. Testar o script antes do empacotamento

Na pasta `Source`:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\install.ps1"
```

Depois:

``` powershell
Get-Content "C:\ProgramData\CheckPoint\Logs\Harmony-Install.log" -Tail 100
```

Confirme novamente a instalação:

``` powershell
Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "Check Point|Harmony|Endpoint"
} |
Select-Object DisplayName, DisplayVersion, PSChildName
```

Anote o `PSChildName`. Caso seja um GUID MSI, ele poderá ser utilizado
posteriormente na regra de detecção.

------------------------------------------------------------------------

## 7. Empacotar como Win32 App

Coloque o `IntuneWinAppUtil.exe`, por exemplo, em:

``` text
C:\Deploy\IntuneWinAppUtil.exe
```

Execute:

``` powershell
C:\Deploy\IntuneWinAppUtil.exe
```

Informe:

``` text
Please specify the source folder:
C:\Deploy\CheckPoint-Harmony-Intune\Source

Please specify the setup file:
install.ps1

Please specify the output folder:
C:\Deploy\CheckPoint-Harmony-Intune\Output

Do you want to specify catalog folder:
N
```

Também é possível executar diretamente:

``` powershell
C:\Deploy\IntuneWinAppUtil.exe `
    -c "C:\Deploy\CheckPoint-Harmony-Intune\Source" `
    -s "install.ps1" `
    -o "C:\Deploy\CheckPoint-Harmony-Intune\Output"
```

Será criado:

``` text
install.intunewin
```

> O IntuneWinAppUtil empacota o conteúdo da pasta `Source`, não apenas o
> arquivo informado como setup. Portanto, `GRP-ADM.exe` e os scripts
> devem estar dentro da pasta antes da criação do `.intunewin`.

------------------------------------------------------------------------

## 8. Criar o aplicativo no Intune

No **Intune Admin Center**:

``` text
Apps
→ Windows
→ Create
→ App type
→ Windows app (Win32)
```

Envie:

``` text
install.intunewin
```

Sugestão:

``` text
Name: Check Point Harmony Endpoint
Publisher: Check Point Software Technologies
Description: Check Point Harmony Endpoint - Deploy corporativo via Microsoft Intune
```

------------------------------------------------------------------------

## 9. Program

### Install command

``` text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

### Uninstall command

Defina somente depois de validar o método de remoção suportado pela
versão implantada. Não reutilize um ProductCode de outra versão do
Harmony.

### Install behavior

``` text
System
```

### Device restart behavior

``` text
App install may force a device restart
```

Ajuste conforme o comportamento validado no seu pacote.

------------------------------------------------------------------------

## 10. Requirements

Exemplo inicial:

``` text
Operating system architecture:
64-bit

Minimum operating system:
Windows 10 22H2
```

Ajuste os requisitos para os sistemas efetivamente homologados no seu
ambiente.

------------------------------------------------------------------------

## 11. Detection Rule

A regra deve ser baseada no que **realmente existir após uma instalação
bem-sucedida**.

### Opção recomendada: MSI Product Code

Depois da instalação manual:

``` powershell
Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "Check Point|Harmony|Endpoint"
} |
Select-Object DisplayName, DisplayVersion, PSChildName
```

Se o produto retornar, por exemplo:

``` text
DisplayName    : Check Point Endpoint Security
DisplayVersion : X.X.X
PSChildName    : {PRODUCT-CODE-VALIDADO}
```

configure a regra utilizando **o ProductCode encontrado no seu próprio
ambiente**.

### Importante

Durante o troubleshooting deste projeto, a regra estava verificando:

``` text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\
{45CB4B1A-BBB8-47E4-AA69-B76116EE9A34}

DisplayName = Check Point Endpoint Security
```

Porém, a detecção retornou `False`. Portanto, **não copie esse GUID para
outro ambiente sem validar**.

------------------------------------------------------------------------

## 12. Assignments

Primeiro publique para um grupo piloto.

Exemplo:

``` text
GRP-INTUNE-PILOT-CHECKPOINT
```

Configure:

``` text
Assignments
→ Required
→ Add group
→ GRP-INTUNE-PILOT-CHECKPOINT
```

Após homologação, amplie gradualmente a implantação.

------------------------------------------------------------------------

## 13. Sincronizar o dispositivo

No Windows:

``` text
Settings
→ Accounts
→ Access work or school
→ Conta corporativa
→ Info
→ Sync
```

Também é possível reiniciar o serviço da Intune Management Extension
durante troubleshooting:

``` powershell
Restart-Service IntuneManagementExtension
```

------------------------------------------------------------------------

## 14. Logs do Intune

Os principais logs ficam em:

``` text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Principal arquivo para Win32 Apps:

``` text
IntuneManagementExtension.log
```

Abra em tempo real:

``` powershell
Get-Content `
"C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" `
-Wait
```

Para procurar referências ao Check Point:

``` powershell
Select-String `
-Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" `
-Pattern "CheckPoint|Check Point|Harmony|GRP-ADM"
```

Log criado pelo `install.ps1`:

``` text
C:\ProgramData\CheckPoint\Logs\Harmony-Install.log
```

Consultar:

``` powershell
Get-Content "C:\ProgramData\CheckPoint\Logs\Harmony-Install.log" -Tail 100
```

------------------------------------------------------------------------

## 15. Troubleshooting observado durante o projeto

O Intune conseguiu baixar e extrair o pacote normalmente. O problema
ocorreu posteriormente: a regra configurada não encontrou o produto
esperado e o aplicativo terminou como falha.

Erro observado:

``` text
-2016345060
```

A regra de registro retornou:

``` text
applicationDetected: False
```

Por isso, é importante separar:

``` text
Download do pacote
        ↓
Execução do instalador
        ↓
Exit Code
        ↓
Produto realmente instalado
        ↓
Detection Rule
```

Um download bem-sucedido **não significa** que o Harmony foi instalado.

------------------------------------------------------------------------

## 16. Checklist antes da produção

-   [ ] Instalador testado manualmente.
-   [ ] Instalação silenciosa funcionando.
-   [ ] Exit Code conhecido.
-   [ ] Produto aparece no registro.
-   [ ] Serviços do Check Point são criados.
-   [ ] `install.ps1` testado como administrador.
-   [ ] Log próprio sendo criado.
-   [ ] `.intunewin` criado com todos os arquivos.
-   [ ] Install behavior configurado como `System`.
-   [ ] Detection Rule validada na máquina piloto.
-   [ ] Aplicativo testado em grupo piloto.
-   [ ] Instalação confirmada no portal Harmony.
-   [ ] Expansão para produção somente após homologação.

------------------------------------------------------------------------

## 17. Estrutura final do repositório

``` text
CheckPoint-Harmony-Intune/
│
├── README.md
│
├── Scripts/
│   ├── install.ps1
│   └── uninstall.ps1
│
└── Images/
    └── screenshots/
```

> **Não publique o instalador corporativo `GRP-ADM.exe`, arquivos
> `.intunewin`, tokens, chaves, URLs privadas ou informações do tenant
> em um repositório público.** Mantenha somente scripts sanitizados e
> documentação.

------------------------------------------------------------------------

## Resultado esperado

Ao final do processo:

``` text
Microsoft Intune
      ↓
Win32 App
      ↓
install.ps1 (SYSTEM)
      ↓
GRP-ADM.exe
      ↓
Check Point Harmony Endpoint
      ↓
Detection Rule = Detected
      ↓
Installed
```

------------------------------------------------------------------------

## Autor

**André Luiz**

Projeto de automação e gerenciamento de endpoints utilizando Microsoft
Intune.
