<img src="https://raw.githubusercontent.com/4ndreLuiz2807/lab-intune-entraid/refs/heads/main/APLICAÇÕES/Google%20Chrome/banner_google_chrome_intune.svg" width="100%" />


# 🌐 Google Chrome — Deploy via Microsoft Intune

Documentação para instalação do **Google Chrome Enterprise** em dispositivos Windows gerenciados pelo **Microsoft Intune**, utilizando o instalador oficial em formato **MSI**.

Como o Google disponibiliza o Chrome Enterprise diretamente em `.msi`, o processo é simples e **não exige scripts de instalação nem preparação manual do instalador**.

---

## 📋 Pré-requisitos

- Acesso ao **Microsoft Intune Admin Center**
- Permissão para adicionar aplicativos
- Dispositivos Windows registrados no Intune
- Instalador **Google Chrome Enterprise `.msi`**

---

## 📥 1. Download do Google Chrome Enterprise

Baixe o instalador através da página oficial do Google Chrome Enterprise:

https://chromeenterprise.google/intl/pt_br/download/?utm_source=adwords&utm_medium=cpc&utm_campaign=2026-h2-dr-paidmed-chromebrowserent&utm_term=pacote+chrome%7Cp&utm_content=GCQN&brand=GCQN&gclsrc=aw.ds&gad_source=1&gad_campaignid=14223660404&gclid=CjwKCAjw7p_UBhBlEiwAhpIs7xAYSdQ-zkH53tOU_jcWqO8sxLyIecPZlc-mPvMVIUD-8Y5QV67S7RoCIM4QAvD_BwE&modal-id=download-chrome

Na página de download, selecione:

```text
Channel: Stable
File type: MSI
Architecture: 64 bit
```

O arquivo baixado será semelhante a:

```text
googlechromestandaloneenterprise64.msi
```

> **Importante:** utilize o pacote **MSI Enterprise**, e não o instalador `.exe` convencional do Google Chrome.

---

## 📦 2. Adicionar o aplicativo no Intune

Acesse:

```text
Microsoft Intune Admin Center
    ↓
Apps
    ↓
Windows
    ↓
Create
```

Em **App type**, selecione:

```text
Line-of-business app
```

Clique em **Select**.

---

## 📂 3. Enviar o MSI

Em **App package file**, selecione:

```text
googlechromestandaloneenterprise64.msi
```

Clique em **OK**.

O Intune fará a leitura das informações existentes no próprio pacote MSI.

---

## ⚙️ 4. Configurar as informações do aplicativo

Revise os campos identificados automaticamente pelo Intune.

Exemplo:

```text
Name:
Google Chrome

Description:
Google Chrome Enterprise - Navegador corporativo

Publisher:
Google LLC

App install context:
Device
```

Para ambiente corporativo, utilize:

```text
App install context: Device
```

Dessa forma, a instalação será realizada no computador independentemente do usuário conectado.

---

## 💻 5. Comandos de instalação

Por utilizar um aplicativo **Line-of-business baseado em MSI**, não é necessário criar scripts PowerShell nem informar manualmente comandos como:

```powershell
msiexec /i googlechromestandaloneenterprise64.msi /qn
```

O Intune utiliza as informações do próprio pacote MSI para realizar a instalação.

Também não é necessário converter o arquivo para `.intunewin` neste método.

---

## 👥 6. Assignments

Em **Assignments**, defina quais usuários ou dispositivos receberão o Google Chrome.

Exemplo:

```text
Required
└── GRP-DEVICES-CHROME
```

Para instalar automaticamente nos computadores, prefira atribuir o aplicativo a um **grupo de dispositivos**.

Também é possível utilizar:

```text
Required
Available for enrolled devices
Uninstall
```

### Required

Instala automaticamente o Chrome nos dispositivos atribuídos.

### Available for enrolled devices

Disponibiliza o Chrome para instalação através do **Company Portal**.

### Uninstall

Remove o aplicativo dos dispositivos pertencentes ao grupo atribuído.

---

## 🚀 7. Criar o aplicativo

Depois de revisar as configurações:

```text
Review + create
    ↓
Create
```

Aguarde o upload e processamento do MSI.

Após isso, o Google Chrome estará disponível para distribuição nos dispositivos definidos em **Assignments**.

---

## 🔄 8. Forçar sincronização no dispositivo

Para acelerar os testes, no Windows acesse:

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

Também é possível iniciar a sincronização pelo **Company Portal**.

---

## 🔎 9. Validar a instalação

Após o deploy, valide se o executável existe:

```powershell
Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

Resultado esperado:

```text
True
```

Para consultar a versão instalada:

```powershell
(Get-Item "C:\Program Files\Google\Chrome\Application\chrome.exe").VersionInfo.ProductVersion
```

Também é possível abrir:

```text
chrome://settings/help
```

para verificar a versão instalada e o status das atualizações.

---

## 📊 10. Acompanhar o deploy pelo Intune

No Intune:

```text
Apps
    ↓
Windows
    ↓
Google Chrome
    ↓
Device install status
```

Os dispositivos poderão aparecer como:

```text
Installed
Failed
Pending
Not installed
```

Para troubleshooting, também consulte:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Principal log:

```text
IntuneManagementExtension.log
```

> Dependendo do tipo de implantação e do fluxo utilizado pelo Intune, os eventos relevantes também podem estar nos logs MDM do Windows.

---

## 📁 Estrutura do projeto

Uma estrutura simples para manter esta documentação no GitHub:

```text
GOOGLE-CHROME/
│
├── README.md
└── banner_chrome_intune.svg
```

O instalador não precisa ser armazenado no repositório. Recomenda-se realizar o download diretamente da página oficial do **Google Chrome Enterprise** sempre que um novo pacote for necessário.

---

## ✅ Resumo

```text
Download Chrome Enterprise MSI
            ↓
Intune Admin Center
            ↓
Apps → Windows → Create
            ↓
Line-of-business app
            ↓
Upload do MSI
            ↓
App install context: Device
            ↓
Assignments
            ↓
Create
            ↓
Deploy
```

### Vantagens deste método

- Instalador oficial do Google
- Pacote MSI pronto para distribuição
- Não necessita script PowerShell
- Não necessita conversão para `.intunewin`
- Instalação silenciosa gerenciada pelo Intune
- Fácil atribuição para grupos de dispositivos
- Atualizações posteriores gerenciadas pelo mecanismo de atualização do Chrome

---

## 🔗 Referências

**Google Chrome Enterprise**

https://chromeenterprise.google/intl/pt_br/download/

**Microsoft Intune**

https://intune.microsoft.com/

---

> Documentação destinada à padronização do deploy do **Google Chrome Enterprise em dispositivos Windows através do Microsoft Intune**.
