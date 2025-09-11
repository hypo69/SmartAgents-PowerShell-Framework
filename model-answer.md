# SmartAgents Framework - Рефакторинг

## Структура проекта

```
SmartAgents/
├── SmartAgents.psm1              # Основной модуль
├── SmartAgents.psd1              # Манифест модуля
├── Public/                       # Публичные функции (экспортируемые)
│   ├── Start-FindSpecAgent.ps1
│   ├── Start-FlightPlanAgent.ps1
│   └── New-SmartAgent.ps1
├── Private/                      # Приватные функции (внутренние)
│   ├── New-GeminiConfig.ps1
│   ├── Initialize-GeminiSession.ps1
│   ├── Invoke-GeminiAPI.ps1
│   ├── Write-ColoredMessage.ps1
│   ├── Add-ChatHistory.ps1
│   └── ConvertTo-JsonData.ps1
├── Configs/                      # Конфигурационные файлы
│   ├── FindSpec/
│   │   ├── GEMINI.md
│   │   └── ShowHelp.md
│   ├── FlightPlan/
│   │   ├── GEMINI.md
│   │   └── ShowHelp.md
│   └── Templates/                # Шаблоны для новых агентов
│       ├── GEMINI.template.md
│       ├── ShowHelp.template.md
│       └── Agent.template.ps1
├── Scripts/                      # Вспомогательные скрипты
│   ├── Install-SmartAgents.ps1
│   └── Manage-Agents.ps1
├── Tests/                        # Тесты
│   ├── SmartAgents.Tests.ps1
│   └── Private.Tests.ps1
└── README.md                     # Документация
```

## 1. Основной модуль (SmartAgents.psm1)

```powershell
## \file SmartAgents.psm1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
SmartAgents Framework - Основной модуль
======================================
Фреймворк для создания специализированных AI-агентов на PowerShell
с использованием Google Gemini API.

.. module:: SmartAgents
"""

# Определение путей модуля
$script:ModuleRoot = $PSScriptRoot
$script:PublicFunctionsPath = Join-Path $ModuleRoot 'Public'
$script:PrivateFunctionsPath = Join-Path $ModuleRoot 'Private'
$script:ConfigsPath = Join-Path $ModuleRoot 'Configs'

# Глобальные переменные модуля
$script:SmartAgentsConfig = @{
    Version = '2.0.0'
    Author = 'hypo69'
    DefaultModel = 'gemini-2.5-flash'
    SupportedModels = @('gemini-2.5-pro', 'gemini-2.5-flash')
    ConfigPath = $ConfigsPath
    LogLevel = 'Info'
    RequiredModules = @('Microsoft.PowerShell.ConsoleGuiTools')
}

# Функция инициализации модуля
function Initialize-SmartAgentsModule {
    """Функция инициализирует модуль SmartAgents"""
    
    Write-Verbose "Инициализация SmartAgents Framework v$($script:SmartAgentsConfig.Version)"
    
    # Проверка системных требований
    $requirements = Test-SmartAgentsRequirements
    if (-not $requirements.IsValid) {
        Write-Warning "Обнаружены проблемы с системными требованиями:"
        $requirements.Issues | ForEach-Object { Write-Warning "  - $_" }
        return $false
    }
    
    # Загрузка приватных функций
    $privateFunctions = Get-ChildItem -Path $PrivateFunctionsPath -Filter '*.ps1' -ErrorAction SilentlyContinue
    foreach ($function in $privateFunctions) {
        try {
            . $function.FullName
            Write-Verbose "Загружена приватная функция: $($function.BaseName)"
        } catch {
            Write-Error "Ошибка загрузки приватной функции $($function.Name): $($_.Exception.Message)"
            return $false
        }
    }
    
    # Загрузка публичных функций
    $publicFunctions = Get-ChildItem -Path $PublicFunctionsPath -Filter '*.ps1' -ErrorAction SilentlyContinue
    foreach ($function in $publicFunctions) {
        try {
            . $function.FullName
            Write-Verbose "Загружена публичная функция: $($function.BaseName)"
        } catch {
            Write-Error "Ошибка загрузки публичной функции $($function.Name): $($_.Exception.Message)"
            return $false
        }
    }
    
    Write-Verbose "SmartAgents Framework успешно инициализирован"
    return $true
}

function Test-SmartAgentsRequirements {
    """Функция проверяет системные требования"""
    
    $result = @{
        IsValid = $true
        Issues = @()
    }
    
    # Проверка версии PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $result.Issues += "Требуется PowerShell 7+. Текущая версия: $($PSVersionTable.PSVersion)"
        $result.IsValid = $false
    }
    
    # Проверка Gemini CLI
    try {
        $null = Get-Command 'gemini' -ErrorAction Stop
    } catch {
        $result.Issues += "Gemini CLI не найден в PATH"
        $result.IsValid = $false
    }
    
    # Проверка Out-ConsoleGridView
    try {
        $null = Get-Command 'Out-ConsoleGridView' -ErrorAction Stop
    } catch {
        $result.Issues += "Out-ConsoleGridView недоступен. Установите Microsoft.PowerShell.ConsoleGuiTools"
        $result.IsValid = $false
    }
    
    return $result
}

# Инициализация модуля при загрузке
$initResult = Initialize-SmartAgentsModule
if (-not $initResult) {
    throw "Не удалось инициализировать SmartAgents Framework"
}

# Экспорт публичных функций (определяется динамически)
$publicFunctionNames = (Get-ChildItem -Path $PublicFunctionsPath -Filter '*.ps1' -ErrorAction SilentlyContinue | 
                       ForEach-Object { $_.BaseName })

Export-ModuleMember -Function $publicFunctionNames

Write-Verbose "SmartAgents Framework загружен и готов к работе"
```

