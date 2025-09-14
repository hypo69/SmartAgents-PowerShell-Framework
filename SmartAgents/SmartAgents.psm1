## \file SmartAgents/SmartAgents.psm1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

"""
SmartAgents Framework - Главный модуль
=======================================

.. module:: SmartAgents
"""

# --- Определение базовых путей ---
$ModuleRoot = $PSScriptRoot

# =================================================================================
# 1. ОБЩИЕ ("ПРИВАТНЫЕ") ФУНКЦИИ МОДУЛЯ (ДВИЖОК)
# =================================================================================

function New-GeminiConfig {
    """Функция создает конфигурацию для агента"""
    param(
        [string]$AgentRoot, 
        [string]$AppName, 
        [string]$Emoji, 
        [string]$SessionPrefix
    )
    return @{
        AgentRoot       = $AgentRoot
        HistoryDir      = Join-Path $AgentRoot '.gemini/.chat_history'
        ConfigDir       = Join-Path $AgentRoot '.gemini'
        SessionPrefix   = $SessionPrefix
        AppName         = $AppName
        Emoji           = $Emoji
        Color           = @{ 
            Success = 'Green'; 
            Warning = 'Yellow'; 
            Info = 'Cyan'; 
            Error = 'Red'; 
            Prompt = 'Green'; 
            Selection = 'Magenta'; 
            Processing = 'Gray' 
        }
    }
}

function Write-ColoredMessage {
    """Функция выводит цветное сообщение"""
    param(
        [string]$Message, 
        [string]$Color = 'White', 
        [switch]$NoNewline
    )
    $params = @{ Object = $Message; ForegroundColor = $Color }
    if ($NoNewline) { 
        $params.NoNewline = $true 
    }
    Write-Host @params
}

