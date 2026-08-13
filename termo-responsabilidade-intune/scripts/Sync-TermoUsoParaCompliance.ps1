<#
.SINOPSE
    Sincroniza aceites do Termos de Uso (Entra ID) com o flag de
    Compliance Customizado do Intune. Roda periodicamente (agendado)
    e faz: aceite no Termos de Uso -> gera o .ok -> Intune fica compliant.

.PRE-REQUISITOS
    1. App Registration no Entra ID com permissões de aplicativo (não delegadas):
       - Agreement.Read.All
       - AgreementAcceptance.Read.All
       - DeviceManagementManagedDevices.Read.All
       Precisa de consentimento de administrador para as três.
    2. Módulo: Install-Module Microsoft.Graph -Scope AllUsers
    3. Rodar numa máquina/servidor com acesso de ESCRITA a \\server221\termos$
       (idealmente uma conta de serviço dedicada, não sua conta pessoal)

.AGENDAMENTO
    Task Scheduler rodando este script a cada 1h (ou o intervalo que preferir).
    Não precisa estar sempre ligado — só precisa rodar periodicamente.
#>

# ================== CONFIGURAÇÃO — AJUSTE AQUI ==================
$TenantId       = "SEU-TENANT-ID"
$ClientId       = "SEU-APP-ID"
$ClientSecret   = "SEU-CLIENT-SECRET"
$AgreementName  = "Termo de Responsabilidade"
$CaminhoBase    = "\\server221\termos$"
# ==================================================================

$SecureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential   = New-Object System.Management.Automation.PSCredential($ClientId, $SecureSecret)
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Credential -NoWelcome

try {
    $agreement = Get-MgIdentityGovernanceTermsOfUseAgreement -All |
        Where-Object { $_.DisplayName -eq $AgreementName } |
        Select-Object -First 1

    if (-not $agreement) {
        throw "Termo de Uso '$AgreementName' não encontrado. Confira o nome exato no Entra ID."
    }

    $acceptances = Get-MgIdentityGovernanceTermsOfUseAgreementAcceptance `
        -AgreementId $agreement.Id -All

    Write-Host "Encontrados $($acceptances.Count) aceites para '$AgreementName'."

    $registrados = 0

    foreach ($acceptance in $acceptances) {
        $userId = $acceptance.UserId

        $devices = Get-MgUserManagedDevice -UserId $userId -All

        foreach ($device in $devices) {
            $hostname = $device.DeviceName
            if ([string]::IsNullOrWhiteSpace($hostname)) { continue }

            $arquivoOk = Join-Path -Path $CaminhoBase -ChildPath "$hostname.ok"
            $dataAceite = $acceptance.RecordedDateTime.ToString("yyyy-MM-dd")

            $conteudoAtual = if (Test-Path $arquivoOk) { Get-Content $arquivoOk -Raw -ErrorAction SilentlyContinue } else { $null }

            if ($conteudoAtual -ne $dataAceite) {
                try {
                    Set-Content -Path $arquivoOk -Value $dataAceite -Encoding UTF8 -Force -ErrorAction Stop
                    Write-Host "  OK: $hostname (usuário $userId, aceite em $dataAceite)"
                    $registrados++
                }
                catch {
                    Write-Warning "  Falha ao gravar flag para $hostname : $_"
                }
            }
        }
    }

    Write-Host "Sincronização concluída. $registrados dispositivo(s) atualizado(s)."
}
finally {
    Disconnect-MgGraph | Out-Null
}
