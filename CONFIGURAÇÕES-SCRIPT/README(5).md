# OneDrive KFM via Microsoft Intune

Implementação corporativa do **OneDrive Known Folder Move (KFM)** com **Microsoft Intune**, incluindo proteção de pastas conhecidas do Windows, **Files On-Demand**, **login silencioso do OneDrive** e estratégia para migração de dados legados fora das pastas padrão.

---

## Visão geral

O **Known Folder Move (KFM)** permite redirecionar automaticamente as pastas padrão do Windows para o **OneDrive corporativo**, protegendo os dados do usuário e facilitando:

- backup automático;
- recuperação após formatação;
- troca de equipamento;
- integração com **Windows Autopilot**;
- redução de perda de dados;
- padronização do ambiente.

Pastas normalmente protegidas:

- **Desktop**
- **Documents**
- **Pictures**

---

## Índice

- [1. Objetivo](#1-objetivo)
- [2. Escopo](#2-escopo)
- [3. Arquitetura](#3-arquitetura)
- [4. Pré-requisitos](#4-pré-requisitos)
- [5. Estrutura sugerida do repositório](#5-estrutura-sugerida-do-repositório)
- [6. Implementação do KFM no Intune](#6-implementação-do-kfm-no-intune)
- [7. Configurações recomendadas](#7-configurações-recomendadas)
- [8. Validação pós-implantação](#8-validação-pós-implantação)
- [9. Migração de arquivos fora das pastas padrão](#9-migração-de-arquivos-fora-das-pastas-padrão)
- [10. Scripts de exemplo](#10-scripts-de-exemplo)
- [11. Boas práticas](#11-boas-práticas)
- [12. Cenários com computadores compartilhados](#12-cenários-com-computadores-compartilhados)
- [13. Troubleshooting](#13-troubleshooting)
- [14. Checklist de implantação](#14-checklist-de-implantação)
- [15. Conclusão](#15-conclusão)

---

## 1. Objetivo

Padronizar a implementação do **OneDrive KFM** em dispositivos Windows gerenciados pelo **Microsoft Intune**, garantindo que os dados principais do usuário sejam automaticamente protegidos no OneDrive corporativo.

Além disso, esta documentação também cobre uma abordagem segura para **migrar arquivos que estejam fora das pastas padrão do KFM**, como:

- `C:\Relatorios`
- `C:\Projetos`
- `C:\Bioaroeira`
- outras estruturas legadas

---

## 2. Escopo

Esta documentação cobre:

- configuração do **OneDrive KFM**;
- configuração de **login silencioso**;
- habilitação de **Files On-Demand**;
- bloqueio de reversão do KFM pelo usuário;
- prevenção de sincronização de **OneDrive pessoal**;
- migração de dados legados com **PowerShell**;
- uso opcional de **Intune Remediations**.

---

## 3. Arquitetura

### Fluxo básico

```text
Windows
   │
   ├── Desktop
   ├── Documents
   └── Pictures
           │
           ↓
       OneDrive
           │
           ↓
   Microsoft 365 Cloud
```

### Fluxo com Intune

```text
Microsoft Intune
       │
       ↓
Configuration Profile
       │
       ↓
OneDrive Policies
       │
       ├── Silent Sign-In
       ├── Known Folder Move
       ├── Files On-Demand
       └── Prevent KFM Opt-Out
```

### Fluxo com migração de dados legados

```text
Dados legados
(C:\Relatorios / C:\Projetos / C:\Bioaroeira)
           │
           ↓
      Script PowerShell
           │
           ↓
Documents (OneDrive)
           │
           ↓
      Sincronização
           │
           ↓
Microsoft 365
```

---

## 4. Pré-requisitos

Antes da implantação, valide:

- [ ] Microsoft Intune ativo
- [ ] Licença compatível do Microsoft 365
- [ ] OneDrive instalado no dispositivo
- [ ] Usuários com conta corporativa Microsoft Entra ID
- [ ] Dispositivos ingressados no Entra ID ou híbridos
- [ ] Tenant ID disponível
- [ ] Conectividade com Microsoft 365
- [ ] Grupo piloto definido para testes

Cenários suportados:

- **Microsoft Entra Joined**
- **Microsoft Entra Hybrid Joined**

---

## 5. Estrutura sugerida do repositório

```text
onedrive-kfm-intune/
│
├── README.md
├── docs/
│   ├── arquitetura.md
│   ├── troubleshooting.md
│   └── validacoes.md
│
├── scripts/
│   ├── detection/
│   │   └── Detect-BioaroeiraFolder.ps1
│   │
│   ├── remediation/
│   │   └── Migrate-BioaroeiraFolder.ps1
│   │
│   └── examples/
│       ├── Migrate-Relatorios.ps1
│       └── Migrate-Projetos.ps1
│
└── images/
    ├── architecture.png
    └── flow-kfm.png
```

---

## 6. Implementação do KFM no Intune

### 6.1 Criar a política

No **Microsoft Intune Admin Center**:

```text
Devices
   ↓
Configuration
   ↓
Create
   ↓
New policy
```

Configuração:

```text
Platform: Windows 10 and later
Profile type: Settings catalog
```

### 6.2 Nome sugerido da política

```text
WIN - OneDrive - KFM Corporativo
```

### 6.3 Descrição sugerida

```text
Configuração corporativa do OneDrive responsável por login silencioso,
Known Folder Move, Files On-Demand e proteção das pastas conhecidas do Windows.
```

---

## 7. Configurações recomendadas

Dentro da política, em:

```text
Configuration settings
   ↓
Add settings
```

Pesquise por:

```text
OneDrive
```

### 7.1 Login silencioso do OneDrive

Habilitar:

```text
Silently sign in users to the OneDrive sync app with their Windows credentials
```

Valor:

```text
Enabled
```

---

### 7.2 Known Folder Move

Habilitar:

```text
Silently move Windows known folders to OneDrive
```

Valor:

```text
Enabled
```

Configurar:

- **Desktop = Enabled**
- **Documents = Enabled**
- **Pictures = Enabled**
- **Tenant ID = <SEU-TENANT-ID>**

---

### 7.3 Bloquear reversão do KFM

Habilitar:

```text
Prevent users from redirecting their Windows known folders to their PC
```

Valor:

```text
Enabled
```

---

### 7.4 Files On-Demand

Habilitar:

```text
Use OneDrive Files On-Demand
```

Valor:

```text
Enabled
```

---

### 7.5 Bloquear OneDrive pessoal

Habilitar:

```text
Prevent users from syncing personal OneDrive accounts
```

Valor:

```text
Enabled
```

---

### 7.6 Grupo piloto

Sugestão de grupo:

```text
GRP-INTUNE-PILOT-ONEDRIVE-KFM
```

Atribuir inicialmente apenas para o grupo piloto.

---

## 8. Validação pós-implantação

### 8.1 Verificar caminho das pastas conhecidas

#### Desktop

```powershell
[Environment]::GetFolderPath("Desktop")
```

#### Documents

```powershell
[Environment]::GetFolderPath("MyDocuments")
```

#### Pictures

```powershell
[Environment]::GetFolderPath("MyPictures")
```

Resultado esperado:

```text
C:\Users\usuario\OneDrive - Empresa\Desktop
C:\Users\usuario\OneDrive - Empresa\Documents
C:\Users\usuario\OneDrive - Empresa\Pictures
```

---

### 8.2 Verificar caminho do OneDrive comercial

```powershell
$env:OneDriveCommercial
```

Exemplo:

```text
C:\Users\usuario\OneDrive - Empresa
```

---

### 8.3 Verificar se o processo do OneDrive está em execução

```powershell
Get-Process OneDrive -ErrorAction SilentlyContinue
```

---

### 8.4 Verificar políticas no registro

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -ErrorAction SilentlyContinue
```

---

### 8.5 Forçar sincronização do Intune

No Windows:

```text
Settings
   ↓
Accounts
   ↓
Access work or school
   ↓
Conta corporativa
   ↓
Info
   ↓
Sync
```

Ou:

```text
Company Portal
   ↓
Settings
   ↓
Sync
```

---

## 9. Migração de arquivos fora das pastas padrão

O **KFM não sincroniza qualquer pasta personalizada do disco**.

Ele cobre principalmente:

- Desktop
- Documents
- Pictures

### Exemplo de limitação

O KFM **não** permite apontar diretamente para:

```text
C:\Relatorios
C:\Projetos
C:\Dados
C:\Downloads
C:\SAP
```

### Estratégia recomendada

Migrar os dados para dentro de uma estrutura suportada, por exemplo:

```text
OneDrive - Empresa
└── Documents
    └── Bioaroeira
        ├── Relatorios
        ├── Projetos
        ├── Planilhas
        └── Exportacoes
```

---

## 10. Scripts de exemplo

### 10.1 Exemplo simples — migrar `C:\Relatorios`

```powershell
$Origem = "C:\Relatorios"
$Documentos = [Environment]::GetFolderPath("MyDocuments")
$Destino = Join-Path $Documentos "Relatorios"

if (Test-Path $Origem) {

    if (!(Test-Path $Destino)) {
        New-Item -Path $Destino -ItemType Directory -Force | Out-Null
    }

    robocopy $Origem $Destino /E /COPY:DAT /DCOPY:DAT /R:2 /W:2
}
```

---

### 10.2 Exemplo corporativo — migrar `C:\Bioaroeira`

```powershell
$Origem = "C:\Bioaroeira"
$Documentos = [Environment]::GetFolderPath("MyDocuments")
$Destino = Join-Path $Documentos "Bioaroeira"

if (Test-Path $Origem) {

    if (!(Test-Path $Destino)) {
        New-Item -Path $Destino -ItemType Directory -Force | Out-Null
    }

    robocopy `
        $Origem `
        $Destino `
        /E `
        /COPY:DAT `
        /DCOPY:DAT `
        /R:2 `
        /W:2
}
```

---

### 10.3 Detection Script para Intune Remediation

```powershell
$Origem = "C:\Bioaroeira"

if (Test-Path $Origem) {
    Write-Output "Pasta encontrada. Migração necessária."
    exit 1
}
else {
    Write-Output "Pasta não encontrada."
    exit 0
}
```

---

### 10.4 Remediation Script para Intune

```powershell
$Origem = "C:\Bioaroeira"
$Documentos = [Environment]::GetFolderPath("MyDocuments")
$Destino = Join-Path $Documentos "Bioaroeira"

if (!(Test-Path $Origem)) {
    Write-Output "Nenhuma pasta encontrada."
    exit 0
}

if (!(Test-Path $Destino)) {
    New-Item -Path $Destino -ItemType Directory -Force | Out-Null
}

robocopy `
    $Origem `
    $Destino `
    /E `
    /COPY:DAT `
    /DCOPY:DAT `
    /R:2 `
    /W:2

$Resultado = $LASTEXITCODE

if ($Resultado -le 7) {
    Write-Output "Migração realizada com sucesso."
    exit 0
}
else {
    Write-Output "Erro Robocopy: $Resultado"
    exit 1
}
```

---

## 11. Boas práticas

1. **Comece com grupo piloto**.
2. **Copie antes de excluir**.
3. Use **Files On-Demand**.
4. Evite sincronizar **Downloads** automaticamente.
5. Não migre diretórios de sistema.
6. Não use **junctions** ou **links simbólicos** para forçar sincronização.
7. Monitore espaço em disco.
8. Documente exceções e cenários especiais.
9. Use **Storage Sense** quando aplicável.
10. Faça validação com usuário piloto antes da expansão em massa.

---

## 12. Cenários com computadores compartilhados

Em computadores compartilhados, tenha cuidado com KFM, pois múltiplos perfis podem gerar múltiplas estruturas de OneDrive no mesmo dispositivo.

Exemplo:

```text
C:\Users\UsuarioA\OneDrive - Empresa
C:\Users\UsuarioB\OneDrive - Empresa
C:\Users\UsuarioC\OneDrive - Empresa
```

### Recomendação para Shared PC

Combinar:

- **Shared PC Mode**
- **OneDrive Files On-Demand**
- **Storage Sense**
- **limpeza automática de perfis**

---

## 13. Troubleshooting

### Problema: OneDrive não entra automaticamente

Verificar:

- usuário autenticado no Windows com conta corporativa;
- OneDrive instalado e atualizado;
- política aplicada corretamente;
- conectividade com Microsoft 365.

### Problema: pastas continuam locais

Verificar:

- política realmente atribuída ao usuário/dispositivo;
- sincronização do Intune;
- caminho retornado por `GetFolderPath`;
- processo do OneDrive em execução.

### Problema: arquivos legados não migraram

Verificar:

- existência da pasta de origem;
- permissões de acesso;
- resultado do `robocopy`;
- código de saída do script.

### Problema: consumo alto de disco

Verificar:

- Files On-Demand habilitado;
- múltiplos perfis locais;
- volume de arquivos sincronizados;
- se o dispositivo é compartilhado.

---

## 14. Checklist de implantação

### Planejamento

- [ ] Identificar Tenant ID
- [ ] Validar licenças
- [ ] Confirmar OneDrive instalado
- [ ] Criar grupo piloto

### Política Intune

- [ ] Criar política KFM
- [ ] Habilitar Silent Sign-In
- [ ] Habilitar Desktop
- [ ] Habilitar Documents
- [ ] Habilitar Pictures
- [ ] Habilitar Files On-Demand
- [ ] Bloquear reversão do KFM
- [ ] Bloquear OneDrive pessoal

### Validação

- [ ] Forçar sync do Intune
- [ ] Validar caminhos com PowerShell
- [ ] Validar sincronização no OneDrive
- [ ] Validar processo `OneDrive.exe`

### Dados legados

- [ ] Identificar pastas fora do padrão
- [ ] Criar scripts de migração
- [ ] Testar Remediation
- [ ] Validar dados no destino
- [ ] Só depois avaliar exclusão da origem

### Expansão

- [ ] Validar piloto
- [ ] Ajustar exceções
- [ ] Expandir gradualmente

---

## 15. Conclusão

A combinação abaixo representa um cenário moderno para ambientes corporativos Windows:

```text
Intune
+
OneDrive KFM
+
Files On-Demand
+
Silent Sign-In
+
Remediations
+
Storage Sense
```

Use o **KFM** para proteger:

- Desktop
- Documents
- Pictures

E utilize **PowerShell + Intune Remediations** para migrar dados legados que estejam fora do escopo padrão do OneDrive.

---

## Autor

**André Luiz**

Documentação técnica sobre **Microsoft Intune**, **OneDrive**, gerenciamento moderno de dispositivos e automação de ambientes Windows.
