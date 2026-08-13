# Problemas conhecidos e soluções

| Sintoma | Causa | Solução |
|---|---|---|
| "is not digitally signed. You cannot run this script" | Execution Policy bloqueando script baixado/sincronizado (ex: via OneDrive) | `Unblock-File -Path "script.ps1"` antes de rodar, ou `powershell -ExecutionPolicy Bypass -File "script.ps1"` |
| JSON rejeitado: "English locale must be specified" | Falta entrada en_US no RemediationStrings | Sempre incluir en_US junto com pt_BR (ver `docs/compliance-rules.json`) |
| Política aparece "Não aplicável" no dispositivo | Avaliação ainda não rodou (normal logo após atribuir) | Aguardar ciclo natural (até 8h), ou forçar via `Get-ScheduledTask -TaskName "PushLaunch" \| Start-ScheduledTask`, ou Sync pelo próprio Intune admin center (mais rápido) |
| Status muda para "Sem conformidade" em vez de "Conformidade" mesmo com .ok criado | Permissão de leitura faltando (Share ou NTFS) para Domain Computers, ou script no Intune desatualizado | Conferir as duas camadas de permissão; sempre re-colar o script atualizado dentro do Intune admin center, não só editar localmente |
| Set-Content "funciona" mas arquivo não é criado | Erro de permissão não-terminante engolido silenciosamente | Sempre usar `-ErrorAction Stop` + validar com `Test-Path` depois da escrita (já corrigido nos scripts deste repositório) |
| `Get-MgDeviceManagementManagedDevice` com filtro por userId retorna erro 400 Unsupported parameter | Esse endpoint não aceita `$filter` por userId | Usar `Get-MgUserManagedDevice -UserId $userId` (endpoint de dispositivos do usuário) |
| 403 Forbidden no Graph, "does not have any of the required roles" | Falta permissão de aplicativo ou falta consentimento de admin | Conferir as 3 permissões (ver `setup.md`, seção 6), sempre clicar em "Grant admin consent" após adicionar qualquer permissão nova |
| Página HTML perde estilo/logo ao converter ou salvar | Arquivo salvo a partir da visualização do SharePoint (captura toda a "casca" da página), não do HTML original | Sempre partir do arquivo .html original, não de um "Salvar como" feito de dentro do navegador no SharePoint |
