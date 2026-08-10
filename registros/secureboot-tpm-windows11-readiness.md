# Secure Boot e TPM 2.0 — Readiness para Windows 11 via Intune

**Área:** Intune
**Objetivo:** Detectar e (quando possível) corrigir remotamente dispositivos sem Secure Boot/TPM 2.0 habilitados, pré-requisito para Windows 11

---

## Contexto

Windows 11 exige **Secure Boot habilitado** e **TPM 2.0 ativo** no firmware (UEFI). Em ambientes com parque de máquinas herdado, é comum encontrar Secure Boot desabilitado ou TPM desativado na BIOS — e isso **não pode ser alterado remotamente por padrão do Windows**, pois é uma configuração de firmware, fora do alcance do SO. Existem três caminhos práticos:

1. **Detectar** via Intune (compliance policy ou script de inventário) quais máquinas estão fora do padrão.
2. **Corrigir remotamente** nas máquinas onde o fabricante oferece uma ferramenta de linha de comando para BIOS (ex.: Dell Command | Configure, HP BIOS Configuration Utility/CMSL, Lenovo WMI).
3. **Notificar o usuário** para habilitar manualmente na BIOS, nas máquinas sem ferramenta OEM disponível ou quando a BIOS tem senha.

## Passo a passo realizado

### 1. Detecção via script (Proactive Remediation / relatório)

Script de detecção (`DetectSecureBootTPM.ps1`) — retorna exit code 1 quando o dispositivo está fora de conformidade, o que aciona o script de remediação automaticamente no fluxo do Intune:

```powershell
$secureBootOk = $false
$tpmOk = $false

try {
    $secureBootOk = Confirm-SecureBootUEFI
} catch {
    $secureBootOk = $false  # firmware legado (BIOS/Legacy), não suporta Secure Boot
}

try {
    $tpm = Get-Tpm
    $tpmOk = $tpm.TpmPresent -and $tpm.TpmReady -and $tpm.TpmEnabled
} catch {
    $tpmOk = $false
}

if ($secureBootOk -and $tpmOk) {
    Write-Output "Compliant: Secure Boot e TPM 2.0 OK"
    exit 0
} else {
    Write-Output "Non-compliant: SecureBoot=$secureBootOk TPM=$tpmOk"
    exit 1
}
```

### 2. Remediação (quando possível) + notificação

Script de remediação (`RemediateSecureBootTPM.ps1`) — tenta identificar o fabricante e, se houver ferramenta OEM instalada, tenta habilitar via CLI; caso contrário, notifica o usuário com instruções.

> A remediação automática só funciona em modelos com ferramenta de gerenciamento de BIOS instalada (Dell Command \| Configure, HP CMSL, etc.) e sem senha de BIOS. Na maioria dos parques mistos, o caminho realista é notificar o usuário.

### 3. Publicar como Proactive Remediation no Intune

Portal Intune → **Reports → Endpoint analytics → Proactive remediations** → Create script package:

| Campo | Valor |
|---|---|
| Detection script | `DetectSecureBootTPM.ps1` |
| Remediation script | `RemediateSecureBootTPM.ps1` |
| Run this script using the logged-on credentials | Não (rodar como SYSTEM, necessário para `Get-Tpm`) |
| Enforce script signature check | Conforme política da organização |
| Run script in 64-bit PowerShell | Sim |

Atribuir a um grupo de dispositivos piloto antes de expandir para todo o parque — a remediação silenciosa via OEM tool deve ser testada em poucas máquinas primeiro.

### 4. Alternativa via Compliance Policy (somente detecção/relatório)

Para apenas **reportar** sem tentar corrigir, uma Compliance Policy do Intune com "Require TPM" já cobre o TPM nativamente (Devices → Compliance policies → Windows 10 and later → Device Health). Secure Boot não tem toggle nativo na compliance policy — por isso o script acima complementa o que a policy não cobre.

### 5. Passo manual (quando a máquina precisa de intervenção física)

Para o usuário final, ou para o técnico indo até a máquina:

1. Reiniciar e entrar na BIOS/UEFI (tecla varia por fabricante: F2, F10, F12, Del, Esc).
2. Localizar **Boot** ou **Security** → **Secure Boot** → **Enabled**.
3. Localizar **Security** → **TPM** / **PTT** (Intel) / **fTPM** (AMD) → **Enabled**.
4. Salvar e sair (geralmente F10).
5. Validar no Windows: `Confirm-SecureBootUEFI` deve retornar `True`, e `Get-Tpm` deve mostrar `TpmReady: True`.

## Problemas encontrados e soluções

- **Problema:** `Confirm-SecureBootUEFI` lança exceção em vez de retornar `False`.
  **Causa:** a máquina está em modo Legacy BIOS/CSM, não UEFI — Secure Boot não é sequer uma opção disponível nesse modo.
  **Solução:** verificar se o disco está em GPT (`Get-Disk`) e se há suporte a conversão para UEFI (MBR2GPT) antes de tentar habilitar Secure Boot.

- **Problema:** `Get-Tpm` mostra `TpmPresent: True` mas `TpmReady: False`.
  **Causa:** TPM presente no hardware mas desabilitado na BIOS, ou precisa de "Clear TPM".
  **Solução:** habilitar na BIOS (passo manual acima); se já habilitado e ainda `False`, rodar `Initialize-Tpm` no Windows.

## Checklist rápido

- [ ] Script de detecção testado localmente em pelo menos 1 máquina compliant e 1 non-compliant
- [ ] Script de remediação testado em grupo piloto (não em produção direto)
- [ ] Proactive Remediation publicada e agendada (ex.: diária)
- [ ] Compliance Policy com "Require TPM" habilitada como camada adicional
- [ ] Processo documentado para o time de suporte físico (passo manual) nas máquinas sem ferramenta OEM

## Referências

- Scripts: [`DetectSecureBootTPM.ps1`](../scripts/intune-remediation/DetectSecureBootTPM.ps1), [`RemediateSecureBootTPM.ps1`](../scripts/intune-remediation/RemediateSecureBootTPM.ps1)
- Requisitos oficiais de hardware do Windows 11 (Secure Boot + TPM 2.0): consultar a documentação da Microsoft para a versão vigente, pois os requisitos mínimos podem ser atualizados.
