function Crop-SVG {
    [CmdletBinding()]
    param(
        # A single SVG file or a folder containing SVGs
        [Parameter(Mandatory = $true)]
        [string]$Path,

        # Optional: where to put cropped files (defaults to in-place overwrite)
        [string]$OutDir = $null,

        # If set, keeps the original file and writes a new *_cropped.svg beside it (or to OutDir)
        [switch]$KeepOriginal
    )
	
	# --- Create Folder "cropped" ---
	$svgDir = (Get-Location).Path
	$OutDir = Join-Path $svgDir "cropped"
	if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

    # --- Locate inkscape ---
    $ink = $null
    try {
        $cmd = Get-Command inkscape -ErrorAction Stop
        $ink = $cmd.Source
    } catch {
        Write-Error "Inkscape not found in PATH. Install it or add it to PATH, then try again."
        return
    }

    # --- Collect files ---
    $files = @()
    if (Test-Path $Path -PathType Leaf) {
        if ($Path.ToLower().EndsWith(".svg")) {
            $files = ,(Resolve-Path $Path).Path
        } else {
            Write-Error "The provided file is not an .svg: $Path"
            return
        }
    } elseif (Test-Path $Path -PathType Container) {
        $files = Get-ChildItem -Path $Path -Recurse -Filter *.svg | ForEach-Object { $_.FullName }
        if (-not $files) {
            Write-Warning "No .svg files found under: $Path"
            return
        }
    } else {
        Write-Error "Path does not exist: $Path"
        return
    }

    # --- Ensure output dir (if given) ---
    if ($OutDir) {
        if (-not (Test-Path $OutDir)) {
            New-Item -ItemType Directory -Path $OutDir | Out-Null
        }
        $OutDir = (Resolve-Path $OutDir).Path
    }

    # --- Process each file ---
    foreach ($f in $files) {
        $fi = Get-Item $f
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fi.Name)
        $parent = $fi.DirectoryName

        if ($KeepOriginal) {
            $outName = "${baseName}_cropped.svg"
        } else {
            $outName = "${baseName}.svg"   # overwrite unless OutDir is different
        }

        $destDir = $OutDir
        if (-not $destDir) { $destDir = $parent }

        # Preserve subfolder structure when using OutDir on folder input
        if ($OutDir -and (Test-Path $Path -PathType Container)) {
            $rel = Resolve-Path $parent | Split-Path -IsAbsolute:$true
            $rel = $parent.Substring((Resolve-Path $Path).Path.Length).TrimStart('\','/')
            $finalDir = Join-Path $OutDir $rel
            if (-not (Test-Path $finalDir)) { New-Item -ItemType Directory -Path $finalDir | Out-Null }
            $destDir = $finalDir
        }

        $outFile = Join-Path $destDir $outName

        # Inkscape CLI: export area = drawing (fits canvas), write plain SVG, overwrite output
        # Works with Inkscape ≥ 1.0
        & "$ink" `
            "$f" `
            --export-type=svg `
            --export-plain-svg `
            --export-area-drawing `
            --export-overwrite `
            --export-filename="$outFile" | Out-Null

        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $outFile)) {
            Write-Warning "Failed to crop: $f"
        } else {
            Write-Host "Cropped -> $outFile"
            # If overwriting in-place and not keeping original but OutDir used,
            # we already wrote to a different location; nothing else to do.
            if (-not $KeepOriginal -and -not $OutDir) {
                # We exported to same name; nothing to move.
            }
        }
    }
}

Crop-SVG -Path ".\"
