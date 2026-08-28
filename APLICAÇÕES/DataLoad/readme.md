# DataLoad 5.5.0.0 --- Deploy via Microsoft Intune

Documentação do processo utilizado para disponibilizar o **DataLoad
Classic 5.5.0.0** através do **Microsoft Intune**, utilizando o
instalador `dlsetup.exe` como aplicativo Win32.

## Visão geral

  Item                    Configuração
  ----------------------- ---------------------
  Aplicativo              DataLoad
  Versão                  5.5.0.0
  Instalador              `dlsetup.exe`
  Tipo de instalador      EXE / NSIS
  Arquitetura             32 bits
  Instalação silenciosa   `/S`
  Contexto no Intune      System
  Detecção                Registro do Windows

------------------------------------------------------------------------

## 1. Estrutura dos arquivos

Crie uma pasta para preparar o pacote:

``` text
DataLoad\
└── dlsetup.exe
```

> O nome do executável pode variar conforme a versão baixada. Caso seja
> diferente, ajuste os comandos desta documentação.

------------------------------------------------------------------------

## 2. Validar a instalação silenciosa

Antes de criar o pacote do Intune, teste o instalador localmente.

Abra o PowerShell como administrador, acesse a pasta onde está o
instalador e execute:

``` powershell
$p = Start-Process ".\dlsetup.exe" -ArgumentList "/S" -Wait -PassThru
$p.ExitCode
```

Resultado esperado:

``` text
0
```

O código `0` indica que o processo terminou com sucesso.

### Atenção ao caminho

Se o diretório possuir espaços, coloque o caminho entre aspas:

``` powershell
cd "C:\Caminho com espaços\DataLoad"
```

------------------------------------------------------------------------

## 3. Validar a instalação

Após a instalação, confirme o registro criado pelo DataLoad:

``` powershell
Get-ChildItem `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" |
ForEach-Object {
    Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
} |
Where-Object {
    $_.DisplayName -like "*DataLoad*"
} |
Select-Object DisplayName, DisplayVersion, PSPath
```

No ambiente validado, o resultado foi:

``` text
DisplayName     DisplayVersion
-----------     --------------
DataLoad        5.5.0.0
```

A aplicação foi registrada em:

``` text
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\DataLoad
```

------------------------------------------------------------------------

## 4. Criar o pacote `.intunewin`

Utilize o **Microsoft Win32 Content Prep Tool**
(`IntuneWinAppUtil.exe`).

Exemplo de estrutura:

``` text
C:\Intune\
├── Source\
│   └── DataLoad\
│       └── dlsetup.exe
└── Output\
```

Execute:

``` cmd
IntuneWinAppUtil.exe -c "C:\Intune\Source\DataLoad" -s "dlsetup.exe" -o "C:\Intune\Output"
```

O resultado será um arquivo semelhante a:

``` text
dlsetup.intunewin
```

Esse é o arquivo que deverá ser enviado ao Intune.

------------------------------------------------------------------------

## 5. Criar o aplicativo no Intune

No **Microsoft Intune Admin Center**, acesse:

``` text
Apps
└── Windows
    └── Add
        └── Windows app (Win32)
```

Faça upload do arquivo:

``` text
dlsetup.intunewin
```

Preencha as informações do aplicativo conforme o padrão da sua
organização.

------------------------------------------------------------------------

## 6. Configuração do programa

### Comando de instalação

``` cmd
dlsetup.exe /S
```

O parâmetro `/S` deve ser escrito com **S maiúsculo**.

### Comando de desinstalação

No ambiente utilizado durante os testes, o desinstalador é instalado em:

``` text
C:\Program Files (x86)\DataLoad\uninstall.exe
```

Configure:

``` cmd
"C:\Program Files (x86)\DataLoad\uninstall.exe" /S
```

### Comportamento de instalação

Configure:

``` text
Install behavior: System
```

Isso permite que o aplicativo seja instalado pelo Intune Management
Extension em contexto de máquina, sem depender de privilégios
administrativos do usuário.

### Reinicialização

Utilize:

``` text
App install may force a device restart: No
```

Ajuste essa opção caso uma versão futura do instalador passe a exigir
reinicialização.

------------------------------------------------------------------------

## 7. Requisitos

Configuração sugerida:

``` text
Operating system architecture:
32-bit and 64-bit

