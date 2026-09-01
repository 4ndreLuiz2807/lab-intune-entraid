# Deploy do PIMS via Microsoft Intune

## Visual C++ + Team Developer 7.3 + BDE 5.2 + Oracle Client 19c + Configuração PIMCS

Este documento registra a implantação validada do ambiente **PIMS**
através de **Microsoft Intune Win32 Apps**, incluindo os testes e
correções realizados durante o processo.

> **Importante:** caminhos, arquivos `.reg`, unidade de rede, parâmetros
> Oracle/PIMS e nomes de instaladores devem ser adaptados conforme a
> infraestrutura.

------------------------------------------------------------------------

## Arquitetura do deploy

``` text
PIMS - Pré-Requisitos
│
├── Microsoft Visual C++ 2005 x86
├── Microsoft Visual C++ 2008 x86
├── Microsoft Visual C++ 2008 x64
├── Microsoft Visual C++ 2013 x86
├── Microsoft Visual C++ 2013 x64
├── Team Developer 7.3 Deployment
└── Borland Database Engine 5.2
          │
          ▼
Oracle Client 19c x64
          │
          ▼
Oracle Client 19c x86
          │
          ▼
PIMCS-Config
```

A cadeia de dependências no Intune deve respeitar essa ordem.

------------------------------------------------------------------------

# 1. PIMS - Pré-Requisitos

Estrutura utilizada:

``` text
C:\Deploy\PIMS-Prerequisitos\
│
├── Install.ps1
├── uninstall.ps1
├── Visual C++ 2005_x86.exe
├── Visual C++ 2008_x86.exe
├── Visual C++ 2008_x64.exe
├── Visual C++ 2013_x86.exe
├── Visual C++ 2013_x64.exe
├── Team Developer 7.3 Deployment.msi
└── bde520.exe
```

Utilize uma pasta separada para saída:

``` text
C:\Deploy\Output\
```

**Não deixe o `.intunewin` dentro da pasta source.**

## Visual C++

Parâmetros silenciosos utilizados:

``` text
Visual C++ 2005 x86: /q
Visual C++ 2008 x86: /q /norestart
Visual C++ 2008 x64: /q /norestart
Visual C++ 2013 x86: /install /quiet /norestart
Visual C++ 2013 x64: /install /quiet /norestart
```

Códigos tratados como sucesso:

    Exit Code Significado
  ----------- -------------------------------------------------
            0 Sucesso
         1638 Produto/versão equivalente já instalado
         3010 Sucesso com reinicialização necessária
         1641 Sucesso com reinicialização iniciada/solicitada

## Team Developer 7.3

``` powershell
msiexec.exe /i "Team Developer 7.3 Deployment.msi" /qn /norestart
```

Log:

``` text
C:\ProgramData\PIMSDeploy\TeamDeveloper-7.3-MSI.log
```

Nos testes, o MSI retornou `ExitCode 0`.

## BDE 5.2

Instalador:

``` text
bde520.exe
```

Instalação silenciosa validada:

``` powershell
bde520.exe /S
```

O BDE foi encontrado em:

``` text
C:\Program Files (x86)\Common Files\Borland Shared\BDE
```

## Logs

``` text
C:\ProgramData\PIMSDeploy\PIMS-Prerequisitos-Install.log
C:\ProgramData\PIMSDeploy\TeamDeveloper-7.3-MSI.log
```

------------------------------------------------------------------------

# 2. Oracle Client 19c x64

Oracle Home:

``` text
C:\oracle\product\19.0.0\client_x64
```

Instalação silenciosa:

``` powershell
.\setup.exe -silent -waitforcompletion -responseFile ".\response\client_install.rsp"
```

Parâmetros principais:

``` text
ORACLE_HOME=C:\oracle\product\19.0.0\client_x64
ORACLE_BASE=C:\oracle
oracle.install.IsBuiltInAccount=true
```

Validação:

``` text
C:\oracle\product\19.0.0\client_x64\bin\sqlplus.exe
```

------------------------------------------------------------------------

# 3. Oracle Client 19c x86

Oracle Home:

``` text
C:\oracle\product\19.0.0\client_x86
```

Instalação:

``` powershell
.\setup.exe -silent -waitforcompletion -responseFile ".\response\client_install.rsp"
```

Validação:

