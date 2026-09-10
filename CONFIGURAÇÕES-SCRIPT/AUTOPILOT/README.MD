
# Coleta de Hardware Hash do Windows Autopilot via GPO

Este projeto documenta uma solução para **coletar automaticamente o Hardware Hash de computadores Windows por meio de GPO** e armazenar o arquivo CSV em um compartilhamento de rede centralizado.

A solução foi pensada para ambientes corporativos com **Active Directory Domain Services**, estações Windows e parque misto com **Windows PowerShell 5.1** e **PowerShell 7.x**.

---

## Objetivo

Automatizar a coleta do Hardware Hash utilizado pelo **Windows Autopilot**, evitando a execução manual do `Get-WindowsAutopilotInfo.ps1` em cada equipamento.

O fluxo implementado é:

```text
Computador inicia
        |
        v
GPO de Computador
        |
        v
Script de Inicialização
        |
        v
Coleta Serial + Hardware Hash
        |
        v
Gera CSV local
C:\Autopilot\HOSTNAME.csv
        |
        v
Copia para o compartilhamento
\\server02\mapeamentos$\Autopilot
        |
        v
HOSTNAME.csv
```

Exemplo:

```text
Hostname:
BA-NOTESI277

Arquivo gerado:
\\server02\mapeamentos$\Autopilot\BA-NOTESI277.csv
```

---

# Requisitos

## Active Directory

É necessário possuir:

- Active Directory Domain Services;
- GPMC / Group Policy Management;
- computadores ingressados no domínio;
- comunicação SMB entre os computadores e o servidor de arquivos.

---

## Sistema operacional

A coleta utiliza componentes nativos do Windows.

Recomendado:

```text
Windows 10
Windows 11
```

---

## PowerShell

O script utiliza comandos compatíveis com:

```text
Windows PowerShell 5.1
PowerShell 7.x
```

Para garantir padronização no ambiente, a GPO pode chamar explicitamente o **Windows PowerShell 5.1 nativo do Windows**:

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

Dessa forma, mesmo computadores com PowerShell 7 instalado executam o mesmo mecanismo.

---

# Estrutura utilizada

Neste exemplo:

```text
Servidor:
SERVER02

Compartilhamento:
\\server02\mapeamentos$

Subpasta:
Autopilot

Destino final:
\\server02\mapeamentos$\Autopilot
```

Estrutura no servidor:

```text
C:\
└── Mapeamentos
    └── Autopilot
```

Exemplo após a coleta:

```text
Autopilot
├── BA-NOTESI277.csv
├── BA-NOTETI014.csv
├── BA-PCADM022.csv
└── BA-PCRH041.csv
```

---

# Permissões do compartilhamento

Como a solução é executada através de uma **GPO de computador**, o script é executado normalmente no contexto:

```text
NT AUTHORITY\SYSTEM
```

Ao acessar um recurso de rede, o computador utiliza sua conta de máquina no domínio.

Exemplo:

```text
BIOAROEIRA\BA-NOTESI277$
```

Essa conta é membro de:

```text
Computadores do domínio
```

## Permissões de compartilhamento

No compartilhamento `mapeamentos$`, configure:

```text
Computadores do domínio

Permitir:
[x] Alteração
[x] Leitura
```

Não é necessário conceder `Controle Total`.

---

## Permissões NTFS

Na pasta:

```text
C:\Mapeamentos\Autopilot
```

adicione:

```text
Computadores do domínio
```

com:

```text
[x] Modificar
[x] Ler e executar
[x] Listar conteúdo da pasta
[x] Leitura
[x] Gravar
```

Recomendação para ambientes mais restritivos:

```text
GRP-GPO-AUTOPILOT-HASH
```

Nesse grupo podem ser adicionadas somente as contas dos computadores que participarão da coleta.

Exemplo:

```text
BA-NOTESI277$
BA-NOTETI014$
BA-PCADM022$
```

---

# Script PowerShell

Salve o arquivo como:

```text
HashAutopilot.ps1
```

Conteúdo:

