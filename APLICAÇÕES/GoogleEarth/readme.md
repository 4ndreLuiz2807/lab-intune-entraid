# Google Earth Pro - Deploy via Microsoft Intune

## Visão Geral

Este pacote realiza a instalação do **Google Earth Pro** através do **Microsoft Intune**, utilizando o formato **Win32 App (.intunewin)**.

O aplicativo pode ser disponibilizado no **Portal da Empresa** para instalação sob demanda pelos usuários autorizados.

---

## Objetivo

Disponibilizar o Google Earth Pro de forma silenciosa e padronizada através do Microsoft Intune.

Principais objetivos:

- Instalação silenciosa
- Instalação em contexto SYSTEM
- Disponibilização no Portal da Empresa
- Detecção automática pelo Intune
- Desinstalação silenciosa
- Sem necessidade de intervenção do usuário

---

## Estrutura do Pacote

Exemplo:

```text
GoogleEarth
│
├── googleearth-win-pro-x64.exe
└── uninstall.ps1
```

> Ajuste o nome do executável conforme a versão baixada.  
> Exemplo atual: `googleearth-win-pro-7.3.7.xxxx-x64.exe`

---

## Instalação Silenciosa

Para o instalador EXE do Google Earth Pro, utilize:

```cmd
googleearth-win-pro-x64.exe OMAHA=1
```

Se o arquivo possuir a versão no nome:

```cmd
googleearth-win-pro-7.3.7.xxxx-x64.exe OMAHA=1
```

### Parâmetro

| Parâmetro | Função |
|---|---|
| `OMAHA=1` | Executa a instalação do Google Earth Pro em modo silencioso |

---

## Empacotamento com IntuneWinAppUtil

Exemplo de estrutura:

```text
C:\Intune\GoogleEarth
│
├── googleearth-win-pro-x64.exe
└── uninstall.ps1
```

Executar:

```cmd
IntuneWinAppUtil.exe -c "C:\Intune\GoogleEarth" -s "googleearth-win-pro-x64.exe" -o "C:\Intune\Output"
```

O resultado será um arquivo `.intunewin`.

---

## Cadastro no Microsoft Intune

Acessar:

```text
Microsoft Intune Admin Center
→ Aplicativos
→ Windows
→ Adicionar
→ Aplicativo do Windows (Win32)
```

Selecionar o arquivo `.intunewin` gerado.

---

## Informações do Aplicativo

Sugestão:

```text
Nome:
Google Earth Pro

Editor:
Google LLC

Categoria:
Mapas / Engenharia / Geoprocessamento

Descrição:
Aplicativo Google Earth Pro disponibilizado através do Portal da Empresa para visualização de imagens de satélite, mapas, terrenos e dados geográficos.
```

---

## Programa

### Comando de instalação

```cmd
googleearth-win-pro-x64.exe OMAHA=1
```

> Substitua pelo nome exato do instalador incluído no pacote.

### Comando de desinstalação

Recomenda-se utilizar um script que localize automaticamente o comando de desinstalação registrado pelo Google Earth Pro.

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

### Comportamento da instalação

```text
Sistema
```

### Reinicialização do dispositivo

```text
Nenhuma ação específica
```

---

## Script de Desinstalação

Arquivo:

```text
uninstall.ps1
```

Conteúdo:

```powershell
$ErrorActionPreference = "Stop"

$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$GoogleEarth = Get-ItemProperty $RegistryPaths -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -match "^Google Earth Pro"
    } |
    Select-Object -First 1

if (-not $GoogleEarth) {
    Write-Output "Google Earth Pro não encontrado."
    exit 0
}

Write-Output "Google Earth Pro encontrado: $($GoogleEarth.DisplayName)"
Write-Output "Versão: $($GoogleEarth.DisplayVersion)"

if ($GoogleEarth.QuietUninstallString) {

    Start-Process `
        -FilePath "cmd.exe" `
        -ArgumentList "/c `"$($GoogleEarth.QuietUninstallString)`"" `
        -Wait

    exit 0
}

$UninstallString = $GoogleEarth.UninstallString

if ($UninstallString -match "\{[A-Fa-f0-9\-]+\}") {

    $ProductCode = $Matches[0]

    $Process = Start-Process `
        -FilePath "msiexec.exe" `
        -ArgumentList "/x $ProductCode /qn /norestart" `
        -Wait `
        -PassThru

    exit $Process.ExitCode
}

