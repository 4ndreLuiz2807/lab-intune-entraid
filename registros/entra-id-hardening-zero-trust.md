# Hardening do Tenant Entra ID — CA MFA, Permissões, Grupos e Zero Trust

**Área:** Entra ID
**Objetivo:** Configuração inicial de segurança do tenant: Conditional Access MFA para todos, revisão de permissões administrativas, estrutura de grupos de segurança, mensagem de "manter conectado", e alinhamento geral com princípios de Zero Trust.

---

## Contexto

Este registro cobre as configurações de segurança que devem existir em **qualquer** tenant Entra ID desde o início — não são específicas de um cenário Hybrid ou Autopilot, são a base de identidade sobre a qual tudo o resto (Intune incluso) se apoia. A ordem de aplicação importa: política de MFA sem conta de emergência excluída pode travar o próprio administrador para fora do tenant.

## 1. Conditional Access — MFA para todos os usuários

### 1.1 Antes de criar: conta de emergência (break-glass)

**Nunca crie a política de MFA para "All users" sem antes ter pelo menos uma conta de emergência excluída.** Se a política travar por qualquer motivo (erro de configuração, indisponibilidade do provedor de MFA), essa conta é o único jeito de entrar de volta.

- Crie um usuário dedicado (ex.: `break-glass-admin@labtask.online`), com senha longa e complexa, armazenada em cofre físico ou gerenciador de senhas corporativo — **não em texto puro em lugar nenhum**.
- Atribua Global Administrator a essa conta.
- Exclua essa conta de **toda** política de Conditional Access que possa bloqueá-la.
- Monitore o login dela com um alerta separado — ela só deve ser usada em emergência.

### 1.2 Criar a política — passo a passo

Entra ID → **Protection → Conditional Access → Policies → New policy**

| Campo | Valor |
|---|---|
| Name | `CA01-MFA FOR ALL USERS` |
| Users → Include | All users |
| Users → Exclude | Conta de emergência (break-glass) + Service Principals do Intune (ver seção abaixo) |
| Target resources → Include | All cloud apps |
| Conditions | (opcional) Exclua a rede corporativa confiável, se fizer sentido no seu modelo de risco — em Zero Trust puro, geralmente não se exclui rede nenhuma |
| Grant → Grant access | Require multifactor authentication |
| Session (opcional) | Sign-in frequency + Persistent browser session, conforme seção 4 |
| Enable policy | **Report-only** primeiro, depois `On` |

### 1.3 Testar em Report-only antes de ativar

Rode a política em **Report-only** por alguns dias e revise em **Conditional Access → Insights and reporting** quem seria bloqueado. Só mude para `On` depois de confirmar que não há usuário legítimo sendo pego de surpresa.

### 1.4 Exceções técnicas necessárias

Apps first-party da Microsoft usados no fluxo de enrollment do Intune precisam ser excluídos, senão o próprio enrollment de dispositivo quebra:

| App | AppId |
|---|---|
| Microsoft Intune | `0000000a-0000-0000-c000-000000000000` |
| Microsoft Intune Enrollment | `d4ebce55-015a-49b5-a083-c84d1797ae8c` |

Se esses apps não aparecerem no picker de exclusão, veja [troubleshooting-service-principal-intune-enrollment.md](./troubleshooting-service-principal-intune-enrollment.md) — provavelmente o Service Principal ainda não foi provisionado no tenant.

## 2. Validar permissões de usuários (least privilege)

### 2.1 Levantamento de administradores

Entra ID → **Roles and administrators**, revisar principalmente:

- **Global Administrator** — deve ter o menor número possível de contas permanentes (idealmente 2 a 4, incluindo a break-glass). Cada Global Admin extra é superfície de ataque.
- **Intune Administrator**, **User Administrator**, **Groups Administrator** — atribuir por função real, nunca "por garantia".

```powershell
# Via Microsoft Graph PowerShell — listar quem tem Global Administrator
Connect-MgGraph -Scopes "RoleManagement.Read.Directory"
$roleId = (Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'").Id
Get-MgDirectoryRoleMember -DirectoryRoleId $roleId
```

### 2.2 Privileged Identity Management (PIM)

Se a licença permitir (Entra ID P2), mova administradores de atribuição **permanente** para **elegível** via PIM:

- Admin ativa a role só quando precisa, por tempo limitado (ex.: 4 a 8 horas).
- Reduz a janela de exposição de uma conta administrativa comprometida.
- Configurar aprovação e/ou MFA obrigatória na ativação.

### 2.3 Access Reviews

Configurar revisões periódicas (trimestral, por exemplo) de quem tem acesso a quê — especialmente para roles administrativas e grupos com acesso a dados sensíveis. Entra ID → **Identity Governance → Access reviews**.