```powershell
$Destino = "\\server02\mapeamentos$\Autopilot"
$Hostname = $env:COMPUTERNAME

$PastaLocal = "C:\Autopilot"
$ArquivoLocal = "$PastaLocal\$Hostname.csv"
$ArquivoRede = "$Destino\$Hostname.csv"
$Log = "$PastaLocal\HashAutopilot.log"

if (!(Test-Path $PastaLocal)) {
    New-Item -Path $PastaLocal -ItemType Directory -Force | Out-Null
}

"$(Get-Date) - Inicio - $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" |
Out-File $Log -Append

try {

    $Serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber

    $Hash = (
        Get-CimInstance `
        -Namespace "root/cimv2/mdm/dmmap" `
        -ClassName "MDM_DevDetail_Ext01" `
        -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" `
        -ErrorAction Stop
    ).DeviceHardwareData

    if ([string]::IsNullOrWhiteSpace($Hash)) {
        throw "Hardware Hash vazio."
    }

    [PSCustomObject]@{
        "Device Serial Number" = $Serial
        "Windows Product ID"   = ""
        "Hardware Hash"        = $Hash
        "Group Tag"            = ""
        "Assigned User"        = ""
    } | Export-Csv `
        -Path $ArquivoLocal `
        -NoTypeInformation `
        -Encoding UTF8 `
        -Force

    "$(Get-Date) - CSV local criado: $ArquivoLocal" |
    Out-File $Log -Append

    Copy-Item `
        -Path $ArquivoLocal `
        -Destination $ArquivoRede `
        -Force `
        -ErrorAction Stop

    "$(Get-Date) - CSV enviado: $ArquivoRede" |
    Out-File $Log -Append

}
catch {

    "$(Get-Date) - ERRO: $($_.Exception.Message)" |
    Out-File $Log -Append

    exit 1
}

exit 0
```

---

# Como o Hardware Hash é coletado

A solução não depende de NuGet, PSGallery ou instalação dinâmica de scripts.

O Hardware Hash é obtido diretamente através do provedor MDM do Windows:

```text
Namespace:
root/cimv2/mdm/dmmap

Classe:
MDM_DevDetail_Ext01

