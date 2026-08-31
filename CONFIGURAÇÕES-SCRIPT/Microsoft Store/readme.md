

# 🔒 Bloqueio e Liberação da Microsoft Store via Microsoft Intune

Este documento apresenta uma forma de **bloquear e posteriormente liberar o acesso à Microsoft Store em dispositivos Windows gerenciados pelo Microsoft Intune**, utilizando scripts PowerShell.

A estratégia é especialmente útil em ambientes com **Windows 10/11 Pro**, nos quais determinadas políticas nativas de bloqueio da Microsoft Store possuem limitações de edição/licenciamento.

> **Objetivo:** impedir que usuários utilizem a Microsoft Store para instalar aplicativos não autorizados, mantendo o gerenciamento centralizado através do Microsoft Intune.

---

## 📋 Visão geral

Em ambientes corporativos, permitir acesso irrestrito à Microsoft Store pode possibilitar a instalação de aplicativos que não fazem parte do catálogo homologado pela organização.

Exemplos:

* Jogos;
* Redes sociais;
* Aplicativos de entretenimento;
* Aplicativos não homologados pela TI;
* Ferramentas sem avaliação de segurança.

A estratégia apresentada utiliza **PowerShell + Microsoft Intune** para aplicar configurações no Registro do Windows responsáveis pelo comportamento da Microsoft Store.

São utilizados dois scripts:

```text
BlockStore.ps1
EnableStore.ps1
```

| Script            | Finalidade                                             |
| ----------------- | ------------------------------------------------------ |
| `BlockStore.ps1`  | Aplicar o bloqueio da Microsoft Store                  |
| `EnableStore.ps1` | Remover as configurações de bloqueio                   |
| Intune            | Distribuir os scripts para os dispositivos             |
| Grupos Entra ID   | Controlar quais dispositivos recebem cada configuração |

---

# ⚠️ Windows Pro x Enterprise/Education

Este ponto é importante.

A Microsoft disponibiliza oficialmente a política:

```text
Turn off the Store application
```

No Intune ela pode ser encontrada no **Catálogo de Configurações**, em:

```text
Administrative Templates
└── Windows Components
    └── Store
        └── Turn off the Store application
```

Entretanto, o suporte oficial da política de dispositivo é destinado às edições:

```text
Windows Enterprise
Windows Education
Windows IoT Enterprise
```

Por isso, em ambientes utilizando **Windows Pro**, pode ser necessário utilizar uma abordagem alternativa através de PowerShell/Registro.

---

# 🏗️ Arquitetura da solução

O fluxo utilizado será:

```text
Microsoft Intune
       │
       │
       ▼
Grupo Entra ID
       │
       ▼
Script PowerShell
       │
       ▼
Registro do Windows
       │
       ▼
Microsoft Store
       │
       ├── 🔒 Bloqueada
       │
       └── 🔓 Liberada
```

Dessa forma, a TI consegue controlar centralmente quais equipamentos poderão utilizar a Microsoft Store.

---

# 🔒 Script para bloquear a Microsoft Store

Crie um arquivo chamado:

```text
BlockStore.ps1
```

Adicione:

```powershell
# ============================================================
# BLOQUEIO DA MICROSOFT STORE
# Microsoft Intune
#
# Objetivo:
# Bloquear o acesso à Microsoft Store através de políticas
# aplicadas no Registro do Windows.
# ============================================================

$ErrorActionPreference = "Stop"

try {

    Write-Host "Aplicando políticas de bloqueio da Microsoft Store..."

    # ========================================================
    # Política principal da Microsoft Store
    # ========================================================

    $StorePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"

    if (!(Test-Path $StorePolicyPath)) {

        New-Item `
            -Path $StorePolicyPath `
            -Force | Out-Null
    }


    # ========================================================
    # Força comportamento restrito da Store
    # ========================================================

    New-ItemProperty `
        -Path $StorePolicyPath `
        -Name "RequirePrivateStoreOnly" `
        -PropertyType DWord `
        -Value 1 `
        -Force | Out-Null


    # ========================================================
    # Bloqueia o aplicativo Microsoft Store
    # ========================================================

    New-ItemProperty `
        -Path $StorePolicyPath `
        -Name "RemoveWindowsStore" `
        -PropertyType DWord `
        -Value 1 `
        -Force | Out-Null


    # ========================================================
    # Política complementar
    # ========================================================

    $ExplorerPolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    if (!(Test-Path $ExplorerPolicyPath)) {

        New-Item `
            -Path $ExplorerPolicyPath `
            -Force | Out-Null
    }


    New-ItemProperty `
        -Path $ExplorerPolicyPath `
        -Name "NoWindowsStore" `
        -PropertyType DWord `
        -Value 1 `
        -Force | Out-Null


    # ========================================================
    # Mantém comportamento padrão das atualizações
    # ========================================================

    if (
        Get-ItemProperty `
            -Path $StorePolicyPath `
            -Name "AutoDownload" `
            -ErrorAction SilentlyContinue
    ) {

        Remove-ItemProperty `
            -Path $StorePolicyPath `
            -Name "AutoDownload" `
            -ErrorAction SilentlyContinue
    }


    Write-Host "Bloqueio da Microsoft Store aplicado com sucesso."

    exit 0

}
catch {

    Write-Host "Erro ao aplicar bloqueio da Microsoft Store:"
    Write-Host $_.Exception.Message

    exit 1
}
```

---

# 🔎 O que o script altera?

O principal caminho utilizado é:

```text
HKEY_LOCAL_MACHINE
└── SOFTWARE
    └── Policies
        └── Microsoft
            └── WindowsStore
```

São configurados valores relacionados ao comportamento da Store.

### RemoveWindowsStore

```text
RemoveWindowsStore = 1
```

Utilizado para bloquear o acesso à Microsoft Store.

### RequirePrivateStoreOnly

```text
RequirePrivateStoreOnly = 1
```

Aplica uma restrição adicional relacionada ao catálogo da Store.

### NoWindowsStore

Também é criado:

```text
HKEY_LOCAL_MACHINE
└── SOFTWARE
    └── Microsoft
        └── Windows
            └── CurrentVersion
                └── Policies
                    └── Explorer
```

com:

```text
NoWindowsStore = 1
```

---

# 🚀 Distribuindo pelo Microsoft Intune

Acesse:

```text
Microsoft Intune Admin Center
```

Depois:

```text
Dispositivos
   ↓
Windows
   ↓
Scripts e correções
   ↓
Scripts de plataforma
   ↓
Adicionar
   ↓
Windows 10 e posterior
```

Crie o script com um nome padronizado.

Exemplo:

```text
WIN - Bloqueio Microsoft Store
```

Descrição sugerida:

```text
Aplica restrições para impedir o acesso dos usuários
à Microsoft Store em dispositivos Windows gerenciados
pelo Microsoft Intune.
```

---

# ⚙️ Configuração do script

Faça upload do:

```text
BlockStore.ps1
```

Configuração recomendada:

| Configuração                                                    | Valor |
| --------------------------------------------------------------- | ----- |
| Executar este script usando as credenciais do usuário conectado | Não   |
| Impor verificação de assinatura do script                       | Não   |
| Executar script no host do PowerShell de 64 bits                | Sim   |

O script precisa executar como **SYSTEM**, pois realiza alterações em:

```text
HKLM
```

---

# 👥 Atribuição

É recomendado utilizar um grupo específico para controlar os dispositivos que receberão o bloqueio.

Exemplo:

```text
GRP-INTUNE-BLOQUEIO-MICROSOFT-STORE
```

Fluxo:

```text
GRP-INTUNE-BLOQUEIO-MICROSOFT-STORE
                 │
                 ▼
          BlockStore.ps1
                 │
                 ▼
             Intune
                 │
                 ▼
        Dispositivos Windows
                 │
                 ▼
       🔒 Microsoft Store
```

Isso facilita testes, troubleshooting e futuras exceções.

---

# 🔄 Forçando sincronização

No equipamento cliente:

```powershell
Start-Process "intunemanagementextension://syncapp"
```

Também é possível iniciar uma sincronização pelo próprio Windows:

```text
Configurações
   ↓
