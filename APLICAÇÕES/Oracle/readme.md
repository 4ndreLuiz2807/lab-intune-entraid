<img src="https://raw.githubusercontent.com/4ndreLuiz2807/lab-intune-entraid/refs/heads/main/APLICA%C3%87%C3%95ES/Oracle/banner_pims_intune_raw_editavel.svg" width="100%" />

# Deploy Completo do PIMS via Microsoft Intune

> Documentação do processo validado em laboratório para implantação dos
> pré-requisitos do PIMS, Oracle Client 19c x64/x86 e configuração final
> do PIMCS utilizando Microsoft Intune Win32 Apps.

------------------------------------------------------------------------

## 1. Objetivo

A implantação foi dividida em **quatro pacotes Win32**, evitando
concentrar todos os componentes em um único `.intunewin`.

Ordem utilizada:

``` text
1. C++ - BDE
   ├── Microsoft Visual C++ Redistributables
   ├── Team Developer 7.3 Deployment
   └── Borland Database Engine 5.2
            ↓
2. Oracle Client 19c x64
            ↓
3. Oracle Client 19c x86
            ↓
4. Oracle-PIMCS-Config
   ├── IDAPI32.CFG
   ├── sqlora8.dll
   ├── win.ini
   ├── arquivos .reg
   └── PATH do sistema
```

No diretório de trabalho, a organização utilizada foi:

``` text
C:\DeployOracle\
│
├── C++ - BDE\
├── Oracle-PIMCS-Config\
├── x64\
├── x86\
└── detectc++.ps1
```

> Os arquivos `.intunewin` devem ser gerados em uma pasta de **saída
> separada**. Não salve o `.intunewin` dentro da própria pasta source.

------------------------------------------------------------------------

# 2. Preparação das pastas

Crie uma pasta para os arquivos gerados:

``` powershell
New-Item -Path "C:\DeployOracle\Output" -ItemType Directory -Force
```

Estrutura recomendada:

``` text
C:\DeployOracle\
│
├── C++ - BDE\                    # Pacote 1
├── x64\                          # Pacote 2
├── x86\                          # Pacote 3
├── Oracle-PIMCS-Config\          # Pacote 4
├── Output\                       # .intunewin gerados
└── detectc++.ps1                 # Script auxiliar de detecção/teste
```

------------------------------------------------------------------------

# 3. Pacote 1 --- C++ + Team Developer + BDE

## 3.1 Estrutura

``` text
C:\DeployOracle\C++ - BDE\
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

## 3.2 Visual C++

Parâmetros silenciosos validados:

``` text
Visual C++ 2005 x86
/q

Visual C++ 2008 x86
/q /norestart

Visual C++ 2008 x64
/q /norestart

Visual C++ 2013 x86
/install /quiet /norestart

Visual C++ 2013 x64
/install /quiet /norestart
```

Códigos tratados como sucesso pelo script:

    ExitCode Tratamento
  ---------- -------------------------------------------------
         `0` Sucesso
      `1638` Produto/versão equivalente já instalado
      `3010` Sucesso, reinicialização necessária
      `1641` Sucesso com reinicialização iniciada/solicitada

## 3.3 Team Developer 7.3

Instalação silenciosa:

``` powershell
msiexec.exe /i "Team Developer 7.3 Deployment.msi" /qn /norestart /L*v "C:\ProgramData\PIMSDeploy\TeamDeveloper-7.3-MSI.log"
```

No teste validado:

``` text
ExitCode: 0
```

## 3.4 BDE 5.2

Instalador:

``` text
bde520.exe
```

Parâmetro silencioso que funcionou:

``` powershell
bde520.exe /S
```

No teste:

``` text
ExitCode: 0
```

Diretório confirmado:

``` text
C:\Program Files (x86)\Common Files\Borland Shared\BDE
```

## 3.5 Logs

``` text
C:\ProgramData\PIMSDeploy\PIMS-Prerequisitos-Install.log
C:\ProgramData\PIMSDeploy\TeamDeveloper-7.3-MSI.log
```

O arquivo de controle criado após sucesso foi:

``` text
C:\ProgramData\PIMSDeploy\PrerequisitosPIMS.done
```

Validação:

``` powershell
Test-Path "C:\ProgramData\PIMSDeploy\PrerequisitosPIMS.done"
```

Resultado validado:

``` text
True
```

> Durante troubleshooting, remova um marker antigo antes de testar
> novamente. Caso contrário, uma regra de detecção baseada somente no
> `.done` pode considerar o aplicativo instalado antes de executar o
> novo pacote.

``` powershell
Remove-Item "C:\ProgramData\PIMSDeploy\PrerequisitosPIMS.done" -Force -ErrorAction SilentlyContinue
```

------------------------------------------------------------------------

# 4. Empacotamento do Pacote 1

Execute o `IntuneWinAppUtil.exe`.

Exemplo:

``` powershell
IntuneWinAppUtil.exe -c "C:\DeployOracle\C++ - BDE" -s "Install.ps1" -o "C:\DeployOracle\Output" -q
```

Resultado esperado:

``` text
C:\DeployOracle\Output\Install.intunewin
```

Depois de gerar o pacote, renomeie o arquivo de saída se necessário para
facilitar a identificação, por exemplo:

``` text
PIMS-Prerequisitos.intunewin
```

## Intune

Comando de instalação:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

Comportamento:

``` text
Install behavior: System
```

------------------------------------------------------------------------

# 5. Pacote 2 --- Oracle Client 19c x64

## 5.1 Por que compactar o Oracle antes do `.intunewin`

O Oracle possui uma grande quantidade de arquivos e uma estrutura
extensa de diretórios.

Durante os testes, a abordagem que funcionou foi:

``` text
Arquivos originais Oracle
        ↓
