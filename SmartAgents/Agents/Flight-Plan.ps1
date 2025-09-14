## \file SmartAgents/Agents/Flight-Plan.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
Агент планирования перелетов
============================

.. module:: SmartAgents.FlightPlanAgent
"""

function Start-FlightPlanAgent {
    <#
    .SYNOPSIS
        Запуск AI-агента планирования перелетов
    
    .PARAMETER Model
        Модель Gemini для использования
    
    .PARAMETER ApiKey
        API ключ Google Gemini (опционально, если установлен в переменной окружения)
        
    .PARAMETER Key
        Псевдоним для параметра ApiKey
    
    .EXAMPLE
        Start-FlightPlanAgent
        Запускает агента с проверкой наличия API ключа
        
    .EXAMPLE
        Start-FlightPlanAgent -ApiKey "your-api-key"
        Запускает агента с указанным API ключом
        
    .EXAMPLE
        Start-FlightPlanAgent -Key "your-api-key"
        Запускает агента с указанным API ключом (короткий синтаксис)
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('gemini-2.5-pro', 'gemini-2.5-flash')]
        [string]$Model = 'gemini-2.5-flash',
        
        [string]$ApiKey,
        
        [Alias('Key')]
        [string]$K
    )
    
    # Функция запроса API ключа
    function Request-ApiKey {
        """Функция запрашивает API ключ у пользователя"""
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║                          ТРЕБУЕТСЯ GEMINI API КЛЮЧ                             ║" -ForegroundColor Yellow
        Write-Host "╠════════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
        Write-Host "║  API ключ не найден в переменной окружения GEMINI_API_KEY                      ║" -ForegroundColor White
        Write-Host "║  и не был предоставлен в качестве параметра.                                   ║" -ForegroundColor White
        Write-Host "║                                                                                ║" -ForegroundColor White
        Write-Host "║  Способы получения API ключа:                                                  ║" -ForegroundColor Cyan
        Write-Host "║  1. Перейдите на https://aistudio.google.com/app/apikey                        ║" -ForegroundColor Gray
        Write-Host "║  2. Войдите в свой аккаунт Google                                              ║" -ForegroundColor Gray
        Write-Host "║  3. Нажмите 'Create API key'                                                   ║" -ForegroundColor Gray
        Write-Host "║  4. Скопируйте созданный ключ                                                  ║" -ForegroundColor Gray
        Write-Host "║                                                                                ║" -ForegroundColor White
        Write-Host "║  Способы установки:                                                            ║" -ForegroundColor Cyan
        Write-Host "║  • Через параметр: Start-FlightPlanAgent -ApiKey 'ваш-ключ'                    ║" -ForegroundColor Gray
        Write-Host "║  • Через переменную: `$env:GEMINI_API_KEY = 'ваш-ключ'                         ║" -ForegroundColor Gray
        Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        
        # Запрос ввода ключа
        $inputKey = $null
        while ([string]::IsNullOrWhiteSpace($inputKey)) {
            Write-Host "Введите ваш Gemini API ключ (или 'exit' для выхода): " -ForegroundColor Cyan -NoNewline
            $inputKey = Read-Host
            
            if ($inputKey -eq 'exit') {
                Write-Host "Выход из агента." -ForegroundColor Yellow
                return $null
            }
            
            if ([string]::IsNullOrWhiteSpace($inputKey)) {
                Write-Host "Ключ не может быть пустым. Попробуйте еще раз." -ForegroundColor Red
            }
        }
        
        # Валидация формата ключа (базовая проверка)
        if ($inputKey.Length -lt 20 -or -not ($inputKey -match '^[A-Za-z0-9_-]+$')) {
            Write-Host ""
            Write-Host "⚠️  Предупреждение: Формат ключа выглядит подозрительно." -ForegroundColor Yellow
            Write-Host "    API ключи Google обычно содержат буквы, цифры, дефисы и подчеркивания" -ForegroundColor Yellow
            Write-Host "    и имеют длину более 20 символов." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Продолжить с введенным ключом? (y/N): " -ForegroundColor Yellow -NoNewline
            $confirm = Read-Host
            if ($confirm -notmatch '^[Yy]') {
                return Request-ApiKey  # Рекурсивный вызов для повторного ввода
            }
        }
        
        Write-Host ""
        Write-Host "✓ API ключ получен. Сохранить его в переменную окружения для этой сессии? (Y/n): " -ForegroundColor Green -NoNewline
        $save = Read-Host
        if ($save -notmatch '^[Nn]') {
            $env:GEMINI_API_KEY = $inputKey
            Write-Host "✓ API ключ сохранен в `$env:GEMINI_API_KEY для текущей сессии." -ForegroundColor Green
        }
        
        return $inputKey
    }
    
    # Определение API ключа
    $finalApiKey = $null
    
    # Приоритет: параметры -> переменная окружения
    if (-not [string]::IsNullOrWhiteSpace($K)) {
        $finalApiKey = $K
        Write-Host "Использован API ключ из параметра -Key" -ForegroundColor Green
    } elseif (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $finalApiKey = $ApiKey
        Write-Host "Использован API ключ из параметра -ApiKey" -ForegroundColor Green
    } elseif (-not [string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
        $finalApiKey = $env:GEMINI_API_KEY
        Write-Host "Использован API ключ из переменной окружения GEMINI_API_KEY" -ForegroundColor Green
    } else {
        # Запрос ключа у пользователя
        $finalApiKey = Request-ApiKey
        if (-not $finalApiKey) {
            return  # Пользователь выбрал выход
        }
    }
    
    # Инициализация конфигурации агента
    $agentRoot = Join-Path $PSScriptRoot '..\FlightPlan'
    $Config = New-GeminiConfig -AppName 'AI-планировщик перелетов' -Emoji '✈️' -SessionPrefix 'flight_session' -AgentRoot $agentRoot

    # --- Вложенные функции, специфичные для этого агента ---
    function Show-FlightHelp {
        """Функция отображает справку по агенту планирования перелетов"""
        $helpFilePath = Join-Path $Config.ConfigDir "ShowHelp.md"
        if (-not (Test-Path $helpFilePath)) {
            Write-Warning "Файл справки не найден: $helpFilePath"
            return
        }
        Get-Content -Path $helpFilePath -Raw | Write-Host
    }

    function Show-History {
        """Функция отображает историю сессии"""
        param([string]$HistoryFilePath)
        if (-not (Test-Path $HistoryFilePath)) {
            Write-ColoredMessage "История сессии пуста." -Color $Config.Color.Warning
            return
        }
        Get-Content $HistoryFilePath | ForEach-Object {
            $entry = $_ | ConvertFrom-Json
            if ($entry.user) {
                Write-ColoredMessage "USER: $($entry.user)" -Color $Config.Color.Info
            }
            if ($entry.model) {
                Write-ColoredMessage "MODEL: $($entry.model)" -Color 'White'
            }
        }
    }

    function Clear-History {
        """Функция очищает историю сессии"""
        param([string]$HistoryFilePath)
        if (Test-Path $HistoryFilePath) {
            Remove-Item $HistoryFilePath -Force
        }
        Write-ColoredMessage "История сессии очищена." -Color $Config.Color.Warning
    }
    
    function Command-Handler-Flight {
        """Функция обрабатывает системные команды агента"""
        param([string]$Command, [string]$HistoryFilePath)
        switch ($Command.Trim().ToLower()) {
            '?'         { Show-FlightHelp; return 'continue' }
            'help'      { Show-FlightHelp; return 'continue' }
            'history'   { Show-History -HistoryFilePath $HistoryFilePath; return 'continue' }
            'clear'     { Clear-History -HistoryFilePath $HistoryFilePath; return 'continue' }
            'exit'      { return 'break' }
            'quit'      { return 'break' }
            'key'       { Show-ApiKeyInfo; return 'continue' }
            default     { return $null }
        }
    }
    
    function Show-ApiKeyInfo {
        """Функция показывает информацию об используемом API ключе"""
        $keySource = if (-not [string]::IsNullOrWhiteSpace($K)) {
            "параметр -Key"
        } elseif (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
            "параметр -ApiKey"
        } elseif (-not [string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
            "переменная окружения GEMINI_API_KEY"
        } else {
            "интерактивный ввод"
        }
        
        $maskedKey = if ($finalApiKey.Length -gt 10) {
            $finalApiKey.Substring(0, 4) + "*" * ($finalApiKey.Length - 8) + $finalApiKey.Substring($finalApiKey.Length - 4)
        } else {
            "*" * $finalApiKey.Length
        }
        
        Write-Host ""
        Write-Host "Информация об API ключе:" -ForegroundColor Cyan
        Write-Host "  Источник: $keySource" -ForegroundColor White
        Write-Host "  Ключ: $maskedKey" -ForegroundColor Gray
        Write-Host "  Длина: $($finalApiKey.Length) символов" -ForegroundColor Gray
        Write-Host ""
    }

    # Инициализация сессии с проверкой API ключа
    try {
        $historyFilePath = Initialize-GeminiSession -Config $Config -ApiKey $finalApiKey
        Write-Host "✓ Сессия успешно инициализирована" -ForegroundColor Green
    } catch {
        Write-ColoredMessage "Ошибка инициализации: $($_.Exception.Message)" -Color $Config.Color.Error
        Write-Host ""
        Write-Host "Возможные причины:" -ForegroundColor Yellow
        Write-Host "  • Неверный API ключ" -ForegroundColor Gray
        Write-Host "  • Отсутствие интернет соединения" -ForegroundColor Gray  
        Write-Host "  • Превышен лимит запросов API" -ForegroundColor Gray
        Write-Host "  • Gemini CLI не установлен или недоступен в PATH" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Попробуйте:" -ForegroundColor Cyan
        Write-Host "  • Проверить правильность API ключа на https://aistudio.google.com/app/apikey" -ForegroundColor Gray
        Write-Host "  • Убедиться, что gemini-cli установлен: gemini --version" -ForegroundColor Gray
        return
    }

    # Приветствие с информацией о ключе
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    ✈️ AI-ПЛАНИРОВЩИК ПЕРЕЛЕТОВ                             ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║  Модель: $($Model.PadRight(65))║" -ForegroundColor White
    Write-Host "║  API ключ: ✓ Подключен                                                      ║" -ForegroundColor White
    Write-Host "║                                                                              ║" -ForegroundColor White
    Write-Host "║  Доступные команды:                                                         ║" -ForegroundColor Cyan
    Write-Host "║    ?/help   - Показать справку                                              ║" -ForegroundColor Gray
    Write-Host "║    history  - История сессии                                                ║" -ForegroundColor Gray
    Write-Host "║    clear    - Очистить историю                                              ║" -ForegroundColor Gray
    Write-Host "║    key      - Информация об API ключе                                       ║" -ForegroundColor Gray
    Write-Host "║    exit     - Выход                                                         ║" -ForegroundColor Gray
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $selectionContextJson = $null 
    
    # Основной цикл взаимодействия
    while ($true) {
        $promptText = if ($selectionContextJson) { "$($Config.Emoji)AI [Выборка активна] :) > " } else { "$($Config.Emoji)AI :) > " }
        Write-ColoredMessage -Message $promptText -Color $Config.Color.Prompt -NoNewline
        $UserPrompt = Read-Host
        
        # Обработка системных команд
        $commandResult = Command-Handler-Flight -Command $UserPrompt -HistoryFilePath $historyFilePath
        if ($commandResult -eq 'break') { break }
        if ($commandResult -eq 'continue') { continue }
        if ([string]::IsNullOrWhiteSpace($UserPrompt)) { continue }

        Write-ColoredMessage "Идет поиск маршрутов..." -Color $Config.Color.Processing
        
        # Формирование полного промпта с историей и контекстом
        $historyContent = if (Test-Path $historyFilePath) { Get-Content -Path $historyFilePath -Raw } else { "" }
        $fullPrompt = "### ИСТОРИЯ`n$historyContent`n"
        if ($selectionContextJson) {
            $fullPrompt += "### ВЫБОРКА`n$selectionContextJson`n"
            $selectionContextJson = $null
        }
        $fullPrompt += "### НОВЫЙ ЗАПРОС`n$UserPrompt"
        
        # Запрос к Gemini API
        $ModelResponse = Invoke-GeminiAPI -Prompt $fullPrompt -Model $Model -Config $Config
        
        if ($ModelResponse) {
            # Проверка на JSON формат
            $jsonObject = ConvertTo-JsonData -GeminiResponse $ModelResponse
            if ($jsonObject) {
                Write-ColoredMessage "`n--- Варианты перелетов (JSON) ---`n" -Color $Config.Color.Success
                $gridSelection = $jsonObject | Out-ConsoleGridView -Title "Выберите маршруты для следующего запроса" -OutputMode Multiple
                if ($gridSelection) {
                    $selectionContextJson = $gridSelection | ConvertTo-Json -Compress -Depth 10
                    Write-ColoredMessage "Выборка сохранена. Добавьте ваш следующий запрос." -Color $Config.Color.Selection
                }
            } else {
                Write-ColoredMessage $ModelResponse -Color 'White'
            }
            # Сохранение в историю
            Add-ChatHistory -HistoryFilePath $historyFilePath -UserPrompt $UserPrompt -ModelResponse $ModelResponse
        } else {
            Write-ColoredMessage "Не удалось получить ответ от Gemini API. Попробуйте еще раз." -Color $Config.Color.Error
        }
    }
    Write-ColoredMessage "Завершение работы. Удачного полета! ✈️" -Color $Config.Color.Success
}