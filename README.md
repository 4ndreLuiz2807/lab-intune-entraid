<div align="center">

# 🧪 Laboratório Intune / Entra ID / Microsoft 365

**Registro de práticas, testes e troubleshooting em um ambiente de laboratório Microsoft 365**

[![Last Commit](https://img.shields.io/github/last-commit/4ndreLuiz2807/lab-intune-entraid?color=0078D4&label=último%20commit)](https://github.com/4ndreLuiz2807/lab-intune-entraid/commits/main)
[![Registros](https://img.shields.io/badge/registros-3-0078D4)](./registros)
[![License](https://img.shields.io/badge/licença-MIT-blue.svg)](./LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?logo=powershell&logoColor=white)](./scripts)
[![Microsoft Intune](https://img.shields.io/badge/Microsoft-Intune-0078D4?logo=microsoft&logoColor=white)](#)
[![Microsoft Entra ID](https://img.shields.io/badge/Microsoft-Entra%20ID-0078D4?logo=microsoft&logoColor=white)](#)

</div>

---

## 📖 Sobre

Este repositório documenta, de forma estruturada, as ações e práticas realizadas em um laboratório pessoal focado em **Microsoft Intune**, **Microsoft Entra ID** e no ecossistema **Microsoft 365**. Cada configuração testada vira um registro reprodutível — com contexto, passo a passo, problemas encontrados e evidências — servindo tanto como base de conhecimento pessoal quanto como portfólio técnico.

## 📑 Índice

- [Estrutura do repositório](#-estrutura-do-repositório)
- [Registros disponíveis](#-registros-disponíveis)
- [Scripts](#-scripts)
- [Convenção de commits](#-convenção-de-commits)
- [Como usar este repositório](#-como-usar-este-repositório)
- [Aviso](#️-aviso)

## 🗂️ Estrutura do repositório

```
lab-intune-entraid/
├── README.md                  # Este arquivo
├── LICENSE                    # Licença MIT
├── docs/
│   ├── modelos/                # Modelo reutilizável para novos registros
│   └── configuracoes/          # Exports de políticas e configurações aplicadas
├── registros/                  # Um arquivo markdown por prática/sessão
├── scripts/                    # Scripts organizados por finalidade
│   ├── intune-apps/
│   ├── intune-remediation/
│   ├── intune-store-policy/
│   └── forticlient-vpn/
└── evidencias/                 # Screenshots e evidências visuais
    └── autopilot/
```

## 📚 Registros disponíveis

| Registro | Área | Descrição |
|---|---|---|
| [MDM Enrollment em Hybrid Azure AD Joined](./registros/mdm-enrollment-hybrid.md) | Entra ID / Intune | Auto-enrollment em ambiente Hybrid: DNS split-brain, GPO e exceções de Conditional Access |
| [Troubleshooting: Service Principal ausente](./registros/troubleshooting-service-principal-intune-enrollment.md) | Entra ID | App não aparece no picker do Conditional Access — provisionamento manual via Microsoft Graph |
| [Autopilot Devices — Hybrid Join](./registros/autopilot-hybrid-join.md) | Intune | Configuração completa de dispositivos Autopilot com domain join híbrido |

> Novos registros seguem o [modelo padrão](./docs/modelos/modelo-registro.md) e devem ser adicionados a esta tabela.

## ⚙️ Scripts

| Pasta | Conteúdo |
|---|---|
| [`intune-apps/`](./scripts/intune-apps) | Instalação de apps via winget e criação de atalhos no desktop |
| [`intune-remediation/`](./scripts/intune-remediation) | Script de remediation proativa (aviso de reinicialização) |
| [`intune-store-policy/`](./scripts/intune-store-policy) | Bloqueio/reversão de acesso à Microsoft Store |
| [`forticlient-vpn/`](./scripts/forticlient-vpn) | Empacotamento Win32 do FortiClient VPN para deploy via Intune |

## 📝 Convenção de commits

| Prefixo | Uso |
|---|---|
| `registro:` | Nova entrada de prática/log |
| `script:` | Novo script ou alteração em script |
| `doc:` | Atualização de documentação/modelo |
| `fix:` | Correção de erro em registro ou script anterior |

Exemplo: `git commit -m "registro: teste de política de compliance no Intune"`

## 🚀 Como usar este repositório

1. Cada prática vira um arquivo em `registros/`, nomeado como `AAAA-MM-DD-titulo-curto.md`.
2. Use o [modelo de registro](./docs/modelos/modelo-registro.md) como ponto de partida.
3. Scripts vão em `scripts/<categoria>/`, evidências em `evidencias/`.
4. Ao adicionar um novo registro, inclua-o na tabela acima.

## ⚠️ Aviso

Este é um ambiente de laboratório/estudo. Nenhuma informação sensível de ambiente de produção real (senhas, tokens, domínios corporativos reais) deve ser incluída — segredos devem ficar em variáveis de ambiente ou cofres de segredos, nunca versionados.

---

<div align="center">

Feito por [Andre Luiz](https://github.com/4ndreLuiz2807) — laboratório de estudo em Microsoft 365, Intune e Entra ID.

</div>
