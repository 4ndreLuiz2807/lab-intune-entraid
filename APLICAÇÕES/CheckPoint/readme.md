<img src="https://raw.githubusercontent.com/4ndreLuiz2807/lab-intune-entraid/refs/heads/main/APLICA%C3%87%C3%95ES/banner.svg" alt="Banner" width="100%" />

# Deploy do Check Point Harmony Endpoint via Microsoft Intune

Passo a passo para preparar o pacote do **Check Point Harmony
Endpoint**, converter o instalador exportado em **MSI**, testar a
instalação silenciosa, empacotar como **Win32 App (.intunewin)** e
realizar o deploy pelo Microsoft Intune.

> Este procedimento usa como exemplo o instalador personalizado
> `GRP-ADM.exe`. Os nomes e Product Codes podem variar conforme a
> versão/pacote exportado do ambiente Check Point.

------------------------------------------------------------------------

## 1. Fluxo do deploy

``` text
GRP-ADM.exe
     ↓
GRP-ADM.exe /CreateMSI
     ↓
EPS.msi
     ↓
Teste local
     ↓
IntuneWinAppUtil
     ↓
EPS.intunewin
     ↓
Microsoft Intune
     ↓
Grupo piloto
     ↓
Produção
```

------------------------------------------------------------------------

## 2. Pré-requisitos

-   Microsoft Intune configurado.
-   Dispositivos Windows inscritos no Intune.
-   Instalador do Harmony exportado do ambiente Check Point.
-   `IntuneWinAppUtil.exe`.
-   PowerShell executado como Administrador.
-   Uma máquina de teste.

------------------------------------------------------------------------

# 3. Preparar a pasta

Exemplo:

``` text
C:\Deploy\CheckPoint-Harmony\
│
├── Source\
│   └── GRP-ADM.exe
│
└── Output\
```

Criar as pastas:

``` powershell
New-Item -ItemType Directory -Path "C:\Deploy\CheckPoint-Harmony\Source" -Force
New-Item -ItemType Directory -Path "C:\Deploy\CheckPoint-Harmony\Output" -Force
```

Copie o instalador:

``` text
GRP-ADM.exe
```

para:

``` text
C:\Deploy\CheckPoint-Harmony\Source
```

------------------------------------------------------------------------

# 4. Converter o EXE do Check Point para MSI

Abra o **PowerShell como Administrador**.

Entre na pasta do instalador:

``` powershell
Set-Location "C:\Deploy\CheckPoint-Harmony\Source"
```

Confirme que o arquivo está presente:

``` powershell
Get-ChildItem
```

Deve aparecer:

``` text
GRP-ADM.exe
```

## 4.1 Gerar o MSI

No PowerShell, arquivos existentes no diretório atual precisam ser
chamados com `.\`.

Execute:

``` powershell
.\GRP-ADM.exe /CreateMSI
```

Aguarde o processo finalizar.

Depois procure o MSI:

``` powershell
Get-ChildItem -Path . -Filter *.msi -Recurse |
    Select-Object FullName, Length, LastWriteTime
```

O resultado esperado é um arquivo MSI, por exemplo:

``` text
EPS.msi
```

> Se nenhum `.msi` for criado, pare neste ponto e valide se a versão do
> pacote exportado suporta `/CreateMSI`. Não publique no Intune supondo
> que a conversão funcionou.

------------------------------------------------------------------------

# 5. Organizar o pacote após a conversão

Depois que o MSI for criado, a pasta utilizada para empacotamento pode
ficar somente com o MSI:

``` text
C:\Deploy\CheckPoint-Harmony\
│
├── Source\
│   └── EPS.msi
│
└── Output\
```

Você pode mover o EXE original para uma pasta separada:

``` powershell
New-Item -ItemType Directory -Path "C:\Deploy\CheckPoint-Harmony\Original" -Force

Move-Item `
    "C:\Deploy\CheckPoint-Harmony\Source\GRP-ADM.exe" `
    "C:\Deploy\CheckPoint-Harmony\Original\GRP-ADM.exe"
