# Bloqueio de Acesso por Termo de Responsabilidade

**Área:** Entra ID / Intune
**Data:** 2026-08-13

## Contexto

Vincular o Termo de Responsabilidade pela Guarda e Zelo de Equipamentos
ao Intune, bloqueando automaticamente o acesso do colaborador
a recursos corporativos até que o termo seja aceito.

**Escopo:** sem eSignature — o documento individual continua sendo
assinado em papel/PDF à parte. Este registro cobre apenas o bloqueio
automático de acesso via compliance + Conditional Access.

## Arquitetura

```
Usuário aceita o Termos de Uso (Entra ID)
        |
        v
Sync-TermoUsoParaCompliance.ps1  (roda 1x, agendado, em 1 servidor)
  consulta o Microsoft Graph -> identifica quem aceitou -> identifica
  o(s) notebook(s) da pessoa -> cria/atualiza o arquivo .ok
        |
        v
\\server221\termos$\<HOSTNAME>.ok   (compartilhamento de rede)
        |
        v
Discovery-TermoResponsabilidade.ps1  (roda em CADA notebook, via política
  de Custom Compliance do Intune) -> lê se o .ok existe -> reporta
  TermoAssinado = true/false
        |
        v
Intune marca o dispositivo como Compliant / Não compliant
        |
        v
Conditional Access bloqueia/libera acesso a e-mail, Teams etc.
```

**Duas peças rodam em lugares diferentes:**

| Script | Onde roda | Quantas vezes |
|---|---|---|
| `Sync-TermoUsoParaCompliance.ps1` | 1 servidor central | 1x, agendado periodicamente |
| `Discovery-TermoResponsabilidade.ps1` | Em cada notebook | Automaticamente, distribuído pelo Intune via política |

O documento formal (FO.TI.05 assinado em papel/PDF) continua sendo feito à
parte, como registro jurídico — este fluxo cuida apenas do bloqueio
automático de acesso.

## Passo a passo

### 1. Compartilhamento de rede

Local usado: `C:\Contents\Termos` no `SERVER221`, compartilhado como
`\\server221\termos$`.

1. Criar a pasta no servidor de arquivos.
2. Propriedades da pasta → Compartilhamento Avançado → marcar
   "Compartilhar esta pasta" → nome do compartilhamento com `$` no final
   (oculto).
3. Aba Permissões de Compartilhamento:

   | Conta/Grupo | Permissão |
   |---|---|
   | Domain Computers | Leitura |
   | Conta/grupo de técnicos de TI | Leitura e Gravação |

4. Aba Segurança (NTFS) da mesma pasta — repetir as permissões
   equivalentes (Leitura para Domain Computers, Modificar para a conta
   de TI/serviço). As duas camadas (Share + NTFS) precisam estar
   configuradas — o Windows aplica a mais restritiva entre as duas.

> **Por que não usar SharePoint/Graph API direto no discovery script?**
> Autenticar a partir de um script que roda como SYSTEM no cliente
> exigiria guardar uma credencial (client secret) na própria máquina —
> risco de segurança desnecessário. Um compartilhamento de rede interno,
> com permissão só de leitura pra máquinas do domínio, resolve sem esse
> problema.

Conteúdo da pasta: um arquivo por equipamento, nomeado pelo hostname
exato, extensão `.ok`, sem subpastas:

```
\\server221\termos$\BA-NOTESI277.ok
\\server221\termos$\WORKSTATION02.ok
```

O conteúdo do arquivo é opcional — geralmente a data do aceite em texto
puro. Um arquivo vazio também funciona: o discovery script usa a data
de modificação como fallback.

### 2. Publicar o discovery script no Intune

**2.1 Subir o script de descoberta**

1. Intune admin center → Dispositivos → Conformidade → aba Scripts →
   + Adicionar → Windows 10 and later.