## 2. Манифест модуля (SmartAgents.psd1)

```powershell
@{
    # Версия модуля
    ModuleVersion = '2.0.0'

    # Уникальный идентификатор модуля
    GUID = '8f4e9d6d-2c7b-4a0e-8f1d-9c3e4b7a6d5c'

    # Автор модуля
    Author = 'hypo69'

    # Описание функциональности модуля
    Description = 'Фреймворк для создания специализированных AI-агентов в PowerShell с использованием Google Gemini API'

    # Главный файл модуля
    RootModule = 'SmartAgents.psm1'

    # Минимальная версия PowerShell
    PowerShellVersion = '7.0'

    # Функции для экспорта
    FunctionsToExport = @(
        'Start-FindSpecAgent',
        'Start-FlightPlanAgent',
        'New-SmartAgent'
    )

    # Псевдонимы для экспорта
    AliasesToExport = @(
        'find-spec',
        'flight-plan',
        'new-agent'
    )

    # Командлеты для экспорта
    CmdletsToExport = @()

    # Переменные для экспорта
    VariablesToExport = @()

    # Приватные данные
    PrivateData = @{
        PSData = @{
            Tags = @('AI', 'Gemini', 'Automation', 'PowerShell', 'Agent', 'Framework')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Рефакторинг архитектуры, улучшенная модульность, система создания агентов'
        }
    }

    # Зависимости модуля
    RequiredModules = @(
        @{
            ModuleName = 'Microsoft.PowerShell.ConsoleGuiTools'
            ModuleVersion = '0.6.0'
        }
    )
}
```

## 3. Приватные функции

### Private/New-GeminiConfig.ps1

