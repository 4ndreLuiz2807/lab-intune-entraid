<img src="https://raw.githubusercontent.com/4ndreLuiz2807/lab-intune-entraid/refs/heads/main/APLICA%C3%87%C3%95ES/SAP/sap.svg" alt="Banner" width="50%" />

# SAP GUI 8.00 --- Deploy via Microsoft Intune

Documentação do pacote utilizado para instalação silenciosa do **SAP GUI
for Windows 8.00 64-bit** através do **Microsoft Intune --- Windows app
(Win32)**.

> O pacote é executado pelo **Intune Management Extension (IME)** em
> contexto `SYSTEM`.

## 📦 Estrutura do pacote

``` text
SAP-GUI/
├── Source/
│   ├── sap.exe
│   ├── Script Install SAP GUI.ps1
│   └── Uninstall SAP.ps1
├── Detection/
│   └── Detect-SAP.ps1
└── README.md
```

## 🔄 Fluxo

``` text
Microsoft Intune
      ↓
Download do .intunewin
      ↓
Intune Management Extension
      ↓
Script Install SAP GUI.ps1
      ↓
sap.exe /Silent
      ↓
SAP GUI 8.00
      ↓
Detect-SAP.ps1
      ↓
Installed
```

O instalador é localizado dentro do pacote com:

``` powershell
$Installer = Join-Path $PSScriptRoot "sap.exe"
```

Isso elimina dependência de unidade mapeada ou compartilhamento de rede
durante o deploy.

## 🚀 1. Preparar os arquivos

Pasta de origem:

``` text
C:\Intune\SAP-GUI\Source\
```

Conteúdo:

``` text
Source\
├── sap.exe
├── Script Install SAP GUI.ps1
└── Uninstall SAP.ps1
```

Detecção:

``` text
C:\Intune\SAP-GUI\Detection\
└── Detect-SAP.ps1
```

## 📦 2. Gerar o `.intunewin`

Use o Microsoft Win32 Content Prep Tool:

``` cmd
IntuneWinAppUtil.exe -c "C:\Intune\SAP-GUI\Source" -s "Script Install SAP GUI.ps1" -o "C:\Intune\Output"
```

No modo interativo:

``` text
Please specify the source folder:
C:\Intune\SAP-GUI\Source

Please specify the setup file:
Script Install SAP GUI.ps1

Please specify the output folder:
C:\Intune\Output
```

> O Setup File é apenas o arquivo principal. Todo o conteúdo da pasta
> `Source` é incluído no pacote `.intunewin`.

## ☁️ 3. Criar o aplicativo no Intune

Acesse:

``` text
Apps
└── Windows
    └── Add
        └── Windows app (Win32)
```

Faça upload do `.intunewin`.

Nome sugerido:

``` text
SAP GUI 8.00
```

## ⚙️ 4. Program

### Install command

``` text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Script Install SAP GUI.ps1"
```

### Uninstall command

``` text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Uninstall SAP.ps1"
```

### Install behavior

``` text
System
```

A instalação será executada como `NT AUTHORITY\SYSTEM`.

## 🔎 5. Detection rules

Selecione:

``` text
Use a custom detection script
```

Faça upload de:

``` text
Detect-SAP.ps1
```

Configure:

``` text
Run script as 32-bit process on 64-bit clients: No
Enforce script signature check: No
```

A detecção procura por:

``` text
SAP GUI for Windows 8.00*
```

nas chaves:

``` text
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
```

Quando encontrado, o script deve produzir saída e retornar `exit 0`.
Caso contrário, retorna `exit 1`.

## 🌐 6. Conexão SAP

O SAP GUI pode utilizar o arquivo:

``` text
SAPUILandscape.xml
```

para distribuir conexões pré-configuradas.

Configuração utilizada:

  Parâmetro               Valor
  ----------------------- ----------------
  Descrição               `DEV - DS4`
  SID                     `DS4`
  Número da instância     `00`
  Servidor de aplicação   `172.18.3.211`

> Não armazene senhas, tokens ou credenciais no repositório.

## 📝 7. Logs da instalação

O script grava:

``` text
C:\ProgramData\Bioaroeira\Logs\SAP-Install.log
```

Consultar:

``` powershell
Get-Content "C:\ProgramData\Bioaroeira\Logs\SAP-Install.log"
```

Verificar se o script chegou a executar:

``` powershell
Test-Path "C:\ProgramData\Bioaroeira\Logs\SAP-Install.log"
```

## 🛠️ 8. Troubleshooting do Intune

Logs do Intune Management Extension:

``` text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\
```

Principais:

``` text
AppWorkload.log
IntuneManagementExtension.log
AgentExecutor.log
```

Consultar o `AppWorkload.log`:

``` powershell
Get-Content "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppWorkload.log" -Tail 300
```

Ele ajuda a validar download do `.intunewin`, extração, Install Command,
diretório `IMECache`, criação do processo e Exit Code.

## ✅ 9. Validar o SAP instalado

``` powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -like "SAP GUI for Windows*"
} |
Select-Object DisplayName, DisplayVersion
```

Resultado observado:

``` text
SAP GUI for Windows 8.00 64bit (Patch 2)
8.00 Compilation 1
```

## 🔧 SAP não detectado

Liste todos os componentes SAP:

``` powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -like "*SAP*" } |
Select-Object DisplayName, DisplayVersion
```

Consulte as últimas linhas do log:

``` powershell
Get-Content "C:\ProgramData\Bioaroeira\Logs\SAP-Install.log" -Tail 100
```

## ⚠️ Atualização do pacote

Sempre que `sap.exe`, os scripts ou arquivos de configuração forem
alterados, gere novamente o `.intunewin` antes de atualizar o aplicativo
no Intune.

## ✅ Checklist

-   [ ] `sap.exe` presente em `Source`
-   [ ] Script de instalação incluído
-   [ ] Script de desinstalação incluído
-   [ ] `.intunewin` gerado
-   [ ] Aplicativo Win32 criado
-   [ ] `Install behavior = System`
-   [ ] Install command configurado
-   [ ] Uninstall command configurado
-   [ ] `Detect-SAP.ps1` configurado
-   [ ] Detecção em 64 bits
-   [ ] Grupo piloto atribuído
-   [ ] `SAP-Install.log` validado
-   [ ] SAP detectado pelo Intune
-   [ ] Conexão `DEV - DS4` validada

## 🎯 Resultado esperado

``` text
SAP GUI for Windows 8.00 64-bit
             +
       Microsoft Intune
             ↓
          Installed
```
