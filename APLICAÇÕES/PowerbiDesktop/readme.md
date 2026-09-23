
# Power BI Desktop - Deploy via Microsoft Intune

## Visão Geral

Este pacote realiza a instalação do **Microsoft Power BI Desktop** através do **Microsoft Intune**, utilizando o formato **Windows App (Win32) / `.intunewin`**.

O aplicativo pode ser disponibilizado no **Portal da Empresa** para instalação sob demanda ou atribuído como obrigatório para grupos específicos.

---

## Objetivo

Padronizar o deploy do Power BI Desktop no ambiente corporativo utilizando o Microsoft Intune.

Principais objetivos:

- Instalação silenciosa
- Instalação em contexto SYSTEM
- Aceite automático da EULA
- Sem reinicialização automática
- Disponibilização no Portal da Empresa
- Detecção automática pelo Intune
- Desinstalação silenciosa
- Possibilidade de controle de atualização

---

## Arquivo Utilizado

Exemplo:

```text
PBIDesktopSetup_x64.exe
```

Estrutura do pacote:

```text
PowerBI
│
└── PBIDesktopSetup_x64.exe
```

---

## Instalação Silenciosa

A Microsoft suporta instalação silenciosa através dos parâmetros de linha de comando do instalador.

Comando recomendado:

```cmd
PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1
```

Para forçar Português do Brasil:

```cmd
PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1 LANGUAGE=pt-BR
```

> Observação: se o instalador não aceitar `pt-BR` em uma versão específica, remova o parâmetro `LANGUAGE`. Nesse caso, o Power BI Desktop utilizará o idioma configurado no Windows.

---

## Parâmetros Utilizados

| Parâmetro | Função |
|---|---|
| `-quiet` | Executa a instalação silenciosamente |
| `-norestart` | Impede reinicialização automática |
| `ACCEPT_EULA=1` | Aceita automaticamente os termos de licença |
| `LANGUAGE=pt-BR` | Define o idioma padrão, quando suportado |
| `INSTALLDESKTOPSHORTCUT=1` | Cria atalho na área de trabalho |
| `DISABLE_UPDATE_NOTIFICATION=1` | Desabilita notificações de atualização |

Exemplo corporativo:

```cmd
PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1 INSTALLDESKTOPSHORTCUT=1
```

Caso as atualizações sejam controladas exclusivamente pelo Intune:

```cmd
PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1 INSTALLDESKTOPSHORTCUT=1 DISABLE_UPDATE_NOTIFICATION=1
```

---

## Teste Local

Antes de criar o `.intunewin`, testar o instalador localmente.

Abra PowerShell como administrador:

```powershell
.\PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1
```

Aguarde o término da instalação.

Depois valide:

```powershell
Get-Process PBIDesktop -ErrorAction SilentlyContinue
```

ou procure o executável:

```powershell
Get-ChildItem "C:\Program Files\Microsoft Power BI Desktop" -Recurse -Filter PBIDesktop.exe -ErrorAction SilentlyContinue
```

---

## Empacotamento com IntuneWinAppUtil

Estrutura:

```text
C:\Intune\PowerBI
│
└── PBIDesktopSetup_x64.exe
```

Gerar o pacote:

```cmd
IntuneWinAppUtil.exe -c "C:\Intune\PowerBI" -s "PBIDesktopSetup_x64.exe" -o "C:\Intune\Output"
```

Resultado esperado:

```text
PBIDesktopSetup_x64.intunewin
```

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

Selecionar:

```text
PBIDesktopSetup_x64.intunewin
```

---

## Informações do Aplicativo

Sugestão:

```text
Nome:
Microsoft Power BI Desktop

Descrição:
Ferramenta Microsoft para criação de relatórios, dashboards e análise de dados.

Editor:
Microsoft Corporation

Categoria:
Business Intelligence / Análise de Dados
```

---

## Configuração - Programa

### Tipo de instalador

```text
Linha de comando
```

### Comando de instalação

```cmd
PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1
```

Ou:

```cmd
PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1 LANGUAGE=pt-BR
```

### Comando de desinstalação

O instalador do Power BI Desktop suporta o parâmetro:

```text
-uninstall
```

Utilize:

```cmd
PBIDesktopSetup_x64.exe -uninstall -quiet -norestart
```

> O executável utilizado na desinstalação precisa estar disponível durante a execução do pacote Win32. Como o Intune mantém os arquivos do pacote apenas durante a execução, esse método funciona quando o comando é executado a partir do conteúdo extraído do `.intunewin`.

---

## Alternativa de Desinstalação por Registro

Para descobrir a entrada registrada pelo Power BI Desktop:

```powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "Power BI Desktop"
} |
Format-List `
DisplayName,
DisplayVersion,
PSChildName,
UninstallString,
QuietUninstallString
```

Se a versão instalada possuir `QuietUninstallString`, ele pode ser utilizado diretamente no Intune.

---

## Comportamento da Instalação

```text
Sistema
```

---

## Comportamento de Reinicialização

```text
Nenhuma ação específica
```

---

## Tempo Máximo de Instalação

Sugestão:

```text
60 minutos
```

---

## Códigos de Retorno

Manter os códigos padrão do Intune:

| Código | Comportamento |
|---:|---|
| `0` | Êxito |
| `1707` | Êxito |
| `3010` | Reinicialização suave |
| `1641` | Reinicialização forçada |
| `1618` | Tentar novamente |

---

## Requisitos

Sugestão:

```text
Arquitetura:
64-bit

