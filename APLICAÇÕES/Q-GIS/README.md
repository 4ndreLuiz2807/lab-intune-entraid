<img src="https://raw.githubusercontent.com/4ndreLuiz2807/lab-intune-entraid/refs/heads/main/APLICA%C3%87%C3%95ES/Q-GIS/banner_qgis_intune.svg" alt="Banner" width="100%" />

# 🗺️ Deploy do QGIS via Microsoft Intune

![QGIS + Microsoft Intune](./banner_qgis_intune.svg)

Documentação do processo utilizado para realizar o **deploy do QGIS em dispositivos Windows gerenciados pelo Microsoft Intune**, incluindo instalação silenciosa e criação automática do atalho na Área de Trabalho.

---

## 📌 Visão geral

| Item           | Configuração                  |
| -------------- | ----------------------------- |
| Aplicação      | QGIS                          |
| Plataforma     | Windows                       |
| Gerenciamento  | Microsoft Intune              |
| Instalador     | MSI                           |
| Empacotamento  | Win32 (`.intunewin`)          |
| Tipo no Intune | Aplicativo do Windows (Win32) |
| Arquitetura    | 64 bits                       |
| Contexto       | Sistema                       |
| Instalação     | PowerShell + MSI              |
| Atalho         | `C:\Users\Public\Desktop`     |

---

# 📥 1. Download do QGIS

O instalador pode ser obtido através do site oficial:

https://qgis.org/download/

Para ambientes corporativos, pode ser interessante utilizar uma versão **LTR (Long Term Release)**, priorizando estabilidade.

Neste deploy foi utilizado um instalador MSI no padrão:

```text
QGIS-OSGeo4W-3.44.13-1.msi
```

> ⚠️ No repositório do QGIS também existem pacotes como `QGIS-Grids-OSGeo4W`. Eles não correspondem ao instalador principal do QGIS.

---

# ⚠️ 2. Problema encontrado com o MSI

Durante os primeiros testes, foi utilizado um arquivo MSI que não era reconhecido corretamente pelo Intune.

Ao tentar adicioná-lo diretamente como aplicativo LOB, era apresentado:

```text
O pacote do aplicativo selecionado parece não ter um
ProductCode ou ProductVersion.
```

Ao tentar processar o mesmo arquivo através do `IntuneWinAppUtil`, também era apresentado:

```text
The specified Windows Installer file could not be opened.
Verify the file is a valid Windows Installer file.
```

A solução foi obter novamente o **MSI oficial válido do QGIS** e publicá-lo como **Aplicativo do Windows (Win32)**.

---

# 📦 3. Microsoft Win32 Content Prep Tool

Para gerar o pacote utilizado pelo Intune, foi utilizada a ferramenta oficial:

**Microsoft Win32 Content Prep Tool**

https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

Arquivo necessário:

```text
IntuneWinAppUtil.exe
```

---

# 🖥️ 4. Criação automática do atalho

Durante os testes foi identificado que o QGIS era instalado corretamente, porém **o atalho não era criado na Área de Trabalho**.

Como o aplicativo é instalado pelo Intune em contexto **SYSTEM**, foi adicionada uma etapa ao deployment para criar o atalho em:

```text
C:\Users\Public\Desktop
```

Utilizar a Área de Trabalho Pública garante que o atalho fique disponível para **todos os usuários que utilizarem o computador**.

Para isso, o pacote passou a utilizar um script PowerShell como arquivo principal da instalação.

---

# 📁 5. Estrutura do pacote

Prepare uma pasta contendo:

```text
C:\QGIS-INTUNE\
│
├── QGIS-OSGeo4W-3.44.13-1.msi
└── install.ps1
```

O `install.ps1` será responsável por:

```text
Instalar o MSI
      ↓
Aguardar a conclusão
      ↓
Validar o Exit Code
      ↓
Localizar o executável do QGIS
      ↓
Criar o atalho
      ↓
C:\Users\Public\Desktop\QGIS.lnk
```

---

# ⚙️ 6. Script de instalação

Crie o arquivo:

```text
install.ps1
```

Conteúdo:

