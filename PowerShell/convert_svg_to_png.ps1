# ===============================
# Batch convert SVG → PNG with Inkscape
# Works on all Windows + any Inkscape version
# ===============================

# --- Locate Inkscape ---
$inkscape = $null
try {
    $cmd = Get-Command inkscape -ErrorAction SilentlyContinue
    if ($cmd) { $inkscape = $cmd.Source }
} catch {}

if (-not $inkscape) {
    $candidates = @(
        "C:\Program Files\Inkscape\bin\inkscape.exe",
        "C:\Program Files\Inkscape\inkscape.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $inkscape = $c; break }
    }
}

if (-not $inkscape) {
    Write-Host "❌ Inkscape not found. Please edit the script and set `$inkscape manually."
    exit 1
}

# --- Detect version (old vs. new CLI syntax) ---
$verOut = & "$inkscape" --version 2>&1
$useNew = $false
if ($verOut -match "Inkscape\s+(\d+\.\d+)") {
    $ver = [double]$matches[1]
    if ($ver -ge 1.0) { $useNew = $true }
}

# --- Prepare output folder ---
$svgDir = (Get-Location).Path
$outDir = Join-Path $svgDir "png"
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

# --- Convert all SVGs ---
$svgs = Get-ChildItem -File -Filter *.svg
if ($svgs.Count -eq 0) {
    Write-Host "⚠ No SVG files found in $svgDir"
    exit 0
}

foreach ($f in $svgs) {
    $outPath = Join-Path $outDir ($f.BaseName + ".png")

    if ($useNew) {
        & "$inkscape" "$($f.FullName)" --export-filename "$outPath" --export-type png
    } else {
        & "$inkscape" "$($f.FullName)" ("--export-png=" + "$outPath")
    }

    if (Test-Path $outPath) {
        Write-Host "✔ Exported: $($f.Name)"
    } else {
        Write-Host "❌ Failed: $($f.Name)"
    }
}