```powershell
## \file Private/New-GeminiConfig.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
Конфигурация агентов Gemini
===========================

.. module:: SmartAgents.Private.Config
"""

function New-GeminiConfig {
    """
    Функция создает конфигурацию для агента Gemini
    
    Args:
        AgentName (string): Имя агента
        AppName (string): Название приложения
        Emoji (string): Эмодзи для интерфейса
        SessionPrefix (string): Префикс для сессий
        ConfigPath (string): Путь к конфигурации (опционально)
    
    Returns:
        hashtable: Конфигурация агента
    
    Example:
        >>> $config = New-GeminiConfig -AgentName 'TestAgent' -AppName 'Test Agent' -Emoji '🤖' -SessionPrefix 'test'
        >>> $config.AppName
        Test Agent
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentName,
        
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$Emoji,
        
        [Parameter(Mandatory = $true)]
        [string]$SessionPrefix,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:SmartAgentsConfig.ConfigPath
    )
    
    # Проверка существования базового пути конфигурации
    if (-not (Test-Path $ConfigPath)) {
        Write-Verbose "Создание базовой папки конфигурации: $ConfigPath"
        try {
            New-Item -Path $ConfigPath -ItemType Directory -Force | Out-Null
        } catch {
            Write-Error "Ошибка создания папки конфигурации: $($_.Exception.Message)"
            return $null
        }
    }
    
    # Определение путей конфигурации агента
    $configDir = Join-Path $ConfigPath $AgentName
    $historyDir = Join-Path $configDir '.chat_history'
    
    # Создание структуры папок при необходимости
    if (-not (Test-Path $historyDir)) {
        try {
            New-Item -Path $historyDir -ItemType Directory -Force | Out-Null
            Write-Verbose "Создана папка истории: $historyDir"
        } catch {
            Write-Error "Ошибка создания папки истории: $($_.Exception.Message)"
            return $null
        }
    }
    
    $config = @{
        AgentName = $AgentName
        ConfigDir = $configDir
        HistoryDir = $historyDir
        SessionPrefix = $SessionPrefix
        AppName = $AppName
        Emoji = $Emoji
        Color = @{
            Success = 'Green'
            Warning = 'Yellow'
            Info = 'Cyan'
            Error = 'Red'
            Prompt = 'Green'
            Selection = 'Magenta'
            Processing = 'Gray'
        }
        CreatedAt = Get-Date
        Version = $script:SmartAgentsConfig.Version
    }
    
    Write-Verbose "Создана конфигурация для агента: $AppName"
    return $config
}
```

### Private/Initialize-GeminiSession.ps1

```powershell
## \file Private/Initialize-GeminiSession.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
Инициализация сессии Gemini
============================

.. module:: SmartAgents.Private.Session
"""

function Initialize-GeminiSession {
    """
    Функция инициализирует сессию Gemini
    
    Args:
        Config (hashtable): Конфигурация агента
        ApiKey (string): API ключ (опционально)
    
    Returns:
        string: Путь к файлу истории сессии
    
    Raises:
        Exception: При отсутствии API ключа или проблемах с созданием файлов
    
    Example:
        >>> $historyFile = Initialize-GeminiSession -Config $config
        >>> Write-Host "История сохраняется в: $historyFile"
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )
    
    # Установка API ключа если предоставлен
    if ($ApiKey) {
        $env:GEMINI_API_KEY = $ApiKey
        Write-Verbose "API ключ установлен из параметра"
    }
    
    # Проверка наличия API ключа
    if (-not $env:GEMINI_API_KEY) {
        throw "API ключ не найден. Установите переменную GEMINI_API_KEY или передайте параметр ApiKey"
    }
    
    # Создание папки истории если не существует
    if (-not (Test-Path $Config.HistoryDir)) {
        try {
            New-Item -Path $Config.HistoryDir -ItemType Directory -Force | Out-Null
            Write-Verbose "Создана папка истории: $($Config.HistoryDir)"
        } catch {
            throw "Ошибка создания папки истории: $($_.Exception.Message)"
        }
    }
    
    # Генерация имени файла истории
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $historyFileName = "$($Config.SessionPrefix)_$timestamp.jsonl"
    $historyFilePath = Join-Path $Config.HistoryDir $historyFileName
    
    Write-Verbose "Инициализирована сессия. История: $historyFilePath"
    return $historyFilePath
}

function Test-GeminiConnection {
    """
    Функция проверяет подключение к Gemini API
    
    Args:
        Config (hashtable): Конфигурация агента
        Model (string): Модель для тестирования (опционально)
    
    Returns:
        bool: True если подключение успешно, False в противном случае
    
    Example:
        >>> $isConnected = Test-GeminiConnection -Config $config
        >>> if ($isConnected) { Write-Host "Подключение работает" }
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $false)]
        [string]$Model = $script:SmartAgentsConfig.DefaultModel
    )
    
    Write-Verbose "Тестирование подключения к Gemini API..."
    
    $testResponse = Invoke-GeminiAPI -Prompt "Ответь одним словом: OK" -Model $Model -Config $Config
    
    if ($testResponse -and $testResponse.Trim() -match "OK|ok|Ok") {
        Write-ColoredMessage "Подключение к Gemini API успешно" -Color $Config.Color.Success
        return $true
    } else {
        Write-ColoredMessage "Подключение к Gemini API недоступно" -Color $Config.Color.Error
        return $false
    }
}
```

