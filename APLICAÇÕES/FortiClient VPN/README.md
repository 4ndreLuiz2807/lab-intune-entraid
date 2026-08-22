<p align="center">
  <img src="./banner_forticlient_intune.svg" width="100%" alt="FortiClient VPN via Microsoft Intune">
</p>

# FortiClient VPN — Deploy via Microsoft Intune

Documentação do processo utilizado para obter o **MSI do FortiClient VPN a partir do instalador EXE**, empacotar como `.intunewin` e realizar o deploy através do **Microsoft Intune**.

> Este procedimento contempla somente a instalação do FortiClient VPN. Configurações de conexão VPN não fazem parte deste deploy.

---

## Fluxo

```text
FortiClientVPNInstaller.exe
        ↓
Executar o instalador
        ↓
Localizar o MSI temporário
        ↓
Copiar o MSI
        ↓
Empacotar com IntuneWinAppUtil
        ↓
FortiClientVPN.intunewin
        ↓
Microsoft Intune
        ↓
Deploy
```

## 1. Executar o instalador EXE

Execute normalmente:

```text
FortiClientVPNInstaller.exe
```

Mantenha o instalador aberto durante a extração dos arquivos.

Não finalize imediatamente, pois o MSI extraído pode ser removido quando o instalador encerrar.

---

## 2. Localizar o MSI

Com o instalador aberto, execute o **PowerShell como Administrador**:

```powershell
Get-ChildItem "$env:TEMP","C:\Windows\Temp","C:\ProgramData" -Recurse -Filter *.msi -ErrorAction SilentlyContinue |
Where-Object LastWriteTime -gt (Get-Date).AddMinutes(-10) |
Sort-Object LastWriteTime -Descending |
Select-Object FullName,Length,LastWriteTime
```

O comando procura arquivos `.msi` criados ou modificados nos últimos 10 minutos.

Procure pelo arquivo correspondente ao FortiClient.

Exemplo:

```text
FullName
--------
C:\Users\usuario\AppData\Local\Temp\{GUID}\FortiClientVPN.msi
```

> O caminho pode variar de acordo com a versão do instalador.

---

## 3. Copiar o MSI

Assim que localizar o arquivo, copie-o antes de fechar o instalador.

Crie uma pasta:

```powershell
New-Item -ItemType Directory -Path "C:\INTUNE\FortiClient" -Force
```

Copie o MSI:

```powershell
Copy-Item "CAMINHO_DO_MSI\FortiClientVPN.msi" "C:\INTUNE\FortiClient\FortiClientVPN.msi"
```

Confirme:

```powershell
Test-Path "C:\INTUNE\FortiClient\FortiClientVPN.msi"
```

Resultado esperado:

```text
True
```

A estrutura final será:

```text
C:\INTUNE\FortiClient\
└── FortiClientVPN.msi
```

---

## 4. Empacotar para o Intune

Execute:

```text
IntuneWinAppUtil.exe
```

Informe:

### Source folder

```text
C:\INTUNE\FortiClient
```

### Setup file

```text
FortiClientVPN.msi
```

### Output folder

```text
C:\INTUNE\Output
```

Ao finalizar será gerado:

```text
C:\INTUNE\Output\FortiClientVPN.intunewin
```

---

## 5. Criar o aplicativo no Intune

No **Microsoft Intune Admin Center**:

```text
Apps
→ Windows
→ Add
→ Windows app (Win32)
```

Faça upload de:

```text
FortiClientVPN.intunewin
```

Preencha as informações do aplicativo, por exemplo:

```text
Name: FortiClient VPN
Publisher: Fortinet
```

---

## 6. Program

Como o arquivo utilizado no empacotamento é um **MSI**, o Intune consegue ler os metadados do Windows Installer e normalmente preenche automaticamente os comandos de instalação e desinstalação.

Portanto, utilize os comandos preenchidos automaticamente pelo Intune.

Configure:

```text
Install behavior: System
```

Não é necessário utilizar `install.ps1` neste cenário.

---

## 7. Requirements

Configure conforme o ambiente e a versão do FortiClient.

Exemplo:

```text
Operating system architecture: 64-bit
Minimum operating system: Windows 10 ou superior
```

---

## 8. Detection rules

Utilize a detecção baseada no **MSI Product Code** identificado pelo Intune.

Não é necessário criar um script de detecção para este cenário.

---

## 9. Assignments

Em:

```text
Assignments
```

Adicione o grupo que receberá o aplicativo.

Para instalação automática:

```text
Required
```

Para disponibilizar pelo Company Portal:

```text
Available for enrolled devices
```

---

## 10. Logs do Intune

Em caso de falha, consulte:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Principal log para análise do Win32 App:

```text
IntuneManagementExtension.log
```

---

## Resultado

Ao final:

```text
EXE
 ↓
MSI extraído
 ↓
.intunewin
 ↓
Microsoft Intune
 ↓
FortiClient VPN instalado
```

O deploy fica simples, utilizando o **MSI original extraído pelo instalador**, sem necessidade de script PowerShell para instalação.

---

## Estrutura sugerida do repositório

```text
FortiClient-Intune/
├── README.md
└── banner_forticlient_intune.svg
```

> Não publique o instalador do FortiClient no repositório. Mantenha apenas a documentação e os arquivos próprios do projeto.

---

## Tecnologias utilizadas

- Microsoft Intune
- Microsoft Entra ID
- FortiClient VPN
- Windows Installer (MSI)
- Win32 App (`.intunewin`)
- Microsoft Win32 Content Prep Tool
- PowerShell

---

## Autor

**André Luiz**
