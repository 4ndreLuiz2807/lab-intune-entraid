<#
.SYNOPSIS
    Script de remediacao (Intune Proactive Remediation) para Secure Boot + TPM 2.0.
.DESCRIPTION
    Secure Boot e TPM sao configuracoes de firmware (UEFI) e, por padrao, NAO podem
    ser alteradas remotamente pelo Windows. Este script tenta identificar se ha
    uma ferramenta de gerenciamento de BIOS do fabricante disponivel e, se houver,
    tenta habilitar via CLI. Caso contrario, registra a pendencia e notifica o
    usuario com instrucoes para habilitar manualmente na proxima reinicializacao.
    Deve rodar como SYSTEM.
#>

$manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$logPath = "$Env:ProgramData\IntuneRemediation\SecureBootTPM.log"
New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null

function Write-Log($msg) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg" | Out-File -FilePath $logPath -Append
}

$remediated = $false

switch -Wildcard ($manufacturer) {
    "*Dell*" {
        $cctk = "C:\Program Files (x86)\Dell\Command Configure\X86_64\cctk.exe"
        if (Test-Path $cctk) {
            Write-Log "Dell Command | Configure encontrado. Tentando habilitar Secure Boot e TPM."
            & $cctk --secureboot=enable
            & $cctk --tpm=enable
            $remediated = $true
        } else {
            Write-Log "Dell detectado, mas Dell Command | Configure nao instalado. Remediacao automatica nao disponivel."
        }
    }
    "*HP*" {
        Write-Log "HP detectado. Verifique se o modulo HPCMSL (HP.ClientManagement) esta instalado para remediacao via Set-HPBIOSSettingValue."
    }
    "*Lenovo*" {
        Write-Log "Lenovo detectado. Verifique WMI de BIOS Lenovo (Lenovo_SetBiosSetting) para remediacao automatizada."
    }
    default {
        Write-Log "Fabricante '$manufacturer' sem integracao automatica mapeada neste script."
    }
}

if (-not $remediated) {
    Write-Log "Remediacao automatica nao aplicada. Notificando usuario para acao manual."

    # Notificacao Toast para o usuario (requer BurntToast ou notificacao nativa via script separado
    # rodando no contexto do usuario, ja que este script roda como SYSTEM)
    $title = "Acao necessaria: Segurança do dispositivo"
    $message = "Seu dispositivo precisa ter Secure Boot e TPM 2.0 habilitados na BIOS. Contate o suporte de TI para agendar."

    # Registra em um local lido por uma tarefa agendada no contexto do usuario
    # ou por uma politica de notificacao gerenciada separadamente pelo Intune.
    Write-Output "$title : $message"
}

exit 0