### Private/Invoke-GeminiAPI.ps1

```powershell
## \file Private/Invoke-GeminiAPI.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
API интеграция с Google Gemini
==============================

.. module:: SmartAgents.Private.GeminiAPI
"""

function Invoke-GeminiAPI {
    """
    Функция выполняет запрос к Gemini API
    
    Args:
        Prompt (string): Текст запроса
        Model (string): Модель для использования
        Config (hashtable): Конфигурация агента
    
    Returns:
        string | null: Ответ от API или null при ошибке
    
    Raises:
        Exception: При критических ошибках API
    
    Example:
        >>> $response = Invoke-GeminiAPI -Prompt "Hello" -Model "gemini-2.5-flash" -Config $config
        >>> if ($response) { Write-Host $response }
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('gemini-2.5-pro', 'gemini-2.5-flash')]
        [string]$Model,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    # Проверка наличия API ключа
    if (-not $env:GEMINI_API_KEY) {
        Write-ColoredMessage "API ключ Gemini не найден в переменных окружения" -Color $Config.Color.Error
        return $null
    }
    
    # Логирование запроса (только в режиме Verbose)
    Write-Verbose "Отправка запроса к Gemini API (модель: $Model)"
    Write-Verbose "Длина промпта: $($Prompt.Length) символов"
    
    try {
        # Выполнение запроса к API
        $output = & gemini -m $Model -p $Prompt 2>&1
        $outputString = $output -join "`r`n"
        
        # Обработка специфических ошибок API
        if ($outputString -match "429|Quota exceeded|RATE_LIMIT_EXCEEDED") {
            Write-ColoredMessage "`n[ОШИБКА API] Превышена квота Google Gemini (Ошибка 429)" -Color $Config.Color.Error
            Write-ColoredMessage "Возможные причины:" -Color $Config.Color.Warning
            Write-Host "  • API-ключ неактивен или исчерпал лимиты"
            Write-Host "  • Не включен биллинг в Google Cloud Console"
            Write-Host "  • Не активирован Generative Language API"
            Write-Host ""
            return $null
        }
        
        if ($outputString -match "401|UNAUTHENTICATED|Invalid API key") {
            Write-ColoredMessage "`n[ОШИБКА API] Неверный API ключ" -Color $Config.Color.Error
            Write-ColoredMessage "Проверьте правильность API ключа в переменной GEMINI_API_KEY" -Color $Config.Color.Warning
            return $null
        }
        
        if ($outputString -match "403|PERMISSION_DENIED") {
            Write-ColoredMessage "`n[ОШИБКА API] Доступ запрещен" -Color $Config.Color.Error
            Write-ColoredMessage "Убедитесь, что API включен для вашего проекта" -Color $Config.Color.Warning
            return $null
        }
        
        # Проверка кода завершения
        if ($LASTEXITCODE -ne 0) {
            throw "Gemini CLI завершился с ошибкой (код: $LASTEXITCODE): $outputString"
        }
        
        # Очистка ответа от служебных сообщений
        $cleanOutput = $outputString.Trim()
        $cleanOutput = $cleanOutput -replace "(?m)^Data collection is disabled\.`r?`n", ""
        $cleanOutput = $cleanOutput -replace "(?m)^Loaded cached credentials\.`r?`n", ""
        $cleanOutput = $cleanOutput -replace "(?m)^Using project:.*`r?`n", ""
        
        Write-Verbose "Получен ответ от Gemini API (длина: $($cleanOutput.Length) символов)"
        return $cleanOutput
        
    } catch {
        Write-ColoredMessage "`nКритическая ошибка при вызове Gemini API: $($_.Exception.Message)" -Color $Config.Color.Error
        Write-Verbose "Стек ошибки: $($_.ScriptStackTrace)"
        return $null
    }
}
```

### Private/Write-ColoredMessage.ps1

```powershell
## \file Private/Write-ColoredMessage.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
Утилита для цветного вывода
===========================