2. Nome: `Discovery - Termo de Responsabilidade`.
3. Cole/anexe [`Discovery-TermoResponsabilidade.ps1`](../scripts/intune-compliance-termo/Discovery-TermoResponsabilidade.ps1).
4. Deixe as opções padrão de execução (roda como SYSTEM por padrão).
5. Não atribua grupo aqui — o script isolado não tem atribuição própria;
   quem recebe grupo é a política de compliance (próximo passo).

**2.2 Criar a política de Compliance customizada**

1. Dispositivos → Conformidade → aba Políticas → + Criar política.
2. Platform: Windows 10 and later. Profile type: Compliance policy.
3. Aba Compliance settings → expanda Custom Compliance:
   - Custom compliance: Require
   - Discovery script: selecione o script do passo 2.1
   - JSON: o JSON de validação abaixo (seção "JSON de compliance")
4. Aba Actions for noncompliance:
   - Ação 1: Mark device noncompliant — 0 dias
   - Ação 2 (opcional): Send email to end user
   - Não configure Retire/Wipe aqui — é destrutivo e não é o objetivo.
5. Aba Assignments → atribua ao grupo de dispositivos (passo 3).
6. Criar.

> O Intune roda a cópia que ele mesmo guarda no portal, não o arquivo
> local. Sempre que editar o script localmente, volte em Scripts →
> Discovery... → Editar e cole o conteúdo atualizado.

**JSON de compliance:**

```json
{
  "Rules": [
    {
      "SettingName": "TermoAssinado",
      "Operator": "IsEquals",
      "DataType": "Boolean",
      "Operand": true,
      "MoreInfoUrl": ".html",
      "RemediationStrings": [
        {
          "Language": "en_US",
          "Title": "Liability Term pending",
          "Description": "This device does not yet have the Equipment Custody and Care Liability Term (FO.TI.05) registered with IT. Please contact the IT department to sign the term. The device will be released automatically on the next compliance check after registration."
        },
        {
          "Language": "pt_BR",
          "Title": "Termo de Responsabilidade pendente",
          "Description": "Este equipamento ainda não possui o Termo de Responsabilidade pela Guarda e Zelo de Equipamentos (FO.TI.05) registrado junto à TI. Procure o setor de TI para assinar o termo. Após o registro, o dispositivo será liberado automaticamente na próxima verificação de compliance."
        }
      ]
    }
  ]
}
```

Precisa ter uma entrada `en_US` obrigatória, mesmo que a empresa use só
português (o Intune usa como fallback interno) — sem isso o upload é
rejeitado com erro "English locale must be specified".

### 3. Grupo de dispositivos no Entra ID

Use grupo de DISPOSITIVOS, não de usuários. O script de descoberta
verifica pelo hostname da máquina — se o grupo fosse de usuário, a
política valeria em qualquer notebook onde aquela pessoa logasse, o que
não bate com a lógica "1 termo = 1 equipamento".

1. Entra ID → Grupos → Novo grupo.
2. Tipo de grupo: Segurança.
3. Tipo de associação: Dispositivo (não Usuário) — atenção redobrada
   aqui, é o erro mais comum nessa etapa.
4. Adicione os notebooks como membros (manual, ou dinâmico por critério
   como modelo/OU sincronizada, se preferir escalar sem trabalho manual).
5. Volte na política de compliance (passo 2.2) → Atribuições → selecione
   esse grupo.

### 4. Termos de Uso (Entra ID)

Recurso nativo do Entra ID que exibe um PDF e bloqueia acesso até o
usuário ler/expandir e aceitar — com trilha de auditoria (quem, quando).

**Limitações importantes:**

- O documento é um único PDF estático, igual para todo mundo — não
  preenche nome, patrimônio ou dados do equipamento automaticamente.
- Funciona por usuário, não por dispositivo — complementa (não
  substitui) o fluxo de compliance por hostname.
- Serve como declaração geral de ciência da política, não como
  substituto do documento formal individual (FO.TI.05), que continua em
  papel/PDF à parte.

**Passos:**

1. Entra ID → Proteção → Acesso Condicional → Termos de Uso →
   + Novo termo.
2. Upload do PDF (o termo-responsabilidade.pdf gerado a partir da
   página HTML, com logo e identidade visual da empresa).
