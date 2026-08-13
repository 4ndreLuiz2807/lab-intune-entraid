<#
.SINOPSE
    Discovery script de Compliance Customizado do Intune.
    Verifica se existe um "termo de responsabilidade" assinado/registrado
    para o hostname atual, checando um flag em compartilhamento de rede.

.COMO FUNCIONA
    1. Monta o caminho \\SERVIDOR\Compartilhamento\<HOSTNAME>.ok
    2. Se o arquivo existir -> TermoAssinado = true (le conteudo p/ data)
    3. Se nao existir -> TermoAssinado = false
    4. Devolve JSON no formato exigido pelo Intune (via Write-Host)

.IMPORTANTE
    - O Intune executa este script como SYSTEM. A conta de computador
      (COMPUTER$) do dominio precisa ter permissao de LEITURA no
      compartilhamento de rede abaixo.
    - Ajuste $CaminhoBase para o seu servidor/compartilhamento real.
    - O output DEVE ser um JSON valido de uma linha so via Write-Host.
      Nao use Write-Output, Write-Verbose etc para o resultado final.
#>

# ================== CONFIGURACAO - AJUSTE AQUI ==================
$CaminhoBase = "\\server221\termos$"
# ==================================================================

try {
    $hostname   = $env:COMPUTERNAME
    $arquivoOk  = Join-Path -Path $CaminhoBase -ChildPath "$hostname.ok"

    if (Test-Path -Path $arquivoOk -PathType Leaf) {
        $termoAssinado = $true

        $conteudo = Get-Content -Path $arquivoOk -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($conteudo)) {
            $dataTermo = (Get-Item $arquivoOk).LastWriteTime.ToString("yyyy-MM-dd")
        }
        else {
            $dataTermo = $conteudo.Trim()
        }
    }
    else {
        $termoAssinado = $false
        $dataTermo     = ""
    }
}
catch {
    $termoAssinado = $false
    $dataTermo     = ""
}

$resultado = @{
    TermoAssinado = $termoAssinado
    DataTermo     = $dataTermo
}

Write-Host ($resultado | ConvertTo-Json -Compress)
