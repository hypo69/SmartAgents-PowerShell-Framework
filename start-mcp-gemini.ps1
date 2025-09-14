## \file start-mcp-gemini.ps1
# -*- coding: utf-8 -*-
#! .pyenv/bin/powershell

<#
.SYNOPSIS
    Главный скрипт для запуска MCP сервера и настройки работы с Gemini CLI
    
.DESCRIPTION
    Автоматически запускает MCP PowerShell сервер в отдельном окне и настраивает
    gemini-cli для работы с ним. Обеспечивает правильную последовательность запуска.
    
.PARAMETER ApiKey
    Gemini API ключ
    
.PARAMETER LaunchGemini
    Запустить gemini-cli в интерактивном режиме после настройки MCP
    
.PARAMETER Model
    Модель Gemini для использования (по умолчанию gemini-2.5-flash)
    
.EXAMPLE
    .\start-mcp-gemini.ps1 -ApiKey "your-api-key"
    
.EXAMPLE
    .\start-mcp-gemini.ps1 -ApiKey "your-api-key" -LaunchGemini -Model "gemini-2.5-pro"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ApiKey,
    
    [Parameter(Mandatory = $false)]
    [switch]$LaunchGemini,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('gemini-2.5-pro', 'gemini-2.5-flash')]
    [string]$Model = 'gemini-2.5-flash',
    
    [Parameter(Mandatory = $false)]
    [switch]$Help
)

function Write-Launch {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    $color = switch ($Type) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Info' { 'Cyan' }
        'Title' { 'Magenta' }
        default { 'White' }
    }
    
    if ($Type -eq 'Title') {
        Write-Host "`n$('=' * 60)" -ForegroundColor $color
        Write-Host " $Message" -ForegroundColor $color
        Write-Host "$('=' * 60)`n" -ForegroundColor $color
    } else {
        $prefix = switch ($Type) {
            'Success' { '[✓]' }
            'Warning' { '[!]' }
            'Error' { '[✗]' }
            'Info' { '[i]' }
            default { '[-]' }
        }
        Write-Host "$prefix $Message" -ForegroundColor $color
    }
}

function Show-Help {
    $helpText = @"

MCP PowerShell Server + Gemini CLI Launcher

ОПИСАНИЕ:
    Главный скрипт для интеграции MCP PowerShell сервера с gemini-cli.
    Автоматически запускает сервер в отдельном окне и настраивает CLI.

ИСПОЛЬЗОВАНИЕ:
    .\start-mcp-gemini.ps1 [параметры]

ПАРАМЕТРЫ:
    -ApiKey <ключ>      Gemini API ключ (обязательный)
    -LaunchGemini       Запустить gemini-cli после настройки
    -Model <модель>     Модель Gemini (gemini-2.5-pro | gemini-2.5-flash)
    -Help               Показать эту справку

ПРИМЕРЫ:
    # Только настройка и запуск MCP сервера
    .\start-mcp-gemini.ps1 -ApiKey "your-api-key"
    
    # Запуск MCP сервера + автоматический запуск gemini-cli
    .\start-mcp-gemini.ps1 -ApiKey "your-key" -LaunchGemini
    
    # Использование более мощной модели
    .\start-mcp-gemini.ps1 -ApiKey "your-key" -LaunchGemini -Model "gemini-2.5-pro"

РАБОЧИЙ ПРОЦЕСС:
    1. Проверка системных требований
    2. Запуск MCP сервера в отдельном окне
    3. Создание конфигурации MCP для gemini-cli
    4. Настройка переменных окружения
    5. Опциональный запуск gemini-cli

СИСТЕМНЫЕ ТРЕБОВАНИЯ:
    - PowerShell 7+
    - gemini-cli в PATH
    - Gemini API ключ

"@
    Write-Host $helpText -ForegroundColor Cyan
}

if ($Help) {
    Show-Help
    return
}

# Проверка API ключа
if (-not $ApiKey -and -not $env:GEMINI_API_KEY) {
    Write-Launch "ОШИБКА: Необходимо указать Gemini API ключ" -Type 'Error'
    Write-Host "Используйте: .\start-mcp-gemini.ps1 -ApiKey 'your-api-key'" -ForegroundColor Gray
    return
}

