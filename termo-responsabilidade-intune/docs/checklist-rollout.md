# Checklist de rollout

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
- [ ] Teste ponta a ponta validado: aceite -> sync -> .ok -> compliant
- [ ] Conditional Access validado em Report-only e depois ativado
- [ ] Levantamento prévio de equipamentos já em uso (evitar bloqueio em
      massa no dia da ativação)
- [ ] Rollout ampliado gradualmente (piloto -> setor -> empresa toda)
