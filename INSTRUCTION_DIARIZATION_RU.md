# Диаризация (кто говорит) через отдельный инструмент

Этот репозиторий сам по себе не разделяет речь по спикерам. Для диаризации удобнее использовать отдельный инструмент. На практике чаще всего используют `whisperx` (поверх Whisper + диаризация через `pyannote.audio`).

Ниже — отдельная инструкция для Windows + PowerShell с упором на GPU.

## 1) Предпосылки

- Установлен NVIDIA драйвер и CUDA, рабочий `nvidia-smi`.
- Установлен Python 3.10+.
- Установлен `ffmpeg` и он доступен в PATH.
- Есть токен Hugging Face (нужен для моделей диаризации).

## 2) Установка

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -U pip
pip install -U whisperx
```

Если установленный `torch` не видит GPU, поставьте CUDA‑совместимую сборку PyTorch по официальной инструкции PyTorch.

## 3) Запуск для одного видео с диаризацией (GPU)

```powershell
$env:HF_TOKEN="ВАШ_HF_ТОКЕН"
whisperx .\audio-files\video.mp4 `
  --model large-v3 `
  --device cuda `
  --language ru `
  --diarize `
  --output_dir .\audio-files
```

Где искать результат:
- Текст и временные метки обычно появляются в `.txt/.srt/.json` в каталоге `audio-files`.
- Диаризация (Speaker 0/1/2) обычно сохраняется в JSON.

Параметры CLI могут немного отличаться по версиям — при необходимости проверьте `whisperx --help`.

## 4) Обработка нескольких видео (PowerShell)

```powershell
$env:HF_TOKEN="ВАШ_HF_ТОКЕН"
Get-ChildItem -Path .\audio-files -Filter *.mp4 | ForEach-Object {
  whisperx $_.FullName `
    --model large-v3 `
    --device cuda `
    --language ru `
    --diarize `
    --output_dir .\audio-files
}
```

Если нужно ограничить количество спикеров, ищите параметры `--min_speakers` и `--max_speakers` в `whisperx --help`.
