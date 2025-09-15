## \file SmartAgents/Agents/Flight-Plan.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

param (
    [string]$ConfigPath = "FlightPlan\Flight-Plan.config.json"
)

# === Загрузка конфигурации ===
if (-not (Test-Path $ConfigPath)) {
    Write-Host "Файл конфигурации не найден: $ConfigPath" -ForegroundColor Red
    exit 1
}

try {
    $ConfigJson = Get-Content $ConfigPath -Raw
    if (-not ($ConfigJson | Test-Json -ErrorAction SilentlyContinue)) {
        Write-Host "Ошибка: Конфигурационный файл содержит неверный JSON." -ForegroundColor Red
        exit 1
    }
    $Config = $ConfigJson | ConvertFrom-Json
}
catch {
    Write-Host "Не удалось загрузить конфигурацию: $_" -ForegroundColor Red
    exit 1
}

# === Проверка модели ===
$AllowedModels = @("gemini-2.5-flash", "gemini-2.5-pro")
if ($AllowedModels -notcontains $Config.Model) {
    Write-Host "⚠ Указана недопустимая модель '$($Config.Model)'. Используется модель по умолчанию: gemini-2.5-flash" -ForegroundColor Yellow
    $Config.Model = "gemini-2.5-flash"
}

# === Вспомогательные функции ===
function Write-ColoredMessage {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Request-ApiKey {
    param (
        [string]$EnvVar = "GEMINI_API_KEY"
    )

    $apiKey = $env:$EnvVar
    if (-not $apiKey) {
        Write-ColoredMessage "API-ключ не найден в переменной окружения `$EnvVar." -Color $Config.Color.Error
        while ($true) {
            $apiKey = Read-Host "Введите API-ключ"
            if ($apiKey) {
                $env:$EnvVar = $apiKey
                break
            }
            Write-ColoredMessage "API-ключ не может быть пустым. Повторите ввод." -Color $Config.Color.Error
        }
    }
    return $apiKey
}

function Save-History {
    param (
        [string]$Question,
        [string]$Answer
    )
    $entry = @{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Question  = $Question
        Answer    = $Answer
    }
    $json = $entry | ConvertTo-Json -Compress
    Add-Content -Path $Config.HistoryPath -Value $json
}

function Show-History {
    if (Test-Path $Config.HistoryPath) {
        Get-Content $Config.HistoryPath | ForEach-Object {
            if ($_ -and ($_ | Test-Json -ErrorAction SilentlyContinue)) {
                $entry = $_ | ConvertFrom-Json
                Write-ColoredMessage "[$($entry.Timestamp)] Q: $($entry.Question)" -Color $Config.Color.Prompt
                Write-ColoredMessage "A: $($entry.Answer)" -Color $Config.Color.Info
                Write-Host ""
            }
        }
    }
    else {
        Write-ColoredMessage "История пуста." -Color $Config.Color.Info
    }
}

# === Приветствие ===
$line = "═" * 72
Write-Host "╔$line╗" -ForegroundColor White
Write-Host ("║  Добро пожаловать в {0,-63}║" -f "AI Поисковик спецификаций") -ForegroundColor White
Write-Host ("║  Модель: {0,-65}║" -f $Config.Model) -ForegroundColor White
Write-Host "╚$line╝" -ForegroundColor White
Write-Host ""

# === Проверка API-ключа ===
$apiKey = Request-ApiKey
if (-not $apiKey) {
    Write-ColoredMessage "API-ключ обязателен для работы. Завершение." -Color $Config.Color.Error
    exit 1
}

# === Основной цикл ===
while ($true) {
    $selectionContextJson = $null
    $promptText = if ($selectionContextJson) { "$($Config.Emoji)AI [Выборка активна] > " } else { "$($Config.Emoji)AI > " }

    Write-Host -NoNewline $promptText -ForegroundColor $Config.Color.Prompt
    $inputText = Read-Host

    switch -Regex ($inputText) {
        '^exit$' {
            Write-ColoredMessage "Завершение работы. До свидания! [bye]" -Color $Config.Color.Success
            break
        }
        '^history$' {
            Show-History
            continue
        }
        default {
            # Заглушка для обращения к API
            $answer = "Ответ от модели [$($Config.Model)] на запрос: $inputText"
            Write-ColoredMessage $answer -Color $Config.Color.Info
            Save-History -Question $inputText -Answer $answer
        }
    }
}
