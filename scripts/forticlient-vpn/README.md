# Pacote FortiClient VPN (Intune Win32 App)

Este diretório documenta o empacotamento do FortiClient VPN para deploy via Intune, mas **não contém os binários**:

- `FortiClientVPN.msi` (~191 MB) e `FortiClientVPN_intunewin.zip` (~172 MB) **não foram incluídos no repositório** porque excedem o limite de 100 MB por arquivo do GitHub e não fazem sentido versionados em texto.
- Mantenha esses arquivos localmente (ex.: em uma pasta compartilhada da equipe, SharePoint ou storage account) e referencie o caminho no seu registro de prática.

## Sobre a senha do arquivo de configuração da VPN

O `install.ps1` original lia a senha do `vpn-bioaroeira.conf` de uma variável fixa no próprio script. **Isso foi removido** — a versão aqui lê de uma variável de ambiente (`FORTICLIENT_VPN_CONFIG_PW`) que deve ser definida na máquina/pipeline que executa o pacote, nunca commitada.

No Intune, isso normalmente é resolvido de duas formas:
1. Definindo a variável de ambiente como parte do pacote `.intunewin` (fora do controle de versão), ou
2. Usando um cofre de segredos (Azure Key Vault) e buscando o valor em runtime.

## Como empacotar (referência)

1. Colocar `FortiClientVPN.msi`, `install.ps1` e `vpn-bioaroeira.conf` na mesma pasta local.
2. Gerar o `.intunewin` com o **Microsoft Win32 Content Prep Tool**:
   ```
   IntuneWinAppUtil.exe -c <pasta_origem> -s install.ps1 -o <pasta_saida>
   ```
3. Subir o `.intunewin` gerado no Intune como app Win32, com comando de instalação:
   ```
   powershell.exe -ExecutionPolicy Bypass -File install.ps1
   ```
