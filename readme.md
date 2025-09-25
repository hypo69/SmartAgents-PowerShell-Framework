# Update.
mcp сервер переехал в собственный репозиторий: https://github.com/hypo69/mcp-powershell-server



# SmartAgents Framework

Модульная система для создания специализированных AI-агентов на PowerShell с использованием Google Gemini API и поддержкой MCP (Model Context Protocol).

## 🚀 Быстрый старт

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

### 🔗 Интеграция с MCP (Model Context Protocol)

SmartAgents Framework теперь поддерживает интеграцию с MCP для расширенных возможностей выполнения PowerShell команд через Gemini CLI.

#### Запуск MCP сервера с Gemini CLI

```powershell
# Автоматический запуск MCP сервера и настройка Gemini CLI
.\start-mcp-gemini.ps1 -ApiKey "ВАШ_GEMINI_API_КЛЮЧ"

# Запуск с автоматическим стартом Gemini CLI
.\start-mcp-gemini.ps1 -ApiKey "ВАШ_API_КЛЮЧ" -LaunchGemini

# Использование более мощной модели
.\start-mcp-gemini.ps1 -ApiKey "ВАШ_API_КЛЮЧ" -LaunchGemini -Model "gemini-2.5-pro"
```

#### Ручное управление MCP сервером

```powershell
# Запуск MCP сервера в отдельном окне
.\mcp-powershell-server\launch-mcp-stdio.ps1

# Использование Gemini CLI с MCP
gemini --mcp-config ./config/mcp_servers.json -m gemini-2.5-flash -p "Выполни PowerShell команду Get-Process"
```

### Использование существующих агентов

```powershell
# Агент поиска технических спецификаций
Start-FindSpecAgent
Start-FindSpecAgent -ApiKey "ВАШ_API_КЛЮЧ"

# Агент планирования перелетов
Start-FlightPlanAgent
Start-FlightPlanAgent -ApiKey "ВАШ_API_КЛЮЧ"

# Или через псевдонимы
find-spec
find-spec -ApiKey "ВАШ_API_КЛЮЧ"
flight-plan
flight-plan -ApiKey "ВАШ_API_КЛЮЧ"
```

## 🔧 Архитектура системы

### Основные компоненты

1. **SmartAgents Framework** - Основная система агентов
2. **MCP PowerShell Server** - Сервер для выполнения PowerShell команд
3. **Gemini CLI Integration** - Интеграция с Gemini CLI через MCP

### Структура проекта

```
SmartAgents/
├── SmartAgents.psm1                    # Ядро фреймворка
├── SmartAgents.psd1                    # Манифест модуля
├── install.ps1                         # Установочный скрипт
├── start-mcp-gemini.ps1               # 🆕 Главный launcher MCP + Gemini
├── Manage-Agents.ps1                  # Управление агентами
├── config/                            # 🆕 Конфигурационные файлы
│   └── mcp_servers.json               # Конфигурация MCP серверов
├── mcp-powershell-server/             # 🆕 MCP PowerShell Server
│   ├── mcp-powershell-stdio.ps1      # Основной MCP сервер
│   ├── launch-mcp-stdio.ps1          # Launcher для сервера
│   └── start-mcp-server.ps1          # Альтернативный запуск
├── Agents/                            # Библиотека агентов
│   ├── Find-Spec.ps1                 # Агент поиска спецификаций
│   └── Flight-Plan.ps1               # Агент планирования перелетов
├── FindSpec/                          # Конфигурация агента поиска
│   └── .gemini/
│       ├── GEMINI.md                 # Системные инструкции
│       └── ShowHelp.md               # Справка пользователя
└── FlightPlan/                        # Конфигурация агента перелетов
    └── .gemini/
        ├── GEMINI.md                 # Системные инструкции
        └── ShowHelp.md               # Справка пользователя
```

## 🤖 MCP PowerShell Server

### Что такое MCP?

Model Context Protocol (MCP) — это стандартный протокол для подключения AI-ассистентов к внешним системам данных и инструментам. В нашем случае он позволяет Gemini CLI выполнять PowerShell команды.

### Возможности MCP сервера

