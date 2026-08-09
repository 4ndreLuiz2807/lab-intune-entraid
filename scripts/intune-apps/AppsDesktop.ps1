$Softwares = @(
   
    @{
        Name = "FortiClient VPN"
        Target = "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"
    },
    @{
        Name = "Foxit PDF Reader"
        Target = "C:\Program Files\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe"
    }
)

$PublicDesktop = "C:\Users\Public\Desktop"

foreach ($Software in $Softwares) {

    $ResolvedPath = Get-ChildItem -Path $Software.Target -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($ResolvedPath) {
        $ShortcutPath = "$PublicDesktop\$($Software.Name).lnk"

        if (!(Test-Path $ShortcutPath)) {
            $WScriptShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
            $Shortcut.TargetPath = $ResolvedPath.FullName
            $Shortcut.WorkingDirectory = Split-Path $ResolvedPath.FullName
            $Shortcut.Save()
        }
    }
}