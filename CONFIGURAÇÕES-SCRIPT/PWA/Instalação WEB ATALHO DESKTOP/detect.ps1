# ============================================================
# HelpDesk Bio - Detection Script
# Microsoft Intune
# ============================================================

$DetectionFile = "C:\ProgramData\Bioaroeira\HelpDesk\installed.txt"
$IconPath      = "C:\ProgramData\Bioaroeira\HelpDesk\HelpDesk.ico"
$ShortcutPath  = "C:\Users\Public\Desktop\HelpDesk - Bio.url"

$DetectionOK = $true

if (-not (Test-Path $DetectionFile)) {
    $DetectionOK = $false
}

if (-not (Test-Path $IconPath)) {
    $DetectionOK = $false
}

if (-not (Test-Path $ShortcutPath)) {
    $DetectionOK = $false
}

if ($DetectionOK) {

    Write-Output "HelpDesk Bio detected"

    exit 0
}

exit 1