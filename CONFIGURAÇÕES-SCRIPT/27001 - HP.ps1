Import-Module HPCMSL -Force

$BiosPassword = 'Energia@@4588@@'

# Verifica se existe senha de BIOS
$PasswordIsSet = Get-HPBIOSSetupPasswordIsSet

# Se ainda não existir, cria
if (-not $PasswordIsSet) {
    Set-HPBIOSSetupPassword `
        -NewPassword $BiosPassword
}

# Habilita Secure Boot
Set-HPBIOSSettingValue `
    -Name "Secure Boot" `
    -Value "Enable" `
    -Password $BiosPassword
