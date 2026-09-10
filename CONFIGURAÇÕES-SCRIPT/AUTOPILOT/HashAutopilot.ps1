$PastaLocal = "C:\Autopilot"
$DestinoRede = "\\server02\mapeamentos$\Autopilot"

$Hostname = $env:COMPUTERNAME

$ArquivoLocal = "$PastaLocal\$Hostname.csv"
$ArquivoRede  = "$DestinoRede\$Hostname.csv"
$Log          = "$PastaLocal\GPO-Autopilot.log"

if (!(Test-Path $PastaLocal)) {
    New-Item -Path $PastaLocal -ItemType Directory -Force | Out-Null
}

"$(Get-Date) - Inicio script - Usuario: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" |
    Out-File $Log -Append

try {

    $Serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber

    $Hash = (
        Get-CimInstance `
            -Namespace "root/cimv2/mdm/dmmap" `
            -ClassName "MDM_DevDetail_Ext01" `
            -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" `
            -ErrorAction Stop
    ).DeviceHardwareData

    if ([string]::IsNullOrWhiteSpace($Hash)) {
        throw "Hardware Hash vazio."
    }

    [PSCustomObject]@{
        "Device Serial Number" = $Serial
        "Windows Product ID"   = ""
        "Hardware Hash"        = $Hash
        "Group Tag"            = ""
        "Assigned User"        = ""
    } | Export-Csv `
        -Path $ArquivoLocal `
        -NoTypeInformation `
        -Encoding UTF8 `
        -Force

    "$(Get-Date) - CSV local criado: $ArquivoLocal" |
        Out-File $Log -Append

}
catch {

    "$(Get-Date) - ERRO COLETA: $($_.Exception.Message)" |
        Out-File $Log -Append

    exit 1
}

Start-Sleep -Seconds 10

try {

    if (!(Test-Path $DestinoRede)) {
        throw "Destino de rede indisponivel."
    }

    Copy-Item `
        -Path $ArquivoLocal `
        -Destination $ArquivoRede `
        -Force `
        -ErrorAction Stop

    "$(Get-Date) - CSV copiado para: $ArquivoRede" |
        Out-File $Log -Append

}
catch {

    "$(Get-Date) - ERRO COPIA: $($_.Exception.Message)" |
        Out-File $Log -Append

    exit 2
}

exit 0