.. module:: SmartAgents.Private.Output
"""

function Write-ColoredMessage {
    """
    Функция выводит цветное сообщение в консоль
    
    Args:
        Message (string): Сообщение для вывода
        Color (string): Цвет текста (по умолчанию White)
        NoNewline (switch): Не добавлять перевод строки
    
    Returns:
        void
    
    Example:
        >>> Write-ColoredMessage "Успех!" -Color 'Green'
        >>> Write-ColoredMessage "Промпт: " -Color 'Cyan' -NoNewline
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = 'White',
        
        [Parameter(Mandatory = $false)]
        [switch]$NoNewline
    )
    
    $params = @{
        Object = $Message
        ForegroundColor = $Color
    }
    
    if ($NoNewline) {
        $params.NoNewline = $true
    }
    
    Write-Host @params
}
```

### Private/Add-ChatHistory.ps1

```powershell
## \file Private/Add-ChatHistory.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
Управление историей чата
========================

.. module:: SmartAgents.Private.History
"""

function Add-ChatHistory {
    """
    Функция добавляет запись в историю чата
    
    Args:
        HistoryFilePath (string): Путь к файлу истории
        UserPrompt (string): Запрос пользователя
        ModelResponse (string): Ответ модели
    
    Returns:
        bool: True при успешной записи, False при ошибке
    
    Example:
        >>> Add-ChatHistory -HistoryFilePath $historyFile -UserPrompt "Hello" -ModelResponse "Hi there!"
        True
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$HistoryFilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$UserPrompt,
        
        [Parameter(Mandatory = $true)]
        [string]$ModelResponse
    )
    
    try {
        # Создание папки истории если не существует
        $historyDir = Split-Path $HistoryFilePath -Parent
        if (-not (Test-Path $historyDir)) {
            New-Item -Path $historyDir -ItemType Directory -Force | Out-Null
        }
        
        # Запись истории в формате JSONL
        @{ user = $UserPrompt } | ConvertTo-Json -Compress | Add-Content -Path $HistoryFilePath
        @{ model = $ModelResponse } | ConvertTo-Json -Compress | Add-Content -Path $HistoryFilePath
        
        Write-Verbose "История записана в: $HistoryFilePath"
        return $true
        
    } catch {
        Write-Warning "Ошибка записи истории: $($_.Exception.Message)"
        return $false
    }
}