```

------------------------------------------------------------------------

# 6. Testar o MSI manualmente

Antes do Intune, teste o MSI na máquina piloto.

Entre na pasta:

``` powershell
Set-Location "C:\Deploy\CheckPoint-Harmony\Source"
```

Execute:

``` powershell
msiexec.exe /i ".\EPS.msi" /qn /norestart /L*v "C:\Windows\Temp\CheckPoint-Harmony-Install.log"
```

Parâmetros:

``` text
/i          Instala o MSI
/qn         Instalação totalmente silenciosa
/norestart  Impede reinicialização automática
/L*v        Gera log detalhado
```

O log será criado em:

``` text
C:\Windows\Temp\CheckPoint-Harmony-Install.log
```

------------------------------------------------------------------------

# 7. Confirmar se o Harmony foi instalado

Procure o produto no registro:

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

Exemplo de resultado:

``` text
DisplayName    : Check Point Endpoint Security
DisplayVersion : X.X.X
PSChildName    : {XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
```

O valor de `PSChildName`, quando for um GUID MSI, normalmente
corresponde ao **Product Code**.

Guarde esse valor para validar a Detection Rule.

Também verifique os serviços:

``` powershell
Get-Service |
Where-Object {
    $_.DisplayName -match "Check Point|Harmony" -or
    $_.Name -match "CheckPoint|Harmony"
} |
Select-Object Name, DisplayName, Status
```

------------------------------------------------------------------------

# 8. Verificar o Exit Code

Logo após executar o MSI:

``` powershell
$LASTEXITCODE
```

Códigos comuns:

``` text
0     = Sucesso
3010  = Sucesso, reinicialização necessária
1641  = Sucesso, reinicialização iniciada
```

Se houver falha, consulte:

``` text
C:\Windows\Temp\CheckPoint-Harmony-Install.log
```

------------------------------------------------------------------------

# 9. Preciso criar install.ps1 e uninstall.ps1?

**Não para este cenário.**

Como agora temos um MSI, não há necessidade de criar scripts PowerShell
apenas para executar `msiexec`.

O pacote pode conter somente:

``` text
Source\
└── EPS.msi
```

Entretanto, ao criar um **Windows app (Win32)** no Intune, os campos
**Install command** e **Uninstall command** continuam existindo.

Utilizaremos diretamente o `msiexec`.

------------------------------------------------------------------------

# 10. Empacotar o MSI como .intunewin

Baixe e deixe o `IntuneWinAppUtil.exe`, por exemplo, em:

``` text
C:\Deploy\IntuneWinAppUtil.exe
```

Estrutura:

``` text
C:\Deploy\
│
├── IntuneWinAppUtil.exe
│
└── CheckPoint-Harmony\
    ├── Source\
    │   └── EPS.msi
    └── Output\
```

Execute:

``` powershell
C:\Deploy\IntuneWinAppUtil.exe
```

Informe:

``` text
Please specify the source folder:
C:\Deploy\CheckPoint-Harmony\Source
```

Setup file:

``` text
EPS.msi
```

Output:

``` text
C:\Deploy\CheckPoint-Harmony\Output
```

Catalog:

``` text
N
```

Também pode ser feito diretamente:

``` powershell
C:\Deploy\IntuneWinAppUtil.exe `
    -c "C:\Deploy\CheckPoint-Harmony\Source" `
    -s "EPS.msi" `
    -o "C:\Deploy\CheckPoint-Harmony\Output"
```

Ao final será criado:

``` text
EPS.intunewin
```

------------------------------------------------------------------------

# 11. Criar o aplicativo no Microsoft Intune

No Intune Admin Center:

``` text
Apps
→ Windows
→ Create
```

Em **App type**:

``` text
Windows app (Win32)
```

Clique em:

``` text
Select
```

Faça upload de:

``` text
EPS.intunewin
```

------------------------------------------------------------------------

# 12. App Information

Exemplo:

``` text
Name:
Check Point Harmony Endpoint

Description:
Check Point Harmony Endpoint - Deploy corporativo via Microsoft Intune

Publisher:
Check Point Software Technologies
```

Preencha os demais campos conforme o padrão da empresa.

------------------------------------------------------------------------

# 13. Program

## Install command

``` cmd
msiexec.exe /i "EPS.msi" /qn /norestart
```

## Uninstall command

O Intune Win32 App ainda exige um comando de desinstalação.

Utilize o Product Code **real do MSI gerado no seu ambiente**:

``` cmd
msiexec.exe /x "{PRODUCT-CODE}" /qn /norestart
```

Exemplo:

``` text
msiexec.exe /x "{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}" /qn /norestart
```

> Não copie Product Codes de outro pacote ou de outra versão.

## Install behavior

Configure:

``` text
System
```

Isso é importante para instalação corporativa sem depender do usuário
conectado.

## Device restart behavior

Inicialmente:

``` text
App install may force a device restart
```

Ajuste conforme o comportamento homologado do seu pacote.

------------------------------------------------------------------------

# 14. Descobrir o Product Code do MSI

Depois de instalar manualmente:

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

Procure:

``` text
PSChildName : {GUID}
```

Esse GUID deve ser validado como o Product Code da instalação antes de
ser utilizado no Intune.

------------------------------------------------------------------------

# 15. Requirements

Exemplo:

``` text
Operating system architecture:
64-bit

Minimum operating system:
Windows 10 22H2
```

Ajuste conforme os sistemas operacionais homologados no ambiente.

------------------------------------------------------------------------

# 16. Detection Rule

Como estamos trabalhando com MSI, prefira a detecção baseada no **MSI
Product Code** quando ele estiver disponível e validado.

No Intune:

``` text
Detection rules
→ Rules format
→ Manually configure detection rules
→ Add
```

Selecione:

``` text
Rule type:
MSI
```

Informe o Product Code correspondente ao `EPS.msi`.

Exemplo:

``` text
{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
```

A versão pode ser utilizada ou ignorada dependendo da estratégia de
atualização do Harmony.

------------------------------------------------------------------------

# 17. Não reutilizar a regra antiga

Durante o troubleshooting anterior, estava sendo verificado:

``` text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\
{45CB4B1A-BBB8-47E4-AA69-B76116EE9A34}
```

com:

``` text
DisplayName = Check Point Endpoint Security
```

Essa detecção retornou:

``` text
applicationDetected: False
```

Portanto, não reutilize esse GUID automaticamente.

Utilize o Product Code obtido do **MSI que foi realmente gerado e
instalado**.

------------------------------------------------------------------------

# 18. Assignments

Não faça o primeiro deploy para todos os computadores.

Crie/utilize um grupo piloto, por exemplo:

``` text
GRP-INTUNE-PILOT-CHECKPOINT
```

No aplicativo:

``` text
Assignments
→ Required
→ Add group
→ GRP-INTUNE-PILOT-CHECKPOINT
```

Depois da homologação, expanda para os grupos de produção.

------------------------------------------------------------------------

# 19. Forçar sincronização

Na máquina:

``` text
Settings
→ Accounts
→ Access work or school
→ Conta corporativa
→ Info
→ Sync
```

Para troubleshooting, também é possível reiniciar a Intune Management
Extension:

``` powershell
Restart-Service IntuneManagementExtension
```

------------------------------------------------------------------------

# 20. Logs do Intune

Diretório:

``` text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Principal arquivo:

``` text
IntuneManagementExtension.log
```

Acompanhar em tempo real:

``` powershell
Get-Content `
"C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" `
-Wait
```

Pesquisar pelo Check Point:

``` powershell
Select-String `
-Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" `
-Pattern "CheckPoint|Check Point|Harmony|EPS.msi"
```

------------------------------------------------------------------------

# 21. Log do MSI

Para troubleshooting manual:

``` powershell
msiexec.exe /i ".\EPS.msi" /qn /norestart /L*v "C:\Windows\Temp\CheckPoint-Harmony-Install.log"
```

Consultar as últimas linhas:

``` powershell
Get-Content "C:\Windows\Temp\CheckPoint-Harmony-Install.log" -Tail 100
```

Pesquisar erros:

``` powershell
Select-String `
-Path "C:\Windows\Temp\CheckPoint-Harmony-Install.log" `
-Pattern "error|failed|return value 3"
```

------------------------------------------------------------------------

# 22. Troubleshooting do caso analisado

Durante os testes anteriores, o Intune conseguiu:

``` text
Baixar o pacote
→ Validar o conteúdo
→ Descompactar
→ Executar o instalador
```

Porém, posteriormente:

``` text
applicationDetected: False
```

e o aplicativo terminou com:

``` text
-2016345060
```

Por isso o procedimento desta documentação prioriza:

``` text
1. Gerar o MSI
2. Testar o MSI manualmente
3. Confirmar que o produto realmente foi instalado
4. Descobrir o Product Code correto
5. Somente depois criar a Detection Rule
6. Publicar no Intune
```

------------------------------------------------------------------------

# 23. Checklist

-   [ ] `GRP-ADM.exe` obtido do ambiente correto.
-   [ ] `.\GRP-ADM.exe /CreateMSI` executado.
-   [ ] `EPS.msi` gerado.
-   [ ] MSI testado manualmente.
-   [ ] Instalação silenciosa funcionando.
-   [ ] Produto Check Point aparece no registro.
-   [ ] Serviços do Check Point foram criados.
-   [ ] Product Code identificado e validado.
-   [ ] `EPS.intunewin` criado.
-   [ ] Win32 App criado no Intune.
-   [ ] Install behavior = `System`.
-   [ ] Install command configurado.
-   [ ] Uninstall command configurado com Product Code correto.
-   [ ] Detection Rule por MSI configurada.
-   [ ] Grupo piloto atribuído.
-   [ ] Instalação validada no endpoint.
-   [ ] Dispositivo validado no console Harmony.
-   [ ] Deploy liberado para produção.

------------------------------------------------------------------------

# 24. Estrutura recomendada do GitHub

``` text
CheckPoint-Harmony-Intune/
│
├── README.md
│
├── docs/
│   └── images/
│
└── .gitignore
```

O instalador não deve fazer parte do repositório público:

``` gitignore
*.exe
*.msi
*.intunewin
*.log
```

> Não publique instaladores corporativos, pacotes `.intunewin`, Product
> Codes internos desnecessários, tokens, chaves, URLs privadas ou
> informações sensíveis do tenant.

------------------------------------------------------------------------

# Resultado

``` text
Check Point
   ↓
GRP-ADM.exe
   ↓
/CreateMSI
   ↓
EPS.msi
   ↓
IntuneWinAppUtil
   ↓
EPS.intunewin
   ↓
Microsoft Intune
   ↓
SYSTEM
   ↓
msiexec /i EPS.msi /qn
   ↓
Detection Rule (MSI)
   ↓
Check Point Harmony Endpoint instalado
```

------------------------------------------------------------------------

## Autor

**André Luiz**

Projeto de automação e gerenciamento de endpoints utilizando Microsoft
Intune.