``` text
C:\oracle\product\19.0.0\client_x86\bin\sqlplus.exe
```

------------------------------------------------------------------------

# 4. PIMCS-Config

Estrutura correta:

``` text
C:\DeployOracle\Oracle-PIMCS-Config\
│
├── install.ps1
├── uninstall.ps1
├── sqlora8.dll
│
├── Config\
│   ├── BDE\
│   │   └── IDAPI32.CFG
│   └── Windows\
│       └── win.ini
│
└── reg\
    ├── Oracle-x64.reg
    └── Oracle-x86.reg
```

A estrutura precisa ser respeitada porque o script utiliza
`$PSScriptRoot`.

------------------------------------------------------------------------

# 5. IDAPI32.CFG

Origem no pacote:

``` text
Config\BDE\IDAPI32.CFG
```

Destino:

``` text
C:\Program Files (x86)\Common Files\Borland Shared\BDE\IDAPI32.CFG
```

Antes da substituição, é criado backup em:

``` text
C:\ProgramData\PIMSDeploy\IDAPI32-Backup-YYYYMMDD-HHMMSS.CFG
```

O arquivo deve ser obtido de uma máquina de referência com o BDE/PIMS
corretamente configurado.

Configurações Oracle observadas no ambiente de referência:

``` text
DLL32        = SQLORA8.DLL
VENDOR INIT  = OCI.DLL
NET PROTOCOL = TNS
SERVER NAME  = PRD
```

------------------------------------------------------------------------

# 6. SQLORA8.DLL

Origem:

``` text
Oracle-PIMCS-Config\sqlora8.dll
```

Destino:

``` text
C:\Program Files (x86)\Common Files\Borland Shared\BDE\sqlora8.dll
```

Validação:

``` powershell
Test-Path "C:\Program Files (x86)\Common Files\Borland Shared\BDE\sqlora8.dll"
```

Resultado esperado: `True`.

------------------------------------------------------------------------

# 7. WIN.INI

Durante o troubleshooting foi identificado:

``` text
ERRO: win.ini nao encontrado no pacote:
...\Config\Windows\win.ini
```

A estrutura correta é:

``` text
Oracle-PIMCS-Config\
└── Config\
    └── Windows\
        └── win.ini
```

Destino:

``` text
C:\Windows\win.ini
```

Antes da substituição deve ser criado backup.

Configuração PIMS utilizada:

``` ini
[PIMSCS]
ControlFile=I:\ini\PIMSCS.INI
ControlFile01=01-PRODUCAO,I:\ini\PIMSCS.INI

[PIMSTST]
ControlFile=I:\ini\PIMSTST.INI
ControlFile02=02-TESTE,I:\ini\PIMSTST.INI

[PIMSCET]
ControlFile=I:\INI\PIMSCET.INI
ControlFile03=03-CET,I:\INI\PIMSCET.INI
```

------------------------------------------------------------------------

# 8. Arquivos REG

Os arquivos ficam em:

``` text
Oracle-PIMCS-Config\reg\
```

Importação:

``` powershell
reg.exe import "arquivo.reg"
```

O retorno esperado é `ExitCode 0`.

Revise os valores antes de utilizar em outro ambiente.

------------------------------------------------------------------------

# 9. PATH

São adicionados ao PATH de máquina:

``` text
I:\Deploy
I:\Deploy\Axis2c\lib
```

Validação:

``` powershell
[Environment]::GetEnvironmentVariable("Path","Machine")
```

> Adicionar `I:\Deploy` ao PATH não mapeia a unidade `I:`. O mapeamento
> deve ser realizado separadamente no contexto do usuário, por exemplo
> via GPO.

------------------------------------------------------------------------

# 10. Teste local

Antes de gerar o `.intunewin`:

``` powershell
cd "C:\DeployOracle\Oracle-PIMCS-Config"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

Write-Host "ExitCode:" $LASTEXITCODE
```

Resultado esperado:

``` text
ExitCode: 0
```

Validação:

``` powershell
$BDE = "C:\Program Files (x86)\Common Files\Borland Shared\BDE"

Write-Host "SQLORA8:" (Test-Path "$BDE\sqlora8.dll")
Write-Host "IDAPI32:" (Test-Path "$BDE\IDAPI32.CFG")
Write-Host "WIN.INI:" (Test-Path "C:\Windows\win.ini")
Write-Host "LOG:" (Test-Path "C:\ProgramData\PIMSDeploy\ConfigPIMS.log")

[Environment]::GetEnvironmentVariable("Path","Machine")
```

