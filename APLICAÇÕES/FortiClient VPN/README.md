<p align="center">
  <img src="./banner_forticlient_intune.svg" width="100%" alt="FortiClient VPN via Microsoft Intune">
</p>

<p align="center">
  <img src="./banner_forticlient_intune.svg" width="100%" alt="FortiClient VPN via Microsoft Intune">
</p>

# FortiClient VPN — Deploy do MSI via Microsoft Intune

Este repositório documenta o processo utilizado para obter o arquivo **MSI do FortiClient VPN a partir do instalador EXE** e publicá-lo diretamente no **Microsoft Intune como aplicativo Line-of-business (LOB)**.

> Este procedimento contempla somente a instalação do FortiClient VPN. A distribuição de configurações de conexão VPN não faz parte deste deploy.

---

## Fluxo

```text
FortiClientVPNInstaller.exe
        ↓
Executar o instalador
        ↓
Localizar o MSI temporário
        ↓
Copiar o arquivo .MSI
        ↓
Microsoft Intune
        ↓
Line-of-business app
        ↓
Upload direto do MSI
        ↓
Deploy
```

## 1. Executar o instalador EXE

Execute normalmente:

```text
FortiClientVPNInstaller.exe
```

Mantenha o instalador aberto enquanto procura o arquivo MSI.

O instalador pode remover os arquivos temporários quando for finalizado.

---

## 2. Localizar o MSI

Com o instalador em execução, abra o **PowerShell como Administrador** e execute:

```powershell
Get-ChildItem "$env:TEMP","C:\Windows\Temp","C:\ProgramData" -Recurse -Filter *.msi -ErrorAction SilentlyContinue |
Where-Object LastWriteTime -gt (Get-Date).AddMinutes(-10) |
Sort-Object LastWriteTime -Descending |
Select-Object FullName,Length,LastWriteTime
```

O comando procura arquivos `.msi` criados ou modificados nos últimos 10 minutos.

Procure pelo MSI correspondente ao FortiClient.

Exemplo:

```text
FullName
--------
C:\Users\usuario\AppData\Local\Temp\{GUID}\FortiClientVPN.msi
```

> O caminho e o nome podem variar conforme a versão do FortiClient.

---

## 3. Copiar o MSI

Assim que localizar o MSI, copie-o para uma pasta permanente **antes de fechar o instalador**.

Crie uma pasta:

```powershell
New-Item -ItemType Directory -Path "C:\INTUNE\FortiClient" -Force
```

Depois copie o arquivo:

```powershell
Copy-Item "CAMINHO_DO_MSI\FortiClientVPN.msi" "C:\INTUNE\FortiClient\FortiClientVPN.msi"
```

Valide:

```powershell
Test-Path "C:\INTUNE\FortiClient\FortiClientVPN.msi"
```

Resultado esperado:

```text
True
```

---

## 4. Publicar o MSI diretamente no Intune

Acesse o **Microsoft Intune Admin Center**:

```text
Apps
→ Windows
→ Add
```

Em **App type**, selecione:

```text
Line-of-business app
```

Clique em **Select**.

---

## 5. Fazer upload do MSI

Em **App package file**, selecione:

```text
FortiClientVPN.msi
```

O arquivo MSI será enviado diretamente para o Intune.

Neste método:

```text
NÃO é necessário gerar .intunewin
NÃO é necessário usar IntuneWinAppUtil
NÃO é necessário criar install.ps1
```

---

## 6. Informações do aplicativo

Após o upload, o Intune lê informações disponíveis no pacote MSI.

Revise os campos apresentados e preencha o necessário.

Exemplo:

```text
Name: FortiClient VPN
Publisher: Fortinet
```

Adicione também descrição, categoria, logo e informações de suporte conforme o padrão da organização.

---

## 7. Comandos de instalação e desinstalação

Como o aplicativo está sendo publicado diretamente como **MSI / Line-of-business app**, o gerenciamento da instalação utiliza as informações do Windows Installer.

Não é necessário criar um script PowerShell de instalação.

Também não é necessário utilizar o `IntuneWinAppUtil.exe` neste cenário.

---

## 8. Assignments

Em:

```text
Assignments
```

adicione o grupo que receberá o FortiClient VPN.

Para instalação obrigatória:

```text
Required
```

Para disponibilização ao usuário, utilize as opções de atribuição disponíveis para o tipo de aplicativo e para o cenário da organização.

---

## 9. Criar o aplicativo

Revise as configurações:

```text
Review + create
```

Depois:

```text
Create
```

O Intune fará o upload e processamento do MSI.

---

## 10. Sincronizar a máquina de teste

Na máquina gerenciada:

```text
Settings
→ Accounts
→ Access work or school
→ Conta corporativa
→ Info
→ Sync
```

Aguarde o processamento da atribuição.

---

## 11. Validar a instalação

Depois do deploy, valide pelo PowerShell:

```powershell
Get-ChildItem `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" `
-ErrorAction SilentlyContinue |
ForEach-Object {
    Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
} |
Where-Object {
    $_.DisplayName -like "*FortiClient*"
} |
Select-Object DisplayName,DisplayVersion
```

O FortiClient VPN também deverá aparecer entre os aplicativos instalados no Windows.

---

## 12. Logs do Intune

Em caso de falha, consulte os logs do dispositivo:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

Além disso, consulte o status da instalação do aplicativo no próprio Intune para identificar códigos de erro e dispositivos afetados.

---

## 13. Se o MSI desaparecer

Caso o arquivo temporário seja removido antes da cópia:

1. Execute novamente o `FortiClientVPNInstaller.exe`;
2. Mantenha o instalador aberto;
3. Execute o comando PowerShell de busca;
4. Localize o MSI criado recentemente;
5. Copie o arquivo para `C:\INTUNE\FortiClient`;
6. Só depois finalize ou cancele o instalador.

---

## Comando rápido para localizar o MSI

```powershell
Get-ChildItem "$env:TEMP","C:\Windows\Temp","C:\ProgramData" -Recurse -Filter *.msi -ErrorAction SilentlyContinue |
Where-Object LastWriteTime -gt (Get-Date).AddMinutes(-10) |
Sort-Object LastWriteTime -Descending |
Select-Object FullName,Length,LastWriteTime
```

---

## Resultado

```text
FortiClientVPNInstaller.exe
        ↓
MSI localizado durante a instalação
        ↓
MSI copiado
        ↓
Intune
        ↓
Line-of-business app
        ↓
Upload do MSI
        ↓
FortiClient VPN instalado
```

---

## Estrutura sugerida do repositório

```text
FortiClient-Intune/
├── README.md
└── banner_forticlient_intune.svg
```

> Não publique o instalador proprietário do FortiClient no repositório. Mantenha somente documentação e arquivos próprios do projeto.

---

## Tecnologias utilizadas

- Microsoft Intune
- Microsoft Entra ID
- FortiClient VPN
- Windows Installer (MSI)
- PowerShell
- Windows 10 / Windows 11

---

## Autor

**André Luiz**
