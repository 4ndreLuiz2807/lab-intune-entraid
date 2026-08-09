# Laboratório Intune / Entra ID / Microsoft 365

Repositório para registrar ações, testes e práticas realizadas em um ambiente de laboratório voltado para **Microsoft Intune**, **Microsoft Entra ID** e demais serviços do ecossistema Microsoft 365.

O objetivo é manter um histórico organizado do que foi testado, os resultados obtidos e os aprendizados, servindo como base de conhecimento e portfólio técnico.

## Estrutura do repositório

```
lab-intune-entraid/
├── README.md              # Este arquivo
├── docs/
│   └── modelos/            # Modelos reutilizáveis (registro, checklist, etc.)
├── registros/               # Registros das atividades, um arquivo por sessão/dia
├── scripts/                 # Scripts PowerShell/Graph API usados no laboratório
└── evidencias/               # Prints, exports e evidências das configurações testadas
```

### `docs/modelos/`
Contém os modelos padrão usados para criar novos registros (veja `modelo-registro.md`).

### `registros/`
Cada entrada representa uma sessão de estudo/prática. Nomeie os arquivos no formato:

```
AAAA-MM-DD-titulo-curto.md
```

Exemplo: `2026-08-09-configuracao-politica-compliance-intune.md`

### `scripts/`
Scripts PowerShell, Microsoft Graph API ou automações criadas durante os testes. Organize em subpastas por tema se o volume crescer (ex.: `scripts/intune/`, `scripts/entra-id/`).

### `evidencias/`
Screenshots, exports JSON/CSV de políticas, ou qualquer evidência visual do que foi configurado. Recomenda-se nomear os arquivos referenciando o registro correspondente.

## Convenções de commit

Use prefixos para facilitar o histórico:

- `registro:` — nova entrada de prática/log
- `script:` — novo script ou alteração em script
- `doc:` — atualização de documentação/modelo
- `fix:` — correção de erro em registro ou script anterior

Exemplo: `git commit -m "registro: teste de política de compliance no Intune"`

## Tópicos cobertos (ajuste conforme o laboratório evoluir)

- Microsoft Entra ID (usuários, grupos, políticas de acesso condicional, roles)
- Microsoft Intune (compliance, configuration profiles, aplicativos, Autopilot)
- Microsoft Graph API / PowerShell para administração
- Integração entre Entra ID e Intune (Conditional Access + Compliance)
- Outros serviços Microsoft 365 relacionados ao laboratório

## Aviso

Este é um ambiente de laboratório/estudo. Nenhuma informação sensível de ambiente de produção real deve ser incluída (nomes de usuários reais, domínios corporativos reais, senhas, tokens, etc.).
