# SmartAgents Framework

Модульная система для создания специализированных AI-агентов на PowerShell с использованием Google Gemini API.

## Быстрый старт

### Системные требования

- PowerShell 7+
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- Модуль Microsoft.PowerShell.ConsoleGuiTools: `Install-Module Microsoft.PowerShell.ConsoleGuiTools`
- Google Gemini API ключ

### Установка

1. Клонируйте репозиторий
2. Запустите установочный скрипт:

```powershell
.\install.ps1 -ApiKey "ВАШ_GEMINI_API_КЛЮЧ"
```

3. Импортируйте модуль:

```powershell
Import-Module .\SmartAgents.psd1
```

### Использование существующих агентов

```powershell
# Агент поиска технических спецификаций
Start-FindSpecAgent

# Агент планирования перелетов
Start-FlightPlanAgent

# Или через псевдонимы
find-spec
flight-plan
```

## Создание собственного агента

### Шаг 1: Создание функции агента

Создайте файл `Agents/YourAgent.ps1`:

```powershell
## \file Agents/YourAgent.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
Агент для [описание назначения]
===============================

.. module:: SmartAgents.YourAgent
"""

function Start-YourAgent {
    <#
    .SYNOPSIS
        Запуск вашего специализированного AI-агента
    
    .PARAMETER Model
        Модель Gemini для использования
    
    .PARAMETER ApiKey
        API ключ Google Gemini (опционально, если установлен в переменной окружения)
    
    .EXAMPLE
        Start-YourAgent
        Запускает агента с настройками по умолчанию
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('gemini-2.5-pro', 'gemini-2.5-flash')]
        [string]$Model = 'gemini-2.5-flash',
        [string]$ApiKey
    )
    
    # Инициализация конфигурации агента
    $agentRoot = $PSScriptRoot 
    $Config = New-GeminiConfig -AppName 'Ваш агент' -Emoji '🎯' -SessionPrefix 'your_session' -AgentRoot $agentRoot

    # Специализированные функции агента
    function Show-YourAgentHelp {
        """Функция отображает справку по агенту"""
        $helpFilePath = Join-Path $Config.ConfigDir "ShowHelp.md"
        if (Test-Path $helpFilePath) {
            Get-Content -Path $helpFilePath -Raw | Write-Host
        } else {
            Write-Warning "Файл справки не найден: $helpFilePath"
        }
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

    function Command-Handler-YourAgent {
        """Функция обрабатывает системные команды агента"""
        param([string]$Command, [string]$HistoryFilePath)
        switch ($Command.Trim().ToLower()) {
            '?'         { Show-YourAgentHelp; return 'continue' }
            'help'      { Show-YourAgentHelp; return 'continue' }
            'history'   { Show-History -HistoryFilePath $HistoryFilePath; return 'continue' }
            'clear'     { Clear-History -HistoryFilePath $HistoryFilePath; return 'continue' }
            'exit'      { return 'break' }
            'quit'      { return 'break' }
            # Добавьте специализированные команды для вашего агента
            'export'    { Export-YourAgentData; return 'continue' }
            'settings'  { Show-YourAgentSettings; return 'continue' }
            default     { return $null }
        }
    }

    # Дополнительные функции для вашего агента
    function Export-YourAgentData {
        """Функция экспортирует данные агента"""
        Write-ColoredMessage "Экспорт данных..." -Color $Config.Color.Info
        # Логика экспорта
    }

    function Show-YourAgentSettings {
        """Функция отображает настройки агента"""
        Write-ColoredMessage "Настройки агента:" -Color $Config.Color.Info
        # Логика отображения настроек
    }

    # Инициализация сессии
    try {
        $historyFilePath = Initialize-GeminiSession -Config $Config -ApiKey $ApiKey
    } catch {
        Write-ColoredMessage "Ошибка инициализации: $($_.Exception.Message)" -Color $Config.Color.Error
        return
    }

    Write-Host "`nДобро пожаловать в $($Config.AppName)! Модель: '$Model'. Введите '?' для помощи, 'exit' для выхода.`n"
    $selectionContextJson = $null 
    
    # Основной цикл взаимодействия
    while ($true) {
        $promptText = if ($selectionContextJson) { "$($Config.Emoji)AI [Выборка активна] :) > " } else { "$($Config.Emoji)AI :) > " }
        Write-ColoredMessage -Message $promptText -Color $Config.Color.Prompt -NoNewline
        $UserPrompt = Read-Host
        
        # Обработка системных команд
        $commandResult = Command-Handler-YourAgent -Command $UserPrompt -HistoryFilePath $historyFilePath
        if ($commandResult -eq 'break') { break }
        if ($commandResult -eq 'continue') { continue }
        if ([string]::IsNullOrWhiteSpace($UserPrompt)) { continue }

        Write-ColoredMessage "Обработка запроса..." -Color $Config.Color.Processing
        
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
                Write-ColoredMessage "`n--- Результат ---`n" -Color $Config.Color.Success
                $gridSelection = $jsonObject | Out-ConsoleGridView -Title "Выберите данные для следующего запроса" -OutputMode Multiple
                if ($gridSelection) {
                    $selectionContextJson = $gridSelection | ConvertTo-Json -Compress -Depth 10
                    Write-ColoredMessage "Выборка сохранена. Добавьте ваш следующий запрос." -Color $Config.Color.Selection
                }
            } else {
                Write-ColoredMessage $ModelResponse -Color 'White'
            }
            # Сохранение в историю
            Add-ChatHistory -HistoryFilePath $historyFilePath -UserPrompt $UserPrompt -ModelResponse $ModelResponse
        }
    }
    Write-ColoredMessage "Завершение работы." -Color $Config.Color.Success
}
```

