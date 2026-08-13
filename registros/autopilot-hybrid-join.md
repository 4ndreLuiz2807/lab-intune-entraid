# Passo a Passo Intune — Autopilot Devices (Hybrid Join)

**Área:** Intune / Entra ID
**Objetivo:** Configurar dispositivos Autopilot com domain join híbrido (RH como setor de referência)

---

## Padrões de nomes de grupos utilizados

| Finalidade | Padrão |
|---|---|
| Domain Join | `GRP – Domain Join – Hybrid – (RH)` |
| Grupo de dispositivos dinâmico | `GRP – Autopilot Devices – (RH)` |

## Passo a passo realizado

### 1. Criar OU no controlador para os devices pós-writeback

Criar a Unidade Organizacional onde os dispositivos ficarão após o writeback do Entra ID Connect.

![Criação da OU no AD](../evidencias/autopilot/image2.png)

**1.2 — Delegar controle** sobre a OU criada:

![Delegação de controle](../evidencias/autopilot/image3.png)

**1.3 — Adicionar o controlador de domínio** para ter controle sobre a OU:

![Adicionar controlador de domínio](../evidencias/autopilot/image4.png)
![Adicionar controlador de domínio - continuação](../evidencias/autopilot/image5.png)

**1.4 — Criar tarefas customizadas de delegação:**

![Tarefas customizadas de delegação](../evidencias/autopilot/image6.png)

**1.5 — Delegar permissões de criação/exclusão de computadores:**

![Delegar permissões de criação e exclusão](../evidencias/autopilot/image7.png)

**1.6 — Selecionar todas as permissões:**

![Selecionar todas as permissões](../evidencias/autopilot/image8.png)

**1.7 — Primeiro passo concluído:**

![Primeiro passo concluído](../evidencias/autopilot/image9.png)

### 2. Configurações no portal do Intune

Link: https://intune.microsoft.com/#home

Criar um grupo de dispositivo dinâmico para devices Autopilot: **Groups → New Group**

- Grupo: `GRP – Autopilot – Hybrid – RH`
- ⚠️ Grupos de usuários **não** fazem autopilot devices — apenas dispositivos.

![Criação do grupo dinâmico](../evidencias/autopilot/image10.png)

**2.1 — Regra dinâmica (Group Tag):**

```
(device.devicePhysicalIds -any (_ -eq "[OrderID]:RH"))
```

O Group Tag usado neste exemplo é RH, mas pode ser adaptado para outros setores — basta trocar o sufixo:
```
(device.devicePhysicalIds -any (_ -eq "[OrderID]:TI"))
(device.devicePhysicalIds -any (_ -eq "[OrderID]:ADM"))
```

![Regra dinâmica Group Tag](../evidencias/autopilot/image11.png)

### 3. Configurar Domain Join (ingresso no domínio local durante o OOBE)

![Configuração de domain join](../evidencias/autopilot/image12.png)
![Configuração de domain join - continuação](../evidencias/autopilot/image13.png)

**3.1 — Parâmetros de configuração:**
- 3.1.1 Configurar o prefixo dos dispositivos
- 3.1.2 Configurar domínio
- 3.1.3 Configurar a Unidade Organizacional onde os dispositivos ficarão

![Parâmetros de configuração do domain join](../evidencias/autopilot/image14.png)

### 4. Criar o perfil de implantação Autopilot (AP)

![Perfil de implantação Autopilot](../evidencias/autopilot/image15.png)

### 5. Comando Autopilot V1 — rodar no dispositivo

Gera o arquivo com o HWID do dispositivo, necessário para registrar no Autopilot:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

New-Item -ItemType Directory -Path "C:\HWID" -Force
Set-Location -Path "C:\HWID"
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
Install-Script -Name Get-WindowsAutopilotInfo -Force

# Obtém o hostname da máquina
$Hostname = $env:COMPUTERNAME

# Define o nome do arquivo CSV com o hostname
$OutputFile = "C:\HWID\$Hostname-AutopilotHWID.csv"

Get-WindowsAutopilotInfo -OutputFile $OutputFile
```

### 6. Desabilitar ESP via OMA-URI

```
OMA URI: ./Vendor/MSFT/DMClient/Provider/MS DM Server/FirstSyncStatus/SkipUserStatusPage
```

![Configuração OMA-URI para desabilitar ESP](../evidencias/autopilot/image16.png)

## Aprendizados / próximos passos

- O Group Tag é a forma de segmentar dispositivos Autopilot por setor sem precisar de múltiplos perfis de implantação separados.
- A ordem importa: a OU e a delegação de permissões no AD precisam existir **antes** de configurar o domain join no Intune, senão o writeback falha silenciosamente.

- ---

## Referência técnica complementar

> Conteúdo consolidado a partir de documentação de implementação do Windows
> Autopilot v1 em ambiente híbrido (17/04/2026), revisado e corrigido contra
> a documentação oficial da Microsoft antes de entrar aqui.

### Requisitos resumidos

**Hardware:** TPM 2.0 (ou 1.2 com firmware atualizado), UEFI (sem BIOS legado),
Secure Boot habilitado, processador com suporte a virtualização.

```powershell
# Verificar TPM
Get-WmiObject -Class Win32_Tpm -Namespace root\cimv2\security\microsofttpm
```

**Licenciamento:** Azure AD Premium P1 (ou M365) + licença de Intune, Intune
Connector for Active Directory instalado, Azure AD Connect sincronizando
dispositivos.

**Proxy:** sem inspeção SSL/TLS no tráfego Microsoft; portas 80/443 liberadas;
autenticação de proxy configurada via GPO ou WinHTTP antes do deployment.

### Intune Connector for Active Directory

Instalado em servidor membro do domínio, autenticado com conta de admin
global ou de Intune.

```powershell
# Verificar se o conector está registrado
Get-ADComputer -Filter "Name -like '*IntuneConnector*'"