## 3. Criação de grupos de segurança

Segue a mesma convenção de nomes do restante deste laboratório (ver [guia de boas práticas](../docs/guias/boas-praticas-gerenciamento-dispositivos.md#21-convenção-de-nomes)):

```
GRP – <Finalidade> – <Tipo> – <Setor/Escopo>
```

### 3.1 Tipo de grupo correto

| Cenário | Tipo recomendado |
|---|---|
| Licenciamento (group-based licensing) | Security group, dinâmico por atributo |
| Acesso a recursos (SharePoint, apps) | Security group, pode ser estático |
| Distribuição de e-mail apenas | Distribution list ou Microsoft 365 Group (não Security) |
| Autopilot / gerenciamento de dispositivo | Security group de **dispositivos**, dinâmico por Group Tag |

### 3.2 Cuidados na criação

- **Sem aninhamento para licenciamento:** group-based licensing não funciona com grupos aninhados em todos os cenários — teste antes de depender disso em produção.
- **Nomear a regra dinâmica de forma auditável:** documentar a query usada (ex.: `(user.department -eq "TI")`) em algum lugar acessível ao time, não só na tela do Entra ID.
- **Dono do grupo (Owner):** sempre atribuir um dono humano, não deixar só o administrador que criou — facilita governança e Access Reviews.

## 4. Mensagem para manter conectado (Keep Me Signed In / KMSI)

Controla se o usuário vê a pergunta "Continuar conectado?" após o login, reduzindo prompts repetidos de autenticação em dispositivos confiáveis.

Entra ID → **Company branding → Sign-in and registration form customization** (ou **Entra ID → User settings → Manage** dependendo da versão do portal):

- **Show option to remain signed in:** habilite para reduzir a fricção do usuário — combinado com Conditional Access, o dispositivo compliant já reduz a necessidade de reautenticação frequente.
- Em ambientes com terminais compartilhados (ex.: recepção, chão de fábrica), **desabilite** essa opção especificamente para esses grupos via Conditional Access com sessão configurada para não persistir.

### Sessão — controle fino via Conditional Access

Na mesma política de MFA (ou em uma dedicada), em **Session**:

- **Sign-in frequency:** define de quanto em quanto tempo o usuário precisa reautenticar (ex.: a cada 7 dias, ou "Every time" para recursos muito sensíveis).
- **Persistent browser session:** equivalente ao KMSI, mas controlado centralmente por política em vez de depender da escolha do usuário no prompt.

## 5. Zero Trust — princípios aplicados neste tenant

Zero Trust não é um produto, é um conjunto de princípios: **verificar explicitamente, usar o menor privilégio possível, assumir que a violação já aconteceu.** Como isso se traduz nas configurações acima:

| Princípio | Configuração equivalente neste tenant |
|---|---|
| Verificar explicitamente | Conditional Access exigindo MFA para todos + Compliance policy (dispositivo precisa estar `Compliant` no Intune para acessar recursos) |
| Menor privilégio | PIM para roles administrativas, Access Reviews periódicas, grupos de segurança bem escopados |
| Assumir violação | Sign-in frequency curta em recursos sensíveis, Identity Protection habilitado (detecção de login de risco), segregação de conta break-glass monitorada |

### Próximo passo natural: Identity Protection

Entra ID → **Protection → Identity Protection** — habilitar políticas de **User risk** e **Sign-in risk**, integradas à mesma Conditional Access, para bloquear ou exigir MFA adicional em logins classificados como suspeitos (viagem impossível, IP anônimo, credencial vazada conhecida). Fica como próximo registro a documentar.

## Checklist

- [ ] Conta de emergência (break-glass) criada, senha em cofre, excluída de toda política de CA
- [ ] `CA01-MFA FOR ALL USERS` testada em Report-only antes de ativar
- [ ] Apps de Intune Enrollment excluídos da política de MFA
- [ ] Levantamento de quem tem Global Administrator revisado (o menor número possível)
- [ ] PIM avaliado/configurado para roles administrativas (se licença permitir)
- [ ] Access Review agendada para roles privilegiadas
- [ ] Grupos de segurança seguindo a convenção de nomes do laboratório
- [ ] Dono (owner) atribuído a cada grupo criado
- [ ] KMSI (Keep Me Signed In) configurado conforme perfil de risco do ambiente
- [ ] Sign-in frequency definida para recursos sensíveis

## Referências

- [Boas práticas: do zero até o dispositivo "Managed"](../docs/guias/boas-praticas-gerenciamento-dispositivos.md)
- [Troubleshooting: Service Principal ausente](./troubleshooting-service-principal-intune-enrollment.md)
