# Configuração passo a passo

## 1. Compartilhamento de rede

Local usado: `C:\Contents\Termos` no `SERVER221`, compartilhado como
`\\server221\termos$`.

### Passos

1. Criar a pasta no servidor de arquivos.
2. Propriedades da pasta -> Compartilhamento Avançado -> marcar
   "Compartilhar esta pasta" -> nome do compartilhamento com `$` no final
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

> Por que não usar SharePoint/Graph API direto no discovery script?
> Autenticar a partir de um script que roda como SYSTEM no cliente
> exigiria guardar uma credencial (client secret) na própria máquina —
> risco de segurança desnecessário. Um compartilhamento de rede interno,
> com permissão só de leitura pra máquinas do domínio, resolve sem esse
> problema.

### O que fica dentro da pasta

Um arquivo por equipamento, nomeado pelo hostname exato, extensão `.ok`,
sem subpastas:

```
\\server221\termos$\BA-NOTESI277.ok
\\server221\termos$\WORKSTATION02.ok
```

Conteúdo do arquivo: opcional, geralmente a data do aceite/assinatura em
texto puro. Um arquivo vazio também funciona — o script usa a data de
modificação como fallback.

## 2. Publicar o discovery script no Intune

### 2.1 Subir o script de descoberta

1. Intune admin center -> Dispositivos -> Conformidade -> aba Scripts ->
   + Adicionar -> Windows 10 and later.
2. Nome: `Discovery - Termo de Responsabilidade`.
3. Cole/anexe o script `scripts/Discovery-TermoResponsabilidade.ps1`.
4. Deixe as opções padrão de execução (roda como SYSTEM por padrão).
5. Não atribua grupo aqui — o script isolado não tem atribuição própria;
   quem recebe grupo é a política de compliance (próximo passo).

### 2.2 Criar a política de Compliance customizada

1. Dispositivos -> Conformidade -> aba Políticas -> + Criar política.
2. Platform: Windows 10 and later. Profile type: Compliance policy.
3. Aba Compliance settings -> expanda Custom Compliance:
   - Custom compliance: Require
   - Discovery script: selecione o script do passo 2.1
   - JSON: upload do arquivo `docs/compliance-rules.json`
4. Aba Actions for noncompliance:
   - Ação 1: Mark device noncompliant — 0 dias
   - Ação 2 (opcional): Send email to end user
   - Não configure Retire/Wipe aqui — é destrutivo e não é o objetivo.
5. Aba Assignments -> atribua ao grupo de dispositivos (seção 3).
6. Criar.

Atenção: o Intune roda a cópia que ele mesmo guarda no portal, não o
arquivo no seu computador. Sempre que editar o script localmente, volte
em Scripts -> Discovery... -> Editar e cole o conteúdo atualizado —
editar só o arquivo local não muda o que roda nos notebooks.

## 3. Grupo de dispositivos no Entra ID

Use grupo de DISPOSITIVOS, não de usuários. O script de descoberta
verifica pelo hostname da máquina — se o grupo fosse de usuário, a
política valeria em qualquer notebook onde aquela pessoa logasse, o que
não bate com a lógica "1 termo = 1 equipamento".

1. Entra ID -> Grupos -> Novo grupo.
2. Tipo de grupo: Segurança.
3. Tipo de associação: Dispositivo (não Usuário) — atenção redobrada
   aqui, é o erro mais comum nessa etapa.
4. Adicione os notebooks como membros (manual, ou dinâmico por critério
   como modelo/OU sincronizada, se preferir escalar sem trabalho manual).
5. Volte na política de compliance (seção 2.2) -> Atribuições -> selecione
   esse grupo.

## 4. Termos de Uso (Entra ID)

Recurso nativo do Entra ID que exibe um PDF e bloqueia acesso até o
usuário ler/expandir e aceitar — com trilha de auditoria (quem, quando).

### Limitações importantes

- O documento é um único PDF estático, igual para todo mundo — não
  preenche nome, patrimônio ou dados do equipamento automaticamente.
- Funciona por usuário, não por dispositivo — complementa (não
  substitui) o fluxo de compliance por hostname.
- Serve como declaração geral de ciência da política, não como
  substituto do documento formal individual (FO.TI.05), que continua em
  papel/PDF à parte.

### Passos

1. Entra ID -> Proteção -> Acesso Condicional -> Termos de Uso ->
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

## 5. Conditional Access

Quem de fato bloqueia o acesso — a política de compliance sozinha só
marca o status, não impede nada por si só.

1. Entra ID -> Proteção -> Acesso Condicional -> + Nova política.
2. Nome: `CA - Bloqueio por Termo de Responsabilidade`.
3. Usuários: comece com um grupo piloto, nunca "Todos os usuários" direto.
4. Recursos de destino -> Aplicativos na nuvem -> comece com um app de
   baixo risco (ex: Exchange Online) antes de expandir pra tudo.
5. Condições -> Plataformas de dispositivo -> Windows.
6. Controles de acesso -> Conceder:
   - Exigir que o dispositivo seja marcado como compatível
   - Exigir termos de uso (a que você criou na seção 4)
7. Habilitar política: comece em Somente relatório (Report-only). Só
   ative ("On") depois de validar nos logs de sign-in.

Sempre tenha uma conta break-glass (conta de emergência, excluída de
toda política de CA) antes de ativar qualquer coisa de verdade —
Conditional Access mal configurado pode travar acesso da empresa toda,
incluindo o seu.

## 6. App Registration para automação

Necessário para o script de sincronização (seção 7) consultar o Graph
com permissão de aplicativo (app-only), sem depender de login de usuário.

1. Entra ID -> App registrations -> New registration.
   - Nome: `Sync-TermoUso-Compliance`
   - Tipo: Accounts in this organizational directory only
2. API permissions -> + Add a permission -> Microsoft Graph ->
   Application permissions -> adicionar:
   - `Agreement.Read.All`
   - `AgreementAcceptance.Read.All`
   - `DeviceManagementManagedDevices.Read.All`
3. Clicar em "Grant admin consent for [tenant]" (precisa de Global Admin
   ou Privileged Role Admin). Confirmar que as três aparecem com check
   verde "Concedido".
4. Certificates & secrets -> New client secret -> copiar o valor do
   secret imediatamente (só aparece uma vez).
5. Anotar da aba Overview: Application (client) ID e Directory
   (tenant) ID.

## 7. Script de sincronização automática

Roda periodicamente em 1 servidor central. Consulta o Graph, acha quem
aceitou o Termos de Uso, localiza o(s) dispositivo(s) da pessoa no
Intune, e cria/atualiza o .ok automaticamente — eliminando o passo
manual.

Pré-requisito: `Install-Module Microsoft.Graph -Scope AllUsers -Force`
na máquina que vai rodar o script.

Script: `scripts/Sync-TermoUsoParaCompliance.ps1`

## 8. Agendamento (Task Scheduler)

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

## 9. Script manual de fallback

Para casos excepcionais — ex: alguém que assinou o termo em papel, fora
do fluxo digital, e precisa ser liberado manualmente. Roda no computador
do técnico, exige permissão de escrita no compartilhamento.

Script: `scripts/Registrar-TermoAssinado.ps1`

```powershell
.\Registrar-TermoAssinado.ps1 -Hostname "PC-FULANO01"
.\Registrar-TermoAssinado.ps1 -Hostname "PC-FULANO01" -DataAssinatura "2026-08-12"
```