function Get-ChatHistory {
    """
    Функция получает историю чата
    
    Args:
        HistoryFilePath (string): Путь к файлу истории
        LastN (int): Количество последних записей (опционально)
    
    Returns:
        array: Массив записей истории
    
    Example:
        >>> $history = Get-ChatHistory -HistoryFilePath $historyFile -LastN 10
        >>> $history.Count
        10
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$HistoryFilePath,
        
        [Parameter(Mandatory = $false)]
        [int]$LastN = 0
    )
    
    if (-not (Test-Path $HistoryFilePath)) {
        Write-Verbose "Файл истории не найден: $HistoryFilePath"
        return @()
    }
    
    try {
        $lines = Get-Content -Path $HistoryFilePath
        $entries = @()
        
        foreach ($line in $lines) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $entry = $line | ConvertFrom-Json
                $entries += $entry
            }
        }
        
        if ($LastN -gt 0 -and $entries.Count -gt $LastN) {
            return $entries[-$LastN..-1]
        }
        
        return $entries
        
    } catch {
        Write-Warning "Ошибка чтения истории: $($_.Exception.Message)"
        return @()
    }
}

function Clear-ChatHistory {
    """
    Функция очищает историю чата
    
    Args:
        HistoryFilePath (string): Путь к файлу истории
    
    Returns:
        bool: True при успешной очистке, False при ошибке
    
    Example:
        >>> Clear-ChatHistory -HistoryFilePath $historyFile
        True
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$HistoryFilePath
    )
    
    try {
        if (Test-Path $HistoryFilePath) {
            Remove-Item $HistoryFilePath -Force
            Write-Verbose "История очищена: $HistoryFilePath"
        }
        return $true
        
    } catch {
        Write-Warning "Ошибка очистки истории: $($_.Exception.Message)"
        return $false
    }
}
```

### Private/ConvertTo-JsonData.ps1

```powershell
## \file Private/ConvertTo-JsonData.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
Обработка JSON данных от Gemini
===============================

.. module:: SmartAgents.Private.JsonProcessor
"""

function ConvertTo-JsonData {
    """
    Функция извлекает и преобразует JSON данные из ответа Gemini
    
    Args:
        GeminiResponse (string): Ответ от Gemini API
    
    Returns:
        object | null: Объект PowerShell или null если JSON не найден
    
    Example:
        >>> $data = ConvertTo-JsonData -GeminiResponse '```json\n[{"Name": "Test"}]\n```'
        >>> $data[0].Name
        Test
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GeminiResponse
    )
    
    if ([string]::IsNullOrWhiteSpace($GeminiResponse)) {
        Write-Verbose "Пустой ответ от Gemini"
        return $null
    }
    
    # Попытка извлечь JSON из блока кода
    $jsonContent = $GeminiResponse
    if ($GeminiResponse -match '(?s)```json\s*(.*?)\s*```') {
        $jsonContent = $matches[1]
        Write-Verbose "JSON извлечен из блока кода"
    }
    
    try {
        $result = $jsonContent.Trim() | ConvertFrom-Json
        
        # Преобразование в массив если получен один объект
        if ($result -is [PSCustomObject]) {
            Write-Verbose "JSON преобразован в массив объектов"
            return @($result)
        }
        
        Write-Verbose "JSON успешно преобразован (тип: $($result.GetType().Name))"
        return $result
        
    } catch {
        Write-Verbose "Ошибка парсинга JSON: $($_.Exception.Message)"
        return $null
    }
}

function Test-JsonResponse {
    """
    Функция проверяет является ли ответ валидным JSON
    
    Args:
        Response (string): Строка для проверки
    
    Returns:
        bool: True если строка содержит валидный JSON, False в противном случае
    
    Example:
        >>> Test-JsonResponse -Response '{"test": "value"}'
        True
    """
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Response
    )
    
    if ([string]::IsNullOrWhiteSpace($Response)) {
        return $false
    }
    
    # Проверка наличия JSON блока
    if ($Response -match '(?s)```json\s*(.*?)\s*```') {
        $jsonContent = $matches[1