- ✅ Выполнение PowerShell скриптов и команд
- ✅ Изолированная среда выполнения
- ✅ Обработка параметров и переменных окружения
- ✅ Контроль таймаутов
- ✅ Подробное логирование
- ✅ Обработка ошибок и предупреждений

### Примеры использования MCP

После запуска MCP сервера вы можете использовать Gemini CLI для выполнения PowerShell команд:

```powershell
# Системная информация
gemini --mcp-config ./config/mcp_servers.json -p "Покажи информацию о системе через PowerShell"

# Управление процессами
gemini -p "Найди все процессы Chrome и покажи их использование памяти"

# Работа с файлами
gemini -p "Создай отчет о занятом дисковом пространстве"

# Анализ логов
gemini -p "Проанализируй последние 100 строк системного лога Windows"
```

## 📋 Создание собственного агента

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

## ⚙️ Расширенные возможности

### Интеграция с внешними API

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

### MCP интеграция в агентах

Ваши агенты могут использовать MCP сервер для выполнения PowerShell команд:

```powershell
function Invoke-AgentPowerShell {
    """Функция выполняет PowerShell команды через MCP"""
    param([string]$Script)
    
    # Проверка доступности MCP конфигурации
    $mcpConfig = Join-Path $PSScriptRoot '../config/mcp_servers.json'
    if (-not (Test-Path $mcpConfig)) {
        Write-ColoredMessage "MCP сервер не настроен. Запустите start-mcp-gemini.ps1" -Color $Config.Color.Warning
        return $null
    }
    
    try {
        $prompt = "Выполни PowerShell команду: $Script"
        $result = & gemini --mcp-config $mcpConfig -m $Model -p $prompt
        return $result
    } catch {
        Write-ColoredMessage "Ошибка выполнения через MCP: $($_.Exception.Message)" -Color $Config.Color.Error
        return $null
    }
}
```

## 🔍 Управление проектом

### Проверка статуса агентов и MCP

```powershell
# Статус агентов
.\Manage-Agents.ps1 -Action Status

# Проверка MCP сервера
Test-NetConnection -ComputerName localhost -Port 8090
```

### Конфигурационные файлы

- `config/mcp_servers.json` - Конфигурация MCP серверов
- `YourAgent/.gemini/GEMINI.md` - Системные инструкции для AI
- `YourAgent/.gemini/ShowHelp.md` - Справка пользователя

## 🎯 Примеры интеграции MCP + Агенты

### Системный агент с MCP

```powershell
function Start-SystemMonitorAgent {
    # Инициализация агента
    $Config = New-GeminiConfig -AppName 'Системный монитор' -Emoji '🖥️' -SessionPrefix 'system_monitor'
    
    # Использование MCP для получения системной информации
    function Get-SystemInfo {
        $script = @"
        Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, 
        TotalPhysicalMemory, AvailablePhysicalMemory, CsProcessors
"@
        return Invoke-AgentPowerShell -Script $script
    }
    
    # Интеграция с основным циклом агента...
}
```

### Агент анализа производительности

```powershell
function Start-PerformanceAgent {
    # Мониторинг процессов через MCP
    function Get-TopProcesses {
        $script = "Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, CPU, WorkingSet"
        return Invoke-AgentPowerShell -Script $script
    }
    
    # Анализ использования диска
    function Get-DiskUsage {
        $script = "Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, Size, FreeSpace"
        return Invoke-AgentPowerShell -Script $script
    }
}
```

## 📊 Лучшие практики

### 1. Использование MCP

- **Безопасность**: MCP сервер выполняет команды в изолированной среде
- **Таймауты**: Настройте подходящие таймауты для длительных операций
- **Логирование**: MCP сервер ведет подробные логи в `%TEMP%/mcp-powershell-server.log`
- **Ошибки**: Всегда проверяйте статус выполнения команд

### 2. Структура кода

- Используйте функции фреймворка для единообразия
- Добавляйте docstrings для всех функций
- Следуйте соглашениям именования PowerShell

### 3. Обработка ошибок