### Шаг 2: Создание папки конфигурации

Создайте структуру папок для вашего агента:

```
YourAgent/
└── .gemini/
    ├── GEMINI.md      # Системные инструкции для AI
    └── ShowHelp.md    # Справка для пользователя
```

### Шаг 3: Настройка системных инструкций

Создайте файл `YourAgent/.gemini/GEMINI.md`:

```markdown
# СИСТЕМНАЯ ИНСТРУКЦИЯ ДЛЯ YourAgent AI

## 1. Твоя Роль и Главная Задача

Ты — специализированный ИИ-ассистент для [описание предметной области].
Твоя цель — [описание основной функции агента].

## 2. Основные Директивы

### 2.1. Автоматическая обработка запросов
- При получении запроса типа [примеры запросов] выполняй поиск/анализ автоматически
- Не задавай уточняющих вопросов, если данных достаточно

### 2.2. Обработка неоднозначности
Если запрос неоднозначен, верни JSON-список с вариантами:

```json
[
  {"Вариант": "Вариант 1", "Уточнение": "Описание варианта"},
  {"Вариант": "Вариант 2", "Уточнение": "Описание варианта"}
]
```

## 3. Формат Ответов

### 3.1. ВСЕГДА JSON (кроме ошибок)
Структурированные данные возвращаются ТОЛЬКО в виде валидного JSON.

### 3.2. Формат для основных данных
```json
[
  {"Параметр": "Название параметра", "Значение": "Значение параметра"},
  {"Параметр": "Другой параметр", "Значение": "Другое значение"}
]
```

### 3.3. Формат для сравнения
```json
[
  {"Параметр": "Параметр", "Объект1": "Значение1", "Объект2": "Значение2"}
]
```

## 4. Специализированная логика

[Добавьте специфические инструкции для вашего агента]

### 4.1. Обработка типичных запросов
[Примеры типичных запросов и ожидаемых ответов]

### 4.2. Источники данных
[Укажите предпочтительные источники информации]

## 5. Обработка ошибок

Если данные не найдены, верни текстовый ответ (не JSON):
`Поиск по "[запрос]" не дал результатов. [Предложения по улучшению запроса]`
```

### Шаг 4: Создание справки пользователя

Создайте файл `YourAgent/.gemini/ShowHelp.md`:

```markdown
# Справка по YourAgent

## Основное использование
[Описание основного функционала агента]

Примеры запросов:
- `пример запроса 1`
- `пример запроса 2`

## Интерактивная таблица
- Когда AI возвращает таблицу, она открывается в интерактивном окне
- Выберите нужные строки (Click или пробел)
- Нажмите OK для сохранения выборки
- Нажмите Cancel для закрытия

## Работа с выборкой
После сохранения выборки приглашение изменится на `🎯AI [Выборка активна] :) >`
Теперь ваш следующий запрос будет учитывать выбранные данные.

Примеры использования выборки:
- `сравни выбранные элементы`
- `найди аналоги`
- `покажи подробности`

## Доступные команды
- `?` или `help` - Показать эту справку
- `history` - Показать историю сессии
- `clear` - Очистить историю
- `export` - Экспорт данных
- `settings` - Настройки агента
- `exit` / `quit` - Выход

## Специальные команды
[Добавьте описание специализированных команд вашего агента]
```

