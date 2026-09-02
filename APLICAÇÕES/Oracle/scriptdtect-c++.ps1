# ============================================================
# DETECCAO DIAGNOSTICA
# C++ + TEAM DEVELOPER + BDE
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$Programs = @()

$Programs += Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue

$Programs += Get-ItemProperty `
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue


$Missing = @()


# TEAM DEVELOPER
$Team = $Programs | Where-Object {
    $_.DisplayName -like "*Team Developer 7.3 Deployment*"
}

if (!$Team) {
    $Missing += "Team Developer 7.3"
}


# VC++ 2008 x86
$VC2008x86 = $Programs | Where-Object {
    $_.DisplayName -like "*Visual C++ 2008*" -and
    $_.DisplayName -match "x86"
}

if (!$VC2008x86) {
    $Missing += "Visual C++ 2008 x86"
}


# VC++ 2008 x64
$VC2008x64 = $Programs | Where-Object {
    $_.DisplayName -like "*Visual C++ 2008*" -and
    $_.DisplayName -match "x64"
}

if (!$VC2008x64) {
    $Missing += "Visual C++ 2008 x64"
}


# VC++ 2013 x86
$VC2013x86 = $Programs | Where-Object {
    $_.DisplayName -like "*Visual C++ 2013*" -and
    $_.DisplayName -match "x86"
}

if (!$VC2013x86) {
    $Missing += "Visual C++ 2013 x86"
}


# VC++ 2013 x64
$VC2013x64 = $Programs | Where-Object {
    $_.DisplayName -like "*Visual C++ 2013*" -and
    $_.DisplayName -match "x64"
}

if (!$VC2013x64) {
    $Missing += "Visual C++ 2013 x64"
}


# BDE
$BDEAdmin = "C:\Program Files (x86)\Common Files\Borland Shared\BDE\BDEADMIN.EXE"

if (!(Test-Path $BDEAdmin)) {
    $Missing += "BDEADMIN.EXE"
}


# RESULTADO
if ($Missing.Count -gt 0) {

    Write-Output "NAO DETECTADO: $($Missing -join ', ')"
    exit 1
}


Write-Output "DETECTED: C++ / Team Developer / BDE"
exit 0