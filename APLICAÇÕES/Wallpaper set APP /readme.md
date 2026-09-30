
# Wallpaper corporativo full cloud — Intune + aplicativo Win32

Documentação baseada no `install.ps1` fornecido para o wallpaper Biomil e na tratativa do erro de extensão da imagem. O pacote distribui o arquivo pelo Intune, sem depender de compartilhamento de rede ou GPO local.

## 1. Como a solução funciona

1. O aplicativo Win32 entrega a imagem e executa o `install.ps1` como SYSTEM.
2. O script cria `C:\WallpaperBiomil`, copia a imagem e grava `versao.txt`.
3. Uma política de configuração do Intune aponta para a imagem instalada e aplica o wallpaper.

**O `install.ps1` anexado instala a imagem, mas não define sozinho o plano de fundo.** Ele não altera políticas de wallpaper, registro de personalização nem o perfil do usuário. A aplicação visual exige a política complementar.

## 2. Requisitos

- Dispositivo Windows em versão suportada, ingressado no Microsoft Entra ID e inscrito no Intune para este cenário full cloud.
- Licenciamento que permita gerenciar o dispositivo no Intune, permissões para publicar aplicativos e criar políticas e conectividade aos serviços.
- Intune Management Extension disponível no dispositivo para processar o aplicativo Win32.
- Windows PowerShell e instalação em contexto **Sistema**, permitindo gravar em `C:\WallpaperBiomil`.
- Microsoft Win32 Content Prep Tool (`IntuneWinAppUtil.exe`) para preparar o pacote.
- Imagem válida e legível pelos usuários, com resolução e proporção adequadas aos monitores.
- Para a política **Personalization CSP**, Windows Enterprise ou Education. No Windows Pro, a Microsoft documenta condições específicas de Shared PC; não considere o Pro comum compatível apenas porque o pacote Win32 instalou.

