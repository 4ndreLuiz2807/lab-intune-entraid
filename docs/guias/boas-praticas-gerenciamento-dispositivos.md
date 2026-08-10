# Boas práticas: do zero até o dispositivo "Managed" no Intune

**Área:** Intune / Entra ID
**Objetivo:** Guia de referência com a ordem correta e boas práticas de licenciamento, grupos e configurações para levar um dispositivo até o estado `Managed` no Intune, evitando os erros mais comuns de quem está começando.

---

## Por que a ordem importa

A causa mais comum de "enrollment não funciona" não é um bug — é configuração feita fora de ordem. Licença sem grupo, grupo sem escopo de MDM, compliance policy antes de ter Conditional Access, Autopilot profile atribuído a um grupo de usuário em vez de dispositivo. Este guia estabelece a sequência recomendada.

## 1. Licenciamento — o pré-requisito que trava tudo se estiver errado

| Necessário para | Licença mínima |
|---|---|
| Gerenciamento MDM básico (Intune) | Microsoft Intune Plan 1 (standalone ou incluso em M365 E3/E5, Business Premium) |
| Conditional Access | Microsoft Entra ID P1 (incluso em M365 E3/E5, Business Premium) |
| Windows Autopilot | Já incluso com licença de Intune, sem custo adicional |
| Compliance avançado (baseline de segurança, etc.) | Intune Plan 1 cobre a maior parte; alguns recursos avançados pedem Plan 2 |

**Boa prática:** atribua a licença **antes** de tentar qualquer enrollment. Sem licença de Intune no usuário, o dispositivo pode até aparecer registrado no Entra ID, mas nunca vira `Managed` — fica preso em "Registered" sem política nenhuma sendo aplicada.

Atribuição de licença: prefira **grupos de licenciamento dinâmicos** (baseados em atributo, ex: departamento) em vez de atribuir usuário por usuário — evita esquecimento quando um novo colaborador entra.

## 2. Estrutura de grupos — a base de tudo

Erro mais comum de quem está começando: usar um único grupo "todo mundo" para tudo. Isso funciona no laboratório e quebra em produção. Estrutura recomendada:

### 2.1 Convenção de nomes

Adote um padrão único e documentado desde o primeiro grupo. Exemplo usado neste laboratório:

```
GRP – <Finalidade> – <Tipo> – <Setor/Escopo>
```

Exemplos reais:
- `GRP – Licenciamento – Intune – TI`
- `GRP – Domain Join – Hybrid – (RH)`
- `GRP – Autopilot Devices – (RH)`
- `GRP – Compliance – Baseline – Todos`

### 2.2 Tipos de grupo por finalidade

| Finalidade | Tipo de grupo | Dinâmico ou estático? |
|---|---|---|
| Licenciamento | Usuários | Dinâmico (por atributo: departamento, cargo) |
| Autopilot / domain join | Dispositivos | Dinâmico (por Group Tag) |
| Compliance policies | Dispositivos ou Usuários | Dinâmico quando possível |
| Configuration profiles | Dispositivos | Misto (dinâmico para regra ampla + estático para exceções) |
| Apps obrigatórios | Usuários ou Dispositivos | Depende do app (per-user vs per-device) |
| Conditional Access | Usuários | Geralmente estático ou "All users" com exclusões nomeadas |

**Regra de ouro:** grupos de usuário nunca recebem perfil de Autopilot — Autopilot é sempre dispositivo. Esse é o erro nº1 de quem está aprendendo.

### 2.3 Regra dinâmica por Group Tag (Autopilot)

```
(device.devicePhysicalIds -any (_ -eq "[OrderID]:TI"))
```

Troque o sufixo (`TI`, `RH`, `ADM`...) por setor, permitindo múltiplos perfis de implantação sem duplicar configuração manual por dispositivo.

## 3. Ordem recomendada de configuração

```
1. Licenciamento atribuído (grupo dinâmico de usuários)
2. Grupos de dispositivos/usuários criados e nomeados
3. MDM Authority confirmada (Intune, não co-management ainda nesse ponto)
4. Enrollment Restrictions revisadas (limite de dispositivos por usuário, plataformas permitidas)
5. Enrollment Status Page (ESP) configurada
6. Windows Autopilot profile (se aplicável) atribuído ao grupo de DISPOSITIVOS
7. Configuration Profiles (baseline: Wi-Fi, VPN, certificados, restrições)
8. Compliance Policies
9. Conditional Access (só depois de Compliance existir — senão bloqueia sem critério de saída)
10. Apps obrigatórios (Required apps)
11. Validação: dispositivo piloto do enrollment ao estado Managed
```

