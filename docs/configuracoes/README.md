# Configurações exportadas

Exports de configurações aplicadas no ambiente de laboratório, para referência e possível reaplicação.

| Arquivo | Descrição |
|---|---|
| `CFG-Diretivas-OneDrive-SharePoint-SiteTI.json` | Export (via Graph API beta) da política de configuração do OneDrive/SharePoint aplicada ao grupo TI — auto-mount de site de equipe, KFM (Known Folder Move), files-on-demand, etc. |
| `Taskbar.xml` | Layout customizado da barra de tarefas (Company Portal, Edge, Word, Excel, Explorer, Teams, Outlook) aplicado via política de Intune/GPO. |
| `Chamados-HelpDesk-PWA.txt` | Configuração de atalho PWA (Progressive Web App) para o sistema de chamados TomTicket, usado em scripts de provisionamento de desktop. |

> Os exports de política (JSON) contêm IDs internos do tenant (tenantId, siteId, webId). Como este é um ambiente de laboratório, foi mantido como referência — em um tenant de produção real, considere ofuscar esses IDs antes de versionar.
