# CFG - Otimização de Navegadores - Microsoft Edge

## Objetivo

Esta política do Microsoft Intune tem como objetivo otimizar o uso de recursos do **Microsoft Edge**, reduzindo consumo desnecessário de memória RAM e CPU por abas que permanecem abertas sem uso.

> **Atenção:** apesar de o perfil exibido no print estar nomeado como `CFG - Otimização navegadores - Chrome`, as configurações adicionadas pertencem ao **Microsoft Edge**.  
> Recomenda-se renomear o perfil para:
>
> `CFG - Otimização navegadores - Edge`

---

## Caminho no Intune

1. Acesse o **Microsoft Intune Admin Center**.
2. Vá em:
   - **Dispositivos**
   - **Configuração**
   - **Políticas**
3. Crie ou edite um perfil:
   - Plataforma: **Windows 10 e posterior**
   - Tipo de perfil: **Catálogo de configurações**
4. Em **Adicionar configurações**, pesquise pelas opções relacionadas a:
   - `Sleeping Tabs`
   - `background tab inactivity timeout`

---

# Configurações aplicadas

## 1. Configure Sleeping Tabs

**Valor configurado:**

```text
Enabled
```

### O que faz

Habilita o recurso **Sleeping Tabs** do Microsoft Edge.

Quando uma aba fica inativa por determinado período, o Edge reduz os recursos utilizados por ela.

Isso pode diminuir:

- uso de memória RAM;
- uso de CPU;
- consumo de bateria em notebooks;
- processamento desnecessário em segundo plano.

### O que acontece com a aba

A aba **não é fechada**.

Ela continua aparecendo normalmente na barra de abas do navegador.

Exemplo:

```text
Usuário abre uma página
        ↓
Usuário deixa de utilizar a aba
        ↓
Passa o tempo configurado
        ↓
A aba entra em modo Sleeping
        ↓
Uso de CPU/RAM é reduzido
        ↓
Usuário volta para a aba
        ↓
A aba é reativada
```

### Configuração adotada

```text
Configure Sleeping Tabs
Enabled
```

---

## 2. Set the background tab inactivity timeout for sleeping tabs

**Valor configurado:**

```text
Enabled
```

**Escopo:**

```text
Device
```

**Tempo configurado:**

```text
30 minutes of inactivity
```

### O que faz

Define quanto tempo uma aba precisa permanecer inativa antes de ser colocada em modo **Sleeping Tab**.

Nesta política foi definido:

```text
30 minutos
```

Portanto:

```text
Aba ativa
    ↓
30 minutos sem utilização
    ↓
Edge coloca a aba em suspensão
```

### Por que usar 30 minutos

É um valor equilibrado para ambiente corporativo.

Tempos muito baixos, como:

```text
30 segundos
5 minutos
```

podem ser agressivos demais, principalmente para usuários que alternam constantemente entre sistemas, portais e aplicações web.

Já 30 minutos permite economia de recursos sem tornar o comportamento do navegador excessivamente agressivo.

### Escopo Device x User

Foi escolhida a versão:

```text
Device
```

em vez de:

```text
User
```

Isso significa que a configuração fica vinculada ao **equipamento**, independentemente de qual usuário fizer login.

É indicado principalmente para:

- estações corporativas;
- computadores compartilhados;
- equipamentos utilizados por vários turnos;
- dispositivos em que a TI deseja manter um comportamento padronizado.

### Configuração adotada

```text
Set the background tab inactivity timeout for sleeping tabs
Enabled

Scope
Device

Timeout
30 minutes of inactivity
```

---

## 3. Configure auto discard sleeping tabs

**Valor atual:**

```text
Not configured
```

### O que faz

Essa opção permite ao Edge ser mais agressivo na economia de memória.

Uma aba que já está em modo Sleeping pode ter seu conteúdo descarregado completamente da memória.

Fluxo:

```text
Aba aberta
    ↓
Fica inativa
    ↓
Sleeping Tab
    ↓
Permanece sem uso por muito tempo
    ↓
Auto Discard
    ↓
Conteúdo sai da memória RAM
    ↓
Usuário acessa novamente
    ↓
Página pode ser recarregada
```

### A aba é fechada?

Não.

A aba continua visível no navegador.

Porém, o conteúdo pode precisar ser carregado novamente quando o usuário retornar.

### Por que deixar como Not configured inicialmente

Em ambiente corporativo, algumas aplicações podem manter:

- sessão ativa;
- formulários não enviados;
- dashboards;
- conexões em tempo real;
- aplicações SAP;
- sistemas internos;
- páginas que não lidam bem com recarregamento.

Por isso, inicialmente foi mantido:

```text
Not configured
```

Depois de testes e criação de exceções para sistemas críticos, essa configuração pode ser habilitada em um grupo piloto.

---

# Resumo da política atual

```text
CFG - Otimização navegadores - Edge

Configure Sleeping Tabs
Enabled

Set the background tab inactivity timeout for sleeping tabs
Enabled

Scope
Device

Timeout
30 minutes of inactivity

Configure auto discard sleeping tabs
Not configured
```

---

# Comportamento esperado

