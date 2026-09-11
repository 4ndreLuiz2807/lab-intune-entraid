# ============================================================
# AgroCAD - Detecção Intune
# ============================================================

$RegistryPaths = @(

    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",

    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

)

$AgroCAD = Get-ItemProperty `
    $RegistryPaths `
    -ErrorAction SilentlyContinue |
    Where-Object {

        $_.DisplayName -match "AgroCAD"

    } |
    Select-Object -First 1

if ($AgroCAD) {

    Write-Output "AgroCAD instalado - $($AgroCAD.DisplayVersion)"

    exit 0

}

exit 1