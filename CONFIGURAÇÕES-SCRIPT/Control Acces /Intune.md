# Microsoft Intune Auto Enrollment + MFA via Conditional Access

Este repositório documenta a configuração de **autoenrollment do Microsoft Intune em dispositivos Windows Hybrid Microsoft Entra Joined**, utilizando **GPO** e **Microsoft Entra Conditional Access**, evitando que uma exigência interativa de MFA bloqueie o processo de registro do dispositivo.

O objetivo é manter o ambiente protegido por MFA, mas permitir que o fluxo de **Microsoft Intune Enrollment** conclua o registro automaticamente.

---

## Cenário

Ambiente utilizado:

- Windows 10/11
- Active Directory Domain Services on-premises
- Microsoft Entra ID
- Microsoft Entra Connect
- Microsoft Intune
- Hybrid Microsoft Entra Join
- Autoenrollment via GPO
- MFA controlado por Conditional Access

Fluxo esperado:

```text
Active Directory
      |
      v
Microsoft Entra Connect
      |
      v
Hybrid Microsoft Entra Join
      |
      v
GPO de Autoenrollment
      |
      v
Microsoft Intune Enrollment
      |
      v
Dispositivo gerenciado pelo Intune
```

---

## Problema

Em determinados cenários, o autoenrollment pode falhar quando o usuário possui MFA legado configurado como:

```text
Per-user MFA = Enforced
```

O processo de enrollment executado em segundo plano pode não conseguir atender um desafio de MFA interativo.

Erros que podem aparecer incluem:

```text
AADSTS50076
interaction_required
0xCAA2000C
0x8018002A
```

---

# 1. Desabilitar o Per-user MFA legado

No Microsoft Entra Admin Center:

```text
Identity
> Users
> All users
> Per-user MFA
```

Localize o usuário utilizado no teste.

Altere:

```text
Enforced
```

para:

```text
Disabled
```

> A desativação do Per-user MFA não significa deixar o usuário sem MFA.  
> O objetivo é mover o controle de MFA para o Conditional Access.

---

# 2. Criar a política de Conditional Access

Acesse:

```text
Microsoft Entra Admin Center
> Protection
> Conditional Access
> Policies
> New policy
```

Nome sugerido:

```text
CA - MFA - Excluir Intune Enrollment
```

---

## Usuários

Durante os testes, aplique somente ao usuário utilizado para validar o enrollment.

Exemplo:

```text
Include
> Select users and groups
> usuario@empresa.com.br
```

Após a validação, a política pode ser expandida para grupos ou demais usuários conforme a estratégia da organização.

---

## Recursos de destino

Configure:

```text
Include
> All resources
```

Em **Exclude**, selecione:

```text
Microsoft Intune Enrollment
```

Resultado esperado:

```text
INCLUDE
All resources

EXCLUDE
Microsoft Intune Enrollment
```

---

# 3. Microsoft Intune Enrollment não aparece no Conditional Access

Em alguns tenants, o Service Principal do **Microsoft Intune Enrollment** pode não existir.

App ID:

```text
d4ebce55-015a-49b5-a083-c84d1797ae8c
```

Neste caso, ele pode ser criado usando Microsoft Graph PowerShell.

---

## Instalar os módulos necessários

Abra PowerShell.

```powershell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Applications -Scope CurrentUser -Force
```

Importe os módulos:

```powershell
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications
```

---

## Conectar ao Microsoft Graph

Se a autenticação via navegador apresentar erro, utilize Device Code:

```powershell
Connect-MgGraph -Scopes "Application.ReadWrite.All" -UseDeviceCode
```

Valide a sessão:

```powershell
Get-MgContext
```

---

## Verificar se o Service Principal existe

```powershell
Get-MgServicePrincipal `
  -Filter "appId eq 'd4ebce55-015a-49b5-a083-c84d1797ae8c'" |