Após a aplicação da política:

```text
Usuário abre várias abas
        ↓
Continua trabalhando normalmente
        ↓
Uma aba fica sem uso por 30 minutos
        ↓
Edge coloca a aba em Sleeping Mode
        ↓
Consumo de recursos é reduzido
        ↓
A aba permanece visível
        ↓
Usuário volta para a aba
        ↓
Edge reativa a página
```

---

# Configurações adicionais recomendadas

Estas opções podem ser adicionadas posteriormente ao mesmo perfil de otimização.

## BackgroundModeEnabled

Recomendação:

```text
Disabled
```

### Objetivo

Evita que o Microsoft Edge continue executando aplicativos e extensões em segundo plano depois que todas as janelas do navegador forem fechadas.

Benefícios:

- menor consumo de RAM;
- menos processos do Edge após fechamento;
- menor uso de CPU em segundo plano.

---

## PerformanceDetectorEnabled

Recomendação:

```text
Enabled
```

### Objetivo

Permite que o Edge identifique abas que estejam causando uso excessivo de recursos.

Pode ajudar na identificação de:

- alto consumo de CPU;
- páginas pesadas;
- abas com comportamento anormal.

---

## ExtensionsPerformanceDetectorEnabled

Recomendação:

```text
Enabled
```

### Objetivo

Permite que o Edge detecte extensões que estejam degradando o desempenho do navegador.

É útil para identificar extensões que provocam:

- alto consumo de CPU;
- lentidão;
- consumo excessivo de memória;
- impacto na inicialização do navegador.

---

## EfficiencyModeEnabled

Recomendação inicial:

```text
Enabled
```

### Objetivo

Ativa recursos de eficiência do Edge para reduzir o consumo de recursos do sistema.

Pode contribuir para reduzir:

- CPU;
- memória;
- consumo de energia;
- atividade em segundo plano.

---

## StartupBoostEnabled

Se o objetivo principal for reduzir processos em segundo plano:

```text
Disabled
```

### O que faz

O Startup Boost mantém alguns processos do Edge preparados em segundo plano para fazer o navegador abrir mais rápido.

### Trade-off

```text
Enabled
→ Edge abre mais rapidamente
→ alguns processos podem permanecer carregados

Disabled
→ menor atividade em segundo plano
→ Edge pode demorar um pouco mais para iniciar
```

Para uma política focada exclusivamente em redução de recursos, pode ser interessante deixar desabilitado.

---

## SleepingTabsBlockedForUrls

Esta configuração permite criar exceções para sites que **não devem entrar em Sleeping Tabs**.

É recomendada para sistemas corporativos que dependem de:

- sessão contínua;
- atualização em tempo real;
- notificações;
- formulários;
- dashboards;
- aplicações web críticas.

Exemplos:

```text
[*.]bioaroeira.com.br
[*.]office.com
[*.]microsoftonline.com
[*.]sharepoint.com
```

Também podem ser adicionados sistemas internos específicos, como:

```text
SAP
GLPI
TomTicket
Portais internos
Sistemas operacionais web
```

> Teste os padrões de URL antes de distribuir amplamente.

---

# Recomendações de implantação

Não aplique inicialmente em todos os computadores da empresa.

Recomenda-se utilizar um grupo piloto, por exemplo:

```text
GRP-INTUNE-PILOT-EDGE-OPT
```

Incluindo:

- 1 ou 2 notebooks;
- 1 desktop administrativo;
- 1 computador compartilhado;
- computadores da equipe de TI.

Fluxo sugerido:

```text
Piloto
   ↓
Validação
   ↓
TI
   ↓
Grupo maior
   ↓
Produção
```

---

# Validação no computador cliente

Depois que a política for aplicada, abra no Microsoft Edge:

```text
edge://policy
```

Clique em:

```text
Reload Policies
```

ou:

```text
Recarregar políticas
```

Procure pelas políticas relacionadas a:

```text
SleepingTabsEnabled
SleepingTabsTimeout
```

Também é possível verificar a página:

```text
edge://settings/system
```

ou a área de desempenho disponível na versão instalada do Edge.

---

# Resultado esperado

A política deve melhorar o uso de recursos sem fechar abas automaticamente.

O objetivo é:

```text
Menos RAM
+
Menos CPU
+
Menos atividade em segundo plano
+
Manter as abas abertas
+
Padronizar o comportamento em todos os dispositivos
```

---

## Status atual

| Configuração | Valor |
|---|---|
| Configure Sleeping Tabs | Enabled |
| Sleeping Tabs Timeout | Enabled |
| Escopo | Device |
| Timeout | 30 minutos |
| Auto Discard Sleeping Tabs | Not configured |

---

## Próximos passos

Após validar esta primeira etapa, adicionar:

```text
BackgroundModeEnabled
PerformanceDetectorEnabled
ExtensionsPerformanceDetectorEnabled
EfficiencyModeEnabled
StartupBoostEnabled
SleepingTabsBlockedForUrls
```

A recomendação é manter todas as configurações de **otimização do Microsoft Edge** dentro deste mesmo perfil, evitando criar uma política separada para cada item.