# Verificar logs
Get-EventLog -LogName 'Intune Connector' -Newest 20
```

### Azure AD Connect — sincronização

```powershell
# Forçar sincronização imediata
Start-ADSyncSyncCycle -PolicyType Delta

# Verificar status
Get-ADSyncConnectorRunStatus
```

> Aguarde até 24h para que todos os dispositivos sejam sincronizados para o
> Azure AD após a configuração inicial.

### Grupos de dispositivos (regra dinâmica)

```powershell
# Exemplo de regra dinâmica em Azure AD
(device.deviceOSType -eq "Windows") -and (device.deviceOwnership -eq "Company")
```

```powershell
New-MgGroup -DisplayName "Autopilot Devices" `
  -MailEnabled:$false `
  -SecurityEnabled:$true `
  -GroupTypes @("DynamicMembership") `
  -MembershipRuleProcessingState "On"
```

### Template de nome de dispositivo — sintaxe correta

⚠️ **Correção:** a sintaxe usa **porcentagem**, não chaves duplas.

| Errado | Correto |
|---|---|
| `AP-{{RAND:4}}` | `AP-%RAND:4%` |
| — | `MyCompany-%SERIAL%` |

Regras: nome com até 15 caracteres, apenas letras/números/hífen, não pode
ser só números.

### Hardware Hash — como obter (só existe 1 método válido)

⚠️ **Correção:** a única forma confiável de gerar o hash é via o script
oficial da Microsoft. Não existe um "método alternativo" combinando UUID +
número de série via WMI — isso não produz um hash válido para import.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile C:\autopilot-hash.csv
```

Alternativas legítimas: exportação via Configuration Manager/MECM ("Export
for Autopilot"), ou coleta durante o próprio OOBE (Shift+F10 → PowerShell).

### Formato do CSV de import — colunas corretas

⚠️ **Correção:** as colunas exigidas pelo Intune são:

```
Device Serial Number,Windows Product ID,Hardware Hash,Group Tag,Assigned User
```

Apenas `Device Serial Number` e `Hardware Hash` são obrigatórias; `Windows
Product ID`, `Group Tag` e `Assigned User` são opcionais. Cabeçalhos são
case-sensitive e o arquivo não deve ser editado/salvo pelo Excel (corrompe o
CSV) — use editor de texto puro.

### Importação no Intune

1. `endpoint.microsoft.com` → Devices → Windows → Windows enrollment → Devices
2. Import devices → selecionar o CSV
3. Aguardar 5–15 min, revisar resumo, monitorar na aba Summary

### Enrollment Status Page (ESP)

| Status | Significado |
|---|---|
| Running | Deployment em andamento |
| Success | Concluído com sucesso |
| Failed | Erro durante deployment |
| Blocked | Compliance rules bloqueando acesso |

```powershell
Get-Content "C:\Windows\Logs\CloudDM\DmEnrollmentManager.log" -Tail 50
```

### Verificação de status do dispositivo

```powershell
dsregcmd /status
# Device State: Joined -> registrado com sucesso
# Workplace Joined: YES -> registrado com Azure AD
```

```powershell
Connect-MgGraph -Scopes "Device.Read.All"
Get-MgDevice -All | Select-Object DisplayName, IsCompliant, RegisteredOwners
```

### Troubleshooting comum

| Problema | Causa provável | Solução |
|---|---|---|
| Dispositivo não reconhecido no Autopilot | Hash não importado ou inválido | Verificar CSV, re-importar, aguardar sincronização |
| Erro de domain join no OOBE | Conectividade AD, permissões ou OU inválida | Verificar OU, firewall, DNS, credenciais do connector |
| ESP travado / timeout | App com falha, conectividade, script travado | Revisar logs, aumentar timeout, remover app problemático |
| Dispositivo não sincroniza com Azure AD | Azure AD Connect não sincronizado | Forçar sincronização, verificar conectividade AAD Connect |
| Erro de conectividade ao Intune | Proxy, firewall, DNS ou credenciais | Testar conectividade, configurar proxy, verificar DNS |

### Limitações importantes

- **Autopilot Reset não funciona em Hybrid Azure AD Join** (confirmado —
  continua valendo). Para reset em ambiente híbrido, use Wipe completo via
  Intune, ou reimaging.
- **GPO sobre VPN durante o OOBE** é instável (latência/DNS/timeout) — evite
  VPN no OOBE; prefira Configuration Profiles do Intune, ou conecte a VPN só
  depois do OOBE concluído.
- **Autopilot exige internet durante o OOBE** — validação de hash,
  autenticação Azure AD, download de políticas e sync com AD não funcionam
  offline. Mínimo recomendado: 10+ Mbps, latência <100ms para endpoints
  Microsoft.

### Estrutura de OUs recomendada

```
DC=empresa,DC=com
├── OU=Computadores
│   ├── OU=Autopilot
│   │   ├── OU=Laptops
│   │   ├── OU=Desktops
│   │   └── OU=Tablets
│   ├── OU=Legacy
│   └── OU=Servidores
└── OU=Usuários
```

### Referências oficiais

- [Windows Autopilot overview](https://learn.microsoft.com/autopilot)
- [Entra hybrid join + Autopilot](https://learn.microsoft.com/en-us/autopilot/windows-autopilot-hybrid)
- [Configure Autopilot profiles (device name template)](https://learn.microsoft.com/en-us/autopilot/profiles)
