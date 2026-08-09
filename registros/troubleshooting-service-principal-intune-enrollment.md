# Troubleshooting: Service Principal ausente no tenant (Intune Enrollment)

**Domínio:** labtask.online
**Área:** Entra ID
**Cenário:** Política de Conditional Access exigindo MFA bloqueando o enrollment MDM
**App afetado:** Microsoft Intune Enrollment (AppId `d4ebce55-015a-49b5-a083-c84d1797ae8c`)
**Sintoma:** App não aparece no picker de exclusão da Conditional Access, mesmo buscando por nome ou AppId

---

## Contexto

Ao excluir o app Microsoft Intune Enrollment de uma política de Conditional Access que exige MFA para todos os cloud apps, ele não aparece na busca do picker — mesmo pesquisando pelo nome completo ou AppId. Isso ocorre porque o picker do Entra ID só lista apps que já possuem um objeto Service Principal (Enterprise Application) provisionado no tenant. Alguns apps first-party da Microsoft só são provisionados quando algum fluxo os aciona pela primeira vez — o que pode nunca ter acontecido no tenant.

## Passo a passo realizado

### Pré-requisito: módulo Microsoft Graph PowerShell

```powershell
# 1. Instalar para todos os usuários (evita problema de PSModulePath)
Install-Module Microsoft.Graph -Scope AllUsers -Force -AllowClobber
# Se pedir confirmação de repositório: Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# 2. Confirmar que o módulo foi reconhecido
Get-Module -ListAvailable Microsoft.Graph.Applications, Microsoft.Graph.Identity.SignIns | Select Name, Version, ModuleBase

# 3. Importar os módulos necessários
Import-Module Microsoft.Graph.Applications
Import-Module Microsoft.Graph.Identity.SignIns

# 4. Conectar (conta com Administrador Global ou de Aplicativos)
Connect-MgGraph -Scopes "Application.ReadWrite.All"
```

### Diagnóstico e correção

```powershell
# 5. Verificar se o Service Principal já existe
Get-MgServicePrincipal -Filter "AppId eq 'd4ebce55-015a-49b5-a083-c84d1797ae8c'"
# Vazio -> nunca foi provisionado, seguir para o passo 6
# Retornou objeto -> já existe, pular para o passo 7

# 6. Criar o Service Principal faltante
New-MgServicePrincipal -AppId "d4ebce55-015a-49b5-a083-c84d1797ae8c"
# Resultado esperado: objeto com DisplayName 'Microsoft Intune Enrollment' e um Object ID
```

```powershell
# 7. Adicionar a exclusão na política via Graph (alternativa ao picker)
$policy = Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq 'CA01-MFA FOR ALL USERS'"
Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id `
  -Conditions @{
    Applications = @{
      ExcludeApplications = @(
        "0000000a-0000-0000-c000-000000000000",
        "d4ebce55-015a-49b5-a083-c84d1797ae8c"
      )
    }
  }
```

### 8. Confirmar no portal

Entra ID → Conditional Access → CA01-MFA FOR ALL USERS → Exclude → Select resources, buscar "enrollment" novamente. O app deve aparecer, já selecionado se aplicado via Graph.

## Alternativa sem PowerShell

Forçar o provisionamento via link de admin consent (Administrador Global):
```
https://login.microsoftonline.com/labtask.online/adminconsent?client_id=d4ebce55-015a-49b5-a083-c84d1797ae8c
```

## Problemas encontrados e soluções

- **Problema:** `Import-Module` diz que o módulo não foi encontrado mesmo após instalação bem-sucedida.
  **Causa:** PSModulePath da sessão não inclui a pasta do módulo instalado (comum com GPO customizada ou Azure AD Connect instalado, que sobrescrevem o PSModulePath padrão).
  **Diagnóstico:** `$env:PSModulePath -split ';'`
  **Solução definitiva:** reinstalar com `-Scope AllUsers` (grava em `C:\Program Files\WindowsPowerShell\Modules`).
  **Solução temporária:** `$env:PSModulePath += ";<caminho>\Modules"`

> Antes de reinstalar, confirme com `Test-Path`/`Get-ChildItem` se os arquivos já existem em disco — o problema costuma ser de reconhecimento de path, não de instalação em si.

## Checklist rápido

- [ ] Módulo Microsoft.Graph instalado com `-Scope AllUsers`
- [ ] `Get-Module` confirma Applications e Identity.SignIns disponíveis
- [ ] `Connect-MgGraph` realizado com conta de Administrador Global/Aplicativos
- [ ] `Get-MgServicePrincipal` verificado antes de tentar criar
- [ ] `New-MgServicePrincipal` executado com sucesso (ou app já existia)
- [ ] Exclusão aplicada na política CA01-MFA FOR ALL USERS
- [ ] Política salva e testada novamente no fluxo de enrollment

## Referências

- AppIds usados: Microsoft Intune = `0000000a-0000-0000-c000-000000000000` · Microsoft Intune Enrollment = `d4ebce55-015a-49b5-a083-c84d1797ae8c`
- Registro relacionado: [mdm-enrollment-hybrid.md](./mdm-enrollment-hybrid.md)
