# Инструкция по запуску OpenAI Whisper в Docker (RU)

Этот проект использует `openai-whisper` и `ffmpeg`, поэтому может обрабатывать видеофайлы (Whisper сам извлекает аудио).

## 1) Сборка образа

```bash
docker build -t openai-whisper .
```

## 2) Запуск для одного видео (GPU)

Положите видео в `audio-files`, например `audio-files\video.mp4`, затем:

```bash
docker run --gpus all -it ^
  -v ${PWD}/models:/root/.cache/whisper ^
  -v ${PWD}/audio-files:/app ^
  openai-whisper whisper /app/video.mp4 ^
  --device cuda --model turbo --language Russian ^
  --output_dir /app --output_format txt
```

Результат появится в `audio-files` рядом с исходным файлом.

## 3) Запуск для одного видео (CPU)

```bash
docker run -it ^
  -v ${PWD}/models:/root/.cache/whisper ^
  -v ${PWD}/audio-files:/app ^
  openai-whisper whisper /app/video.mp4 ^
  --model turbo --language Russian ^
  --output_dir /app --output_format txt
```

## 4) Обработка нескольких видео

Whisper умеет принимать несколько файлов, но в Docker удобнее запускать по одному файлу в цикле:

```powershell
Get-ChildItem -Path .\audio-files -Filter *.mp4 | ForEach-Object {
  docker run --gpus all -it `
    -v ${PWD}/models:/root/.cache/whisper `
    -v ${PWD}/audio-files:/app `
    openai-whisper whisper /app/$($_.Name) `
    --device cuda --model turbo --language Russian `
    --output_dir /app --output_format txt
}
```

Если нужно CPU, уберите `--gpus all` и `--device cuda`.

## 5) Модели

- `large-v3` — максимальная точность, но требует больше VRAM.
- `turbo` — более легкая по памяти альтернатива.
