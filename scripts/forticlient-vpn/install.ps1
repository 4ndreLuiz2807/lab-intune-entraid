$PackageName = "FortiClientVPN"

# ATENCAO: a senha do arquivo de configuracao da VPN NAO deve ficar
# em texto puro neste script nem ser commitada no Git.
# Defina-a como variavel de ambiente na maquina que executa o Intunewin
# (ex.: via variavel de ambiente do sistema, ou Azure Key Vault / cofre de
# segredos do Intune) e leia-a em runtime, como abaixo:
$ConfigPW = $Env:FORTICLIENT_VPN_CONFIG_PW
if ([string]::IsNullOrEmpty($ConfigPW)) {
    Write-Error "Variavel de ambiente FORTICLIENT_VPN_CONFIG_PW nao definida. Abortando instalacao."
    exit 1
}

$Path_local = "$Env:Programfiles\_MEM"
$Path_local = "$Env:temp"
Start-Transcript -Path "$Path_local\$PackageName-install.log" -Force
(Start-Process "msiexec.exe" -ArgumentList "/i FortiClientVPN.msi /passive /quiet INSTALLLEVEL=3 DESKTOPSHORTCUT=0 /NORESTART" -NoNewWindow -Wait -PassThru).ExitCode
Start-Sleep 5
Start-Process "C:\Program Files\Fortinet\FortiClient\FCConfig.exe" -ArgumentList "-m vpn -f vpn-bioaroeira.conf -o import -p $ConfigPW" -Wait
Stop-Transcript
