
# Bloqueio de Acesso por Termo de Responsabilidade

Vincula o Termo de Responsabilidade pela Guarda e Zelo de Equipamentos
(FO.TI.05) ao Intune, bloqueando automaticamente o acesso do colaborador
a recursos corporativos até que o termo seja aceito.

**Empresa:** Empresa.local
**Escopo:** Sem eSignature (documento individual continua em papel/PDF à parte)

## Índice

- [Arquitetura](#arquitetura)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Configuração passo a passo](docs/setup.md)
- [Problemas conhecidos e soluções](docs/troubleshooting.md)
- [Checklist de rollout](docs/checklist-rollout.md)

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

## Estrutura do repositório

```
termo-responsabilidade-intune/
├── README.md
├── scripts/
│   ├── Discovery-TermoResponsabilidade.ps1   # roda em cada notebook (Intune)
│   ├── Sync-TermoUsoParaCompliance.ps1       # roda 1x, agendado, servidor central
│   └── Registrar-TermoAssinado.ps1           # fallback manual (termo assinado em papel)
└── docs/
    ├── compliance-rules.json                 # regra de validação do Intune
    ├── setup.md                              # passo a passo completo de configuração
    ├── troubleshooting.md                    # problemas conhecidos e soluções
    └── checklist-rollout.md                  # checklist de implantação
```