Esperado:

``` text
SQLORA8: True
IDAPI32: True
WIN.INI: True
LOG: True
```

------------------------------------------------------------------------

# 11. Empacotamento

Estrutura:

``` text
C:\DeployOracle\
├── Oracle-PIMCS-Config\
└── Output-PIMCS\
```

No `IntuneWinAppUtil`:

``` text
Source folder:
C:\DeployOracle\Oracle-PIMCS-Config

Setup file:
install.ps1

Output folder:
C:\DeployOracle\Output-PIMCS
```

Resultado:

``` text
C:\DeployOracle\Output-PIMCS\install.intunewin
```

Sempre gere um novo `.intunewin` após alterar qualquer arquivo do
pacote.

------------------------------------------------------------------------

# 12. Configuração no Intune

Instalação:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Desinstalação:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Install behavior:

``` text
System
```

Nos testes, o log confirmou execução como:

``` text
AUTORIDADE NT\SISTEMA
```

O Intune Management Extension extraiu o pacote para um caminho
semelhante a:

``` text
C:\WINDOWS\IMECache\<GUID>
```

------------------------------------------------------------------------

# 13. Troubleshooting

Logs próprios:

``` text
C:\ProgramData\PIMSDeploy\
```

Principais arquivos:

``` text
PIMS-Prerequisitos-Install.log
TeamDeveloper-7.3-MSI.log
ConfigPIMS.log
IDAPI32-Backup-*.CFG
win-Backup-*.ini
```

Logs do Intune:

``` text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\
```

Principais:

``` text
IntuneManagementExtension.log
AppWorkload.log
```

Cache:

``` text
C:\Windows\IMECache\
```

Fluxo recomendado de diagnóstico:

``` text
Download do .intunewin
        ↓
Extração pelo IME
        ↓
Execução do install.ps1
        ↓
ExitCode
        ↓
Log próprio
        ↓
Arquivos/registro criados
        ↓
Regra de detecção
```

## Falha de instalação x falha de detecção

Um `ExitCode 0` não significa automaticamente que o Intune marcará o
aplicativo como instalado.

É necessário validar separadamente:

-   execução do instalador;
-   logs;
-   arquivos criados;
-   registros;
-   regra de detecção.

Durante os testes, os pré-requisitos foram instalados corretamente, mas
regras de detecção incorretas chegaram a fazer o Intune reportar falha.

------------------------------------------------------------------------

# 14. Resultado

``` text
Microsoft Intune
       │
       ▼
PIMS - Pré-Requisitos
       │
       ├── Visual C++
       ├── Team Developer 7.3
       └── BDE 5.2
       │
       ▼
Oracle Client 19c x64
       │
       ▼
Oracle Client 19c x86
       │
       ▼
PIMCS-Config
       │
       ├── IDAPI32.CFG
       ├── SQLORA8.DLL
       ├── WIN.INI
       ├── Registro
       └── PATH
       │
       ▼
Ambiente PIMS
```

## Boas práticas validadas

-   Separar Oracle x64 e x86.
-   Controlar a ordem através de dependências do Intune.
-   Instalar BDE antes do PIMCS-Config.
-   Usar um `IDAPI32.CFG` proveniente de máquina funcional.
-   Fazer backup do `IDAPI32.CFG`.
-   Fazer backup do `win.ini`.
-   Usar `$PSScriptRoot` para arquivos do pacote.
-   Gerar logs em `C:\ProgramData`.
-   Testar localmente antes de empacotar.
-   Manter source e output em pastas diferentes.
-   Recriar o `.intunewin` após alterações.
-   Diferenciar falha de instalação de falha de detecção.
-   Não depender de unidade mapeada no contexto `SYSTEM`.

------------------------------------------------------------------------

## Tecnologias

-   Microsoft Intune
-   Intune Win32 Apps
-   PowerShell
-   Oracle Client 19c
-   Borland Database Engine 5.2
-   OpenText/Gupta Team Developer 7.3
-   Microsoft Visual C++ Redistributables
-   Intune Management Extension
