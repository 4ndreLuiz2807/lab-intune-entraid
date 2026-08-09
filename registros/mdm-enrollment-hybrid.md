# Enrollment MDM (Intune) em Ambientes Hybrid Azure AD Joined

**Domínio:** labtask.online (interno e público — mesmo nome)
**Área:** Entra ID / Intune
**Cenário:** Estações Hybrid Azure AD Joined, gerenciadas por GPO
**Objetivo:** Auto-enrollment funcional no Intune, sem bloqueios de DNS, GPO ou Conditional Access

---

## Contexto

Em um ambiente Hybrid, as estações são primeiro ingressadas no Active Directory on-premises e, em seguida, sincronizadas como dispositivos no Microsoft Entra ID via Azure AD Connect. Para o auto-enrollment no Intune funcionar, três camadas precisam estar corretas: (1) o dispositivo registrado corretamente no Entra ID, (2) a resolução de DNS interna apontando para os serviços corretos, e (3) GPO/Conditional Access não bloqueando o fluxo de autenticação.

## Passo a passo realizado

### 1. DNS dividido (split-brain DNS)

Como `labtask.online` é o mesmo nome usado interna e externamente, é preciso duplicar os registros CNAME também na zona DNS interna do AD — senão a resolução falha silenciosamente para usuários internos, mesmo com o DNS público correto.

No Domain Controller (DNS Manager → Forward Lookup Zones → labtask.online → New Alias):

| Tipo  | Nome (Host) | Valor esperado |
|-------|-------------|-----------------|
| CNAME | enterpriseregistration | enterpriseregistration.windows.net |
| CNAME | enterpriseenrollment | enterpriseenrollment-s.manage.microsoft.com |

Validação em uma estação:
```powershell
ipconfig /flushdns
nslookup enterpriseregistration.labtask.online
nslookup enterpriseenrollment.labtask.online
```
O retorno deve apontar para os FQDNs da Microsoft, não "Non-existent domain".

### 2. GPO para auto-enrollment

Duas políticas trabalham juntas:

- **Register domain joined computers as devices** — Computer Configuration → Administrative Templates → Windows Components → Device Registration → Enabled.
- **Enable automatic MDM enrollment using default Azure AD credentials** — Computer Configuration → Administrative Templates → Windows Components → MDM → Enabled, com "Select Credential Type to Use" = User Credential (fora de cenário de co-management com SCCM/MECM ou AVD).

> O rótulo "Device Credential (0x0)" no Event Viewer pode aparecer mesmo com a GPO em User Credential — é apenas um rótulo padrão do cliente de enrollment, não indica erro por si só.

### 3. Conditional Access — exceções necessárias

Políticas de MFA para "All cloud apps" bloqueiam silenciosamente a renovação de token durante o enrollment (erros típicos: `0xCAA90056` / `0x8018002a`). É necessário excluir:

| App | AppId |
|-----|-------|
| Microsoft Intune | 0000000a-0000-0000-c000-000000000000 |
| Microsoft Intune Enrollment | d4ebce55-015a-49b5-a083-c84d1797ae8c |

Caminho: Entra ID → Conditional Access → [política de MFA] → Exclude → Select resources.

Se o app não aparecer no picker, o Service Principal ainda não foi provisionado no tenant — ver registro [troubleshooting-service-principal-intune-enrollment.md](./troubleshooting-service-principal-intune-enrollment.md).

### 4. Roteiro de verificação na estação

```powershell
# Confirma Hybrid Azure AD Join e PRT válido
dsregcmd /status
# Verificar: AzureAdJoined : YES / DomainJoined : YES / AzureAdPrt : YES

# Se AzureAdJoined = NO, forçar sync no servidor do Azure AD Connect:
Start-ADSyncSyncCycle -PolicyType Delta

# Confirmar que as GPOs chegaram na estação
gpresult /r
```

Eventos de enrollment ficam em: Visualizador de Eventos → Aplicativos e Serviços → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostics-Provider → Admin. Evento 76 = falha; Evento 75/72 = sucesso.

## Checklist consolidado

- [ ] Registros CNAME existem no DNS público
- [ ] Os mesmos CNAME existem na zona DNS interna do AD (split-brain)
- [ ] `nslookup` na estação resolve corretamente os dois nomes
- [ ] GPO "Register domain joined computers as devices" Enabled
- [ ] GPO "Enable automatic MDM enrollment..." Enabled com User Credential
- [ ] `dsregcmd /status` confirma AzureAdJoined/DomainJoined/AzureAdPrt = YES
- [ ] `gpresult /r` confirma as duas GPOs aplicadas
- [ ] Apps Intune/Intune Enrollment excluídos das políticas de MFA
- [ ] MDM user scope inclui o grupo correto
- [ ] Tarefa de enrollment (Agendador → EnterpriseMgmt) executada manualmente
- [ ] Evento 75/72 (sucesso) presente no log

## Referências

- Registro relacionado: [troubleshooting-service-principal-intune-enrollment.md](./troubleshooting-service-principal-intune-enrollment.md)
