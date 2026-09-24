# Intune — Implementações e Automações para Windows

Este documento reúne um conjunto de implementações recomendadas para ambientes corporativos gerenciados pelo Microsoft Intune, com foco em automação, padronização, redução de chamados e melhoria da experiência dos usuários.

## Objetivo

Implementar e documentar as seguintes configurações:

- Limpeza de arquivos temporários
- Controle de espaço em disco
- Desabilitar Fast Startup
- Configurar OneDrive KFM
- Configurar Wi-Fi corporativo
- Configurar Device Cleanup Rule
- Configurar Shared PC

---

# Pré-requisitos

Antes de aplicar qualquer política em produção, crie um grupo piloto, por exemplo:

```text
GRP-INTUNE-PILOTO-WINDOWS
```

Adicione inicialmente entre 2 e 5 dispositivos de teste.

Para computadores compartilhados, utilize um grupo dedicado, por exemplo:

```text
GRP-INTUNE-SHARED-PC
```

Recomenda-se utilizar o seguinte fluxo de implantação:

```text
FASE 1
Dispositivo de TI

        ↓

FASE 2
Grupo piloto

        ↓

FASE 3
10 a 20 dispositivos

        ↓

FASE 4
Produção
```

---

# A. Limpeza de arquivos temporários

## Objetivo

Detectar e remover automaticamente arquivos temporários antigos, reduzindo consumo desnecessário de disco.

A recomendação é utilizar **Remediations** no Intune.

## Script de detecção

Arquivo:

```text
Detect-TempFiles.ps1
```

```powershell
$DaysToKeep = 7
$ThresholdMB = 500

$Cutoff = (Get-Date).AddDays(-$DaysToKeep)

$Paths = @(
    "$env:windir\Temp",
    "C:\Users\*\AppData\Local\Temp"
)

$TotalBytes = 0

foreach ($Path in $Paths) {
    try {
        $Files = Get-ChildItem -Path $Path -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $Cutoff }

        $TotalBytes += ($Files | Measure-Object -Property Length -Sum).Sum
    }
    catch {}
}

$TotalMB = [math]::Round($TotalBytes / 1MB, 2)

if ($TotalMB -ge $ThresholdMB) {
    Write-Output "Detectado $TotalMB MB de arquivos temporários antigos."
    exit 1
}

Write-Output "Somente $TotalMB MB de arquivos temporários elegíveis."
exit 0
```

## Script de correção

Arquivo:

```text
Remediate-TempFiles.ps1
```

```powershell
$DaysToKeep = 7
$Cutoff = (Get-Date).AddDays(-$DaysToKeep)

$Paths = @(
    "$env:windir\Temp",
    "C:\Users\*\AppData\Local\Temp"
)

$FreedBytes = 0

foreach ($Path in $Paths) {

    $Files = Get-ChildItem -Path $Path -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $Cutoff }

    foreach ($File in $Files) {

        $Size = $File.Length

        try {
            Remove-Item -LiteralPath $File.FullName -Force -ErrorAction Stop
            $FreedBytes += $Size
        }
        catch {
            # Arquivos em uso são ignorados
        }
    }
}

$FreedMB = [math]::Round($FreedBytes / 1MB, 2)

Write-Output "Limpeza concluída. Aproximadamente $FreedMB MB liberados."
exit 0
```

## Criar no Intune

Caminho:

```text
Intune Admin Center
→ Devices
→ Manage devices
→ Scripts and remediations
→ Create script package
```

Nome sugerido:

```text
REM - Windows - Temporary Files Cleanup
```

Configurações:

```text
Run this script using logged-on credentials: No
Enforce script signature check: No
Run script in 64-bit PowerShell: Yes
```

Atribuir inicialmente ao:

```text
GRP-INTUNE-PILOTO-WINDOWS
```

Periodicidade recomendada:

```text
Daily
```

## Validação

No dispositivo:

```powershell
Get-ChildItem C:\Windows\Temp -Force
```

No Intune:

```text
Devices
→ Scripts and remediations
→ REM - Windows - Temporary Files Cleanup
→ Device status
```

## Observações

Não adicionar ao script:

```text
Downloads
Desktop
Documents
OneDrive
```

A limpeza deve ser restrita a diretórios temporários.

---

# B. Controle de espaço em disco

## Objetivo

Utilizar o Storage Sense para limpeza automática nativa do Windows e complementar com uma Remediation para identificar máquinas com pouco espaço livre.

---