compactar em Oracle19c-x64.zip
        ↓
colocar o ZIP junto com install.ps1
        ↓
gerar o .intunewin
        ↓
Intune baixa o pacote
        ↓
install.ps1 extrai o ZIP localmente
        ↓
setup.exe executa a instalação
```

Isso também evita depender da estrutura completa do Oracle diretamente
dentro do pacote Win32.

------------------------------------------------------------------------

# 6. Preparando o Oracle x64

Considere a pasta contendo os arquivos originais do Oracle x64.

Antes de compactar, ela deve conter o `setup.exe` e toda a mídia
original Oracle.

Exemplo conceitual:

``` text
C:\DeployOracle\Oracle19c-x64-Original\
│
├── setup.exe
├── response\
│   └── client_install.rsp
├── client\
├── install\
├── stage\
└── demais arquivos Oracle...
```

Compacte **o conteúdo necessário para a instalação**, preservando toda a
estrutura interna.

Exemplo em PowerShell:

``` powershell
Compress-Archive `
    -Path "C:\DeployOracle\Oracle19c-x64-Original\*" `
    -DestinationPath "C:\DeployOracle\x64\Oracle19c-x64.zip" `
    -Force
```

Depois, a pasta que será entregue ao `IntuneWinAppUtil` fica:

``` text
C:\DeployOracle\x64\
│
├── install.ps1
├── uninstall.ps1
└── Oracle19c-x64.zip
```

> O `setup.exe` fica **dentro do ZIP**. O `install.ps1` fica **fora do
> ZIP**, pois é ele que o Intune executará primeiro.

------------------------------------------------------------------------

# 7. Instalação Oracle x64

Durante a execução, o script deve extrair o conteúdo para uma pasta
temporária/local, por exemplo:

``` text
C:\OracleInstall\Oracle19c-x64
```

Depois da extração, deve existir:

``` text
C:\OracleInstall\Oracle19c-x64\setup.exe
```

O Oracle Home utilizado foi:

``` text
C:\oracle\product\19.0.0\client_x64
```

Oracle Base:

``` text
C:\oracle
```

Parâmetros importantes do response file:

``` text
ORACLE_HOME=C:\oracle\product\19.0.0\client_x64
ORACLE_BASE=C:\oracle
oracle.install.IsBuiltInAccount=true
```

Instalação silenciosa:

``` powershell
.\setup.exe -silent -waitforcompletion -responseFile ".\response\client_install.rsp"
```

Validação principal:

``` powershell
Test-Path "C:\oracle\product\19.0.0\client_x64\bin\sqlplus.exe"
```

Esperado:

``` text
True
```

------------------------------------------------------------------------

# 8. Empacotamento Oracle x64

Com a pasta:

``` text
C:\DeployOracle\x64\
├── install.ps1
├── uninstall.ps1
└── Oracle19c-x64.zip
```

execute:

``` powershell
IntuneWinAppUtil.exe -c "C:\DeployOracle\x64" -s "install.ps1" -o "C:\DeployOracle\Output" -q
```

No Intune:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Regra de detecção por arquivo:

``` text
Path:
C:\oracle\product\19.0.0\client_x64\bin

File:
sqlplus.exe

Detection method:
File or folder exists

Associated with a 32-bit app on 64-bit clients:
No
```

Tempo máximo recomendado para o Oracle:

``` text
60 minutos
```

------------------------------------------------------------------------

# 9. Pacote 3 --- Oracle Client 19c x86

