# ============================================================
# BLOQUEIO DA MICROSOFT STORE
# Microsoft Intune
#
# Objetivo:
# Bloquear o acesso à Microsoft Store através de políticas
# aplicadas no Registro do Windows.
# ============================================================

$ErrorActionPreference = "Stop"

try {

    Write-Host "Aplicando políticas de bloqueio da Microsoft Store..."

    # ========================================================
    # Política principal da Microsoft Store
    # ========================================================

    $StorePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"

    if (!(Test-Path $StorePolicyPath)) {

        New-Item `
            -Path $StorePolicyPath `
            -Force | Out-Null
    }


    # ========================================================
    # Força comportamento restrito da Store
    # ========================================================

    New-ItemProperty `
        -Path $StorePolicyPath `
        -Name "RequirePrivateStoreOnly" `
        -PropertyType DWord `
        -Value 1 `
        -Force | Out-Null


    # ========================================================
    # Bloqueia o aplicativo Microsoft Store
    # ========================================================

    New-ItemProperty `
        -Path $StorePolicyPath `
        -Name "RemoveWindowsStore" `
        -PropertyType DWord `
        -Value 1 `
        -Force | Out-Null


    # ========================================================
    # Política complementar
    # ========================================================

    $ExplorerPolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    if (!(Test-Path $ExplorerPolicyPath)) {

        New-Item `
            -Path $ExplorerPolicyPath `
            -Force | Out-Null
    }


    New-ItemProperty `
        -Path $ExplorerPolicyPath `
        -Name "NoWindowsStore" `
        -PropertyType DWord `
        -Value 1 `
        -Force | Out-Null


    # ========================================================
    # Mantém comportamento padrão das atualizações
    # ========================================================

    if (
        Get-ItemProperty `
            -Path $StorePolicyPath `
            -Name "AutoDownload" `
            -ErrorAction SilentlyContinue
    ) {

        Remove-ItemProperty `
            -Path $StorePolicyPath `
            -Name "AutoDownload" `
            -ErrorAction SilentlyContinue
    }


    Write-Host "Bloqueio da Microsoft Store aplicado com sucesso."

    exit 0

}
catch {

    Write-Host "Erro ao aplicar bloqueio da Microsoft Store:"
    Write-Host $_.Exception.Message

    exit 1
}