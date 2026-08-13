<#
.SINOPSE
    Marca o termo de responsabilidade de um equipamento como assinado,
    criando o arquivo de flag que o discovery script do Intune verifica.

.USO
    .\Registrar-TermoAssinado.ps1 -Hostname "PC-FULANO01"
    .\Registrar-TermoAssinado.ps1 -Hostname "PC-FULANO01" -DataAssinatura "2026-08-12"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Hostname,

    [string]$DataAssinatura = (Get-Date -Format "yyyy-MM-dd")
)

# ================== CONFIGURAÇÃO — AJUSTE AQUI ==================
$CaminhoBase = "\\server221\termos$"
# ==================================================================

if (-not (Test-Path -Path $CaminhoBase)) {
    Write-Error "Caminho base não encontrado ou inacessível: $CaminhoBase"
    exit 1
}

$arquivoOk = Join-Path -Path $CaminhoBase -ChildPath "$Hostname.ok"

try {
    Set-Content -Path $arquivoOk -Value $DataAssinatura -Encoding UTF8 -Force -ErrorAction Stop

    if (-not (Test-Path -Path $arquivoOk -PathType Leaf)) {
        throw "Set-Content não retornou erro, mas o arquivo não foi encontrado após a gravação."
    }

    Write-Host "Termo registrado para '$Hostname' (data: $DataAssinatura)."
    Write-Host "Arquivo: $arquivoOk"
    Write-Host "O dispositivo ficará compliant na próxima verificação do Intune."
}
catch {
    Write-Error "Falha ao criar o flag: $_"
    Write-Error "Verifique se sua conta tem permissão de ESCRITA em: $CaminhoBase"
    exit 1
}
