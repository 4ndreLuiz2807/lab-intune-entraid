$SAP = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -like "SAP GUI for Windows 8.00*"
    } |
    Select-Object -First 1

if ($SAP) {

    Write-Output "SAP GUI detectado: $($SAP.DisplayName)"
    exit 0

}

exit 1