### Шаг 5: Регистрация агента в модуле

Отредактируйте `SmartAgents.psd1`, добавив вашу функцию и псевдоним:

```powershell
FunctionsToExport = @(
    'Start-FindSpecAgent',
    'Start-FlightPlanAgent',
    'Start-YourAgent'  # Добавьте вашу функцию
)

AliasesToExport = @(
    'find-spec',
    'flight-plan',
    'your-agent'       # Добавьте псевдоним
)
```

Отредактируйте `SmartAgents.psm1`, обновив строку экспорта:

```powershell
Export-ModuleMember -Function 'Start-FindSpecAgent', 'Start-FlightPlanAgent', 'Start-YourAgent' -Alias 'find-spec', 'flight-plan', 'your-agent'
```

### Шаг 6: Тестирование агента

1. Перезагрузите модуль:

```powershell
Remove-Module SmartAgents -Force
Import-Module .\SmartAgents.psd1 -Force
```

2. Запустите ваш агент:

```powershell
Start-YourAgent
# или
your-agent
```

3. Протестируйте базовую функциональность:
   - Введите `?` для проверки справки
   - Протестируйте обработку JSON-ответов
   - Проверьте работу с интерактивными таблицами

## Расширенные возможности

### Интеграция с внешними API

Добавьте в ваш агент функции для работы с внешними сервисами:

```powershell
function Get-ExternalApiData {
    """Функция получает данные из внешнего API"""
    param(
        [string]$Endpoint,
        [hashtable]$Parameters = @{}
    )
    
    try {
        $response = Invoke-RestMethod -Uri $Endpoint -Method GET -Body $Parameters -ContentType "application/json"
        return $response
    } catch {
        Write-ColoredMessage "Ошибка API запроса: $($_.Exception.Message)" -Color $Config.Color.Error
        return $null
    }
}
```

### Сохранение и загрузка данных

```powershell
function Save-AgentData {
    """Функция сохраняет данные агента"""
    param(
        [object]$Data,
        [string]$FileName
    )
    
    $outputPath = Join-Path $Config.ConfigDir $FileName
    
    try {
        if (-not (Test-Path $Config.ConfigDir)) {
            New-Item -Path $Config.ConfigDir -ItemType Directory -Force | Out-Null
        }
        
        $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8
        Write-ColoredMessage "Данные сохранены: $outputPath" -Color $Config.Color.Success
        return $true
    } catch {
        Write-ColoredMessage "Ошибка сохранения: $($_.Exception.Message)" -Color $Config.Color.Error
        return $false
    }
}

function Load-AgentData {
    """Функция загружает данные агента"""
    param([string]$FileName)
    
    $inputPath = Join-Path $Config.ConfigDir $FileName
    
    if (-not (Test-Path $inputPath)) {
        Write-ColoredMessage "Файл не найден: $inputPath" -Color $Config.Color.Warning
        return $null
    }
    
    try {
        $data = Get-Content -Path $inputPath -Raw | ConvertFrom-Json
        Write-ColoredMessage "Данные загружены: $inputPath" -Color $Config.Color.Success
        return $data
    } catch {
        Write-ColoredMessage "Ошибка загрузки: $($_.Exception.Message)" -Color $Config.Color.Error
        return $null
    }
}
```

### Кастомизация промптов

Создайте специализированные промпт-шаблоны:

```powershell
function Build-SpecializedPrompt {
    """Функция формирует специализированный промпт"""
    param(
        [string]$UserQuery,
        [string]$Context = "",
        [string]$Template = "default"
    )
    
    $templates = @{
        "default" = @"
Ты специализированный помощник для [область].

КОНТЕКСТ: $Context

ЗАПРОС ПОЛЬЗОВАТЕЛЯ: $UserQuery

Отвечай в формате JSON согласно инструкциям.
"@
        "analysis" = @"
Проанализируй следующие данные:

ДАННЫЕ ДЛЯ АНАЛИЗА: $Context

ЗАДАЧА: $UserQuery

Верни результат анализа в JSON формате.
"@
        "comparison" = @"
Сравни следующие элементы:

ЭЛЕМЕНТЫ ДЛЯ СРАВНЕНИЯ: $Context

КРИТЕРИИ: $UserQuery

Верни сравнение в табличном JSON формате.
"@
    }
    
    return $templates[$Template]
}
```