if ($UninstallString) {

    Start-Process `
        -FilePath "cmd.exe" `
        -ArgumentList "/c `"$UninstallString`"" `
        -Wait

    exit 0
}

exit 1
```

---

## Requisitos

Configuração recomendada:

```text
Arquitetura:
64-bit

Sistema operacional:
Windows 10 ou Windows 11

Comportamento da instalação:
Sistema
```

---

## Regra de Detecção

Uma forma simples e confiável é detectar o executável do Google Earth Pro.

Normalmente:

```text
C:\Program Files\Google\Google Earth Pro\client\googleearth.exe
```

### Script de detecção

```powershell
$Paths = @(
    "C:\Program Files\Google\Google Earth Pro\client\googleearth.exe",
    "C:\Program Files (x86)\Google\Google Earth Pro\client\googleearth.exe"
)

foreach ($Path in $Paths) {

    if (Test-Path $Path) {

        $Version = (Get-Item $Path).VersionInfo.ProductVersion

        Write-Output "Google Earth Pro detectado - versão $Version"
        exit 0
    }
}

exit 1
```

No Intune:

```text
Formato das regras:
Usar um script de detecção personalizado
```

Selecionar:

```text
detect.ps1
```

---

## Alternativa de Detecção por Registro

Também é possível utilizar:

```powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "^Google Earth Pro"
}
```

Se o aplicativo for encontrado, a detecção pode retornar:

```powershell
Write-Output "Google Earth Pro instalado"
exit 0
```

Caso contrário:

```powershell
exit 1
```

---

## Atribuição

Para disponibilizar no Portal da Empresa:

```text
Atribuições
→ Disponível para dispositivos registrados
→ Adicionar grupo
```

Exemplo:

```text
Disponível:
Grupo de usuários autorizado

Obrigatório:
Nenhuma atribuição

Desinstalar:
Nenhuma atribuição
```

---

## Funcionamento Esperado

```text
Portal da Empresa
        ↓
Usuário seleciona Google Earth Pro
        ↓
Intune Management Extension
        ↓
Download do .intunewin
        ↓
Extração em IMECache
        ↓
Execução do instalador
        ↓
googleearth-win-pro-x64.exe OMAHA=1
        ↓
Instalação em contexto SYSTEM
        ↓
Regra de detecção
        ↓
Google Earth Pro instalado
```

---

## Teste Local Antes do Intune

Abra PowerShell ou CMD como administrador na pasta do instalador.

PowerShell:

```powershell
.\googleearth-win-pro-x64.exe OMAHA=1
```

Depois valide:

```powershell
Test-Path "C:\Program Files\Google\Google Earth Pro\client\googleearth.exe"
```

Também é possível consultar o registro:

```powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "^Google Earth Pro"
} |
Select-Object `
DisplayName,
DisplayVersion,
Publisher,
InstallLocation,
PSChildName,
UninstallString,
QuietUninstallString
```

---

## Troubleshooting

Logs do Microsoft Intune Management Extension:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Principais arquivos:

```text
AppWorkload.log
IntuneManagementExtension.log
AgentExecutor.log
```

Pesquisar falhas relacionadas ao Google Earth:

```powershell
Select-String `
-Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\*.log" `
-Pattern "Google Earth","googleearth","ExitCode","Error","Failed" |
Select-Object -Last 100
```

---

## Boas Práticas

Para este pacote:

```text
Tipo:
Windows app (Win32)

Instalação:
EXE diretamente

Contexto:
SYSTEM

Disponibilização:
Portal da Empresa
```

Sempre testar o comando silencioso localmente antes de empacotar.

Evitar scripts PowerShell intermediários quando o próprio instalador possui um parâmetro silencioso funcional.

Utilizar scripts quando houver necessidade de:

- Pós-configuração
- Manipulação de registro
- Cópia de arquivos
- Tratamento de versões anteriores
- Remoção customizada
- Dependências
- Logs adicionais

---

## Resultado Esperado

```text
Download pelo Intune: OK
Instalação silenciosa: OK
Instalação em SYSTEM: OK
Detecção: OK
Portal da Empresa: OK
Desinstalação: Configurada
```

---

## Referências

- Google Earth Pro - página oficial de versões
- Google Earth Help - instalação e desinstalação
- Google Earth Help - instaladores diretos

---

## Autor

**André Luiz**

Documentação de deploy e gerenciamento de aplicações utilizando Microsoft Intune.
