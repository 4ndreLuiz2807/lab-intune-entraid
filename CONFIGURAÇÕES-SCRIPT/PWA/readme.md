
# Deploy de Aplicações Web (PWA) com Microsoft Intune e Microsoft Edge

## Visão geral

Este documento descreve como distribuir aplicações Web/PWA de forma silenciosa em dispositivos Windows gerenciados pelo **Microsoft Intune**, utilizando a política do **Microsoft Edge `WebAppInstallForceList`**.

O objetivo é permitir que sistemas Web corporativos — por exemplo **SAP Web, TOTVS, Power BI, portais internos e outros sistemas acessados pelo navegador** — sejam instalados como aplicativos do Edge, sem depender de instalação manual pelo usuário.

> **Importante:** os parâmetros utilizados no JSON pertencem à política do Microsoft Edge. Eles não são parâmetros específicos de cada site/PWA.  
> Normalmente, para cadastrar uma nova aplicação, basta alterar a URL e, opcionalmente, o nome e o ícone.

---

## Sumário

- [1. Pré-requisitos](#1-pré-requisitos)
- [2. Política utilizada](#2-política-utilizada)
- [3. Criando o perfil no Intune](#3-criando-o-perfil-no-intune)
- [4. Configuração recomendada](#4-configuração-recomendada)
- [5. Exemplos](#5-exemplos)
- [6. Parâmetros disponíveis](#6-parâmetros-disponíveis)
- [7. Atribuição da política](#7-atribuição-da-política)
- [8. Sincronização e validação](#8-sincronização-e-validação)
- [9. Solução de problemas](#9-solução-de-problemas)
- [10. Remoção ou alteração](#10-remoção-ou-alteração)
- [11. Modelo padrão para novos PWAs](#11-modelo-padrão-para-novos-pwas)
- [12. Referências](#12-referências)

---

# 1. Pré-requisitos

Antes de iniciar, valide:

- Dispositivo Windows gerenciado pelo Microsoft Intune.
- Microsoft Edge instalado e atualizado.
- Dispositivo recebendo políticas do Intune.
- URL do sistema acessível pelo computador.
- Site utilizando `HTTPS`, preferencialmente.
- Permissão administrativa no Microsoft Intune.
- Grupo de dispositivos definido para receber a configuração.

---

# 2. Política utilizada

A política utilizada é:

```text
WebAppInstallForceList
```

Nome apresentado no catálogo do Intune:

```text
Configure list of force-installed Web Apps
```

No Catálogo de Configurações, o campo pode aparecer como:

```text
URLs for Web Apps to be silently installed. (Device)
```

Essa política permite instalar aplicações Web silenciosamente pelo Microsoft Edge.

O Microsoft Edge exige que o valor enviado seja uma **lista JSON**, mesmo quando apenas uma aplicação será instalada.

---

# 3. Criando o perfil no Intune

Acesse:

```text
Microsoft Intune Admin Center
    ↓
Devices
    ↓
Windows
    ↓
Configuration
    ↓
Create
    ↓
New policy
```

Selecione:

```text
Platform:
Windows 10 and later

Profile type:
Settings catalog
```

Exemplo de nome:

```text
CFG - SAP WEB (PWA)
```

Depois selecione:

```text
Add settings
    ↓
Microsoft Edge
    ↓
Configure list of force-installed Web Apps
```

Habilite:

```text
Configure list of force-installed Web Apps = Enabled
```

---

# 4. Configuração recomendada

Para uma aplicação Web corporativa, um modelo simples e reutilizável é:

```json
[
  {
    "url": "https://SEU-SISTEMA/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true
  }
]
```

Esse modelo:

- instala a aplicação Web silenciosamente;
- abre o sistema em uma janela separada do navegador;
- cria um atalho na Área de Trabalho;
- pode ser reutilizado para diferentes sistemas alterando principalmente a URL.

### Versão compacta

Caso o campo do Intune seja exibido em apenas uma linha:

```json
[{"url":"https://SEU-SISTEMA/","default_launch_container":"window","create_desktop_shortcut":true}]
```

---

# 5. Exemplos

## 5.1 Mercado Livre — ambiente de teste

URL limpa:

```text
https://www.mercadolivre.com.br/
```

Evite URLs com parâmetros temporários ou de rastreamento, por exemplo:

```text
https://www.mercadolivre.com.br/?msockid=XXXXXXXX
```

Configuração:

```json
[
  {
    "url": "https://www.mercadolivre.com.br/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true
  }
]
```

---

## 5.2 SAP Web

Exemplo:

```json
[
  {
    "url": "https://URL-DO-SAP/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true,
    "custom_name": "SAP Web"
  }
]
```

Substitua:

```text
https://URL-DO-SAP/
```

pela URL utilizada pelos usuários para acessar o sistema.

---

## 5.3 Power BI

```json
[
  {
    "url": "https://app.powerbi.com/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true,
    "custom_name": "Power BI"
  }
]
```

---

## 5.4 Microsoft 365

```json
[
  {
    "url": "https://www.microsoft365.com/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true,
    "custom_name": "Microsoft 365"
  }
]
```

---

## 5.5 Várias aplicações na mesma política

Também é possível adicionar vários Web Apps na mesma lista:

```json
[
  {
    "url": "https://sistema1.contoso.com/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true,
    "custom_name": "Sistema 1"
  },
  {
    "url": "https://sistema2.contoso.com/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true,
    "custom_name": "Sistema 2"
  },
  {
    "url": "https://app.powerbi.com/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true,
    "custom_name": "Power BI"
  }
]
```

Para facilitar troubleshooting e atribuições diferentes, em ambientes corporativos pode ser mais organizado manter um perfil por aplicação ou por conjunto lógico de aplicações.

Exemplo:

```text
CFG - PWA - SAP
CFG - PWA - Power BI
CFG - PWA - Portal RH
CFG - PWA - TOTVS
```

---

# 6. Parâmetros disponíveis

## `url`

Obrigatório.

Define o endereço da aplicação Web.

Exemplo:

```json
"url": "https://app.contoso.com/"
```

---

## `default_launch_container`

Opcional.

Define como a aplicação será aberta.

Para abrir em janela própria:

```json
"default_launch_container": "window"
```

Também é possível utilizar:

```json
"default_launch_container": "tab"
```

Para experiência semelhante a um aplicativo instalado, recomenda-se:

```text
window
```

---

## `create_desktop_shortcut`

Opcional.

Cria um atalho na Área de Trabalho do Windows.

```json
"create_desktop_shortcut": true
```

---

## `custom_name`

Opcional.

Permite definir um nome personalizado para o aplicativo.

```json
"custom_name": "SAP Web"
```

Disponível em versões modernas do Microsoft Edge.

---

## `fallback_app_name`

Opcional.

Pode ser utilizado como nome alternativo quando o site não fornece adequadamente um nome de aplicação ou quando determinadas condições impedem a obtenção imediata dos metadados.

```json
"fallback_app_name": "SAP Web"
```

Se `custom_name` e `fallback_app_name` forem utilizados juntos, o Edge prioriza `custom_name`.

---

## `custom_icon`

Opcional.

Permite substituir o ícone da aplicação.

Exemplo:

```json
"custom_icon": {
  "url": "https://servidor.contoso.com/icones/sap.png",
  "hash": "HASH_SHA256_DO_ARQUIVO"
}
```

Requisitos indicados pela Microsoft incluem:

- imagem quadrada;
- tamanho máximo de 1 MB;
- formatos suportados como PNG, JPEG, GIF, WEBP ou ICO;
- URL do ícone acessível sem autenticação;
- hash SHA256 correspondente ao arquivo.

Exemplo completo:

```json
[
  {
    "url": "https://sap.contoso.com/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true,
    "custom_name": "SAP Web",
    "custom_icon": {
      "url": "https://servidor.contoso.com/icons/sap.png",
      "hash": "HASH_SHA256"
    }
  }
]
```

Para gerar o SHA256 de um arquivo no PowerShell:

```powershell
Get-FileHash "C:\Temp\sap.png" -Algorithm SHA256
```

---

# 7. Atribuição da política

No perfil criado no Intune, acesse:

```text
Assignments
```

Para o cenário de instalação corporativa em computadores específicos, recomenda-se atribuir a política a um:

```text
Grupo de dispositivos
```

Exemplo:

```text
GRP-DEV-PWA-SAP
```

Fluxo:

```text
Dispositivo entra no grupo
        ↓
Intune entrega a configuração
        ↓
Microsoft Edge recebe WebAppInstallForceList
        ↓
Edge processa a política no perfil
        ↓
Aplicação Web é instalada
```

> Na tela utilizada neste procedimento, o parâmetro aparece explicitamente como `(Device)`.  
> A aplicação Web é gerenciada pelo Edge e sua instalação é refletida no contexto/perfil do navegador do usuário.

---

# 8. Sincronização e validação

## 8.1 Sincronizar pelo Intune

No dispositivo:

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

Também é possível executar uma sincronização pelo portal do Intune.

---

## 8.2 Validar a política no Edge

Abra:

```text
edge://policy
```

Clique em:

```text
Reload policies
```

ou:

```text
Recarregar políticas
```

Procure:

```text
WebAppInstallForceList
```

O resultado esperado é:

```text
Status: OK
```

---

## 8.3 Verificar aplicativos instalados

Abra:

```text
edge://apps
```

A aplicação deverá aparecer na lista de aplicativos gerenciados pelo Edge.

---

## 8.4 Verificar pelo Windows

Pressione:

```text
Win + R
```

Execute:

```text
shell:AppsFolder
```

Procure pelo aplicativo instalado.

Também valide:

- Menu Iniciar;
- Pesquisa do Windows;
- Área de Trabalho, caso `create_desktop_shortcut` esteja habilitado.

---

# 9. Solução de problemas

## Erro: `expected: "list", actual: "string"`

Exemplo observado no `edge://policy`:

```text
Policy type mismatch: expected: "list", actual: "string".
```

### Causa

A política recebeu apenas uma string:

```text
https://www.mercadolivre.com.br/
```

Porém o Edge esperava uma lista JSON.

### Incorreto

```text
https://www.mercadolivre.com.br/
```

### Correto

```json
[
  {
    "url": "https://www.mercadolivre.com.br/"
  }
]
```

Ou:

```json
[{"url":"https://www.mercadolivre.com.br/"}]
```

---

## Intune mostra "Concluído", mas o aplicativo não aparece

O status **Concluído** indica que o Intune processou/aplicou a configuração no dispositivo. Isso não substitui a validação do Edge.

Verifique:

```text
edge://policy
```

Se `WebAppInstallForceList` apresentar:

```text
Erro
```

o Edge rejeitou o valor recebido.

Se apresentar:

```text
OK
```

continue verificando:

```text
edge://apps
```

e:

```text
shell:AppsFolder
```

---

## A política não aparece em `edge://policy`

Verifique:

- atribuição ao grupo correto;
- associação do dispositivo ao Intune;
- status de sincronização;
- se o Microsoft Edge está atualizado;
- se existem conflitos com outros perfis;
- se o dispositivo realmente pertence ao grupo utilizado na atribuição.

---

## O aplicativo aparece, mas não existe atalho no Desktop

Confirme se o JSON contém:

```json
"create_desktop_shortcut": true
```

Exemplo:

```json
[
  {
    "url": "https://app.contoso.com/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true
  }
]
```

---

## O site abre em uma aba normal

Confirme:

```json
"default_launch_container": "window"
```

---

## O nome do aplicativo não ficou correto

Defina:

```json
"custom_name": "Nome do Aplicativo"
```

Exemplo:

```json
[
  {
    "url": "https://sap.contoso.com/",
    "custom_name": "SAP Web",
    "default_launch_container": "window",
    "create_desktop_shortcut": true
  }
]
```

---

## O ícone não ficou correto

Primeiro permita que o Edge utilize o ícone fornecido pelo próprio site.

Caso seja necessário padronizar o ícone corporativamente, utilize `custom_icon` com URL pública/internamente acessível sem autenticação e SHA256 válido.

---

# 10. Remoção ou alteração

A instalação é controlada pela política do Edge.

Para alterar uma aplicação:

1. Edite o JSON no perfil do Intune.
2. Salve a política.
3. Sincronize o dispositivo.
4. Recarregue as políticas em:

```text
edge://policy
```

Para retirar uma aplicação do gerenciamento, remova o respectivo objeto da lista e valide o comportamento no dispositivo após a atualização da política.

> Antes de remover uma aplicação de produção, teste o comportamento em um grupo piloto, especialmente quando usuários dependem dela para acesso a sistemas corporativos.

---

# 11. Modelo padrão para novos PWAs

Para novos sistemas, utilize como base:

```json
[
  {
    "url": "https://URL-DO-SISTEMA/",
    "default_launch_container": "window",
    "create_desktop_shortcut": true,
    "custom_name": "NOME DO SISTEMA"
  }
]
```

Checklist:

```text
[ ] Confirmar URL oficial do sistema
[ ] Remover parâmetros temporários da URL
[ ] Utilizar HTTPS quando disponível
[ ] Definir custom_name, se necessário
[ ] Definir abertura em window
[ ] Criar atalho no Desktop, se desejado
[ ] Atribuir a grupo piloto
[ ] Sincronizar dispositivo
[ ] Validar edge://policy
[ ] Confirmar Status: OK
[ ] Validar edge://apps
[ ] Validar Menu Iniciar / Desktop
[ ] Expandir atribuição para produção
```

---

# 12. Referências

Microsoft Learn — **WebAppInstallForceList**

https://learn.microsoft.com/pt-br/deployedge/microsoft-edge-policies/webappinstallforcelist

Microsoft Edge — páginas úteis para diagnóstico:

```text
edge://policy
edge://apps
```

Windows — pasta de aplicativos:

```text
shell:AppsFolder
```

---

## Resumo rápido

Para a maioria dos sistemas Web corporativos, o padrão pode ser:

```json
[{"url":"https://URL-DO-SISTEMA/","default_launch_container":"window","create_desktop_shortcut":true}]
```

O que normalmente muda entre uma aplicação e outra é apenas:

```text
URL
Nome opcional
Ícone opcional
```

Os parâmetros `default_launch_container`, `create_desktop_shortcut`, `custom_name`, `fallback_app_name` e `custom_icon` são recursos da política do **Microsoft Edge**, e não configurações específicas do SAP, TOTVS, Power BI ou de cada PWA individualmente.