## Управление проектом

### Проверка статуса агентов

```powershell
.\Manage-Agents.ps1 -Action Status
```

### Добавление агента в систему управления

Обновите функцию `Show-ProjectStatus` в `Manage-Agents.ps1` для поддержки вашего агента.

## Лучшие практики

### 1. Структура кода

- Используйте функции фреймворка для единообразия
- Добавляйте docstrings для всех функций
- Следуйте соглашениям именования PowerShell

### 2. Обработка ошибок

```powershell
try {
    # Потенциально опасная операция
    $result = Some-Operation -Parameter $value
    if (-not $result) {
        Write-ColoredMessage "Операция не выполнена" -Color $Config.Color.Warning
        return
    }
} catch {
    Write-ColoredMessage "Критическая ошибка: $($_.Exception.Message)" -Color $Config.Color.Error
    return
}
```

### 3. Цветовая схема

Используйте стандартные цвета из конфигурации:

- `$Config.Color.Success` - успешные операции (зеленый)
- `$Config.Color.Warning` - предупреждения (желтый) 
- `$Config.Color.Error` - ошибки (красный)
- `$Config.Color.Info` - информационные сообщения (голубой)
- `$Config.Color.Processing` - процесс обработки (серый)
- `$Config.Color.Prompt` - приглашение к вводу (зеленый)
- `$Config.Color.Selection` - уведомления о выборке (фиолетовый)

### 4. Тестирование JSON-ответов

Убедитесь, что ваш агент корректно обрабатывает JSON-ответы от Gemini:

```powershell
# Тестовый JSON для проверки
$testJson = @'
[
  {"Параметр": "Тест 1", "Значение": "Значение 1"},
  {"Параметр": "Тест 2", "Значение": "Значение 2"}
]
'@

$testObject = $testJson | ConvertFrom-Json
$testObject | Out-ConsoleGridView
```

### 5. Документация

- Всегда создавайте подробные `GEMINI.md` с примерами
- Обновляйте `ShowHelp.md` при добавлении новых команд
- Добавляйте примеры использования в README

## Примеры специализированных агентов

### Агент мониторинга системы

```powershell
function Start-SystemMonitorAgent {
    # Мониторинг производительности системы, процессов, ресурсов
    # JSON-отчеты о состоянии системы
}
```

### Агент анализа логов

```powershell
function Start-LogAnalyzerAgent {
    # Анализ файлов логов, поиск ошибок, статистика
    # JSON-отчеты с результатами анализа
}
```

### Агент управления проектами

```powershell
function Start-ProjectManagerAgent {
    # Планирование задач, отслеживание прогресса
    # JSON-структуры с планами и отчетами
}
```

## Поддержка и развитие

1. **Тестирование**: Всегда тестируйте новые функции с различными входными данными
2. **Логирование**: Используйте Write-ColoredMessage для информативного вывода
3. **Версионность**: Обновляйте версию в `SmartAgents.psd1` при значительных изменениях
4. **Обратная связь**: Собирайте отзывы пользователей для улучшения агентов

## Устранение неполадок

### Общие проблемы

1. **Агент не запускается**: Проверьте наличие API ключа и правильность импорта модуля
2. **JSON не обрабатывается**: Убедитесь в корректности формата ответов от Gemini
3. **История не сохраняется**: Проверьте права доступа к папке `.gemini/.chat_history`
4. **Интерактивная таблица не работает**: Установите модуль Microsoft.PowerShell.ConsoleGuiTools

### Отладка

Включите подробный вывод для диагностики:

```powershell
$VerbosePreference = 'Continue'
Import-Module .\SmartAgents.psd1 -Verbose
```

---

Создание агента в SmartAgents Framework — это простой процесс, который позволяет быстро получить мощного AI-помощника для любой предметной области. Следуя этой инструкции, вы сможете создать функциональный агент за несколько минут.

## Лицензия

MIT License - подробности в файле LICENSE.

## Вклад в проект

1. Создайте форк репозитория
2. Создайте ветку для ваших изменений
3. Внесите изменения и протестируйте их
4. Создайте Pull Request с описанием изменений

---

*Документация создана для SmartAgents Framework v1.0.0*