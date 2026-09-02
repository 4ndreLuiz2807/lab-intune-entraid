# ============================================================
# DETECCAO - ORACLE PIMCS CONFIG
# Microsoft Intune Win32
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$BDEPath = "C:\Program Files (x86)\Common Files\Borland Shared\BDE"

$SQLORA8 = Join-Path $BDEPath "sqlora8.dll"
$IDAPI   = Join-Path $BDEPath "IDAPI32.CFG"
$WinINI  = "C:\Windows\win.ini"

$RequiredPathEntries = @(
    "I:\Deploy",
    "I:\Deploy\Axis2c\lib"
)

# ============================================================
# VALIDAR SQLORA8.DLL
# ============================================================

if (!(Test-Path $SQLORA8)) {
    exit 1
}

# ============================================================
# VALIDAR IDAPI32.CFG
# ============================================================

if (!(Test-Path $IDAPI)) {
    exit 1
}

# ============================================================
# VALIDAR WIN.INI
# ============================================================

if (!(Test-Path $WinINI)) {
    exit 1
}

# ============================================================
# VALIDAR CONFIGURACAO PIMS NO WIN.INI
# ============================================================

$WinINIContent = Get-Content $WinINI -Raw -ErrorAction SilentlyContinue

$RequiredWinINIEntries = @(
    "[PIMSCS]",
    "ControlFile=I:\ini\PIMSCS.INI",
    "[PIMSTST]",
    "ControlFile=I:\ini\PIMSTST.INI",
    "[PIMSCET]",
    "ControlFile=I:\INI\PIMSCET.INI"
)

foreach ($Entry in $RequiredWinINIEntries) {

    if ($WinINIContent -notlike "*$Entry*") {
        exit 1
    }
}

# ============================================================
# VALIDAR PATH DO SISTEMA
# ============================================================

$MachinePath = [Environment]::GetEnvironmentVariable(
    "Path",
    [EnvironmentVariableTarget]::Machine
)

if ([string]::IsNullOrWhiteSpace($MachinePath)) {
    exit 1
}

$PathEntries = $MachinePath -split ";" |
    ForEach-Object {
        $_.Trim().TrimEnd("\")
    }

foreach ($RequiredPath in $RequiredPathEntries) {

    $NormalizedPath = $RequiredPath.TrimEnd("\")

    $Found = $PathEntries |
        Where-Object {
            $_ -ieq $NormalizedPath
        }

    if (!$Found) {
        exit 1
    }
}

# ============================================================
# DETECCAO CONCLUIDA
# ============================================================

Write-Output "Oracle-PIMCS-Config detectado com sucesso."
exit 0