Sistema operacional mínimo:
Windows 10 ou Windows 11
```

---

## Regra de Detecção

### Opção 1 - Detecção por Arquivo

O executável geralmente é instalado em:

```text
C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe
```

No Intune:

```text
Tipo de regra:
Arquivo

Caminho:
C:\Program Files\Microsoft Power BI Desktop\bin

Arquivo ou pasta:
PBIDesktop.exe

Método de detecção:
Arquivo ou pasta existe
```

---

## Opção 2 - Script de Detecção

Arquivo:

```text
detect.ps1
```

Conteúdo:

```powershell
$Paths = @(
    "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
    "C:\Program Files (x86)\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
)

foreach ($Path in $Paths) {

    if (Test-Path $Path) {

        $Version = (Get-Item $Path).VersionInfo.ProductVersion

        Write-Output "Power BI Desktop detectado - versão $Version"
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

---

## Opção 3 - Detecção por Registro

Para localizar a chave real:

```powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "Power BI Desktop"
} |
Select-Object `
DisplayName,
DisplayVersion,
PSChildName
```

Essa opção é útil quando há necessidade de validar uma versão mínima.

---

## Atribuições

Para disponibilizar no Portal da Empresa:

```text
Atribuições
→ Disponível para dispositivos registrados
→ Adicionar grupo
```

Sugestão:

```text
Obrigatório:
Nenhum grupo

Disponível para dispositivos registrados:
Grupo de usuários autorizado

Desinstalar:
Nenhum grupo
```

---

## Fluxo de Instalação

```text
Portal da Empresa
        ↓
Usuário seleciona Power BI Desktop
        ↓
Intune Management Extension
        ↓
Download do .intunewin
        ↓
Validação e descriptografia
        ↓
Extração em IMECache
        ↓
PBIDesktopSetup_x64.exe
        ↓
Instalação silenciosa
        ↓
Regra de detecção
        ↓
Aplicativo instalado
```

---

## Validação Pós-Instalação

Verificar arquivo:

```powershell
Test-Path "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
```

Verificar versão:

```powershell
(Get-Item "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe").VersionInfo |
Select-Object ProductName,ProductVersion,CompanyName
```

Verificar registro:

```powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "Power BI Desktop"
} |
Select-Object `
DisplayName,
DisplayVersion,
Publisher,
UninstallString
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

Pesquisar informações relacionadas ao Power BI:

```powershell
Select-String `
-Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\*.log" `
-Pattern "Power BI","PBIDesktop","ExitCode","Error","Failed" |
Select-Object -Last 100
```

---

## Log do Instalador

O instalador suporta geração de log.

Exemplo:

```cmd
PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1 -log C:\ProgramData\PowerBI-Install.log
```

Caso a versão utilizada exija o caminho junto ao parâmetro, validar com:

```cmd
PBIDesktopSetup_x64.exe -?
```

---

## Observação Importante - Contexto SYSTEM

A instalação pode ser executada pelo Intune em contexto **SYSTEM**.

Entretanto, o **Power BI Desktop não deve ser executado pelo usuário SYSTEM**, pois o aplicativo utiliza componentes como WebView2 que dependem do perfil do usuário.

Isso não impede o deploy pelo Intune.

O cenário correto é:

```text
Intune / SYSTEM
       ↓
Instala o aplicativo
       ↓
Usuário corporativo faz login
       ↓
Usuário executa Power BI Desktop
```

---

## Atualizações

O Power BI Desktop recebe atualizações frequentes.

Em ambientes corporativos, recomenda-se definir uma estratégia de atualização.

Exemplo:

```text
Versão atual do Power BI
        ↓
Nova versão validada
        ↓
Atualizar pacote Win32
        ↓
Atualizar regra de detecção
        ↓
Redistribuir pelo Intune
```

Se a organização quiser controlar totalmente as versões pelo Intune, pode utilizar:

```text
DISABLE_UPDATE_NOTIFICATION=1
```

Exemplo:

```cmd
PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1 DISABLE_UPDATE_NOTIFICATION=1
```

---

## Boas Práticas

- Utilizar sempre o instalador oficial da Microsoft.
- Priorizar o instalador x64.
- Testar os comandos localmente antes do upload.
- Evitar instalação interativa.
- Utilizar contexto SYSTEM para o deploy.
- Validar a instalação com regra de detecção.
- Manter controle da versão publicada.
- Criar um processo periódico de atualização do pacote.
- Não executar o Power BI Desktop como SYSTEM.

---

## Configuração Recomendada

Resumo:

```text
Tipo:
Windows App (Win32)

Instalador:
PBIDesktopSetup_x64.exe

Instalação:
PBIDesktopSetup_x64.exe -quiet -norestart ACCEPT_EULA=1

Desinstalação:
PBIDesktopSetup_x64.exe -uninstall -quiet -norestart

Comportamento:
Sistema

Reinicialização:
Nenhuma ação específica

Detecção:
C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe

Disponibilização:
Portal da Empresa
```

---

## Resultado Esperado

```text
Download pelo Intune: OK
Instalação silenciosa: OK
Contexto SYSTEM: OK
Portal da Empresa: OK
Detecção: OK
Desinstalação silenciosa: OK
```

---

## Referências

- Microsoft Learn - Download Power BI Desktop
- Microsoft Learn - Add and assign Win32 apps to Microsoft Intune
- Microsoft Learn - Windows Installer uninstall registry information

---

## Autor

**André Luiz**

Documentação de deploy e gerenciamento de aplicações utilizando Microsoft Intune.