3. Idioma: pt-BR.
4. Marcar:
   - Exigir que os usuários expandam o Termos de Uso
   - Exigir nova aceitação (periodicidade, se aplicável — ex: a cada
     novo equipamento)
5. Salvar. Anote o nome exato do termo (usado depois no script de
   sincronização, `$AgreementName`).

### 5. Conditional Access

Quem de fato bloqueia o acesso — a política de compliance sozinha só
marca o status, não impede nada por si só.

1. Entra ID → Proteção → Acesso Condicional → + Nova política.
2. Nome: `CA - Bloqueio por Termo de Responsabilidade`.
3. Usuários: comece com um grupo piloto, nunca "Todos os usuários" direto.
4. Recursos de destino → Aplicativos na nuvem → comece com um app de
   baixo risco (ex: Exchange Online) antes de expandir pra tudo.
5. Condições → Plataformas de dispositivo → Windows.
6. Controles de acesso → Conceder:
   - Exigir que o dispositivo seja marcado como compatível
   - Exigir termos de uso (a que você criou no passo 4)
7. Habilitar política: comece em Somente relatório (Report-only). Só
   ative ("On") depois de validar nos logs de sign-in.

> Sempre tenha uma conta break-glass (conta de emergência, excluída de
> toda política de CA) antes de ativar qualquer coisa de verdade —
> Conditional Access mal configurado pode travar acesso da empresa toda,
> incluindo o seu.

### 6. App Registration para automação

Necessário para o script de sincronização (passo 7) consultar o Graph
com permissão de aplicativo (app-only), sem depender de login de usuário.

1. Entra ID → App registrations → New registration.
   - Nome: `Sync-TermoUso-Compliance`
   - Tipo: Accounts in this organizational directory only
2. API permissions → + Add a permission → Microsoft Graph →
   Application permissions → adicionar:
   - `Agreement.Read.All`
   - `AgreementAcceptance.Read.All`
   - `DeviceManagementManagedDevices.Read.All`
3. Clicar em "Grant admin consent for [tenant]" (precisa de Global Admin
   ou Privileged Role Admin). Confirmar que as três aparecem com check
   verde "Concedido".
4. Certificates & secrets → New client secret → copiar o valor do
   secret imediatamente (só aparece uma vez).
5. Anotar da aba Overview: Application (client) ID e Directory
   (tenant) ID.

### 7. Script de sincronização automática

Roda periodicamente em 1 servidor central. Consulta o Graph, acha quem
aceitou o Termos de Uso, localiza o(s) dispositivo(s) da pessoa no
Intune, e cria/atualiza o `.ok` automaticamente — eliminando o passo
manual.

Pré-requisito: `Install-Module Microsoft.Graph -Scope AllUsers -Force`
na máquina que vai rodar o script.

Script: [`Sync-TermoUsoParaCompliance.ps1`](../scripts/intune-compliance-termo/Sync-TermoUsoParaCompliance.ps1)

### 8. Agendamento (Task Scheduler)

1. No servidor que roda o script de sincronização, abra o Agendador de
   Tarefas.
2. Criar Tarefa Básica:
   - Disparador: Diariamente, repetir a cada 1 hora (ou intervalo
     preferido — quanto menor, mais rápido o aceite reflete em
     compliance).
   - Ação: Iniciar um programa
     - Programa: `powershell.exe`
     - Argumentos: `-File "C:\caminho\Sync-TermoUsoParaCompliance.ps1"`
3. Rodar com uma conta de serviço dedicada, não a conta pessoal do
   administrador.
4. Testar manualmente uma vez antes de deixar 100% automático.

### 9. Script manual de fallback

Para casos excepcionais — ex: alguém que assinou o termo em papel, fora
do fluxo digital, e precisa ser liberado manualmente. Roda no computador
do técnico, exige permissão de escrita no compartilhamento.

Script: [`Registrar-TermoAssinado.ps1`](../scripts/intune-compliance-termo/Registrar-TermoAssinado.ps1)

