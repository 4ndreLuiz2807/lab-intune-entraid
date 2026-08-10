<#
.SYNOPSIS
    Script de deteccao (Intune Proactive Remediation) para Secure Boot + TPM 2.0.
.DESCRIPTION
    Retorna exit code 0 quando o dispositivo esta em conformidade (Secure Boot
    habilitado E TPM 2.0 pronto/habilitado). Retorna exit code 1 caso contrario,
    o que aciona o script de remediacao correspondente no Intune.
    Deve rodar como SYSTEM (nao usar "logged-on credentials").
#>

$secureBootOk = $false
$tpmOk = $false

try {
    $secureBootOk = Confirm-SecureBootUEFI
} catch {
    # Excecao geralmente indica firmware Legacy BIOS/CSM, sem suporte a Secure Boot
    $secureBootOk = $false
}

try {
    $tpm = Get-Tpm
    $tpmOk = $tpm.TpmPresent -and $tpm.TpmReady -and $tpm.TpmEnabled
} catch {
    $tpmOk = $false
}

if ($secureBootOk -and $tpmOk) {
    Write-Output "Compliant: SecureBoot=$secureBootOk TPM=$tpmOk"
    exit 0
} else {
    Write-Output "Non-compliant: SecureBoot=$secureBootOk TPM=$tpmOk"
    exit 1
}
