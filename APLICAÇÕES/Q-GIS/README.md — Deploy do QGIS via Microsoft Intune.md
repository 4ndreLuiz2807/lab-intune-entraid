# 🗺️ Deploy do QGIS via Microsoft Intune

Este repositório documenta o processo utilizado para realizar o **deploy do QGIS em dispositivos Windows gerenciados pelo Microsoft Intune**.

O instalador utilizado é disponibilizado em formato **MSI** e foi empacotado como **Win32 App (`.intunewin`)**, permitindo a distribuição centralizada através do Intune.

---

## 📌 Visão geral

| Item | Configuração |
|---|---|
| Aplicação | QGIS |
| Plataforma | Windows |
| Gerenciamento | Microsoft Intune |
| Instalador | MSI |
| Pacote para upload | `.intunewin` |
| Tipo no Intune | Aplicativo do Windows (Win32) |
| Arquitetura | 64 bits |
| Contexto de instalação | Sistema |

---

## 📥 1. Download do QGIS

O instalador pode ser obtido através do site oficial do QGIS:

**QGIS Download:**  
https://qgis.org/download/

Para ambientes corporativos, pode ser interessante utilizar uma versão **LTR (Long Term Release)**, priorizando estabilidade e suporte prolongado.

Neste deploy foi utilizado o instalador MSI:

```text
QGIS-OSGeo4W-3.44.13-1.msi
```

> ⚠️ Atenção: no repositório de downloads também existem pacotes como `QGIS-Grids-OSGeo4W`. Eles não correspondem ao instalador principal do QGIS.

---

# 📦 2. Preparação do pacote

Para disponibilizar o QGIS como **Win32 App**, foi utilizada a ferramenta oficial da Microsoft:

**Microsoft Win32 Content Prep Tool**

Repositório:

https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

Baixe o arquivo:

```text
IntuneWinAppUtil.exe
```

---

## 📁 3. Estrutura de diretórios

Exemplo utilizado para preparação:

```text
C:\
├── IntuneWin\
│   └── IntuneWinAppUtil.exe
│
├── QGIS-INTUNE\
│   └── QGIS-OSGeo4W-3.44.13-1.msi
│
└── QGIS-OUTPUT\
```

É recomendado manter somente os arquivos necessários dentro da pasta de origem, pois o `IntuneWinAppUtil` empacota o conteúdo desse diretório.

---

# ⚙️ 4. Gerando o `.intunewin`

Abra o PowerShell ou Prompt de Comando e acesse a pasta da ferramenta:

```powershell
cd C:\IntuneWin
```

Execute:

```powershell
.\IntuneWinAppUtil.exe `
-c "C:\QGIS-INTUNE" `
-s "QGIS-OSGeo4W-3.44.13-1.msi" `
-o "C:\QGIS-OUTPUT"
```

Onde:

| Parâmetro | Função |
|---|---|
| `-c` | Diretório contendo os arquivos de origem |
| `-s` | Arquivo principal de instalação |
| `-o` | Diretório onde será salvo o pacote |
 
Ao finalizar, será criado:

```text
C:\QGIS-OUTPUT\QGIS-OSGeo4W-3.44.13-1.intunewin
```

Este é o arquivo que será enviado ao Microsoft Intune.

---

# ☁️ 5. Criando o aplicativo no Intune

No **Microsoft Intune Admin Center**, acesse:

```text
Aplicativos
└── Windows
    └── Criar
```

Em **Tipo de aplicativo**, selecione:

```text
Aplicativo do Windows (Win32)
```

Clique em **Selecionar**.

---

# 📤 6. Upload do pacote

Em **Arquivo de pacote do aplicativo**, selecione:

```text
QGIS-OSGeo4W-3.44.13-1.intunewin
```

Aguarde o Intune processar o pacote.

Como o arquivo principal utilizado no empacotamento é um **MSI válido**, o Intune consegue extrair automaticamente diversas informações do Windows Installer.

---

# 📝 7. Informações do aplicativo

Após o processamento do pacote, revise as informações apresentadas pelo Intune.

Exemplo:

```text
Nome: QGIS
Fornecedor: QGIS
Categoria: Aplicativos
```

A descrição e demais informações podem ser ajustadas de acordo com o padrão adotado pela organização.

---

# 🔧 8. Programa

Uma vantagem de utilizar o MSI como arquivo principal do pacote Win32 é que o Intune consegue identificar as propriedades do Windows Installer.

Dessa forma, os comandos de **instalação** e **desinstalação** são preenchidos automaticamente pelo Intune.

O comando de instalação normalmente seguirá o padrão:

```cmd
msiexec /i "{ProductCode}" /qn
```

E a desinstalação:

```cmd
msiexec /x "{ProductCode}" /qn
```

> **Não é necessário criar scripts de instalação e desinstalação para este cenário**, desde que o MSI seja corretamente reconhecido pelo Intune.

Antes de finalizar a aplicação, valide os comandos preenchidos automaticamente no portal.

### Comportamento de instalação

Configure:

```text
Comportamento de instalação: Sistema
```

Isso permite que a instalação seja executada pelo **Intune Management Extension em contexto SYSTEM**, sem depender de privilégios administrativos do usuário.

---

# 💻 9. Requisitos

Configure os requisitos de acordo com o ambiente.

Exemplo:

```text
Arquitetura do sistema operacional:
☑ 64 bits