```powershell
.\Registrar-TermoAssinado.ps1 -Hostname "PC-FULANO01"
.\Registrar-TermoAssinado.ps1 -Hostname "PC-FULANO01" -DataAssinatura "2026-08-12"
```

## Problemas encontrados

| Sintoma | Causa | Solução |
|---|---|---|
| "is not digitally signed. You cannot run this script" | Execution Policy bloqueando script baixado/sincronizado (ex: via OneDrive) | `Unblock-File -Path "script.ps1"` antes de rodar, ou `powershell -ExecutionPolicy Bypass -File "script.ps1"` |
| JSON rejeitado: "English locale must be specified" | Falta entrada en_US no RemediationStrings | Sempre incluir en_US junto com pt_BR |
| Política aparece "Não aplicável" no dispositivo | Avaliação ainda não rodou (normal logo após atribuir) | Aguardar ciclo natural (até 8h), ou forçar via `Get-ScheduledTask -TaskName "PushLaunch" \| Start-ScheduledTask`, ou Sync pelo próprio Intune admin center (mais rápido) |
| Status muda para "Sem conformidade" mesmo com .ok criado | Permissão de leitura faltando (Share ou NTFS) para Domain Computers, ou script no Intune desatualizado | Conferir as duas camadas de permissão; sempre re-colar o script atualizado dentro do Intune admin center, não só editar localmente |
| Set-Content "funciona" mas arquivo não é criado | Erro de permissão não-terminante engolido silenciosamente | Sempre usar `-ErrorAction Stop` + validar com `Test-Path` depois da escrita (já corrigido nos scripts) |
| `Get-MgDeviceManagementManagedDevice` com filtro por userId retorna 400 Unsupported parameter | Esse endpoint não aceita `$filter` por userId | Usar `Get-MgUserManagedDevice -UserId $userId` |
| 403 Forbidden no Graph, "does not have any of the required roles" | Falta permissão de aplicativo ou falta consentimento de admin | Conferir as 3 permissões do passo 6, sempre clicar em "Grant admin consent" após adicionar qualquer permissão nova |
| Página HTML perde estilo/logo ao converter ou salvar | Arquivo salvo a partir da visualização do SharePoint (captura toda a "casca" da página), não do HTML original | Sempre partir do arquivo .html original, não de um "Salvar como" feito de dentro do navegador no SharePoint |

## Checklist de rollout

- [ ] Pasta de rede criada e compartilhada (`\\server221\termos$`)
- [ ] Permissões de Share e NTFS configuradas (leitura para Domain
      Computers, escrita para conta de TI/serviço)
- [ ] Discovery script publicado no Intune
- [ ] JSON de compliance validado (com en_US incluído)
- [ ] Política de compliance criada, com Custom Compliance configurado
- [ ] Grupo de dispositivos (não usuários) criado no Entra ID
- [ ] Política de compliance atribuída ao grupo piloto
- [ ] Termos de Uso criado no Entra ID, com o PDF final (logo + conteúdo)
- [ ] Conditional Access criado em modo Report-only
- [ ] Conta break-glass confirmada e excluída de toda política de CA
- [ ] App Registration criado, com as 3 permissões + admin consent
- [ ] Script de sincronização testado manualmente com sucesso
- [ ] Script de sincronização agendado no Task Scheduler
- [ ] Teste ponta a ponta validado: aceite → sync → .ok → compliant
- [ ] Conditional Access validado em Report-only e depois ativado
- [ ] Levantamento prévio de equipamentos já em uso (evitar bloqueio em
      massa no dia da ativação)
- [ ] Rollout ampliado gradualmente (piloto → setor → empresa toda)

## Scripts relacionados

- [`Discovery-TermoResponsabilidade.ps1`](../scripts/intune-compliance-termo/Discovery-TermoResponsabilidade.ps1)
- [`Sync-TermoUsoParaCompliance.ps1`](../scripts/intune-compliance-termo/Sync-TermoUsoParaCompliance.ps1)
- [`Registrar-TermoAssinado.ps1`](../scripts/intune-compliance-termo/Registrar-TermoAssinado.ps1)