O processo é o mesmo do x64, mas completamente separado.

## Estrutura da mídia original

``` text
C:\DeployOracle\Oracle19c-x86-Original\
│
├── setup.exe
├── response\
│   └── client_install.rsp
└── demais arquivos Oracle...
```

Compactação:

``` powershell
Compress-Archive `
    -Path "C:\DeployOracle\Oracle19c-x86-Original\*" `
    -DestinationPath "C:\DeployOracle\x86\Oracle19c-x86.zip" `
    -Force
```

Estrutura final da source:

``` text
C:\DeployOracle\x86\
│
├── install.ps1
├── uninstall.ps1
└── Oracle19c-x86.zip
```

Staging utilizado:

``` text
C:\OracleInstall\Oracle19c-x86
```

Oracle Home:

``` text
C:\oracle\product\19.0.0\client_x86
```

Oracle Base:

``` text
C:\oracle
```

Validação:

``` powershell
Test-Path "C:\oracle\product\19.0.0\client_x86\bin\sqlplus.exe"
```

Esperado:

``` text
True
```

------------------------------------------------------------------------

# 10. Empacotamento Oracle x86

``` powershell
IntuneWinAppUtil.exe -c "C:\DeployOracle\x86" -s "install.ps1" -o "C:\DeployOracle\Output" -q
```

No Intune:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Detecção:

``` text
Path:
C:\oracle\product\19.0.0\client_x86\bin

File:
sqlplus.exe

Detection method:
File or folder exists

Associated with a 32-bit app on 64-bit clients:
No
```

------------------------------------------------------------------------

# 11. Pacote 4 --- Oracle-PIMCS-Config

Depois que C++/Team Developer/BDE e os dois Oracle Clients estiverem
instalados, execute a configuração final.

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
│   │
│   └── Windows\
│       └── win.ini
│
└── reg\
    ├── Oracle-x64.reg
    └── Oracle-x86.reg
```

Essa estrutura é importante porque o script utiliza `$PSScriptRoot`.

Quando executado pelo Intune, por exemplo:

``` text
PSScriptRoot:
C:\WINDOWS\IMECache\<GUID>
```

Portanto, caminhos absolutos apontando para `C:\DeployOracle` não devem
ser utilizados para localizar arquivos internos do pacote.

------------------------------------------------------------------------

# 12. IDAPI32.CFG

Origem:

``` text
Config\BDE\IDAPI32.CFG
```

Destino:

``` text
C:\Program Files (x86)\Common Files\Borland Shared\BDE\IDAPI32.CFG
```

Antes da substituição, faça backup:

``` text
C:\ProgramData\PIMSDeploy\IDAPI32-Backup-YYYYMMDD-HHMMSS.CFG
```

O `IDAPI32.CFG` deve vir de uma máquina de referência onde o PIMS/BDE
esteja funcionando.

Parâmetros observados na configuração Oracle do BDE:

``` text
DLL32        = SQLORA8.DLL
VENDOR INIT  = OCI.DLL
NET PROTOCOL = TNS
SERVER NAME  = PRD
```

------------------------------------------------------------------------

# 13. SQLORA8.DLL

Origem:

``` text
C:\DeployOracle\Oracle-PIMCS-Config\sqlora8.dll
```

Destino:

``` text
C:\Program Files (x86)\Common Files\Borland Shared\BDE\sqlora8.dll
```

Validação:

``` powershell
Test-Path "C:\Program Files (x86)\Common Files\Borland Shared\BDE\sqlora8.dll"
```

Esperado:

``` text
True
```

------------------------------------------------------------------------

# 14. WIN.INI

Este foi um dos erros identificados durante os testes.

O Intune executou corretamente o script, porém o log mostrou:

``` text
ERRO: win.ini nao encontrado no pacote:
C:\WINDOWS\IMECache\<GUID>\Config\Windows\win.ini
```

O teste local confirmou:

``` text
install.ps1: True
sqlora8.dll: True
IDAPI32.CFG: True
win.ini: False
pasta reg: True
BDE destino: True
```

Portanto, o arquivo precisa existir exatamente em:

``` text
C:\DeployOracle\Oracle-PIMCS-Config\Config\Windows\win.ini
```

Destino:

``` text
C:\Windows\win.ini
```

Configuração utilizada:

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

# 15. Arquivos REG

Os arquivos de registro ficam em:

``` text
C:\DeployOracle\Oracle-PIMCS-Config\reg\
```

O script pode importá-los com:

``` powershell
reg.exe import "arquivo.reg"
```

Retorno esperado:

``` text
ExitCode 0
```

> Revise os valores dos `.reg` antes de reutilizar em outra
> infraestrutura.