Propriedade:
DeviceHardwareData
```

Trecho responsável pela coleta:

```powershell
$Hash = (
    Get-CimInstance `
    -Namespace "root/cimv2/mdm/dmmap" `
    -ClassName "MDM_DevDetail_Ext01" `
    -Filter "InstanceID='Ext' AND ParentID='./DevDetail'"
).DeviceHardwareData
```

O Serial Number é obtido através de:

```powershell
Get-CimInstance -ClassName Win32_BIOS
```

---

# CSV gerado

O arquivo segue uma estrutura compatível com importação do Windows Autopilot.

Exemplo:

```csv
"Device Serial Number","Windows Product ID","Hardware Hash","Group Tag","Assigned User"
"BRJ511QKFM","","<HARDWARE_HASH>","",""
```

O arquivo recebe automaticamente o hostname do dispositivo.

Exemplo:

```text
BA-NOTESI277.csv
```

---

# Armazenamento local

Antes de copiar o arquivo para a rede, o CSV é gerado localmente em:

```text
C:\Autopilot
```

Exemplo:

```text
C:\Autopilot\BA-NOTESI277.csv
```

Isso permite preservar o Hardware Hash mesmo que o compartilhamento de rede esteja temporariamente indisponível.

---

# Log de execução

O script também gera:

```text
C:\Autopilot\HashAutopilot.log
```

Exemplo:

```text
10/09/2026 09:20:11 - Inicio - NT AUTHORITY\SYSTEM
10/09/2026 09:20:12 - CSV local criado: C:\Autopilot\BA-NOTESI277.csv
10/09/2026 09:20:13 - CSV enviado: \\server02\mapeamentos$\Autopilot\BA-NOTESI277.csv
```

Em caso de falha:

```text
10/09/2026 09:20:13 - ERRO: Access to the path was denied.
```

---

# Armazenar o script no SYSVOL

Uma opção recomendada é armazenar o script em:

```text
\\bioaroeira.com.br\SYSVOL\bioaroeira.com.br\scripts\HashAutopilot.ps1
```

Exemplo de estrutura:

```text
SYSVOL
└── bioaroeira.com.br
    └── scripts
        ├── HashAutopilot.ps1
        └── HashAutopilot.cmd
```

---

# Wrapper CMD

Para melhorar a compatibilidade da execução via GPO, pode ser utilizado um arquivo `.cmd`.

Crie:

```text
HashAutopilot.cmd
```

Conteúdo:

```cmd
@echo off

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "\\bioaroeira.com.br\SYSVOL\bioaroeira.com.br\scripts\HashAutopilot.ps1"

exit /b %errorlevel%
```

Essa abordagem força a utilização do Windows PowerShell 5.1 nativo.

---

# Criando a GPO

Crie uma GPO, por exemplo:

```text
GPO - HASH AUTOPILOT
```

Vincule a GPO à OU que contém os **computadores**.

Exemplo:

```text
OU=GPO
OU=TI
OU=Computers-Intune
```

A política deve ser configurada como **Configuração do Computador**.

Caminho:

```text
Configuração do Computador
└── Políticas
    └── Configurações do Windows
        └── Scripts
            └── Inicialização
```

Adicione:

```text
HashAutopilot.cmd
```

---

# Forçar atualização da GPO

No computador cliente:

```cmd
gpupdate /force
```

Como o script é de inicialização, reinicie o equipamento:

```cmd
shutdown /r /t 0
```

---

# Validar aplicação da GPO

Após o computador reiniciar:

```cmd
gpresult /r /scope computer
```

Procure:

```text
Objetos de política de grupo aplicados
---------------------------------------

GPO - HASH AUTOPILOT
```

---

# Teste manual da coleta

Antes de implantar a GPO em produção, é possível validar a coleta localmente.

Abra PowerShell como administrador:

```powershell
New-Item -Path "C:\Autopilot" -ItemType Directory -Force | Out-Null

$Serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber

$DevDetail = Get-CimInstance `
    -Namespace "root/cimv2/mdm/dmmap" `
    -ClassName "MDM_DevDetail_Ext01" `
    -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" `
    -ErrorAction Stop

$Hash = $DevDetail.DeviceHardwareData

Write-Host "Hostname:" $env:COMPUTERNAME
Write-Host "Serial:" $Serial
Write-Host "Hash encontrado:" (-not [string]::IsNullOrWhiteSpace($Hash))
```

Resultado esperado:

```text
Hostname: BA-NOTESI277
Serial: BRJ511QKFM
Hash encontrado: True
```

---

# Testar geração local

```powershell
[PSCustomObject]@{
    "Device Serial Number" = $Serial
    "Windows Product ID"   = ""
    "Hardware Hash"        = $Hash
    "Group Tag"            = ""
    "Assigned User"        = ""
} | Export-Csv `
    -Path "C:\Autopilot\$env:COMPUTERNAME.csv" `
    -NoTypeInformation `
    -Encoding UTF8
```

Validar:

```powershell
Test-Path "C:\Autopilot\$env:COMPUTERNAME.csv"
```

Esperado:

```text
True
```

---

# Testar cópia para o servidor

```powershell
Copy-Item `
"C:\Autopilot\$env:COMPUTERNAME.csv" `
"\\server02\mapeamentos$\Autopilot\$env:COMPUTERNAME.csv" `
-Force
```

Validar:

```powershell
Test-Path "\\server02\mapeamentos$\Autopilot\$env:COMPUTERNAME.csv"
```

Resultado esperado:

```text
True
```

---

# Validar acesso como SYSTEM

Uma GPO de inicialização executa normalmente como:

```text
NT AUTHORITY\SYSTEM
```

Um teste pode ser realizado através do Agendador de Tarefas.

Exemplo:

```powershell
$Action = New-ScheduledTaskAction `
    -Execute "cmd.exe" `
    -Argument '/c echo TESTE-SYSTEM > "\\server02\mapeamentos$\Autopilot\teste-system-%COMPUTERNAME%.txt"'

$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(5)

Register-ScheduledTask `
    -TaskName "Teste-Autopilot-SYSTEM" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Force

Start-ScheduledTask -TaskName "Teste-Autopilot-SYSTEM"
```

Se o arquivo for criado no compartilhamento, a conta do computador possui acesso de gravação.

---

# Troubleshooting

## GPO aparece no gpresult, mas não gera CSV

Verifique:

```text
C:\Autopilot\HashAutopilot.log
```

Se o log não existir, o script provavelmente não foi executado.

Confirme o caminho do script configurado na GPO.

---

## Hardware Hash vazio

Teste:

```powershell
Get-CimInstance `
-Namespace "root/cimv2/mdm/dmmap" `
-ClassName "MDM_DevDetail_Ext01" `
-Filter "InstanceID='Ext' AND ParentID='./DevDetail'"
```

Depois:

```powershell
(
    Get-CimInstance `
    -Namespace "root/cimv2/mdm/dmmap" `
    -ClassName "MDM_DevDetail_Ext01" `
    -Filter "InstanceID='Ext' AND ParentID='./DevDetail'"
).DeviceHardwareData
```

Se uma grande sequência de caracteres for retornada, a coleta está funcionando.

---

## Acesso negado no compartilhamento

Verifique os dois níveis de permissão:

```text
Compartilhamento SMB
+
Permissão NTFS
```

A permissão efetiva é a combinação das duas.

No servidor:

```powershell
Get-SmbShareAccess -Name "mapeamentos$"
```

Para verificar NTFS:

```cmd
icacls "C:\Mapeamentos\Autopilot"
```

---

## Test-Path retorna True, mas Copy-Item falha

Isso significa que o dispositivo consegue **ler/enxergar a pasta**, mas não necessariamente possui permissão para criar arquivos.

Valide:

```powershell
"TESTE" |
Out-File "\\server02\mapeamentos$\Autopilot\teste.txt"
```

---

## PowerShell 7 funciona e PowerShell 5.1 não

Para evitar diferenças entre versões, configure a GPO para chamar diretamente:

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

Exemplo:

```cmd
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "\\bioaroeira.com.br\SYSVOL\bioaroeira.com.br\scripts\HashAutopilot.ps1"
```

---

# Por que utilizar GPO de computador?

O Hardware Hash está relacionado ao dispositivo e não ao usuário.

Por isso a solução utiliza:

```text
Configuração do Computador
```

em vez de:

```text
Configuração do Usuário
```

Benefícios:

- independe do usuário que realizar logon;
- executa automaticamente durante a inicialização;
- utiliza a identidade da máquina no domínio;
- permite coleta centralizada;
- facilita preparação de dispositivos para Windows Autopilot.

---

# Segurança

Evite conceder:

```text
Controle Total
```

para `Computadores do domínio`.

Para a solução funcionar, normalmente basta:

### Compartilhamento

```text
Alteração
Leitura
```

### NTFS

```text
Modificar
Ler e executar
Listar conteúdo da pasta
Leitura
Gravar
```

Em ambientes com maior requisito de segurança, utilize um grupo dedicado:

```text
GRP-GPO-AUTOPILOT-HASH
```

---

# Resultado esperado

Depois que a GPO estiver aplicada:

```text
Computador:
BA-NOTESI277
```

gera:

```text
C:\Autopilot\BA-NOTESI277.csv
```

e envia:

```text
\\server02\mapeamentos$\Autopilot\BA-NOTESI277.csv
```

O diretório central passa a funcionar como repositório dos Hardware Hashes:

```text
\\server02\mapeamentos$\Autopilot

├── BA-NOTESI277.csv
├── BA-NOTESI301.csv
├── BA-NOTERH012.csv
├── BA-PCADM007.csv
└── BA-PCIND023.csv
```

---

# Melhorias futuras

Algumas evoluções possíveis:

- definir `Group Tag` automaticamente;
- separar arquivos por OU ou setor;
- registrar data e hora da coleta;
- evitar reprocessamento de computadores já coletados;
- enviar logs para um compartilhamento central;
- importar os dispositivos automaticamente no Intune via Microsoft Graph;
- criar grupo dinâmico de dispositivos Autopilot;
- remover o CSV local após confirmação da cópia;
- registrar eventos no Windows Event Viewer.

---

# Estrutura sugerida para o repositório

```text
autopilot-hardwarehash-gpo
│
├── README.md
│
├── scripts
│   ├── HashAutopilot.ps1
│   └── HashAutopilot.cmd
│
└── docs
    └── screenshots
```

---

# Tecnologias utilizadas

- Windows Autopilot
- Microsoft Intune
- Active Directory Domain Services
- Group Policy
- PowerShell
- CIM / WMI
- SMB
- Windows Server

---

# Autor

**André Luiz**

Projeto desenvolvido para documentação e automação de atividades de infraestrutura, gerenciamento de dispositivos Windows e Microsoft Intune.

---

## Aviso

Antes de aplicar em produção, valide o script em um grupo pequeno de computadores e revise os caminhos, permissões SMB, permissões NTFS e estrutura de OUs conforme o ambiente da organização.
