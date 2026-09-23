# Foxit PDF Reader - Deploy via Microsoft Intune

## Visão Geral

Este pacote realiza a instalação do **Foxit PDF Reader** através do **Microsoft Intune**, utilizando o formato **Win32 App (.intunewin)**.

O aplicativo é disponibilizado no **Portal da Empresa** para instalação sob demanda pelos usuários autorizados.

---

## Objetivo

Disponibilizar o Foxit PDF Reader de forma silenciosa e padronizada através do Microsoft Intune.

Principais objetivos:

- Instalação silenciosa
- Instalação em contexto SYSTEM
- Disponibilização no Portal da Empresa
- Desinstalação silenciosa
- Detecção automática pelo Intune
- Sem necessidade de intervenção do usuário

---

## Estrutura do Pacote

```text
FoxitReader
│
└── FoxitPDFReader.exe
```

Neste deploy foi utilizado o executável diretamente, sem script PowerShell intermediário.

---

## Instalação Silenciosa

```cmd
FoxitPDFReader.exe /install /quiet /norestart
```

### Parâmetros

| Parâmetro | Função |
|---|---|
| `/install` | Executa a instalação |
| `/quiet` | Executa sem interface gráfica |
| `/norestart` | Impede reinicialização automática |

---

## Desinstalação Silenciosa

```cmd
FoxitPDFReader.exe /uninstall /quiet /norestart
```

---

## Empacotamento com IntuneWinAppUtil

```text
C:\Intune\FoxitReader
└── FoxitPDFReader.exe
```

```cmd
IntuneWinAppUtil.exe -c "C:\Intune\FoxitReader" -s "FoxitPDFReader.exe" -o "C:\Intune\Output"
```

Resultado esperado:

```text
FoxitPDFReader.intunewin
```

---

## Cadastro no Microsoft Intune

```text
Microsoft Intune Admin Center
→ Aplicativos
→ Windows
→ Adicionar
→ Aplicativo do Windows (Win32)
```

Selecionar:

```text
FoxitPDFReader.intunewin
```

---

## Informações do Aplicativo

```text
Nome:
Foxit PDF Reader

Editor:
Foxit Software

Categoria:
Produtividade / Documentos e PDF

Descrição:
Leitor de arquivos PDF corporativo disponibilizado através do Portal da Empresa.
```

---

## Programa

### Instalação

```cmd
FoxitPDFReader.exe /install /quiet /norestart
```

### Desinstalação

```cmd
FoxitPDFReader.exe /uninstall /quiet /norestart
```

### Comportamento

```text
Comportamento da instalação:
Sistema

Reinicialização:
Nenhuma ação específica
```

---

## Requisitos

```text
Arquitetura:
64-bit

Sistema operacional mínimo:
Windows 10
```

Ajustar conforme os padrões do ambiente corporativo.

---

## Regra de Detecção

```powershell
$Paths = @(
    "C:\Program Files\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe",
    "C:\Program Files (x86)\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe"
)

foreach ($Path in $Paths) {
    if (Test-Path $Path) {
        Write-Output "Foxit PDF Reader instalado"
        exit 0
    }
}

exit 1
```

No Intune:

```text
Formato das regras:
Usar um script de detecção personalizado
```

Selecionar:

```text
detect.ps1
```

---

## Atribuição

```text
Atribuições
→ Disponível para dispositivos registrados
→ Adicionar grupo
```

Exemplo:

```text
Disponível:
Grupo de usuários

Obrigatório:
Nenhuma atribuição

Desinstalar:
Nenhuma atribuição
```

---

## Funcionamento Esperado

```text
Portal da Empresa
        ↓
Usuário seleciona Foxit PDF Reader
        ↓
Intune Management Extension
        ↓
Download do .intunewin
        ↓
Validação / descriptografia
        ↓
Execução do instalador
        ↓
FoxitPDFReader.exe /install /quiet /norestart
        ↓
Regra de detecção
        ↓
Aplicativo instalado
```

---

## Problema Encontrado Durante a Implementação

Inicialmente a instalação era executada através de:

```cmd
powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\install.ps1
```

O pacote era baixado corretamente pelo Intune, porém o processo de instalação permanecia em execução até atingir o tempo máximo configurado.

O Intune retornava falha após o timeout da instalação.

O download do `.intunewin`, validação, descriptografia e extração estavam funcionando corretamente.

A falha ocorria após o início do `install.ps1`.

---

## Solução Aplicada

O script PowerShell foi removido do processo de instalação.

A instalação passou a utilizar diretamente:

```cmd
FoxitPDFReader.exe /install /quiet /norestart
```

Após essa alteração, a instalação através do Portal da Empresa passou a funcionar corretamente.

---

## Boas Práticas

Para aplicações que possuem parâmetros silenciosos oficiais, priorizar a execução direta do instalador.

```text
Intune
   ↓
EXE / MSI
   ↓
Instalação silenciosa
```

Utilizar PowerShell quando houver necessidade de:

- Pós-configuração
- Manipulação de registro
- Cópia de arquivos
- Configuração de variáveis
- Validação de dependências
- Instalação de múltiplos componentes
- Geração de logs customizados

---

## Troubleshooting

Logs do Microsoft Intune Management Extension:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Principais arquivos:

```text
AppWorkload.log
IntuneManagementExtension.log
AgentExecutor.log
```

Pesquisar falhas:

```powershell
Select-String `
-Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\*.log" `
-Pattern "Foxit","ExitCode","Error","Failed" |
Select-Object -Last 100
```

---

## Validação Manual

```powershell
Test-Path "C:\Program Files\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe"
```

Ou:

```powershell
Test-Path "C:\Program Files (x86)\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe"
```

Consulta pelo registro:

```powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "Foxit.*PDF.*Reader"
} |
Select-Object DisplayName,DisplayVersion,Publisher
```

---

## Resultado

```text
Download pelo Intune: OK
Instalação silenciosa: OK
Detecção: OK
Portal da Empresa: OK
Desinstalação: Configurada
Execução em contexto SYSTEM: OK
```

---

## Autor

**André Luiz**

Documentação de deploy e gerenciamento de aplicações utilizando Microsoft Intune.