function Initialize-GeminiSession {
    """Функция инициализирует сессию Gemini"""
    param(
        [hashtable]$Config, 
        [string]$ApiKey
    )
    
    if ($ApiKey) { 
        $env:GEMINI_API_KEY = $ApiKey 
    }
    
    if (-not $env:GEMINI_API_KEY) { 
        throw "API ключ не найден. Установите переменную GEMINI_API_KEY или передайте параметр ApiKey" 
    }
    
    if (-not (Test-Path $Config.HistoryDir)) { 
        New-Item -Path $Config.HistoryDir -ItemType Directory -Force | Out-Null 
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $historyFileName = "$($Config.SessionPrefix)_$timestamp.jsonl"
    return Join-Path $Config.HistoryDir $historyFileName
}

function Add-ChatHistory { 
    """Функция добавляет запись в историю чата"""
    param(
        [string]$HistoryFilePath, 
        [string]$UserPrompt, 
        [string]$ModelResponse
    )
    try {
        @{ user = $UserPrompt } | ConvertTo-Json -Compress | Add-Content -Path $HistoryFilePath
        @{ model = $ModelResponse } | ConvertTo-Json -Compress | Add-Content -Path $HistoryFilePath
    } catch { 
        Write-Warning "Ошибка записи истории: $_" 
    }
}

function Invoke-GeminiAPI {
    """Функция вызывает Gemini API через CLI"""
    param(
        [string]$Prompt, 
        [string]$Model, 
        [hashtable]$Config
    )
    try {
        # Перенаправляем поток ошибок (2) в поток вывода (1), чтобы поймать ВСЕ, что пишет gemini.exe
        $output = & gemini -m $Model -p $Prompt 2>&1
        $outputString = $output -join "`r`n"
        
        # Проверка на ошибку квоты
        if ($outputString -match "429" -or $outputString -match "Quota exceeded") {
             Write-ColoredMessage "`n[ОШИБКА API] Превышена квота Google Gemini (Ошибка 429)." -Color $Config.Color.Error
             Write-ColoredMessage "Это означает, что ваш API-ключ неактивен или исчерпал лимиты." -Color $Config.Color.Warning
             Write-ColoredMessage "Что делать: " -Color $Config.Color.Warning
             Write-Host "  1. Проверьте, что в Google Cloud Console для вашего проекта включен биллинг."
             Write-Host "  2. Убедитесь, что 'Generative Language API' (или 'Vertex AI API') включен."
             Write-Host ""
             return $null
        }

        # Проверка на другие ошибки
        if ($LASTEXITCODE -ne 0) {
            throw "Неизвестная ошибка Gemini CLI (код: $LASTEXITCODE): $outputString"
        }
        
        # Очищаем успешный вывод от служебных сообщений
        return $outputString.Trim() -replace "(?m)^Data collection is disabled\.`r?`n", "" -replace "(?m)^Loaded cached credentials\.`r?`n", ""
    } catch {
        # Этот блок теперь ловит только 'throw' из строки выше
        Write-ColoredMessage "`nКритическая ошибка при вызове Gemini CLI: $($_.Exception.Message)" -Color $Config.Color.Error
        return $null
    }
}

function ConvertTo-JsonData {
    """Функция преобразует ответ Gemini в JSON объект"""
    param([string]$GeminiResponse)
    
    $jsonContent = $GeminiResponse
    if ($GeminiResponse -match '(?s)```json\s*(.*?)\s*```') { 
        $jsonContent = $matches[1] 
    }
    try {
        $result = $jsonContent.Trim() | ConvertFrom-Json
        if ($result -is [PSCustomObject]) { 
            return @($result) 
        }
        return $result
    } catch { 
        return $null 
    }
}

# =================================================================================
# 2. ПСЕВДОНИМЫ (ALIASES) ФУНКЦИИ
# =================================================================================

function find-spec {
    """Псевдоним для Start-FindSpecAgent"""
    param(
        [ValidateSet('gemini-2.5-pro', 'gemini-2.5-flash')]
        [string]$Model = 'gemini-2.5-flash',
        
        [Parameter(ParameterSetName = 'ApiKey')]
        [string]$ApiKey,
        
        [Parameter(ParameterSetName = 'Key')]
        [Alias('Key')]
        [string]$K
    )
    
    # Передача параметров в основную функцию
    $params = @{}
    if ($Model) { $params.Model = $Model }
    if ($ApiKey) { $params.ApiKey = $ApiKey }
    if ($K) { $params.K = $K }
    
    Start-FindSpecAgent @params
}

function flight-plan {
    """Псевдоним для Start-FlightPlanAgent"""
    param(
        [ValidateSet('gemini-2.5-pro', 'gemini-2.5-flash')]
        [string]$Model = 'gemini-2.5-flash',
        
        [Parameter(ParameterSetName = 'ApiKey')]
        [string]$ApiKey,
        
        [Parameter(ParameterSetName = 'Key')]
        [Alias('Key')]
        [string]$K
    )
    
    # Передача параметров в основную функцию
    $params = @{}
    if ($Model) { $params.Model = $Model }
    if ($ApiKey) { $params.ApiKey = $ApiKey }
    if ($K) { $params.K = $K }
    
    Start-FlightPlanAgent @params
}

# =================================================================================
# 3. ЗАГРУЗКА БИБЛИОТЕК АГЕНТОВ
# =================================================================================

$agentScripts = Get-ChildItem -Path (Join-Path $ModuleRoot "Agents") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

if ($agentScripts) {
    foreach ($script in $agentScripts) {
        try {
            . $script.FullName
            Write-Verbose "Загружен скрипт агента: $($script.Name)"
        }
        catch {
            Write-Error "Ошибка при загрузке агента $($script.FullName): $_"
        }
    }
} else {
    Write-Warning "Не найдены скрипты агентов в папке: $(Join-Path $ModuleRoot 'Agents')"
}

# =================================================================================
# 4. ЭКСПОРТ ПУБЛИЧНЫХ КОМАНД
# =================================================================================

# Экспорт основных функций и псевдонимов
Export-ModuleMember -Function 'Start-FindSpecAgent', 'Start-FlightPlanAgent', 'find-spec', 'flight-plan'
New-Alias -Name 'find-spec' -Value 'Start-FindSpecAgent' -Force
New-Alias -Name 'flight-plan' -Value 'Start-FlightPlanAgent' -Force
Export-ModuleMember -Alias 'find-spec', 'flight-plan'

Write-Verbose "Модуль SmartAgents успешно загружен и готов к работе."