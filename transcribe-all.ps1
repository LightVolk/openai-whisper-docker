$ErrorActionPreference = "Stop"

$inputDir = "H:\Syncthing-data\BCS-Fintech\InputVideo"
$outputDir = "H:\Syncthing-data\BCS-Fintech\Transcripts"
$modelCacheDir = Join-Path $PSScriptRoot "models"

if (-not (Test-Path -LiteralPath $inputDir)) {
  throw "Input directory not found: $inputDir"
}

if (-not (Test-Path -LiteralPath $outputDir)) {
  New-Item -ItemType Directory -Path $outputDir | Out-Null
}

if (-not (Test-Path -LiteralPath $modelCacheDir)) {
  New-Item -ItemType Directory -Path $modelCacheDir | Out-Null
}

Get-ChildItem -Path $inputDir -Filter *.mp4 | ForEach-Object {
  $baseName = $_.BaseName
  $outputSubDir = Join-Path $outputDir $baseName

  if (-not (Test-Path -LiteralPath $outputSubDir)) {
    New-Item -ItemType Directory -Path $outputSubDir | Out-Null
  }

  docker run --gpus all -it `
    -v "${modelCacheDir}:/root/.cache/whisper" `
    -v "${inputDir}:/app/in" `
    -v "${outputDir}:/app/out" `
    openai-whisper whisper "/app/in/$($_.Name)" `
    --device cuda --model turbo --language Russian `
    --output_dir "/app/out/$baseName" --output_format txt
}