Select-Object DisplayName,AppId,Id
```

Resultado esperado:

```text
DisplayName : Microsoft Intune Enrollment
AppId       : d4ebce55-015a-49b5-a083-c84d1797ae8c
Id          : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Criar o Service Principal

Execute somente se o comando anterior não retornar nenhum resultado.

```powershell
New-MgServicePrincipal `
  -AppId "d4ebce55-015a-49b5-a083-c84d1797ae8c"
```

Valide novamente:

```powershell
Get-MgServicePrincipal `
  -Filter "appId eq 'd4ebce55-015a-49b5-a083-c84d1797ae8c'" |
Format-List DisplayName,AppId,Id
```

Após alguns minutos, volte ao Conditional Access e procure novamente por:

```text
Microsoft Intune Enrollment
```

---

# 4. Configurar o controle de acesso

Na política de Conditional Access:

```text
Access controls
> Grant
```

Configure:

```text
Grant access
[x] Require multifactor authentication
```

Assim:

```text
Microsoft 365
Azure
Entra
Outros recursos
      |
      v
MFA exigido
```

Enquanto:

```text
Microsoft Intune Enrollment
      |
      v
Excluído dessa política
      |
      v
Enrollment pode ocorrer sem desafio interativo dessa CA
```

---

# 5. Colocar a política em Report-only

Durante a validação, utilize:

```text
Enable policy
> Report-only
```

Isso permite verificar o comportamento sem bloquear usuários.

---

# 6. Validar com What If

Acesse:

```text
Microsoft Entra Admin Center
> Protection
> Conditional Access
> What If
```

Configure:

```text
Identity:
Usuário do teste

Target resource:
Microsoft Intune Enrollment

Device platform:
Windows

Client app:
Mobile apps and desktop clients
```

Não é necessário preencher:

```text
Authentication flow
IP address
Country/Region
Device filter
```

Execute:

```text
What If
```

---

## Resultado esperado

A política de MFA criada deve aparecer em:

```text
Policies that will not apply
```

Motivo esperado:

```text
Target resource excluded
```

Ou equivalente.

Para um recurso não excluído, como Azure Management, a política deverá aparecer entre as políticas aplicadas.

---

# 7. Ativar a política

Após validar o comportamento no What If:

```text
Report-only
```

pode ser alterado para:

```text
On
```

---

# 8. Validar Hybrid Join na máquina

Na estação Windows:

```powershell
dsregcmd /status
```

Confirme:

```text
AzureAdJoined : YES
DomainJoined  : YES
AzureAdPrt    : YES
```

Para um dispositivo Hybrid Microsoft Entra Joined com usuário autenticado corretamente, esses valores são importantes para o fluxo de autoenrollment.

---

# 9. Atualizar as GPOs

```powershell
gpupdate /force
```

---

# 10. Validar a GPO de Autoenrollment

A política utilizada normalmente está em:

```text
Computer Configuration
> Policies
> Administrative Templates
> Windows Components
> MDM
> Enable automatic MDM enrollment using default Microsoft Entra credentials
```

A configuração esperada é:

```text
Enabled
```

Normalmente utilizando:

```text
User Credential
```

---

# 11. Validar a tarefa de enrollment

Abra:

```text
Task Scheduler
> Task Scheduler Library
> Microsoft
> Windows
> EnterpriseMgmt
```

Procure pela tarefa relacionada ao enrollment automático.

Também é possível localizar via PowerShell:

```powershell
Get-ScheduledTask |
Where-Object {
    $_.TaskName -like "*automatically enrolling in MDM*"
} |
Format-Table TaskPath,TaskName,State
```

Para iniciar:

```powershell
Get-ScheduledTask |
Where-Object {
    $_.TaskName -like "*automatically enrolling in MDM*"
} |
Start-ScheduledTask
```

---

# 12. Consultar os logs do Intune Enrollment

Abra:

