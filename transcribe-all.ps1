$ErrorActionPreference = "Stop"

$inputDir = "H:\Syncthing-data\BCS-Fintech\InputVideo"
$outputDir = "H:\Syncthing-data\BCS-Fintech\Transcripts"
$processedDir = "H:\Syncthing-data\BCS-Fintech\Обработано"
$modelCacheDir = Join-Path $PSScriptRoot "models"
$supportedExtensions = @(".mp4", ".m4a")
$successfullyProcessedFiles = @()

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

$inputFiles = Get-ChildItem -Path $inputDir -File | Where-Object { $_.Extension.ToLowerInvariant() -in $supportedExtensions }

$inputFiles | ForEach-Object {
  $baseName = $_.BaseName
  $outputSubDir = Join-Path $outputDir $baseName
  $expectedTranscriptPath = Join-Path $outputSubDir ($baseName + ".txt")

  if (-not (Test-Path -LiteralPath $outputSubDir)) {
    New-Item -ItemType Directory -Path $outputSubDir | Out-Null
  }

  docker run --gpus all `
    -v "${modelCacheDir}:/root/.cache/whisper" `
    -v "${inputDir}:/app/in" `
    -v "${outputDir}:/app/out" `
    openai-whisper whisper "/app/in/$($_.Name)" `
    --device cuda --model turbo --language Russian `
    --output_dir "/app/out/$baseName" --output_format txt

  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Transcription failed for $($_.Name) with exit code $LASTEXITCODE"
    return
  }

  if (-not (Test-Path -LiteralPath $expectedTranscriptPath)) {
    Write-Warning "Transcript was not created for $($_.Name); source file will remain in input."
    return
  }

  $successfullyProcessedFiles += $_
}

$successfullyProcessedFiles | ForEach-Object {
  Move-Item -LiteralPath $_.FullName -Destination $processedDir
}
