param(
    [string]$FfmpegPath = "ffmpeg",
    [switch]$Force,
    [switch]$Recurse,
    [switch]$NoAudio
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$videoExts = @(
    ".mp4", ".mov", ".mkv", ".avi", ".webm", ".wmv", ".m4v"
)

function Resolve-Ffmpeg {
    param([string]$PathHint)

    if ([string]::IsNullOrWhiteSpace($PathHint)) {
        $PathHint = "ffmpeg"
    }

    if ($PathHint -ne "ffmpeg" -and (Test-Path $PathHint)) {
        return (Resolve-Path $PathHint).Path
    }

    $localExe = Join-Path $scriptDir "ffmpeg.exe"
    if (Test-Path $localExe) {
        return $localExe
    }

    $cmd = Get-Command $PathHint -ErrorAction SilentlyContinue
    if ($null -ne $cmd) {
        return $cmd.Source
    }

    throw "ffmpeg not found. Put ffmpeg.exe next to this script, install ffmpeg in PATH, or pass -FfmpegPath <path>."
}

function Get-TargetFiles {
    param([string]$Root, [bool]$DoRecurse)

    $args = @{
        Path = $Root
        File = $true
    }
    if ($DoRecurse) {
        $args.Recurse = $true
    }

    Get-ChildItem @args | Where-Object {
        $ext = $_.Extension.ToLowerInvariant()
        $videoExts -contains $ext
    }
}

$ffmpeg = Resolve-Ffmpeg -PathHint $FfmpegPath
Write-Host "Using ffmpeg: $ffmpeg"
Write-Host "Source folder: $scriptDir"

$files = @(Get-TargetFiles -Root $scriptDir -DoRecurse:$Recurse.IsPresent)
if ($files.Count -eq 0) {
    Write-Host "No source video files found."
    exit 0
}

$converted = 0
$skipped = 0
$failed = 0

foreach ($file in $files) {
    $outPath = [System.IO.Path]::ChangeExtension($file.FullName, ".ogv")

    if ((-not $Force) -and (Test-Path $outPath)) {
        $srcTime = $file.LastWriteTimeUtc
        $dstTime = (Get-Item $outPath).LastWriteTimeUtc
        if ($dstTime -ge $srcTime) {
            Write-Host "Skip (up-to-date): $($file.Name)"
            $skipped++
            continue
        }
    }

    $ffArgs = @(
        "-hide_banner",
        "-loglevel", "warning",
        "-y",
        "-i", $file.FullName,
        "-c:v", "libtheora",
        "-q:v", "7",
        "-pix_fmt", "yuv420p"
    )

    if ($NoAudio) {
        $ffArgs += @("-an")
    } else {
        $ffArgs += @("-c:a", "libvorbis", "-q:a", "4")
    }

    $ffArgs += @($outPath)

    Write-Host "Convert: $($file.Name) -> $(Split-Path -Leaf $outPath)"
    & $ffmpeg @ffArgs
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-Warning "ffmpeg failed ($exitCode): $($file.FullName)"
        $failed++
        continue
    }

    $converted++
}

Write-Host ""
Write-Host "Done. Converted: $converted  Skipped: $skipped  Failed: $failed"
if ($failed -gt 0) {
    exit 1
}
exit 0