```powershell
$ErrorActionPreference = "Stop"

$MsiPath = Join-Path $PSScriptRoot "QGIS-OSGeo4W-3.44.13-1.msi"

Write-Output "Instalando QGIS..."

$Process = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i `"$MsiPath`" /qn /norestart" `
    -Wait `
    -PassThru

if ($Process.ExitCode -notin @(0, 3010, 1641)) {
    Write-Error "Falha na instalacao do QGIS. ExitCode: $($Process.ExitCode)"
    exit $Process.ExitCode
}

Write-Output "QGIS instalado. Procurando executavel..."

$QgisExe = Get-ChildItem `
    -Path "$env:ProgramFiles\QGIS*" `
    -Filter "qgis.exe" `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $QgisExe) {
    $QgisExe = Get-ChildItem `
        -Path "$env:ProgramFiles\QGIS*" `
        -Filter "qgis-bin.exe" `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

if (-not $QgisExe) {
    Write-Error "QGIS foi instalado, mas o executavel nao foi encontrado."
    exit 1
}

Write-Output "Executavel encontrado: $($QgisExe.FullName)"

$DesktopPath = "C:\Users\Public\Desktop"
$ShortcutPath = Join-Path $DesktopPath "QGIS.lnk"

$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = $QgisExe.FullName
$Shortcut.WorkingDirectory = $QgisExe.DirectoryName
$Shortcut.IconLocation = "$($QgisExe.FullName),0"
$Shortcut.Description = "QGIS"

$Shortcut.Save()

if (Test-Path $ShortcutPath) {
    Write-Output "Atalho criado com sucesso: $ShortcutPath"
    exit 0
}

Write-Error "Falha ao criar o atalho do QGIS."
exit 1
```

---

# 📦 7. Gerando o `.intunewin`

A estrutura pode ficar assim:

```text
C:\
├── IntuneWin\
│   └── IntuneWinAppUtil.exe
│
├── QGIS-INTUNE\
│   ├── QGIS-OSGeo4W-3.44.13-1.msi
│   └── install.ps1
│
└── QGIS-OUTPUT\
```

Abra o PowerShell:

```powershell
cd C:\IntuneWin
```

Execute:

```powershell
.\IntuneWinAppUtil.exe `
-c "C:\QGIS-INTUNE" `
-s "install.ps1" `
-o "C:\QGIS-OUTPUT"
```

> ⚠️ **Importante:** utilize `install.ps1` como **Setup File**, e não o MSI.

Dessa forma, tanto o script quanto o MSI serão incluídos no `.intunewin`.

O resultado será:

```text
C:\QGIS-OUTPUT\install.intunewin
```

Você pode renomear o pacote posteriormente, caso necessário.

---

# ☁️ 8. Criando o aplicativo no Intune

No **Microsoft Intune Admin Center**, acesse:

```text
Aplicativos
└── Windows
    └── Criar
```

Selecione:

```text
Aplicativo do Windows (Win32)
```

Faça upload do arquivo:

```text
install.intunewin
```

---

# 📝 9. Informações do aplicativo

Exemplo:

```text
Nome: QGIS
Fornecedor: QGIS
Categoria: Aplicativos
```

A descrição e demais informações podem ser ajustadas conforme o padrão da organização.

---

# ⚙️ 10. Programa

Existe uma diferença importante em relação ao empacotamento direto do MSI.

### Quando o MSI é o Setup File

Se o `.intunewin` for criado selecionando diretamente:

```text
QGIS-OSGeo4W-3.44.13-1.msi
```

o Intune consegue ler os metadados MSI e normalmente preenche automaticamente:

* comando de instalação;
* comando de desinstalação;
* ProductCode;
* informações utilizadas para detecção.

### Quando `install.ps1` é o Setup File

Como neste deployment precisamos executar uma ação adicional para criar o atalho, o arquivo principal passou a ser:

```text
install.ps1
```

Nesse caso, o Intune **não preencherá automaticamente os comandos MSI**.

Configure manualmente.

### Comando de instalação

```cmd
powershell.exe -ExecutionPolicy Bypass -NoProfile -File ".\install.ps1"
```

### Comando de desinstalação

Utilize o ProductCode do MSI:

```cmd
msiexec.exe /x "{PRODUCT-CODE-DO-QGIS}" /qn /norestart
```

O ProductCode pode ser obtido previamente através do MSI ou do aplicativo criado anteriormente no Intune.

### Comportamento de instalação

Configure:

```text
Comportamento de instalação: Sistema
```

Isso é importante porque o Intune Management Extension executará o deployment em contexto **SYSTEM**.

---

# 💻 11. Requisitos

Exemplo:

```text
Arquitetura do sistema operacional:
64 bits

Sistema operacional mínimo:
Windows 10 22H2
```

Adapte os requisitos conforme o parque de dispositivos da organização.

---

# 🔎 12. Regra de detecção

A regra de detecção deve confirmar que o QGIS está instalado.

Pode ser utilizada a detecção MSI através do ProductCode ou uma regra baseada no executável.

Para localizar o executável após uma instalação de teste:

```powershell
Get-ChildItem "C:\Program Files\QGIS*" `
-Filter "qgis*.exe" `
-Recurse `
-ErrorAction SilentlyContinue |
Select-Object FullName
```

Após identificar o caminho correto, configure uma regra de detecção por arquivo.

Exemplo:

```text
Tipo:
Arquivo

Caminho:
C:\Program Files\QGIS 3.44.13\bin

Arquivo:
qgis.exe

Método:
Arquivo ou pasta existe
```

> O caminho deve ser validado de acordo com a versão do QGIS instalada.

---

# 🖱️ 13. Atalho na Área de Trabalho

Após a instalação, o script cria:

```text
C:\Users\Public\Desktop\QGIS.lnk
```

Não foi utilizado:

```text
%USERPROFILE%\Desktop
```

porque o Win32 App está configurado para execução em contexto **SYSTEM**.

Nesse contexto, `%USERPROFILE%` não necessariamente representa o usuário que está utilizando o computador.

Utilizando:

```text
C:\Users\Public\Desktop
```

o atalho fica disponível para todos os usuários da máquina.

---

# 👥 14. Atribuições

O aplicativo pode ser configurado como **Obrigatório** para instalação automática:

```text
Atribuições
└── Obrigatório
    └── Grupo de dispositivos
```

Ou disponibilizado no **Portal da Empresa**:

```text
Atribuições
└── Disponível para dispositivos registrados
    └── Grupo de usuários
```

---

# 🔄 15. Fluxo do deployment

```text
QGIS MSI oficial
       │
       ├──────────────┐
       │              │
       ▼              ▼
install.ps1       QGIS.msi
       │              │
       └──────┬───────┘
              ▼
      IntuneWinAppUtil
              │
              ▼
       install.intunewin
              │
              ▼
      Microsoft Intune
              │
              ▼
       Win32 App / SYSTEM
              │
              ▼
         install.ps1
              │
              ├── msiexec /i QGIS.msi
              │
              ▼
         QGIS instalado
              │
              ▼
    Localiza qgis.exe
              │
              ▼
     Cria QGIS.lnk
              │
              ▼
 C:\Users\Public\Desktop
```

---

# 🛠️ 16. Troubleshooting

Os logs do Intune Management Extension ficam em:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Principais arquivos:

```text
IntuneManagementExtension.log
AppWorkload.log
AppActionProcessor.log
AgentExecutor.log
```

Para acompanhar o log principal:

```powershell
Get-Content "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Wait
```

Para pesquisar informações relacionadas ao QGIS:

```powershell
Select-String `
-Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\*.log" `
-Pattern "QGIS|msiexec|Exit code" `
-Context 5,10
```

No portal:

```text
Intune
→ Aplicativos
→ Windows
→ QGIS
→ Monitorar
→ Status de instalação do dispositivo
```

---

# ✅ Resultado

Com essa configuração, o processo fica totalmente automatizado:

```text
✓ Download do MSI oficial
✓ Empacotamento como Win32 App
✓ Instalação silenciosa do QGIS
✓ Execução em contexto SYSTEM
✓ Validação do retorno do MSI
✓ Localização automática do executável
✓ Criação automática do atalho
✓ Atalho disponível para todos os usuários
✓ Gerenciamento centralizado pelo Intune
```

O dispositivo recebe o QGIS através do Microsoft Intune e, após a instalação, o usuário já encontra o **atalho do QGIS na Área de Trabalho**, sem necessidade de configuração manual.

---

## 🔗 Referências

**QGIS**

https://qgis.org/

**Download do QGIS**

https://qgis.org/download/

**Microsoft Win32 Content Prep Tool**

https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

**Microsoft Intune — Win32 Apps**

https://learn.microsoft.com/mem/intune/apps/apps-win32-app-management

---

## 👨‍💻 Autor

**André Luiz**

Documentação de laboratório voltada para **Microsoft Intune, gerenciamento de endpoints e automação de deployment de aplicações Windows**.
