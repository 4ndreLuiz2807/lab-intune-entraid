# 🛠️ Ferramentas utilizadas neste laboratório

Catálogo das ferramentas usadas nas práticas deste repositório, com o que cada uma faz e onde conseguir.

## Deploy de aplicativos (Win32 Apps)

| Ferramenta | O que faz | Onde obter |
|---|---|---|
| **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`) | Converte um instalador (`.msi`, `.exe` + script) em um pacote `.intunewin`, formato exigido para publicar apps Win32 no Intune. | [GitHub - microsoft/Microsoft-Win32-Content-Prep-Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool) |
| **IntuneWin32App** (módulo PowerShell da comunidade) | Automatiza a criação e publicação de apps Win32 direto via script, sem precisar clicar no portal para cada app. | Galeria do PowerShell (`Install-Module IntuneWin32App`) |
| **WinGet** | Gerenciador de pacotes nativo do Windows, usado nos scripts de `scripts/intune-apps/` para instalar apps sem precisar empacotar `.intunewin` manualmente. | Já vem no Windows 10/11 atualizado |

### Uso básico do Win32 Content Prep Tool

```powershell
# Empacota um instalador em .intunewin
IntuneWinAppUtil.exe -c "<pasta com o instalador>" -s "install.ps1" -o "<pasta de saida>"
```

O resultado é um único arquivo `.intunewin`, que é o que se sobe no portal do Intune (**Apps → Windows → Add → Win32 app**). Veja [`scripts/forticlient-vpn/README.md`](../scripts/forticlient-vpn/README.md) para um exemplo real de empacotamento usado neste laboratório.

## Identidade e automação (Entra ID / Graph)

| Ferramenta | O que faz | Onde obter |
|---|---|---|
| **Microsoft Graph PowerShell SDK** | Módulo oficial para gerenciar Entra ID, Intune e M365 via script (usado no troubleshooting de Service Principal deste repo). | `Install-Module Microsoft.Graph -Scope AllUsers` |
| **Get-WindowsAutopilotInfo** | Script da comunidade que extrai o Hardware Hash (HWID) de um dispositivo para registro no Autopilot. | `Install-Script -Name Get-WindowsAutopilotInfo` |

## Gerenciamento de BIOS/Firmware (por fabricante)

Usadas no registro [Secure Boot e TPM 2.0](../registros/secureboot-tpm-windows11-readiness.md) para tentar remediar configurações de firmware remotamente.

| Fabricante | Ferramenta |
|---|---|
| Dell | Dell Command \| Configure (CLI `cctk.exe`) |
| HP | HP Client Management Script Library (HPCMSL) |
| Lenovo | WMI de BIOS Lenovo (`Lenovo_SetBiosSetting`) |

## Diagnóstico e suporte

| Ferramenta | O que faz |
|---|---|
| `dsregcmd /status` | Confirma o estado de Hybrid Azure AD Join e Primary Refresh Token (PRT) de uma estação. |
| Event Viewer → `DeviceManagement-Enterprise-Diagnostics-Provider` | Log de eventos de enrollment MDM (evento 76 = falha, 75/72 = sucesso). |
| Company Portal → Diagnósticos | Coleta logs de enrollment/sync direto da máquina do usuário. |

## Automação de processos internos

| Ferramenta | O que faz |
|---|---|
| Power Automate | Fluxos de automação para tarefas recorrentes do dia a dia de TI (ex.: integração com sistemas de chamados). |
| TomTicket API | Integração de chamados de HelpDesk, usada para automações de ticket. |

---

Sugestões de outras ferramentas para incluir? Abra uma issue ou adicione direto seguindo o padrão desta tabela.