Contas
   ↓
Acessar trabalho ou escola
   ↓
Conta corporativa
   ↓
Informações
   ↓
Sincronizar
```

Também é possível solicitar a sincronização pelo portal do Intune.

---

# 🔎 Validando o bloqueio

Execute:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
```

Verifique principalmente:

```text
RequirePrivateStoreOnly
RemoveWindowsStore
```

Também valide:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
```

Procure:

```text
NoWindowsStore
```

Depois, tente abrir:

```text
Microsoft Store
```

---

# 🔓 Liberando novamente a Microsoft Store

Também devemos possuir um procedimento de rollback.

Crie:

```text
EnableStore.ps1
```

Utilize:

```powershell
# ============================================================
# LIBERAÇÃO DA MICROSOFT STORE
# Microsoft Intune
#
# Objetivo:
# Remover as configurações utilizadas para bloquear
# a Microsoft Store.
# ============================================================

$ErrorActionPreference = "Stop"

try {

    Write-Host "Removendo políticas de bloqueio da Microsoft Store..."

    $StorePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"


    # ========================================================
    # RequirePrivateStoreOnly
    # ========================================================

    if (!(Test-Path $StorePolicyPath)) {

        New-Item `
            -Path $StorePolicyPath `
            -Force | Out-Null
    }

    New-ItemProperty `
        -Path $StorePolicyPath `
        -Name "RequirePrivateStoreOnly" `
        -PropertyType DWord `
        -Value 0 `
        -Force | Out-Null


    # ========================================================
    # RemoveWindowsStore
    # ========================================================

    Remove-ItemProperty `
        -Path $StorePolicyPath `
        -Name "RemoveWindowsStore" `
        -ErrorAction SilentlyContinue


    # ========================================================
    # AutoDownload
    # ========================================================

    Remove-ItemProperty `
        -Path $StorePolicyPath `
        -Name "AutoDownload" `
        -ErrorAction SilentlyContinue


    # ========================================================
    # NoWindowsStore
    # ========================================================

    $ExplorerPolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    if (Test-Path $ExplorerPolicyPath) {

        Remove-ItemProperty `
            -Path $ExplorerPolicyPath `
            -Name "NoWindowsStore" `
            -ErrorAction SilentlyContinue
    }


    Write-Host "Microsoft Store liberada com sucesso."

    exit 0

}
catch {

    Write-Host "Erro ao liberar Microsoft Store:"
    Write-Host $_.Exception.Message

    exit 1
}
```

---

# 🚀 Distribuindo o script de liberação

No Intune, crie outro script:

```text
WIN - Liberação Microsoft Store
```

Faça upload:

```text
EnableStore.ps1
```

Utilize as mesmas configurações:

```text
Executar usando usuário conectado: NÃO

Impor assinatura:
NÃO

PowerShell 64 bits:
SIM
```

---

# ⚠️ Importante sobre atribuições

Antes de atribuir o script de liberação, retire o dispositivo do grupo responsável pelo bloqueio.

Exemplo:

```text
ANTES

Dispositivo
     │
     ▼
GRP-INTUNE-BLOQUEIO-MICROSOFT-STORE
     │
     ▼
BlockStore.ps1
```

Para liberar:

```text
REMOVER DO GRUPO DE BLOQUEIO
              │
              ▼
      Aplicar EnableStore.ps1
              │
              ▼
       🔓 Microsoft Store
```

Isso evita que duas configurações conflitantes sejam aplicadas ao mesmo equipamento.

---

# 🧪 Teste local

Antes de publicar no Intune, os scripts podem ser testados em uma máquina de homologação.

Abra o **PowerShell como Administrador**.

Para bloquear:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force

.\BlockStore.ps1
```

Reinicie o equipamento e valide a Store.

Para reverter:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force

