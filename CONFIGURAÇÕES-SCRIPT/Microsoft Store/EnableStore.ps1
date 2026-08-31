# ============================================================
# LIBERAÇÃO DA MICROSOFT STORE
# Microsoft Intune
#
# Objetivo:
# Remover as configurações utilizadas para bloquear
# a Microsoft Store.
# ============================================================

$ErrorActionPreference = "Stop"

try {

    Write-Host "Removendo políticas de bloqueio da Microsoft Store..."

    $StorePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"


    # ========================================================
    # RequirePrivateStoreOnly
    # ========================================================

    if (!(Test-Path $StorePolicyPath)) {

        New-Item `
            -Path $StorePolicyPath `
            -Force | Out-Null
    }

    New-ItemProperty `
        -Path $StorePolicyPath `
        -Name "RequirePrivateStoreOnly" `
        -PropertyType DWord `
        -Value 0 `
        -Force | Out-Null


    # ========================================================
    # RemoveWindowsStore
    # ========================================================

    Remove-ItemProperty `
        -Path $StorePolicyPath `
        -Name "RemoveWindowsStore" `
        -ErrorAction SilentlyContinue


    # ========================================================
    # AutoDownload
    # ========================================================

    Remove-ItemProperty `
        -Path $StorePolicyPath `
        -Name "AutoDownload" `
        -ErrorAction SilentlyContinue


    # ========================================================
    # NoWindowsStore
    # ========================================================

    $ExplorerPolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    if (Test-Path $ExplorerPolicyPath) {

        Remove-ItemProperty `
            -Path $ExplorerPolicyPath `
            -Name "NoWindowsStore" `
            -ErrorAction SilentlyContinue
    }


    Write-Host "Microsoft Store liberada com sucesso."

    exit 0

}
catch {

    Write-Host "Erro ao liberar Microsoft Store:"
    Write-Host $_.Exception.Message

    exit 1
}