Minimum operating system:
Definir conforme o padrão do ambiente
```

Embora o DataLoad seja uma aplicação de 32 bits, ele pode ser instalado
em Windows 64 bits através do subsistema WOW64.

------------------------------------------------------------------------

## 8. Regra de detecção

Utilize uma regra do tipo:

``` text
Registry
```

### Key path

``` text
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\DataLoad
```

### Value name

``` text
DisplayVersion
```

### Detection method

``` text
Version comparison
```

### Operator

``` text
Greater than or equal to
```

### Value

``` text
5.5.0.0
```

### Aplicativo de 32 bits

Configure:

``` text
Associated with a 32-bit app on 64-bit clients: Yes
```

Essa regra permite que o Intune valide a versão instalada, em vez de
verificar apenas a existência de um arquivo.

------------------------------------------------------------------------

## 9. Configuração resumida

  ---------------------------------------------------------------------------------------------------------------------
  Campo                               Valor
  ----------------------------------- ---------------------------------------------------------------------------------
  Setup file                          `dlsetup.exe`

  Install command                     `dlsetup.exe /S`

  Uninstall command                   `"C:\Program Files (x86)\DataLoad\uninstall.exe" /S`

  Install behavior                    `System`

  Detection type                      `Registry`

  Registry key                        `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\DataLoad`

  Value                               `DisplayVersion`

  Comparison                          `>= 5.5.0.0`

  32-bit app                          `Yes`
  ---------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 10. Troubleshooting

### `dlsetup.exe` não encontrado

Se ocorrer:

``` text
O sistema não pode encontrar o arquivo especificado.
```

confirme o diretório atual:

``` powershell
Get-Location
```

Liste os arquivos:

``` powershell
Get-ChildItem
```

Depois acesse corretamente a pasta:

``` powershell
cd "C:\Caminho\DataLoad"
```

E execute novamente:

``` powershell
Start-Process ".\dlsetup.exe" -ArgumentList "/S" -Wait -PassThru
```

### Validar o Exit Code

``` powershell
$p = Start-Process ".\dlsetup.exe" -ArgumentList "/S" -Wait -PassThru
$p.ExitCode
```

Resultado esperado:

``` text
0
```

### Erro `0x87D30067`

Durante os testes foi encontrado o erro:

``` text
0x87D30067
Erro ao descompactar o conteúdo baixado.
```

Esse erro ocorre na etapa de processamento do conteúdo Win32 pelo Intune
e não deve ser confundido com falha do parâmetro `/S`.

Quando isso ocorrer, verifique principalmente:

-   integridade do pacote `.intunewin`;
-   cache do Intune Management Extension;
-   download e staging do conteúdo;
-   logs do IME;
-   espaço disponível no disco.

Logs principais:

``` text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppWorkload.log
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```

Para procurar erros:

``` powershell
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"

Select-String `
    -Path "$LogPath\AppWorkload.log","$LogPath\IntuneManagementExtension.log" `
    -Pattern "DataLoad|0x87D30067|87D30067|Unzip|Decrypt|Extract|Download|Content" `
    -Context 10,15
```

------------------------------------------------------------------------

## 11. Validação final

Após a implantação, confirme:

``` powershell
Get-ItemProperty `
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\DataLoad" `
-ErrorAction SilentlyContinue |
Select-Object DisplayName, DisplayVersion, InstallLocation, UninstallString
```

O equipamento deve apresentar o DataLoad instalado e o Intune deve
identificar a aplicação através da regra de detecção.

------------------------------------------------------------------------

## Resultado

Deploy validado com:

``` text
DataLoad Classic 5.5.0.0
Microsoft Intune Win32 App
Instalação silenciosa: dlsetup.exe /S
Contexto: SYSTEM
Detecção: Registro / DisplayVersion
```

A utilização da detecção pelo `DisplayVersion` também facilita a
atualização futura do pacote, permitindo alterar a versão esperada na
regra do Intune.

------------------------------------------------------------------------

## Observações para outras versões/ambientes

Os seguintes campos devem ser revisados antes de reutilizar esta
documentação em outro ambiente:

-   nome do arquivo instalador;
-   versão do DataLoad;
-   caminho de instalação/desinstalação;
-   chave de registro;
-   `DisplayVersion`;
-   arquitetura;
-   requisitos mínimos do Windows;
-   grupos utilizados nas atribuições do Intune.

Nunca reutilize uma regra de detecção sem validar previamente os dados
gravados pela versão que será distribuída.