## Parte 1 — Storage Sense

Criar:

```text
Devices
→ Manage devices
→ Configuration
→ Create
→ New policy
```

Selecionar:

```text
Platform: Windows 10 and later
Profile type: Settings catalog
```

Nome:

```text
CFG - Windows - Storage Sense
```

Pesquisar por:

```text
Storage
```

Adicionar:

```text
Allow Storage Sense Global
Allow Storage Sense Temporary Files Cleanup
Config Storage Sense Global Cadence
Config Storage Sense Recycle Bin Cleanup Threshold
Config Storage Sense Cloud Content Dehydration Threshold
Config Storage Sense Downloads Cleanup Threshold
```

Sugestão inicial:

| Configuração | Valor |
|---|---|
| Allow Storage Sense Global | Allow |
| Temporary Files Cleanup | Allow |
| Global Cadence | Weekly |
| Recycle Bin | 30 dias |
| Cloud Content Dehydration | 30 dias |
| Downloads Cleanup | Não configurar |

Evite inicialmente excluir arquivos da pasta Downloads.

---

## Parte 2 — Detectar pouco espaço em disco

Criar uma Remediation separada.

Nome:

```text
REM - Windows - Low Disk Space
```

Script de detecção:

```powershell
$Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

$FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
$TotalGB = [math]::Round($Disk.Size / 1GB, 2)
$FreePercent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 2)

if ($FreeGB -lt 15 -or $FreePercent -lt 10) {
    Write-Output "ALERTA: C: possui $FreeGB GB livres ($FreePercent%)."
    exit 1
}

Write-Output "OK: C: possui $FreeGB GB livres ($FreePercent%)."
exit 0
```

Critério sugerido:

```text
Menos de 15 GB livres
OU
Menos de 10% livre
```

---

# C. Desabilitar Fast Startup

## Objetivo

Desabilitar o Fast Startup para reduzir problemas relacionados a shutdown incompleto, drivers, rede, VPN e atualizações.

A abordagem recomendada é usar Remediation.

## Script de detecção

```powershell
$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$Name = "HiberbootEnabled"

try {
    $Value = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name

    if ($Value -eq 0) {
        Write-Output "Fast Startup desabilitado."
        exit 0
    }
}
catch {}

Write-Output "Fast Startup habilitado ou não configurado."
exit 1
```

## Script de correção

```powershell
$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"

Set-ItemProperty `
    -Path $Path `
    -Name "HiberbootEnabled" `
    -Type DWord `
    -Value 0

Write-Output "Fast Startup desabilitado."
exit 0
```

Nome:

```text
REM - Windows - Disable Fast Startup
```

Configuração:

```text
Executar como SYSTEM
PowerShell 64-bit
```

## Validação

```powershell
Get-ItemProperty `
"HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" `
-Name HiberbootEnabled
```

Esperado:

```text
HiberbootEnabled : 0
```

## Desabilitar hibernação

Opcionalmente:

```cmd
powercfg /hibernate off
```

Sugestão:

```text
Separar a configuração de Fast Startup da configuração de hibernação.
```

---

# D. OneDrive KFM

## Objetivo

Redirecionar automaticamente as pastas conhecidas do Windows para o OneDrive corporativo.

Pastas:

```text
Desktop
Documents
Pictures
```

---

## 1. Localizar Tenant ID

No Microsoft Entra:

```text
Microsoft Entra admin center
→ Identity
→ Overview
→ Tenant ID
```

Copiar o GUID.

---

## 2. Criar política

Caminho:

```text
Devices
→ Configuration
→ Create
→ New policy
```

Selecionar:

```text
Platform: Windows 10 and later
Profile type: Settings catalog
```

Nome:

```text
CFG - OneDrive - KFM Corporate
```

Pesquisar por:

```text
OneDrive
```

Adicionar:

### Login silencioso

```text
Silently sign in users to the OneDrive sync app with their Windows credentials
```

Valor:

```text
Enabled
```

### Known Folder Move

```text
Silently move Windows known folders to OneDrive
```

Configurar:

```text
Enabled

Desktop: True
Documents: True
Pictures: True
Show notification: No
Tenant ID: SEU-TENANT-ID
```

### Impedir retorno para o PC

```text
Prevent users from redirecting their Windows known folders to their PC
```

Valor:

```text
Enabled
```

### Files On-Demand

```text
Use OneDrive Files On-Demand
```

Valor:

```text
Enabled
```