------------------------------------------------------------------------

# 16. PATH do sistema

O pacote PIMCS adiciona:

``` text
I:\Deploy
I:\Deploy\Axis2c\lib
```

ao PATH de máquina.

Validação:

``` powershell
[Environment]::GetEnvironmentVariable("Path","Machine")
```

Importante:

``` text
Adicionar I:\Deploy ao PATH NÃO mapeia a unidade I:.
```

O mapeamento da unidade deve ser realizado separadamente no contexto do
usuário, por exemplo através de GPO.

------------------------------------------------------------------------

# 17. Teste local do PIMCS-Config

Antes de empacotar:

``` powershell
cd "C:\DeployOracle\Oracle-PIMCS-Config"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

Write-Host "ExitCode:" $LASTEXITCODE
```

Esperado:

``` text
ExitCode: 0
```

Validação:

``` powershell
$BDE = "C:\Program Files (x86)\Common Files\Borland Shared\BDE"

Write-Host "BDE:" (Test-Path $BDE)
Write-Host "SQLORA8:" (Test-Path "$BDE\sqlora8.dll")
Write-Host "IDAPI32:" (Test-Path "$BDE\IDAPI32.CFG")
Write-Host "WIN.INI:" (Test-Path "C:\Windows\win.ini")
Write-Host "LOG:" (Test-Path "C:\ProgramData\PIMSDeploy\ConfigPIMS.log")

[Environment]::GetEnvironmentVariable("Path","Machine")
```

------------------------------------------------------------------------

# 18. Log que confirmou a causa da falha

Durante a execução pelo Intune:

``` text
INICIO - CONFIGURACAO PIMCS
Executando como: AUTORIDADE NT\SISTEMA
PSScriptRoot: C:\WINDOWS\IMECache\<GUID>

Validando instalacao do BDE...
BDE encontrado.

Validando arquivo sqlora8.dll...
Copiando sqlora8.dll para o BDE...
sqlora8.dll copiado com sucesso.

IDAPI32.CFG encontrado no pacote.
Criando backup do IDAPI32.CFG...
IDAPI32.CFG aplicado.

ERRO NA CONFIGURACAO PIMCS
ERRO: win.ini nao encontrado no pacote:
...\Config\Windows\win.ini
```

Isso provou que:

``` text
BDE                  = OK
sqlora8.dll           = OK
IDAPI32.CFG           = OK
execução como SYSTEM  = OK
estrutura do win.ini  = INCORRETA
```

A correção foi colocar o `win.ini` no diretório esperado pelo script.

------------------------------------------------------------------------

# 19. Empacotamento do PIMCS-Config

Pasta source:

``` text
C:\DeployOracle\Oracle-PIMCS-Config
```

Pasta output:

``` text
C:\DeployOracle\Output
```

Comando:

``` powershell
IntuneWinAppUtil.exe -c "C:\DeployOracle\Oracle-PIMCS-Config" -s "install.ps1" -o "C:\DeployOracle\Output" -q
```

No Intune:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Desinstalação:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Comportamento:

``` text
System
```

------------------------------------------------------------------------

# 20. Dependências no Intune

Configure a cadeia:

``` text
PIMS-Prerequisitos
        ↓
Oracle Client 19c x64
        ↓
Oracle Client 19c x86
        ↓
PIMCS-Config
```

A finalidade é impedir que o `PIMCS-Config` execute antes do BDE e dos
Oracle Clients.

------------------------------------------------------------------------

# 21. Estrutura final completa

Ao terminar a preparação, a estrutura de trabalho fica semelhante a:

``` text
C:\DeployOracle\
│
├── C++ - BDE\
│   ├── Install.ps1
│   ├── uninstall.ps1
│   ├── Visual C++ 2005_x86.exe
│   ├── Visual C++ 2008_x86.exe
│   ├── Visual C++ 2008_x64.exe
│   ├── Visual C++ 2013_x86.exe
│   ├── Visual C++ 2013_x64.exe
│   ├── Team Developer 7.3 Deployment.msi
│   └── bde520.exe
│
├── x64\
│   ├── install.ps1
│   ├── uninstall.ps1
│   └── Oracle19c-x64.zip
│
├── x86\
│   ├── install.ps1
│   ├── uninstall.ps1
│   └── Oracle19c-x86.zip
│
├── Oracle-PIMCS-Config\
│   ├── install.ps1
│   ├── uninstall.ps1
│   ├── sqlora8.dll
│   ├── Config\
│   │   ├── BDE\
│   │   │   └── IDAPI32.CFG
│   │   └── Windows\
│   │       └── win.ini
│   └── reg\
│       ├── Oracle-x64.reg
│       └── Oracle-x86.reg
│
├── Output\
│   ├── PIMS-Prerequisitos.intunewin
│   ├── Oracle19c-x64.intunewin
│   ├── Oracle19c-x86.intunewin
│   └── PIMCS-Config.intunewin
│
└── detectc++.ps1
```