function Test-Prerequisites {
    Write-Launch "Проверка системных требований..." -Type 'Info'
    $issues = @()
    
    # PowerShell версия
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $issues += "Требуется PowerShell 7+. Текущая: $($PSVersionTable.PSVersion)"
    } else {
        Write-Launch "PowerShell $($PSVersionTable.PSVersion) - OK" -Type 'Success'
    }
    
    # gemini-cli
    try {
        $null = & gemini --version 2>&1
        Write-Launch "gemini-cli найден" -Type 'Success'
    } catch {
        $issues += "gemini-cli не найден в PATH"
    }
    
    # MCP сервер файлы
    $mcpScript = Join-Path $PSScriptRoot 'mcp-powershell-server/mcp-powershell-stdio.ps1'
    if (-not (Test-Path $mcpScript)) {
        $issues += "MCP сервер не найден: $mcpScript"
    } else {
        Write-Launch "MCP сервер найден" -Type 'Success'
    }
    
    return $issues
}

function Start-MCPServer {
    Write-Launch "Запуск MCP PowerShell сервера..." -Type 'Info'
    
    $launcherScript = Join-Path $PSScriptRoot 'mcp-powershell-server/launch-mcp-stdio.ps1'
    
    try {
        $processArgs = @{
            FilePath = 'pwsh'
            ArgumentList = @('-NoProfile', '-File', $launcherScript)
            WindowStyle = 'Normal'
            PassThru = $true
        }
        
        $serverProcess = Start-Process @processArgs
        Write-Launch "MCP сервер запущен в отдельном окне (PID: $($serverProcess.Id))" -Type 'Success'
        
        # Короткая пауза для инициализации
        Write-Launch "Ожидание инициализации сервера..." -Type 'Info'
        Start-Sleep -Seconds 3
        
        return $serverProcess
    } catch {
        Write-Launch "Ошибка запуска MCP сервера: $($_.Exception.Message)" -Type 'Error'
        return $null
    }
}

function New-MCPConfiguration {
    Write-Launch "Создание конфигурации MCP..." -Type 'Info'
    
    # Путь к MCP серверу
    $mcpServerPath = Join-Path $PSScriptRoot 'mcp-powershell-server/mcp-powershell-stdio.ps1'
    $mcpServerPath = Resolve-Path $mcpServerPath
    
    $mcpConfig = @{
        mcpServers = @{
            powershell = @{
                command = "pwsh"
                args = @(
                    "-File",
                    $mcpServerPath.ToString()
                )
                env = @{
                    POWERSHELL_EXECUTION_POLICY = "RemoteSigned"
                }
            }
        }
    }
    
    # Сохранение конфигурации
    $configDir = Join-Path $PSScriptRoot 'config'
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    
    $configFile = Join-Path $configDir 'mcp_servers.json'
    $mcpConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $configFile -Encoding UTF8
    
    Write-Launch "Конфигурация MCP сохранена: $configFile" -Type 'Success'
    return $configFile
}

function Start-GeminiWithMCP {
    param([string]$ConfigFile)
    
    Write-Launch "Запуск gemini-cli с поддержкой MCP..." -Type 'Info'
    
    try {
        Write-Host ""
        Write-Host "Запускается gemini-cli в интерактивном режиме с MCP поддержкой..." -ForegroundColor Yellow
        Write-Host "Модель: $Model" -ForegroundColor Gray
        Write-Host "MCP конфигурация: $ConfigFile" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Доступные MCP команды:" -ForegroundColor Cyan
        Write-Host "  - 'Выполни PowerShell команду Get-Process'" -ForegroundColor Gray
        Write-Host "  - 'Запусти скрипт: Get-Service | Where Status -eq Running'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Для выхода используйте 'exit' или Ctrl+C" -ForegroundColor Yellow
        Write-Host ""
        
        # Запуск gemini в интерактивном режиме с MCP
        & gemini --mcp-config $ConfigFile -m $Model -i
        
    } catch {
        Write-Launch "Ошибка запуска gemini-cli: $($_.Exception.Message)" -Type 'Error'
    }
}

function Show-UsageInstructions {
    param([string]$ConfigFile)
    
    Write-Host ""
    Write-Launch "СИСТЕМА ГОТОВА К РАБОТЕ" -Type 'Title'
    
    Write-Host "MCP PowerShell сервер запущен в отдельном окне" -ForegroundColor Green
    Write-Host "Конфигурация MCP создана: $ConfigFile" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "СПОСОБЫ ИСПОЛЬЗОВАНИЯ:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Интерактивный режим gemini-cli:" -ForegroundColor Cyan