### Bloquear OneDrive pessoal

Opcional:

```text
Prevent users from syncing personal OneDrive accounts
```

Valor:

```text
Enabled
```

---

## Validação

Executar:

```cmd
dsregcmd /status
```

Validar:

```text
AzureAdJoined : YES
DomainJoined  : YES
AzureAdPrt    : YES
```

Depois verificar:

```text
C:\Users\USUARIO\OneDrive - Bioenergética Aroeira\
```

Confirmar que existem:

```text
Desktop
Documents
Pictures
```

---

# E. Wi-Fi corporativo

## Objetivo

Distribuir automaticamente o perfil Wi-Fi corporativo via Intune.

Exemplo:

```text
SSID: CORPORATIVA
Segurança: WPA3-Personal
Auto-connect: habilitado
Random MAC: desabilitado
```

A melhor abordagem para preservar um perfil WPA3 funcional é exportar o perfil de uma máquina previamente configurada.

---

## 1. Configurar uma máquina de referência

Conectar manualmente à rede:

```text
CORPORATIVA
```

Validar:

```cmd
netsh wlan show interfaces
```

Listar perfis:

```cmd
netsh wlan show profiles
```

---

## 2. Exportar perfil

Criar pasta:

```cmd
mkdir C:\WiFi
```

Exportar:

```cmd
netsh wlan export profile name="CORPORATIVA" key=clear folder=C:\WiFi
```

Será gerado algo semelhante a:

```text
C:\WiFi\Wi-Fi-CORPORATIVA.xml
```

Atenção:

```text
key=clear
```

faz a chave aparecer em texto legível no XML.

Proteja esse arquivo.

---

## 3. Validar XML

Verificar:

```xml
<name>CORPORATIVA</name>
```

e:

```xml
<connectionMode>auto</connectionMode>
```

Não alterar manualmente os parâmetros WPA3 se o Windows já tiver exportado o perfil corretamente.

---

## 4. Criar perfil no Intune

Caminho:

```text
Devices
→ Configuration
→ Create
→ New policy
```

Selecionar:

```text
Platform: Windows 10 and later
Profile type: Templates
Template: Custom
```

Nome:

```text
CFG - WiFi - CORPORATIVA
```

Criar OMA-URI:

```text
Name:
WiFi CORPORATIVA
```

```text
OMA-URI:
./Vendor/MSFT/WiFi/Profile/CORPORATIVA/WlanXml
```

```text
Data type:
String
```

Valor:

```text
Conteúdo completo do XML exportado
```

---

## 5. Atribuição

Preferencialmente atribuir para dispositivos.

Grupo sugerido:

```text
GRP-INTUNE-WIFI-CORPORATIVA
```

---

## 6. Validação

```cmd
netsh wlan show profiles
```

Esperado:

```text
CORPORATIVA
```

Depois:

```cmd
netsh wlan show profile name="CORPORATIVA"
```

Validar:

```text
Connection mode : Connect automatically
```

Reiniciar o computador e verificar se a rede conecta antes do login.

---

# F. Device Cleanup Rule

## Objetivo

Remover do portal registros de dispositivos inativos para manter o ambiente Intune organizado.

Atenção:

```text
Device Cleanup Rule não executa wipe.
Device Cleanup Rule não formata o computador.
Device Cleanup Rule não remove automaticamente o objeto do Entra ID.
```

---

## Criar regra

Caminho:

```text
Devices
→ Organize devices
→ Device cleanup rules
→ Create
```

Nome:

```text
CLEANUP - Windows - Inactive 90 Days
```

Selecionar:

```text
Platform: Windows
```

Definir:

```text
Remove devices that haven't checked in for this many days
```

Valor sugerido:

```text
90
```

---

## Sugestão de retenção

```text
30 dias  → agressivo
60 dias  → intermediário
90 dias  → recomendado para iniciar
180 dias → conservador
```

---

## Antes de aplicar

Sempre utilizar:

```text
Preview affected devices
```

Valide se há equipamentos legítimos sem comunicação recente.

---

# G. Shared PC

## Objetivo

Configurar computadores utilizados por múltiplos usuários ou turnos, controlando perfis, armazenamento e comportamento da máquina.

Ideal para:

```text
PCs compartilhados
Terminais
Estações de produção
Computadores de operação
Ambientes com vários turnos
```

---

## Criar política

Caminho:

```text
Devices
→ Manage devices
→ Configuration
→ Create
→ New policy
```

Selecionar:

```text
Platform: Windows 10 and later
Profile type: Templates
Template: Shared multi-user device
```

Nome:

```text
CFG - Windows - Shared PC
```

---

## Configuração sugerida

### Shared PC mode

```text
Enabled
```

### Account model

```text
Domain-joined only
```

Evitar Guest para ambiente corporativo.

---

## Exclusão de perfis

Evitar inicialmente:

```text
Delete immediately
```

Preferir:

```text
Delete at disk space threshold and inactive threshold
```

Valores sugeridos:

```text
Disk level deletion: 15%
Disk level caching: 30%
Inactive threshold: 7 dias
```

Com isso, o Windows começa a remover perfis mais antigos quando o espaço livre fica abaixo do limite configurado.

---

# Shared PC + OneDrive

## Atenção

O Shared PC tradicional pode interferir no OneDrive.

Em versões recentes do Windows 11 existe suporte para:

```text
EnableSharedPCModeWithOneDriveSync
```

Se o ambiente exige OneDrive em máquinas compartilhadas, teste essa configuração antes da implantação geral.

Arquitetura recomendada:

```text
Shared PC
        ↓
Domain users only
        ↓
OneDrive Sync permitido
        ↓
OneDrive KFM
        ↓
Files On-Demand
        ↓
Storage Sense
        ↓
Limpeza de perfis antigos
```

---

# Padronização de nomes

Recomenda-se utilizar prefixos por tipo de objeto.

## Remediations

```text
REM - Windows - Temporary Files Cleanup
REM - Windows - Low Disk Space
REM - Windows - Disable Fast Startup
```

## Configuration Profiles

```text
CFG - Windows - Storage Sense
CFG - OneDrive - KFM Corporate
CFG - WiFi - CORPORATIVA
CFG - Windows - Shared PC
```

## Cleanup

```text
CLEANUP - Windows - Inactive 90 Days
```

---

# Estratégia de implantação

Não atribuir diretamente a todos os computadores.

Utilizar:

```text
GRP-INTUNE-PILOTO-WINDOWS
```

E para máquinas compartilhadas:

```text
GRP-INTUNE-SHARED-PC
```

Fluxo:

```text
1. Criar configuração
2. Atribuir ao grupo piloto
3. Sincronizar Intune
4. Validar localmente
5. Validar Device Status
6. Aguardar período de testes
7. Expandir para novo grupo
8. Aplicar em produção
```

---

# Checklist final

## Limpeza de temporários

- [ ] Detection script criado
- [ ] Remediation script criado
- [ ] Execução como SYSTEM
- [ ] PowerShell 64-bit
- [ ] Grupo piloto atribuído
- [ ] Device Status validado

## Espaço em disco

- [ ] Storage Sense habilitado
- [ ] Temporários habilitados
- [ ] Recycle Bin configurado
- [ ] Downloads não removidos automaticamente
- [ ] Remediation de Low Disk Space criada

## Fast Startup

- [ ] Detector criado
- [ ] Correção criada
- [ ] HiberbootEnabled validado
- [ ] Teste após reinicialização

## OneDrive

- [ ] Tenant ID informado
- [ ] Silent Sign-In habilitado
- [ ] KFM habilitado
- [ ] Files On-Demand habilitado
- [ ] Desktop validado
- [ ] Documents validado
- [ ] Pictures validado

## Wi-Fi

- [ ] Perfil configurado manualmente
- [ ] XML exportado
- [ ] XML validado
- [ ] OMA-URI criado
- [ ] Perfil atribuído para dispositivos
- [ ] Auto-connect validado
- [ ] Testado antes do login

## Device Cleanup

- [ ] Preview executado
- [ ] Regra de 90 dias criada
- [ ] Dispositivos antigos revisados

## Shared PC

- [ ] Grupo separado criado
- [ ] Shared PC habilitado
- [ ] Domain users only configurado
- [ ] Profile cleanup definido
- [ ] OneDrive validado
- [ ] Storage Sense validado
- [ ] Testado em máquina piloto

---

# Resultado esperado

Após a implantação dessas políticas, o ambiente passa a ter:

```text
Limpeza automática
Controle de armazenamento
Menos problemas com Fast Startup
OneDrive padronizado
Wi-Fi provisionado automaticamente
Portal Intune mais organizado
PCs compartilhados com gerenciamento de perfil
Menos intervenção manual da equipe de TI
```

---

## Autor

Documentação técnica para implementação com Microsoft Intune.