------------------------------------------------------------------------

# 22. Troubleshooting

Logs do projeto:

``` text
C:\ProgramData\PIMSDeploy\
```

Arquivos encontrados durante os testes:

``` text
PIMS-Prerequisitos-Install.log
PrerequisitosPIMS.done
TeamDeveloper-7.3-MSI.log
ConfigPIMS.log
IDAPI32-Backup-*.CFG
```

Logs do Intune Management Extension:

``` text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\
```

Principais:

``` text
IntuneManagementExtension.log
AppWorkload.log
```

Cache de instalação:

``` text
C:\Windows\IMECache\
```

Fluxo de diagnóstico:

``` text
.intunewin
    ↓
download pelo Intune
    ↓
extração no IMECache
    ↓
install.ps1
    ↓
ExitCode
    ↓
log do pacote
    ↓
validação dos arquivos
    ↓
regra de detecção
```

------------------------------------------------------------------------

# 23. Erro 0x87D30067 no Oracle

Durante o processo houve falha relacionada à extração do conteúdo
baixado pelo Intune.

A solução utilizada foi não deixar toda a árvore Oracle diretamente
exposta no source do Win32 App.

Foi adotado:

``` text
Oracle original
    ↓
Oracle19c-x64.zip / Oracle19c-x86.zip
    ↓
ZIP incluído no .intunewin
    ↓
install.ps1 extrai localmente
    ↓
setup.exe
```

Essa abordagem funcionou no ambiente testado.

------------------------------------------------------------------------

# 24. Instalação x detecção

Uma instalação pode concluir corretamente e ainda aparecer como falha no
Intune se a regra de detecção estiver incorreta.

Sempre valide nesta ordem:

``` text
1. O pacote foi baixado?
2. Foi extraído pelo IME?
3. install.ps1 executou?
4. Qual foi o ExitCode?
5. O log mostra sucesso?
6. Os arquivos existem?
7. O registro foi criado/importado?
8. A regra de detecção corresponde ao estado real?
```

Não utilize apenas a existência de um arquivo `.done` durante
troubleshooting sem remover markers de testes anteriores.

------------------------------------------------------------------------

# 25. Resultado final

``` text
Microsoft Intune
       │
       ▼
PIMS-Prerequisitos
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
       ├── REG
       └── PATH
       │
       ▼
Ambiente PIMS
```

------------------------------------------------------------------------

## Boas práticas validadas

-   Separar os componentes em quatro Win32 Apps.
-   Controlar a ordem através de dependências.
-   Manter x64 e x86 separados.
-   Compactar a mídia Oracle em ZIP antes de gerar o `.intunewin`.
-   Deixar `install.ps1` fora do ZIP.
-   Extrair o Oracle para staging local antes de executar `setup.exe`.
-   Não utilizar `C:\oracle` como staging, pois esse caminho também é
    usado como `ORACLE_BASE`.
-   Utilizar `$PSScriptRoot` para localizar arquivos pertencentes ao
    pacote.
-   Testar cada `install.ps1` localmente antes do empacotamento.
-   Manter pasta source e output separadas.
-   Gerar um novo `.intunewin` após qualquer alteração.
-   Criar logs em `C:\ProgramData\PIMSDeploy`.
-   Fazer backup de `IDAPI32.CFG` e `win.ini`.
-   Diferenciar falha de instalação de falha de detecção.
-   Não depender de unidade de rede mapeada no contexto `SYSTEM`.

------------------------------------------------------------------------

## Tecnologias utilizadas

-   Microsoft Intune
-   Intune Win32 Apps
-   Microsoft Win32 Content Prep Tool
-   PowerShell
-   Oracle Client 19c x64
-   Oracle Client 19c x86
-   Borland Database Engine 5.2
-   OpenText/Gupta Team Developer 7.3
-   Microsoft Visual C++ Redistributables
-   Intune Management Extension

------------------------------------------------------------------------

## Observação

Esta documentação registra o fluxo que foi testado no ambiente utilizado
durante a implementação. Antes de replicar em outra infraestrutura,
revise principalmente:

``` text
ORACLE_HOME
ORACLE_BASE
response files
arquivos .reg
IDAPI32.CFG
win.ini
TNS
unidade I:
PATH
nomes dos instaladores
regras de detecção
dependências do Intune
```