```powershell
try {
    # Проверка доступности MCP
    if (-not (Test-Path $mcpConfigFile)) {
        Write-ColoredMessage "MCP сервер недоступен" -Color $Config.Color.Warning
        return
    }
    
    $result = Invoke-AgentPowerShell -Script $powerShellScript
    if (-not $result) {
        Write-ColoredMessage "Операция не выполнена" -Color $Config.Color.Warning
        return
    }
} catch {
    Write-ColoredMessage "Критическая ошибка: $($_.Exception.Message)" -Color $Config.Color.Error
    return
}
```

### 4. Цветовая схема

Используйте стандартные цвета из конфигурации:

- `$Config.Color.Success` - успешные операции (зеленый)
- `$Config.Color.Warning` - предупреждения (желтый) 
- `$Config.Color.Error` - ошибки (красный)
- `$Config.Color.Info` - информационные сообщения (голубой)
- `$Config.Color.Processing` - процесс обработки (серый)
- `$Config.Color.Prompt` - приглашение к вводу (зеленый)
- `$Config.Color.Selection` - уведомления о выборке (фиолетовый)

## 🚦 Устранение неполадок

### MCP сервер не запускается

1. Проверьте версию PowerShell: `$PSVersionTable.PSVersion`
2. Убедитесь, что порт 8090 свободен
3. Проверьте права выполнения скриптов: `Get-ExecutionPolicy`

### Gemini CLI не находит MCP конфигурацию

1. Убедитесь, что файл `config/mcp_servers.json` существует
2. Проверьте правильность путей в конфигурации
3. Запустите `start-mcp-gemini.ps1` для пересоздания конфигурации

### Агенты не могут использовать MCP

1. Убедитесь, что MCP сервер запущен
2. Проверьте наличие конфигурационного файла
3. Проверьте доступность gemini CLI в PATH

### Отладка

Включите подробный вывод для диагностики:

```powershell
# Для агентов
$VerbosePreference = 'Continue'
Import-Module .\SmartAgents.psd1 -Verbose

# Для MCP сервера
# Проверьте лог-файл: %TEMP%\mcp-powershell-server.log
Get-Content "$env:TEMP\mcp-powershell-server.log" -Tail 20
```

## 📈 Примеры использования

### Базовое использование

```powershell
# 1. Запуск системы с MCP
.\start-mcp-gemini.ps1 -ApiKey "your-api-key" -LaunchGemini

# 2. Использование агентов
Start-FindSpecAgent

# 3. Прямое использование Gemini CLI с MCP
gemini --mcp-config ./config/mcp_servers.json -p "Покажи топ-5 процессов по использованию памяти"
```

### Интеграция с существующими скриптами

```powershell
# Создание гибридного агента
function Start-HybridAgent {
    # Использование встроенных функций агента
    $Config = New-GeminiConfig -AppName 'Гибридный агент' -Emoji '🔀'
    
    # Использование MCP для системных операций
    function Get-SystemData {
        $mcpResult = Invoke-AgentPowerShell -Script "Get-Service | Where Status -eq 'Running'"
        return $mcpResult
    }
    
    # Комбинирование результатов
    # Основной цикл агента с интеграцией MCP...
}
```

## 🔄 Миграция существующих агентов

Для добавления MCP поддержки к существующим агентам:

1. Добавьте функцию `Invoke-AgentPowerShell`
2. Обновите системные инструкции для поддержки PowerShell команд
3. Добавьте проверки доступности MCP сервера
4. Обновите справочную документацию

## 📚 Дополнительные ресурсы

### Документация

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Gemini CLI Documentation](https://github.com/google-gemini/gemini-cli)
- [PowerShell 7 Documentation](https://docs.microsoft.com/en-us/powershell/)

### Примеры конфигураций

Примеры конфигурационных файлов и скриптов доступны в папке `examples/` (создайте при необходимости).

## 📄 Лицензия

MIT License - подробности в файле LICENSE.

## 🤝 Вклад в проект

1. Создайте форк репозитория
2. Создайте ветку для ваших изменений
3. Внесите изменения и протестируйте их
4. Создайте Pull Request с описанием изменений

### Особенности разработки

- Все MCP интеграции должны быть опциональными
- Обеспечьте обратную совместимость с существующими агентами
- Добавляйте подробное логирование для отладки
- Тестируйте интеграцию с различными версиями PowerShell

---

**SmartAgents Framework v2.0.0** - теперь с поддержкой MCP для расширенной интеграции с системными инструментами!