.\EnableStore.ps1
```

Reinicie novamente e valide.

---

# 🏢 Estratégia recomendada para produção

Evite aplicar diretamente em todos os dispositivos.

Utilize inicialmente um grupo piloto:

```text
GRP-INTUNE-TESTE-BLOQUEIO-STORE
```

Por exemplo:

```text
              INTUNE
                 │
                 ▼
        Grupo de Homologação
                 │
                 ▼
           5-10 máquinas
                 │
                 ▼
              Testes
                 │
        ┌────────┴────────┐
        ▼                 ▼
     Sucesso            Falha
        │                 │
        ▼                 ▼
   Produção          Troubleshooting
```

Após validar o comportamento, amplie gradualmente a atribuição.

---

# ⚠️ Microsoft Store bloqueada não significa bloqueio total de instalações

Existe uma consideração importante.

Bloquear a interface da Microsoft Store **não necessariamente impede todos os mecanismos de instalação de aplicativos**.

Por exemplo:

```text
winget
```

pode não ser afetado pela política de bloqueio da interface da Microsoft Store.

Portanto, organizações que precisam de um controle mais rigoroso de execução e instalação devem avaliar controles adicionais, como:

```text
Microsoft Intune
App Control for Business
Windows Defender Application Control
AppLocker
Controle de privilégios administrativos
Catálogo corporativo de aplicativos
```

---

# 📦 Aplicativos da Store distribuídos pelo Intune

Outro ponto importante é que bloquear a interface da Microsoft Store para o usuário **não necessariamente impede o Microsoft Intune de distribuir aplicativos provenientes da Microsoft Store**.

Isso permite trabalhar com um modelo corporativo como:

```text
                Usuário
                   │
                   ▼
           Microsoft Store
                   │
                🔒 BLOQUEADA


                  TI
                   │
                   ▼
          Microsoft Intune
                   │
                   ▼
       Microsoft Store (new)
                   │
                   ▼
        Aplicativos aprovados
                   │
                   ▼
              Dispositivo
```

Esse modelo é interessante porque o usuário perde a capacidade de escolher livremente o que instalar, enquanto a TI mantém o catálogo de aplicativos homologados.

---

# 📝 Logs para troubleshooting

Em dispositivos gerenciados pelo Intune, consulte:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Alguns dos principais logs são:

```text
IntuneManagementExtension.log
AgentExecutor.log
```

Também valide diretamente as chaves:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" `
    -ErrorAction SilentlyContinue

Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ErrorAction SilentlyContinue
```

---

# 📂 Estrutura sugerida para o GitHub

Uma estrutura simples para o repositório:

```text
Microsoft-Store-Intune/
│
├── README.md
│
├── Scripts/
│   ├── BlockStore.ps1
│   └── EnableStore.ps1
│
└── Images/
    ├── Intune-01.png
    ├── Intune-02.png
    └── Store-Bloqueada.png
```

---

# 🔐 Boas práticas

Antes da implantação em produção:

* Teste em um grupo piloto;
* Utilize grupos dedicados para atribuição;
* Documente exceções;
* Evite aplicar simultaneamente scripts de bloqueio e liberação;
* Mantenha um procedimento de rollback;
* Valide o comportamento nas versões do Windows utilizadas pela organização;
* Monitore a execução pelo Intune;
* Utilize o Intune como catálogo corporativo para aplicativos homologados.

---

# 📚 Referências

### Jornada 365

**Bloqueando a Loja de Aplicativos do Windows Pro com Microsoft Intune**

Publicação utilizada como base para a estratégia e scripts apresentados nesta documentação.

### Microsoft Learn

Documentação oficial:

* Configure access to the Microsoft Store app for Windows devices;
* ADMX_WindowsStore Policy CSP;
* Add Microsoft Store apps to Microsoft Intune;
* ApplicationManagement Policy CSP.

---

## 📌 Observação

Este projeto tem finalidade de **documentação técnica e administração de endpoints Windows utilizando Microsoft Intune**.

Antes de aplicar qualquer alteração em ambiente produtivo, realize testes controlados e valide a compatibilidade com as versões e edições do Windows utilizadas na organização.

---

## 👨‍💻 Autor

**André Luiz**

Infraestrutura de TI | Microsoft Intune | Microsoft 365 | Windows | Automação