```text
Event Viewer
> Applications and Services Logs
> Microsoft
> Windows
> DeviceManagement-Enterprise-Diagnostics-Provider
> Admin
```

Ou utilize PowerShell:

```powershell
Get-WinEvent `
  -LogName "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" `
  -MaxEvents 50 |
Where-Object {
    $_.Id -in 75,76
} |
Select-Object TimeCreated,Id,Message |
Format-List
```

---

## Event ID 75

```text
Auto MDM Enroll: Succeeded
```

Indica que o autoenrollment foi concluído.

---

## Event ID 76

```text
Auto MDM Enroll: Failed
```

Indica falha no enrollment.

Neste caso, analise o código de erro retornado.

---

# 13. Consultar Sign-in Logs

Se o enrollment ainda falhar:

```text
Microsoft Entra Admin Center
> Monitoring & health
> Sign-in logs
```

Filtre pelo usuário.

Verifique:

```text
Application
Resource
Conditional Access
Authentication requirement
Failure reason
```

Erros de MFA costumam mostrar informações como:

```text
AADSTS50076
interaction_required
MFA required
```

---

# 14. Validação final no Intune

Após o sucesso:

```text
Intune Admin Center
> Devices
> All devices
```

Procure pelo hostname da estação.

Valide:

```text
Managed by: Microsoft Intune
Compliance: conforme política aplicada
Microsoft Entra registered/joined: esperado para o cenário
Primary user: usuário correspondente
```

---

# Boas práticas

- Utilize Conditional Access em vez de Per-user MFA legado.
- Inicie políticas novas em `Report-only`.
- Valide alterações usando `What If`.
- Não aplique mudanças em todos os usuários antes do teste.
- Mantenha contas de emergência/break-glass excluídas das políticas críticas.
- Evite remover MFA de aplicações administrativas sem necessidade.
- Analise Sign-in Logs antes de alterar políticas adicionais.
- Documente qualquer exceção criada no Conditional Access.
- Restrinja exceções ao menor escopo necessário.

---

# Checklist

```text
[ ] Per-user MFA legado desabilitado
[ ] Conditional Access criado
[ ] Usuário de teste selecionado
[ ] All resources incluído
[ ] Microsoft Intune Enrollment excluído
[ ] Require MFA configurado
[ ] Política inicialmente em Report-only
[ ] What If validado
[ ] Política ativada
[ ] gpupdate /force executado
[ ] AzureAdJoined = YES
[ ] DomainJoined = YES
[ ] AzureAdPrt = YES
[ ] Tarefa EnterpriseMgmt executada
[ ] Event ID 75 confirmado
[ ] Dispositivo visível no Intune
```

---

# Referências Microsoft

- Microsoft Intune enrollment and MFA  
  https://learn.microsoft.com/intune/intune-service/enrollment/multi-factor-authentication

- Conditional Access com Microsoft Intune  
  https://learn.microsoft.com/mem/intune/protect/conditional-access-intune-common-ways-use

- Conditional Access What If  
  https://learn.microsoft.com/entra/identity/conditional-access/what-if-tool

- Troubleshooting Windows automatic enrollment  
  https://learn.microsoft.com/troubleshoot/mem/intune/device-enrollment/troubleshoot-windows-auto-enrollment

- Diagnose MDM enrollment  
  https://learn.microsoft.com/windows/client-management/mdm-diagnose-enrollment

- Microsoft Graph PowerShell  
  https://learn.microsoft.com/powershell/microsoftgraph/

---

## Observação

Este procedimento deve ser validado em ambiente de teste antes da aplicação em produção.

A exclusão de um recurso em Conditional Access deve sempre ser analisada de acordo com os requisitos de segurança da organização.

---

## Autor

Documentação criada para estudo e implementação de:

```text
Microsoft Entra ID
Microsoft Intune
Conditional Access
Hybrid Microsoft Entra Join
Windows Auto Enrollment
```