Sistema operacional mínimo:
Windows 10 22H2
```

A versão mínima pode ser alterada de acordo com o parque de dispositivos da organização.

---

# 🔎 10. Regra de detecção

Como o pacote foi criado utilizando diretamente um **MSI**, o Intune pode identificar o **ProductCode** e criar a regra de detecção baseada no Windows Installer.

Exemplo:

```text
Tipo de regra:
MSI

Código do produto:
{PRODUCT-CODE-IDENTIFICADO-PELO-INTUNE}
```

Quando disponível, também é possível utilizar a verificação de versão do produto.

Isso permite ao Intune determinar se o QGIS já está instalado no dispositivo antes de executar novamente o deployment.

---

# 🔗 11. Dependências

Caso não existam dependências adicionais para o pacote utilizado:

```text
Dependências:
Nenhuma
```

Se futuramente forem adicionados componentes externos obrigatórios, eles podem ser configurados nesta etapa.

---

# 🔄 12. Supersedência

Caso não exista uma versão anterior do QGIS publicada no ambiente:

```text
Supersedência:
Nenhuma
```

Para atualizações futuras, a supersedência pode ser utilizada para substituir versões anteriores do QGIS.

Exemplo:

```text
QGIS 3.44.x
      ↓
QGIS nova versão
      ↓
Supersedência
      ↓
Atualização dos dispositivos
```

---

# 👥 13. Atribuições

Defina os grupos que receberão o aplicativo.

O aplicativo pode ser disponibilizado como:

### Obrigatório

O QGIS será instalado automaticamente nos dispositivos ou usuários pertencentes ao grupo.

```text
Atribuições
└── Obrigatório
    └── Grupo de dispositivos/usuários
```

### Disponível

O QGIS ficará disponível para instalação através do **Portal da Empresa**.

```text
Atribuições
└── Disponível para dispositivos registrados
    └── Grupo de usuários
```

A estratégia deve ser definida conforme a necessidade da organização.

---

# 🚀 14. Fluxo completo do deploy

```text
Download do MSI oficial
        │
        ▼
QGIS-OSGeo4W-3.44.13-1.msi
        │
        ▼
Microsoft Win32 Content Prep Tool
        │
        ▼
QGIS-OSGeo4W-3.44.13-1.intunewin
        │
        ▼
Microsoft Intune
        │
        ├── Aplicativo Win32
        ├── Comandos MSI automáticos
        ├── Requisitos
        ├── Detecção MSI
        └── Atribuições
        │
        ▼
Intune Management Extension
        │
        ▼
Dispositivo Windows
        │
        ▼
QGIS instalado
```

---

# 🛠️ 15. Troubleshooting

Durante o acompanhamento do deployment, os principais logs do **Intune Management Extension** podem ser encontrados em:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Arquivos importantes:

```text
IntuneManagementExtension.log
AppWorkload.log
AppActionProcessor.log
AgentExecutor.log
```

Para acompanhar o log principal em tempo real:

```powershell
Get-Content "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Wait
```

Também é possível verificar no portal:

```text
Intune
→ Aplicativos
→ Windows
→ QGIS
→ Monitorar
→ Status de instalação do dispositivo
```

---

# ⚠️ Problema encontrado durante a implementação

Inicialmente foi utilizado um arquivo MSI que apresentava erro durante o processamento pelo Intune:

```text
O pacote do aplicativo selecionado parece não ter um
ProductCode ou ProductVersion.
```

Ao tentar processar o mesmo arquivo através do `IntuneWinAppUtil`, também era apresentado:

```text
The specified Windows Installer file could not be opened.
Verify the file is a valid Windows Installer file.
```

O Windows Installer não conseguia abrir corretamente o banco de dados MSI.

A solução foi utilizar um **MSI válido obtido através da distribuição oficial do QGIS** e realizar novamente o empacotamento com o `IntuneWinAppUtil`.

Após a substituição do instalador:

```text
MSI válido
    ↓
IntuneWinAppUtil
    ↓
.intunewin
    ↓
Upload como Win32 App
    ↓
MSI reconhecido pelo Intune
    ↓
Deploy
```

---

# ✅ Resultado

Com o pacote publicado como **Win32 App**, o QGIS pode ser distribuído de forma centralizada para os dispositivos Windows gerenciados.

O uso do MSI como instalador principal também simplifica o deployment, pois permite que o Intune obtenha automaticamente informações importantes do pacote, incluindo os comandos de instalação/desinstalação e dados utilizados para detecção.

---

## 🔗 Referências

**QGIS**

https://qgis.org/

**Download do QGIS**

https://qgis.org/download/

**Microsoft Win32 Content Prep Tool**

https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

**Microsoft Intune — Win32 Apps**

https://learn.microsoft.com/mem/intune/apps/apps-win32-app-management

---

## 👨‍💻 Autor

**André Luiz**

Projeto desenvolvido para documentação e estudo de **Microsoft Intune, gerenciamento de endpoints e automação de deployments de aplicações Windows**.