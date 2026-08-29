<img src="https://raw.githubusercontent.com/4ndreLuiz2807/lab-intune-entraid/refs/heads/main/APLICA%C3%87%C3%95ES/MOZILLA%20FIREFOX/banner_firefox_intune.svg" width="100%" />

Documentação para implantação do **Mozilla Firefox** em dispositivos Windows gerenciados pelo **Microsoft Intune**, utilizando o instalador oficial **MSI Enterprise** disponibilizado pela Mozilla.

O objetivo é realizar uma implantação simples e centralizada, sem necessidade de converter o instalador `.exe` ou criar um pacote `.intunewin`.

---

## 📋 Visão geral

A Mozilla disponibiliza oficialmente versões corporativas do Firefox em formato **MSI**, facilitando a distribuição do navegador através de ferramentas de gerenciamento como o Microsoft Intune.

Neste cenário será utilizado:

* Mozilla Firefox
* Windows 64 bits
* Instalador MSI
* Microsoft Intune
* Aplicativo do tipo **Line-of-business app**

---

## 📥 1. Download do Firefox Enterprise

Acesse o portal oficial do Firefox Enterprise:

https://www.firefox.com/pt-BR/browsers/enterprise/

Na seção de downloads para **Windows**, selecione:

```text
Firefox (latest) — MSI
```

Para ambientes corporativos que utilizam a versão ESR, também está disponível:

```text
Firefox ESR — MSI
```

### Firefox comum ou ESR?

| Versão      | Indicação                                                                             |
| ----------- | ------------------------------------------------------------------------------------- |
| Firefox     | Ambientes que desejam receber novos recursos mais rapidamente                         |
| Firefox ESR | Ambientes corporativos que priorizam estabilidade e ciclos de atualização mais longos |

Para este procedimento será utilizado o instalador **MSI 64 bits**.

---

## 📦 2. Arquivo utilizado

Após realizar o download, teremos um arquivo semelhante a:

```text
Firefox Setup x.x.x.msi
```

Exemplo de estrutura:

```text
Firefox/
│
└── Firefox Setup x.x.x.msi
```

Como a Mozilla já fornece oficialmente o instalador em formato `.msi`, não é necessário extrair o MSI do instalador EXE.

Também não é necessário utilizar o **Microsoft Win32 Content Prep Tool** para gerar um `.intunewin` neste cenário.

---

## ☁️ 3. Adicionar o Firefox ao Microsoft Intune

Acesse o **Microsoft Intune Admin Center**.

Navegue até:

```text
Apps
└── Windows
    └── Add
```

Em **App type**, selecione:

```text
Line-of-business app
```

Clique em:

```text
Select
```

---

## 📂 4. Selecionar o MSI

Em **App package file**, selecione o arquivo MSI baixado anteriormente.

Exemplo:

```text
Firefox Setup x.x.x.msi
```

O Intune fará a leitura das informações presentes no pacote MSI.

---

## ⚙️ 5. Informações do aplicativo

Revise as informações identificadas pelo Intune.

Sugestão:

```text
Name:
Mozilla Firefox

Description:
Mozilla Firefox - Navegador corporativo distribuído através do Microsoft Intune.

Publisher:
Mozilla

Category:
Productivity

Show this as a featured app in the Company Portal:
No
```

As informações podem ser adaptadas conforme o padrão utilizado pela organização.

---

## 💻 6. Arquitetura

Para ambientes modernos com Windows 10 e Windows 11, normalmente será utilizado:

```text
64-bit
```

Certifique-se de baixar a arquitetura correspondente no portal Enterprise da Mozilla.

---

## 👥 7. Atribuição

Na etapa **Assignments**, defina quais usuários ou dispositivos receberão o Firefox.

Exemplo:

```text
Required
    └── GRP-APP-FIREFOX
```

Utilizar um grupo específico para o aplicativo permite realizar uma implantação controlada antes de disponibilizá-lo para toda a organização.

Uma estratégia possível:

```text
GRP-APP-FIREFOX-PILOTO
        ↓
Testes

GRP-APP-FIREFOX
        ↓
Produção
```

---

## 🚀 8. Criar o aplicativo

Após revisar as configurações:

```text
Review + create
```

Clique em:

```text
Create
```

O Intune realizará o upload do MSI e disponibilizará o aplicativo para os grupos configurados.

---

## 🔄 9. Forçar sincronização no computador

Para acelerar os testes, é possível solicitar uma sincronização manual no dispositivo.

No Windows:

```text
Configurações
→ Contas
→ Acessar trabalho ou escola
→ Conta corporativa
→ Informações
→ Sincronizar
```

Também é possível iniciar a sincronização através do **Company Portal**.

---

## 🔎 10. Validar a instalação

Após a implantação, podemos verificar se o Firefox foi instalado.

### PowerShell

```powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" ,
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -like "*Mozilla Firefox*"
} |
Select-Object DisplayName, DisplayVersion, Publisher
```

Resultado esperado:

```text
DisplayName       DisplayVersion    Publisher
-----------       --------------    ---------
Mozilla Firefox   x.x.x             Mozilla
```

---

## 📁 11. Validar o executável

Também podemos validar diretamente o executável:

```powershell
Test-Path "C:\Program Files\Mozilla Firefox\firefox.exe"
```

Resultado esperado:

```text
True
```

Para verificar a versão:

```powershell
(Get-Item "C:\Program Files\Mozilla Firefox\firefox.exe").VersionInfo |
Select-Object ProductVersion, FileVersion
```

---

## 🛠️ Troubleshooting

Caso o aplicativo não seja instalado, verifique inicialmente o status no:

```text
Intune Admin Center
→ Apps
→ Windows
→ Mozilla Firefox
→ Device install status
```

Também valide se:

* O dispositivo está corretamente registrado no Intune;
* O usuário/dispositivo pertence ao grupo de atribuição;
* O dispositivo realizou sincronização recentemente;
* A arquitetura do MSI está correta;
* Não existe uma instalação anterior causando conflito.

---

## 🔄 Firefox ESR

Para ambientes que priorizam estabilidade, a Mozilla também disponibiliza oficialmente o:

```text
Firefox Extended Support Release (ESR)
```

Inclusive em formato:

```text
Firefox ESR — MSI
```

A implantação pelo Intune pode seguir praticamente o mesmo procedimento descrito nesta documentação.

---

## 🔐 Gerenciamento corporativo

Além da implantação do navegador, o Firefox possui suporte a políticas corporativas.

Isso permite posteriormente controlar configurações como:

```text
Homepage
Proxy
Extensions
Updates
Password Manager
Telemetry
Certificates
Firefox Accounts
DNS over HTTPS
```

Em ambientes Active Directory também podem ser utilizados **templates ADMX** disponibilizados pela Mozilla.

Isso permite transformar o Firefox de apenas um aplicativo instalado pelo Intune em um navegador efetivamente gerenciado pela organização.

---

## 📚 Referências

### Firefox Enterprise

https://www.firefox.com/pt-BR/browsers/enterprise/

Na página oficial estão disponíveis:

* Firefox Enterprise
* Firefox MSI
* Firefox ESR
* Firefox ESR MSI
* Templates de políticas
* Documentação Enterprise

---

## ✅ Resultado

Ao final do processo teremos:

```text
Mozilla Firefox
      │
      ▼
MSI oficial Mozilla
      │
      ▼
Microsoft Intune
      │
      ▼
Grupo de atribuição
      │
      ▼
Dispositivos Windows
      │
      ▼
Firefox instalado
```

Dessa forma, o Firefox pode ser distribuído de maneira centralizada para os dispositivos gerenciados, utilizando diretamente o pacote MSI fornecido pela Mozilla.

---

## 👨‍💻 Autor

**André Luiz**

Infraestrutura de TI | Microsoft Intune | Microsoft Entra ID | Automação | Endpoint Management