Configurar Conditional Access **antes** de ter uma Compliance Policy publicada é a segunda causa mais comum de bloqueio total de acesso — o dispositivo nunca consegue ficar "compliant" porque a política que definiria isso ainda não existe.

## 4. Scope Tags — organização multi-time/multi-cliente

Se mais de uma equipe ou mais de um cliente compartilha o mesmo tenant Intune, use **Scope Tags** desde o início:

- Cada Scope Tag limita quem vê o quê no console (RBAC por escopo).
- Aplique o Scope Tag já na criação do grupo/política, não depois — reaplicar em massa depois é trabalhoso.

## 5. Enrollment Status Page (ESP) — configuração recomendada

- **Show app and profile configuration progress:** habilitado, para o usuário ver o progresso (evita chamados de "travou").
- **Block device use until apps and profiles are installed:** habilitado apenas para os apps/perfis realmente críticos (marcados como "blocking"), não a lista inteira — senão o primeiro boot demora demais e gera percepção de falha.
- **Allow users to reset device if installation error occurs:** habilitado, reduz dependência do suporte para travamentos.

## 6. Como validar que o dispositivo está "Managed"

No portal do Intune, **Devices → All devices**, o dispositivo deve aparecer com:

- **Management state:** `Managed` (não `Unmanaged`, `Pending`, `Retire Pending`)
- **Compliance:** `Compliant` ou `In grace period` (nunca `Not evaluated` por tempo indefinido — indica que a compliance policy não está sendo aplicada)
- **Last check-in:** recente (dispositivos que não fazem check-in em vários dias geralmente têm problema de sync, não de configuração)

Validação complementar na própria estação:

```powershell
dsregcmd /status
# AzureAdJoined : YES
# DomainJoined  : YES (se Hybrid)
# AzureAdPrt    : YES
```

```powershell
Get-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\*" | Get-ScheduledTaskInfo
# Confirma que as tarefas de sync do MDM estão rodando e sem erro
```

## Checklist — do zero ao "Managed"

- [ ] Licença de Intune atribuída via grupo dinâmico (não manual, usuário a usuário)
- [ ] Licença de Entra ID P1 atribuída (se for usar Conditional Access)
- [ ] Convenção de nomes de grupo definida e documentada
- [ ] Grupos de dispositivo e de usuário separados por finalidade (nunca um grupo genérico único)
- [ ] Scope Tags aplicados desde a criação (se multi-time/multi-cliente)
- [ ] Enrollment Restrictions revisadas
- [ ] ESP configurada com apps "blocking" restritos ao essencial
- [ ] Autopilot profile atribuído a grupo de DISPOSITIVOS, nunca de usuários
- [ ] Compliance Policy publicada **antes** da Conditional Access
- [ ] Conditional Access com exclusões corretas (Intune Enrollment app — ver [troubleshooting relacionado](../registros/troubleshooting-service-principal-intune-enrollment.md))
- [ ] Dispositivo piloto validado com `Management state: Managed` e `Compliant`
- [ ] `dsregcmd /status` confirma AzureAdJoined/DomainJoined/AzureAdPrt = YES no piloto

## Erros comuns (resumo rápido)

| Sintoma | Causa provável |
|---|---|
| Dispositivo fica em "Registered", nunca "Managed" | Falta licença de Intune no usuário |
| Autopilot não aplica perfil | Perfil atribuído a grupo de usuário, não de dispositivo |
| Enrollment trava em loop de autenticação | Conditional Access bloqueando o app de Intune Enrollment |
| Compliance sempre "Not evaluated" | Compliance policy não atribuída ao grupo certo, ou dispositivo não fez check-in ainda |
| ESP trava por minutos no primeiro boot | Apps marcados como "blocking" demais na ESP |

## Referências

- [MDM Enrollment em Ambiente Hybrid](../registros/mdm-enrollment-hybrid.md)
- [Autopilot Devices — Hybrid Join](../registros/autopilot-hybrid-join.md)
- [Troubleshooting: Service Principal ausente](../registros/troubleshooting-service-principal-intune-enrollment.md)
