$ErrorActionPreference = "Stop"

$inputDir = "H:\Syncthing-data\BCS-Fintech\InputVideo"
$outputDir = "H:\Syncthing-data\BCS-Fintech\Transcripts"
$processedDir = "H:\Syncthing-data\BCS-Fintech\Обработано"
$modelCacheDir = Join-Path $PSScriptRoot "models"
$lockFilePath = Join-Path $PSScriptRoot ".transcribe-all.lock"
$supportedExtensions = @(".mp4", ".m4a")
$scriptStartedAt = Get-Date

if (-not (Test-Path -LiteralPath $inputDir)) {
  throw "Input directory not found: $inputDir"
}

if (-not (Test-Path -LiteralPath $outputDir)) {
  New-Item -ItemType Directory -Path $outputDir | Out-Null
}

if (-not (Test-Path -LiteralPath $modelCacheDir)) {
  New-Item -ItemType Directory -Path $modelCacheDir | Out-Null
}

if (-not (Test-Path -LiteralPath $processedDir)) {
  New-Item -ItemType Directory -Path $processedDir | Out-Null
}

if (Test-Path -LiteralPath $lockFilePath) {
  $lockContent = Get-Content -LiteralPath $lockFilePath -ErrorAction SilentlyContinue
  $activePid = 0

  if ($lockContent.Count -gt 0) {
    [void][int]::TryParse($lockContent[0], [ref]$activePid)
  }

  if ($activePid -gt 0 -and (Get-Process -Id $activePid -ErrorAction SilentlyContinue)) {
    throw "transcribe-all.ps1 is already running under PID $activePid. If that process is gone, delete '$lockFilePath' and try again."
  }

  Write-Warning "Found stale lock file '$lockFilePath'. It will be replaced."
}

Set-Content -LiteralPath $lockFilePath -Value @($PID, $scriptStartedAt.ToString("o"))

try {
  $inputFiles = Get-ChildItem -Path $inputDir -File | Where-Object { $_.Extension.ToLowerInvariant() -in $supportedExtensions } | Sort-Object Name
  $totalFiles = $inputFiles.Count
  $currentIndex = 0

  Write-Host "Queued files: $totalFiles"

  foreach ($inputFile in $inputFiles) {
    $currentIndex++
    $baseName = $inputFile.BaseName
    $outputSubDir = Join-Path $outputDir $baseName
    $expectedTranscriptPath = Join-Path $outputSubDir ($baseName + ".txt")
    $fileStartedAt = Get-Date

    if (Test-Path -LiteralPath $expectedTranscriptPath) {
      Write-Host "[$currentIndex/$totalFiles] Skipping '$($inputFile.Name)' because transcript already exists."
      Move-Item -LiteralPath $inputFile.FullName -Destination $processedDir -Force
      continue
    }

    if (-not (Test-Path -LiteralPath $outputSubDir)) {
      New-Item -ItemType Directory -Path $outputSubDir | Out-Null
    }

    Write-Host "[$currentIndex/$totalFiles] Starting '$($inputFile.Name)' ($( [math]::Round($inputFile.Length / 1GB, 2) ) GB)..."

    docker run --rm --gpus all `
      -v "${modelCacheDir}:/root/.cache/whisper" `
      -v "${inputDir}:/app/in" `
      -v "${outputDir}:/app/out" `
      openai-whisper whisper "/app/in/$($inputFile.Name)" `
      --device cuda --model turbo --language Russian `
      --output_dir "/app/out/$baseName" --output_format txt

    if ($LASTEXITCODE -ne 0) {
      Write-Warning "[$currentIndex/$totalFiles] Transcription failed for '$($inputFile.Name)' with exit code $LASTEXITCODE"
      continue
    }

    if (-not (Test-Path -LiteralPath $expectedTranscriptPath)) {
      Write-Warning "[$currentIndex/$totalFiles] Transcript was not created for '$($inputFile.Name)'; source file will remain in input."
      continue
    }

    Move-Item -LiteralPath $inputFile.FullName -Destination $processedDir -Force

    $elapsed = (Get-Date) - $fileStartedAt
    Write-Host "[$currentIndex/$totalFiles] Finished '$($inputFile.Name)' in $($elapsed.ToString('hh\:mm\:ss'))."
  }
}
finally {
  if (Test-Path -LiteralPath $lockFilePath) {
    Remove-Item -LiteralPath $lockFilePath -Force
  }
}