Referências: [Aplicativos Win32 no Intune](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-win32) e [Personalization CSP](https://learn.microsoft.com/en-us/windows/client-management/mdm/personalization-csp).

## 3. Arquivos do pacote

Mantenha estes arquivos na mesma pasta de origem:

| Arquivo | Finalidade |
| --- | --- |
| `install.ps1` | Script de instalação anexado |
| `Biomil.jpg` | Imagem exigida pelo script atual |
| `uninstall.ps1` | Script de remoção, caso utilize o exemplo abaixo |

O `detect.ps1` sugerido neste README é carregado separadamente na regra de detecção do Intune. Ele não precisa estar dentro do pacote.

Exemplo de pasta: `C:\PacoteWallpaperBiomil`. Salve a saída `.intunewin` em outra pasta, como `C:\SaidaWallpaperBiomil`, para não incluir pacotes antigos no novo conteúdo.

### Erro tratado: PNG versus JPG

No teste anterior, a pasta continha `Biomil.png`, mas o script procurava `Biomil.jpg`. Isso causou:

```text
Biomil.jpg não foi encontrado junto ao install.ps1
```

Escolha uma das correções:

- Converter a imagem de verdade para JPG e salvá-la como `Biomil.jpg`; o script atual pode ser mantido.
- Manter o PNG e alterar as referências no script, na detecção e na política para `.png`.

**Renomear uma extensão não converte o formato da imagem.** Habilite a exibição das extensões no Explorador para evitar nomes como `Biomil.jpg.png`.

## 4. Parâmetros do install.ps1

Estas são variáveis internas; o script atual não recebe parâmetros pela linha de comando.

```powershell
$versao = '1.0.0'
$origem = Join-Path $PSScriptRoot 'Biomil.jpg'
$pasta = 'C:\WallpaperBiomil'
$destino = Join-Path $pasta 'Biomil.jpg'
$temporario = Join-Path $pasta 'Biomil.novo.jpg'
$marcador = Join-Path $pasta 'versao.txt'
```

| Variável | Valor atual | O que alterar |
| --- | --- | --- |
| `$versao` | `1.0.0` | Aumentar a cada atualização e alinhar à detecção |
| `$origem` | `$PSScriptRoot\Biomil.jpg` | Nome e extensão reais da imagem dentro do pacote |
| `$pasta` | `C:\WallpaperBiomil` | Pasta permanente onde a imagem será instalada |
| `$destino` | `$pasta\Biomil.jpg` | Nome final do arquivo usado pela política |
| `$temporario` | `$pasta\Biomil.novo.jpg` | Arquivo intermediário, diferente do destino final |
| `$marcador` | `$pasta\versao.txt` | Marcador de versão usado pela detecção |

`$PSScriptRoot` é a pasta de execução do script. No Intune, será a pasta onde o pacote foi extraído; não deve ser substituído pelo caminho da pasta do seu computador de preparação.

**A imagem instalada é localizada pelo conjunto `$pasta` + nome de `$destino`.** A política deve apontar exatamente para esse arquivo. `$origem` serve apenas para localizar a imagem que acompanha o instalador.

### Exemplo: manter Biomil.png

Substitua o bloco inicial por:

```powershell
$versao = '1.0.0'
$origem = Join-Path $PSScriptRoot 'Biomil.png'
$pasta = 'C:\WallpaperBiomil'
$destino = Join-Path $pasta 'Biomil.png'
$temporario = Join-Path $pasta 'Biomil.novo.png'
$marcador = Join-Path $pasta 'versao.txt'
```

Altere também a mensagem do `throw` para mencionar `Biomil.png`. Depois ajuste a detecção para `C:\WallpaperBiomil\Biomil.png` e a política para `file:///C:/WallpaperBiomil/Biomil.png`.

### Exemplo: outra empresa ou outro nome

```powershell
$versao = '1.0.0'
$origem = Join-Path $PSScriptRoot 'WallpaperEmpresa.jpg'
$pasta = 'C:\WallpaperEmpresa'
$destino = Join-Path $pasta 'WallpaperEmpresa.jpg'
$temporario = Join-Path $pasta 'WallpaperEmpresa.novo.jpg'
$marcador = Join-Path $pasta 'versao.txt'
```

Atualize as mensagens do script, a detecção, a desinstalação e o endereço na política. O nome do arquivo de origem pode diferir do destino, desde que cada referência corresponda à sua função.

## 5. Testar e empacotar

Em PowerShell como administrador, valide os nomes e execute uma instalação local:

```powershell
Get-ChildItem 'C:\PacoteWallpaperBiomil' |
    Select-Object Name, Extension, Length

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\PacoteWallpaperBiomil\install.ps1"

Get-Item 'C:\WallpaperBiomil\Biomil.jpg'
Get-Content 'C:\WallpaperBiomil\versao.txt'
```

Resultado esperado: imagem criada no destino, marcador com `1.0.0` e mensagem de instalação concluída. Abra a imagem para conferir se o arquivo é válido. Esse teste verifica a cópia; a aplicação do wallpaper deve ser validada separadamente.

Exemplo de empacotamento, ajustando o caminho da ferramenta:

```powershell
& 'C:\Ferramentas\IntuneWinAppUtil.exe' `
    -c 'C:\PacoteWallpaperBiomil' `
    -s 'install.ps1' `
    -o 'C:\SaidaWallpaperBiomil' `
    -q
```

Arquivo gerado: `install.intunewin`. Toda alteração no script ou na imagem exige gerar novamente o pacote e enviar o novo conteúdo ao Intune.

## 6. Configuração sugerida do aplicativo Win32

Crie um aplicativo **Windows app (Win32)** no Intune e carregue `install.intunewin`.

| Campo | Configuração sugerida |
| --- | --- |
| Nome | `Wallpaper - Biomil` |
| Versão | Igual a `$versao`, por exemplo `1.0.0` |
| Comando de instalação | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1` |
| Comando de desinstalação | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1` |
| Comportamento de instalação | Sistema |
| Reinicialização | Nenhuma ação específica |
| Código de sucesso | `0` |
| Requisitos de arquitetura e sistema | Conforme os dispositivos Windows suportados do ambiente |
| Atribuição | Obrigatório para um grupo piloto de dispositivos; ampliar após validar |

O comando de desinstalação só funciona se o `uninstall.ps1` existir no pacote.

## 7. Detecção sugerida por imagem e versão

O script abaixo é uma sugestão complementar, não uma transcrição de um `detect.ps1` anexado. Salve como `detect.ps1` e carregue na opção de script de detecção personalizado.

```powershell
$ErrorActionPreference = 'Stop'
$imagem = 'C:\WallpaperBiomil\Biomil.jpg'
$marcador = 'C:\WallpaperBiomil\versao.txt'
$versaoEsperada = '1.0.0'

try {
    if (-not (Test-Path -LiteralPath $imagem -PathType Leaf)) { exit 1 }
    if ((Get-Item -LiteralPath $imagem).Length -le 0) { exit 1 }
    if (-not (Test-Path -LiteralPath $marcador -PathType Leaf)) { exit 1 }

    $versaoInstalada = (Get-Content -LiteralPath $marcador -Raw).Trim()
    if ($versaoInstalada -ne $versaoEsperada) { exit 1 }

    Write-Output "Wallpaper Biomil $versaoEsperada detectado"
    exit 0
}
catch {
    exit 1
}
```

No Intune, use execução em 64 bits para clientes de 64 bits. Para este exemplo sem assinatura, não habilite a exigência de assinatura.

A detecção precisa retornar código `0` e saída em STDOUT para indicar instalação. O marcador é gravado pelo instalador somente após a cópia. A detecção não confirma que o wallpaper já está aplicado na sessão do usuário.

## 8. Aplicar a imagem por política do Intune

Para edições compatíveis com Personalization CSP, uma alternativa é criar um perfil personalizado para Windows com:

| Campo | Valor |
| --- | --- |
| Nome | `Wallpaper - Biomil - Desktop` |
| OMA-URI | `./Vendor/MSFT/Personalization/DesktopImageUrl` |
| Tipo de dados | String |
| Valor | `file:///C:/WallpaperBiomil/Biomil.jpg` |

O CSP aceita URL de arquivo local para JPG, JPEG ou PNG. Use o caminho do **destino instalado**, nunca o caminho da pasta de preparação ou de extração do aplicativo.

Se a opção de área de trabalho não aparecer no template escolhido, use o perfil personalizado acima, verificando antes a edição do Windows. A configuração de tela de bloqueio é separada e não substitui a de área de trabalho.

Instale e confirme a imagem no grupo piloto antes de atribuir a política. Aplicativo e perfil são processados independentemente; atribuí-los juntos não garante que o arquivo exista quando a política for aplicada. Se houver erro por arquivo ausente, instale o pacote, sincronize e verifique novamente o perfil.

Essa política impede a alteração da imagem pelo usuário. O script anexado não configura o modo de ajuste visual, como preencher ou ajustar.

## 9. Atualizar o wallpaper

1. Substitua a imagem na origem.
2. Aumente `$versao`, por exemplo para `1.0.1`.
3. Ajuste `$versaoEsperada` no script de detecção.
4. Reempacote e atualize o conteúdo do aplicativo, sua versão informativa e a regra de detecção.
5. Teste em um dispositivo piloto antes de ampliar.

Alterar só a versão informativa do aplicativo não muda o conteúdo de `versao.txt`. Uma detecção baseada apenas na existência do arquivo também pode impedir a reinstalação da imagem nova.

Se o destino permanecer igual, a política pode manter o endereço. Porém, substituir o arquivo no mesmo caminho não garante atualização visual imediata por causa do cache/processamento do Windows. Se a imagem antiga persistir, use um novo nome de destino, ajuste a detecção e atualize a URL da política depois que o novo arquivo estiver instalado.

## 10. Desinstalação sugerida

Remova primeiro a atribuição Obrigatória do aplicativo para evitar reinstalação. Remova ou ajuste a política antes de excluir a imagem. Salve este exemplo como `uninstall.ps1` na pasta de origem antes de empacotar:

```powershell
$ErrorActionPreference = 'Stop'
$pasta = 'C:\WallpaperBiomil'

foreach ($nome in @('Biomil.jpg', 'Biomil.novo.jpg', 'versao.txt')) {
    $arquivo = Join-Path $pasta $nome
    if (Test-Path -LiteralPath $arquivo -PathType Leaf) {
        Remove-Item -LiteralPath $arquivo -Force
    }
}

if (Test-Path -LiteralPath $pasta -PathType Container) {
    if (@(Get-ChildItem -LiteralPath $pasta -Force).Count -eq 0) {
        Remove-Item -LiteralPath $pasta -Force
    }
}

Write-Output 'Arquivos do wallpaper Biomil removidos'
exit 0
```

Esse exemplo remove os arquivos conhecidos e só exclui a pasta se estiver vazia. Ajuste os nomes para PNG ou outra empresa. Remover os arquivos não restaura automaticamente o wallpaper anterior.

## 11. Diagnóstico

| Sintoma | Verificação e tratativa |
| --- | --- |
| `Biomil.jpg não foi encontrado` | Conferir nome/extensão em `$origem` e incluir a imagem na mesma pasta do script antes de empacotar |
| Script corrigido, mas Intune continua usando o antigo | Gerar novo `.intunewin` e atualizar o conteúdo enviado |
| Acesso negado ao destino | Verificar instalação em contexto Sistema e permissões da pasta |
| Imagem copiada, mas aplicativo marcado como não instalado | Conferir caminho, versão, saída e código de retorno da detecção |
| Aplicativo instalado, mas fundo não mudou | Verificar a política complementar, edição do Windows, URL, atribuição e conflitos |
| Política falhou antes da instalação | Confirmar o arquivo local e sincronizar/reavaliar o perfil |
| Imagem antiga continua aparecendo | Conferir versão e conteúdo instalado; testar novo nome de imagem e atualizar a política |
| Opção de área de trabalho ausente no template | Usar perfil personalizado compatível e revisar a edição do Windows |

Verificações locais:

```powershell
Test-Path 'C:\WallpaperBiomil\Biomil.jpg'
Get-Content 'C:\WallpaperBiomil\versao.txt'
Get-Item 'C:\WallpaperBiomil\Biomil.jpg' |
    Select-Object FullName, Length, LastWriteTime
```

Para investigar o aplicativo, consulte os logs em `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs` e o status de instalação no Intune. Para a aplicação visual, consulte separadamente o status do perfil de configuração por dispositivo.

## 12. Escopo da validação

O `install.ps1` anexado foi inspecionado para documentar seus caminhos, versão e comportamento. Os exemplos de detecção, remoção e política acima completam o procedimento proposto; não representam execução ou validação remota nos dispositivos do tenant.
