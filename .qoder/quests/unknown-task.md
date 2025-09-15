# SmartAgents PowerShell Framework - Debug and Execution Design

## Overview

This design document outlines the debugging, error handling, and execution procedures for the SmartAgents PowerShell Framework, specifically focusing on running the Start-FindSpecAgent with proper API key management and troubleshooting common issues.

## Technology Stack & Dependencies

### Core Requirements
- **PowerShell**: Version 7+ (critical requirement)
- **Gemini CLI**: Command-line interface for Google Gemini API
- **Microsoft.PowerShell.ConsoleGuiTools**: Required for `Out-ConsoleGridView` functionality
- **Google Gemini API Key**: Authentication for AI services

### API Models Supported
- `gemini-2.5-pro`: Enhanced model for complex queries
- `gemini-2.5-flash`: Default fast model for general use

## Architecture

### Component Hierarchy
```
SmartAgents Framework
├── Core Module (SmartAgents.psm1)
│   ├── Configuration Management
│   ├── Session Initialization  
│   ├── Gemini API Integration
│   ├── JSON Processing
│   └── History Management
├── Find-Spec Agent (Find-Spec.ps1)
│   ├── API Key Management
│   ├── Interactive Session
│   ├── Command Processing
│   └── Results Display
└── Agent Configuration (.gemini/)
    ├── GEMINI.md (System Instructions)
    ├── ShowHelp.md (User Help)
    └── settings.json (Configuration)
```

### Data Flow Architecture
```mermaid
flowchart TD
    A[User Input] --> B{API Key Available?}
    B -->|No| C[Request API Key]
    B -->|Yes| D[Initialize Session]
    C --> E[Validate Key Format]
    E --> F[Save to Session Environment]
    F --> D
    D --> G[Start Agent Loop]
    G --> H[Process User Command]
    H --> I{System Command?}
    I -->|Yes| J[Execute System Command]
    I -->|No| K[Send to Gemini API]
    K --> L[Process Response]
    L --> M{JSON Response?}
    M -->|Yes| N[Display in Grid View]
    M -->|No| O[Display as Text]
    N --> P[Save Selection Context]
    O --> Q[Add to History]
    P --> Q
    Q --> G
    J --> G
```

## Debugging & Error Handling Strategy

### Critical Error Categories

#### 1. System Prerequisites Issues
**Error**: PowerShell version compatibility
```powershell
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "Требуется PowerShell 7+. Текущая версия: $($PSVersionTable.PSVersion)"
}
```

**Error**: Missing Gemini CLI
```powershell
try {
    $geminiVersion = & gemini --version 2>&1
} catch {
    throw "Gemini CLI не найден в PATH. Убедитесь, что он установлен."
}
```

**Error**: Missing ConsoleGuiTools
```powershell
try {
    Get-Command Out-ConsoleGridView -ErrorAction Stop | Out-Null
} catch {
    throw "Out-ConsoleGridView недоступен. Установите модуль Microsoft.PowerShell.ConsoleGuiTools."
}
```

#### 2. UI Display & Console Formatting Issues
**Error**: Console encoding problems
- **Detection**: Malformed box-drawing characters in agent banner (line 239)
- **Resolution**: Ensure console supports UTF-8 encoding
- **Fallback**: Provide ASCII-only display mode

**Error**: Color display issues
- **Detection**: Colors not rendering properly in terminal
- **Resolution**: Validate terminal capabilities and provide monochrome fallback

#### 3. API Key Management Issues
**Error**: Missing API Key
- **Detection**: Check `$env:GEMINI_API_KEY`, parameters, and user input
- **Resolution**: Interactive key request with validation
- **Session Management**: Store only in current session environment

**Error**: Invalid API Key Format
- **Detection**: Length < 20 characters or invalid character pattern
- **Resolution**: Format validation with user confirmation option

#### 4. Gemini API Communication Issues
**Error**: Quota Exceeded (429)
```powershell
if ($outputString -match "429" -or $outputString -match "Quota exceeded") {
    Write-ColoredMessage "Превышена квота Google Gemini (Ошибка 429)." -Color $Config.Color.Error
    # Provide troubleshooting guidance
}
```

**Error**: Network/Authentication Issues
- **Detection**: Non-zero exit codes from Gemini CLI
- **Resolution**: Comprehensive error message with troubleshooting steps

#### 5. MCP Server Integration Issues
**Error**: MCP Server Connection Failure
- **Detection**: Server unavailable on port 8090
- **Resolution**: Check server status, restart if needed
- **Fallback**: Direct Gemini CLI mode without MCP

**Error**: PowerShell Command Execution Timeout
- **Detection**: MCP server timeout responses
- **Resolution**: Implement command timeout handling
- **Recovery**: Graceful degradation to direct mode

### Comprehensive Error Handling Procedures

#### Error Handler Framework
```powershell
function Handle-AgentError {
    param(
        [string]$ErrorType,
        [string]$ErrorMessage,
        [hashtable]$Context,
        [string]$RecoveryAction = 'Continue'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @{
        Timestamp = $timestamp
        ErrorType = $ErrorType
        Message = $ErrorMessage
        Context = $Context
        RecoveryAction = $RecoveryAction
    }
    
    # Log error to file
    $logEntry | ConvertTo-Json | Add-Content -Path $Config.ErrorLogPath
    
    # Display formatted error
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                                    ERROR                                     ║" -ForegroundColor Red
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "║  Type: $($ErrorType.PadRight(69))║" -ForegroundColor White
    Write-Host "║  Time: $($timestamp.PadRight(69))║" -ForegroundColor White
    Write-Host "║  Message: $($ErrorMessage.PadRight(64))║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    
    switch ($RecoveryAction) {
        'Exit' { exit 1 }
        'Retry' { return 'retry' }
        'Continue' { return 'continue' }
        'Fallback' { return 'fallback' }
    }
}
```

### Debugging Workflow

#### Step 1: Environment Validation
```mermaid
flowchart TD
    A[Start Debug Session] --> B[Check PowerShell Version]
    B --> C{Version >= 7?}
    C -->|No| D[Display Version Error]
    C -->|Yes| E[Check Gemini CLI]
    E --> F{CLI Available?}
    F -->|No| G[Display CLI Installation Guide]
    F -->|Yes| H[Check ConsoleGuiTools]
    H --> I{Module Available?}
    I -->|No| J[Display Module Installation Guide]
    I -->|Yes| K[Check Console Encoding]
    K --> L{UTF-8 Support?}
    L -->|No| M[Enable ASCII Mode]
    L -->|Yes| N[Check MCP Server]
    N --> O{Server Available?}
    O -->|No| P[Start Direct Mode]
    O -->|Yes| Q[Environment OK]
    M --> Q
    P --> Q
```

#### Step 2: API Key Configuration
```mermaid
flowchart TD
    A[Check API Key Sources] --> B{Parameter Provided?}
    B -->|Yes| C[Use Parameter Key]
    B -->|No| D{Environment Variable Set?}
    D -->|Yes| E[Use Environment Key]
    D -->|No| F[Request Interactive Input]
    F --> G[Validate Key Format]
    G --> H{Valid Format?}
    H -->|No| I[Warn and Confirm]
    H -->|Yes| J[Set Session Variable]
    C --> J
    E --> J
    I --> K{User Confirms?}
    K -->|Yes| J
    K -->|No| F
```

#### Step 3: Agent Initialization
```mermaid
flowchart TD
    A[Initialize Agent] --> B[Create Config Object]
    B --> C[Setup Directory Structure]
    C --> D[Test API Connection]
    D --> E{Connection OK?}
    E -->|No| F[Display Connection Error]
    E -->|Yes| G[Start Interactive Session]
```

## Common Issues & Resolutions

### Issue 1: Port Conflicts (MCP Server)
**Problem**: MCP server port 8090 in use
**Detection**: Server startup failure with port binding error
**Resolution Strategy**:
```powershell
function Test-MCPServerPort {
    param([int]$Port = 8090)
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-MCPServerPort)) {
    Write-Warning "Port 8090 in use. Switching to direct Gemini CLI mode."
    $Config.UseMCP = $false
}
```

### Issue 2: Module Loading Failures
**Problem**: Agent scripts not found or corrupted
**Detection**: Module import errors during agent initialization
**Resolution**: Enhanced path validation and recovery
```powershell
function Validate-AgentFiles {
    param([string]$AgentPath)
    $requiredFiles = @('Find-Spec.ps1', '.gemini/GEMINI.md', '.gemini/ShowHelp.md')
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $AgentPath $file
        if (-not (Test-Path $fullPath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        throw "Missing agent files: $($missingFiles -join ', ')"
    }
}
```

### Issue 3: JSON Processing Errors
**Problem**: Invalid JSON responses from Gemini API
**Detection**: ConvertFrom-Json exceptions during response parsing
**Resolution**: Robust JSON parsing with fallback modes
```powershell
function Parse-GeminiResponse {
    param([string]$Response)
    
    # Try direct JSON parsing
    try {
        return $Response | ConvertFrom-Json
    } catch {
        # Try extracting JSON from markdown code blocks
        if ($Response -match '(?s)```json\s*(.*?)\s*```') {
            try {
                return $matches[1] | ConvertFrom-Json
            } catch {
                Write-Warning "Failed to parse JSON from code block"
            }
        }
        
        # Fallback to text mode
        Write-Host "Response parsing failed, displaying as text:" -ForegroundColor Yellow
        return $null
    }
}
```

### Issue 4: History File Access
**Problem**: Cannot write to history directory due to permissions
**Detection**: File system permission errors during session initialization
**Resolution**: Graceful degradation with alternative storage
```powershell
function Initialize-HistoryStorage {
    param([string]$PreferredPath)
    
    try {
        if (-not (Test-Path $PreferredPath)) {
            New-Item -Path $PreferredPath -ItemType Directory -Force
        }
        # Test write access
        $testFile = Join-Path $PreferredPath "test_write.tmp"
        "test" | Out-File -FilePath $testFile
        Remove-Item $testFile
        return $PreferredPath
    } catch {
        # Fallback to temp directory
        $tempPath = Join-Path $env:TEMP "SmartAgents_History"
        try {
            if (-not (Test-Path $tempPath)) {
                New-Item -Path $tempPath -ItemType Directory -Force
            }
            Write-Warning "Using temporary history storage: $tempPath"
            return $tempPath
        } catch {
            Write-Warning "History storage disabled due to file system restrictions"
            return $null
        }
    }
}
```

### Issue 5: Console Formatting Errors (Line 239 Context)
**Problem**: Box-drawing characters not displaying correctly
**Detection**: Terminal encoding issues affecting UI elements
**Resolution**: Console compatibility detection and fallback
```powershell
function Test-ConsoleCapabilities {
    $testChars = @('╔', '║', '╚', '═')
    foreach ($char in $testChars) {
        try {
            [Console]::Write($char)
            [Console]::SetCursorPosition([Console]::CursorLeft - 1, [Console]::CursorTop)
            [Console]::Write(' ')
        } catch {
            return $false
        }
    }
    return $true
}

function Show-AgentBanner {
    param([hashtable]$Config, [bool]$UseAscii = $false)
    
    if ($UseAscii -or -not (Test-ConsoleCapabilities)) {
        # ASCII fallback banner
        Write-Host "+==============================================================================+" -ForegroundColor Green
        Write-Host "|                    🔍 AI-ПОИСКОВИК СПЕЦИФИКАЦИЙ                             |" -ForegroundColor Green
        Write-Host "+==============================================================================+" -ForegroundColor Green
    } else {
        # UTF-8 box drawing characters (original line 239 context)
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                    🔍 AI-ПОИСКОВИК СПЕЦИФИКАЦИЙ                             ║" -ForegroundColor Green
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    }
}
```

## MCP Server Integration Architecture

### Model Context Protocol (MCP) Overview
The SmartAgents framework supports dual-mode operation:
1. **Direct Mode**: Direct communication with Gemini API via CLI
2. **MCP Mode**: Enhanced mode using Model Context Protocol server for PowerShell command execution

### MCP Server Components
```mermaid
flowchart TD
    A[Find-Spec Agent] --> B{MCP Available?}
    B -->|Yes| C[MCP PowerShell Server]
    B -->|No| D[Direct Gemini CLI]
    C --> E[Isolated PowerShell Environment]
    C --> F[Command Timeout Handler]
    C --> G[STDIO Communication]
    E --> H[Execute PowerShell Scripts]
    F --> I[Timeout Recovery]
    G --> J[Gemini CLI Integration]
    D --> K[Standard API Calls]
    H --> L[Return Results]
    I --> L
    J --> L
    K --> L
    L --> M[Display to User]
```

### MCP Server Functionality

#### Server Initialization
```powershell
function Initialize-MCPServer {
    param(
        [int]$Port = 8090,
        [int]$TimeoutSeconds = 30
    )
    
    try {
        # Check if MCP server is already running
        $existingProcess = Get-Process -Name "mcp-powershell-server" -ErrorAction SilentlyContinue
        if ($existingProcess) {
            Write-Host "MCP Server already running (PID: $($existingProcess.Id))" -ForegroundColor Green
            return $true
        }
        
        # Start MCP server
        $serverPath = Join-Path $PSScriptRoot "mcp-powershell-server\mcp-powershell-stdio.ps1"
        if (-not (Test-Path $serverPath)) {
            Write-Warning "MCP server script not found: $serverPath"
            return $false
        }
        
        $serverProcess = Start-Process -FilePath "powershell" -ArgumentList "-File", $serverPath, "-Port", $Port -NoNewWindow -PassThru
        
        # Wait for server to initialize
        Start-Sleep -Seconds 2
        
        if (Test-MCPServerConnection -Port $Port) {
            Write-Host "MCP Server started successfully on port $Port" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "Failed to establish connection to MCP server"
            return $false
        }
    } catch {
        Write-Error "Failed to initialize MCP server: $($_.Exception.Message)"
        return $false
    }
}
```

#### MCP Communication Protocol
```powershell
function Invoke-MCPCommand {
    param(
        [string]$Command,
        [hashtable]$Parameters = @{},
        [int]$TimeoutSeconds = 30
    )
    
    $mcpRequest = @{
        jsonrpc = "2.0"
        id = (New-Guid).ToString()
        method = "tools/call"
        params = @{
            name = "powershell_execute"
            arguments = @{
                command = $Command
                parameters = $Parameters
                timeout = $TimeoutSeconds
            }
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        # Send request to MCP server via STDIO
        $response = & gemini -m gemini-2.5-flash --mcp-server "stdio://mcp-powershell-server" -p $mcpRequest
        
        $mcpResponse = $response | ConvertFrom-Json
        
        if ($mcpResponse.error) {
            throw "MCP Error: $($mcpResponse.error.message)"
        }
        
        return $mcpResponse.result
    } catch {
        Write-Error "MCP communication failed: $($_.Exception.Message)"
        return $null
    }
}
```

#### Error Recovery and Fallback
```powershell
function Invoke-GeminiWithMCPFallback {
    param(
        [string]$Prompt,
        [string]$Model,
        [hashtable]$Config
    )
    
    # Try MCP mode first if available
    if ($Config.UseMCP -and (Test-MCPServerConnection)) {
        try {
            Write-Verbose "Using MCP mode for enhanced PowerShell integration"
            $mcpResponse = Invoke-MCPCommand -Command "process_spec_search" -Parameters @{ query = $Prompt }
            if ($mcpResponse) {
                return $mcpResponse.output
            }
        } catch {
            Write-Warning "MCP mode failed, falling back to direct mode: $($_.Exception.Message)"
            $Config.UseMCP = $false
        }
    }
    
    # Fallback to direct Gemini CLI
    Write-Verbose "Using direct Gemini CLI mode"
    return Invoke-GeminiAPI -Prompt $Prompt -Model $Model -Config $Config
}
```

### MCP Server Monitoring and Health Checks

#### Health Check Implementation
```powershell
function Test-MCPServerHealth {
    param([int]$Port = 8090)
    
    try {
        # Test basic connectivity
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("localhost", $Port)
        $tcpClient.Close()
        
        # Test MCP protocol response
        $pingRequest = @{
            jsonrpc = "2.0"
            id = "health_check"
            method = "ping"
        } | ConvertTo-Json
        
        $response = Invoke-MCPCommand -Command "ping"
        return $response -ne $null
    } catch {
        return $false
    }
}

function Start-MCPHealthMonitor {
    param([int]$IntervalSeconds = 30)
    
    $timer = New-Object System.Timers.Timer
    $timer.Interval = $IntervalSeconds * 1000
    $timer.AutoReset = $true
    
    $timer.Add_Elapsed({
        if (-not (Test-MCPServerHealth)) {
            Write-Warning "MCP Server health check failed, attempting restart"
            Initialize-MCPServer
        }
    })
    
    $timer.Start()
    return $timer
}
```

### MCP Integration Configuration

#### Configuration Management
```powershell
function New-MCPConfig {
    param(
        [bool]$EnableMCP = $true,
        [int]$Port = 8090,
        [int]$TimeoutSeconds = 30,
        [bool]$AutoRestart = $true
    )
    
    return @{
        UseMCP = $EnableMCP
        MCPPort = $Port
        MCPTimeout = $TimeoutSeconds
        MCPAutoRestart = $AutoRestart
        MCPServerPath = Join-Path $PSScriptRoot "mcp-powershell-server"
        MCPLogLevel = "INFO"
    }
}
```

#### Environment Detection
```powershell
function Test-MCPSupport {
    $requirements = @(
        @{ Name = "PowerShell 7+"; Test = { $PSVersionTable.PSVersion.Major -ge 7 } },
        @{ Name = "Gemini CLI"; Test = { try { & gemini --version | Out-Null; $true } catch { $false } } },
        @{ Name = "MCP Server Scripts"; Test = { Test-Path (Join-Path $PSScriptRoot "mcp-powershell-server\*.ps1") } },
        @{ Name = "Network Port Available"; Test = { Test-MCPServerPort -Port 8090 } }
    )
    
    $failed = @()
    foreach ($req in $requirements) {
        if (-not (& $req.Test)) {
            $failed += $req.Name
        }
    }
    
    if ($failed.Count -gt 0) {
        Write-Warning "MCP mode not available. Missing requirements: $($failed -join ', ')"
        return $false
    }
    
    return $true
}
```

## Deployment & Execution Procedures

### Prerequisites Verification
Before running Find-Spec agent, ensure all system requirements are met:

```powershell
# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "PowerShell 7+ required. Current: $($PSVersionTable.PSVersion)"
    exit 1
}

# Verify Gemini CLI installation
try {
    $geminiVersion = & gemini --version 2>&1
    Write-Host "✓ Gemini CLI found: $geminiVersion" -ForegroundColor Green
} catch {
    Write-Error "Gemini CLI not found. Install from: https://github.com/google/generative-ai-cli"
    exit 1
}

# Check ConsoleGuiTools module
try {
    Get-Command Out-ConsoleGridView -ErrorAction Stop | Out-Null
    Write-Host "✓ Microsoft.PowerShell.ConsoleGuiTools available" -ForegroundColor Green
} catch {
    Write-Warning "Installing Microsoft.PowerShell.ConsoleGuiTools..."
    Install-Module Microsoft.PowerShell.ConsoleGuiTools -Force
}
```

### Terminal Execution Methods

#### Method 1: Direct Script Execution
```powershell
# Navigate to project directory
cd "c:\powershell\modules\SmartAgents-PowerShell-Framework"

# Set API key for current session
$env:GEMINI_API_KEY = "AIzaSyBUgSKa6hcsmxzRVv16L2zNJiOoFBDJNO8"

# Execute Find-Spec agent directly
.\SmartAgents\Agents\Find-Spec.ps1
```

#### Method 2: Module Import and Function Call
```powershell
# Navigate to SmartAgents directory
cd "c:\powershell\modules\SmartAgents-PowerShell-Framework\SmartAgents"

# Import the module
Import-Module .\SmartAgents.psd1 -Force

# Run with API key parameter
Start-FindSpecAgent -ApiKey "AIzaSyBUgSKa6hcsmxzRVv16L2zNJiOoFBDJNO8"

# Alternative: Use alias
find-spec -Key "AIzaSyBUgSKa6hcsmxzRVv16L2zNJiOoFBDJNO8"
```

#### Method 3: Installation Script Approach
```powershell
# Run installation with API key
cd "c:\powershell\modules\SmartAgents-PowerShell-Framework\SmartAgents"
.\install.ps1 -ApiKey "AIzaSyBUgSKa6hcsmxzRVv16L2zNJiOoFBDJNO8"

# Import module after installation
Import-Module .\SmartAgents.psd1

# Execute agent
Start-FindSpecAgent
```

### Syntax Error Detection and Resolution

#### Critical Syntax Issues Identified

**Error 1: Missing Closing Brace for Main Function**
- **Location**: Find-Spec.ps1, function Start-FindSpecAgent
- **Problem**: Main function missing closing `}` brace
- **Detection**: PowerShell parser error "Missing closing '}' in statement block"
- **Resolution**: Add missing closing brace at end of function

**Error 2: Unicode Character Issues**
- **Location**: Line 256 and 299
- **Problem**: Unicode emoji characters causing parsing issues
- **Detection**: "Unexpected token ')' in expression" errors
- **Resolution**: Properly escape unicode characters or use ASCII alternatives

**Error 3: String Termination Issues**
- **Location**: Line 299
- **Problem**: String missing terminator quote
- **Detection**: "The string is missing the terminator" error
- **Resolution**: Ensure all strings have proper opening and closing quotes

#### Syntax Validation Framework
```powershell
function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    try {
        # Use PowerShell parser to validate syntax
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $FilePath, [ref]$tokens, [ref]$errors
        )
        
        if ($errors.Count -gt 0) {
            Write-Host "Syntax errors found in $FilePath:" -ForegroundColor Red
            foreach ($error in $errors) {
                Write-Host "  Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Yellow
            }
            return $false
        }
        
        Write-Host "✓ Syntax validation passed for $FilePath" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to parse file $FilePath: $($_.Exception.Message)"
        return $false
    }
}
```

#### Specific Fix for Find-Spec.ps1
```powershell
# Add this function to validate and fix syntax issues
function Repair-FindSpecSyntax {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw
    $fixedContent = $content
    
    # Fix 1: Ensure proper function closure
    if (-not ($content -match '(?s)function Start-FindSpecAgent \{.*?\n\}\s*$')) {
        Write-Host "Adding missing closing brace for Start-FindSpecAgent function" -ForegroundColor Yellow
        if (-not $content.TrimEnd().EndsWith('}')) {
            $fixedContent = $content.TrimEnd() + "`n}"
        }
    }
    
    # Fix 2: Handle Unicode emoji issues
    $emojiPattern = '[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]'
    if ($fixedContent -match $emojiPattern) {
        Write-Host "Replacing problematic Unicode characters" -ForegroundColor Yellow
        $fixedContent = $fixedContent -replace '👋', '(wave)'
        $fixedContent = $fixedContent -replace '🔍', '[SEARCH]'
    }
    
    # Fix 3: Ensure proper string termination
    $lines = $fixedContent -split '\r?\n'
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        # Check for unterminated strings
        $quoteCount = ($line.ToCharArray() | Where-Object { $_ -eq '"' }).Count
        if ($quoteCount % 2 -ne 0 -and $line -notmatch '#.*"') {
            Write-Host "Fixing unterminated string on line $($i + 1)" -ForegroundColor Yellow
            $lines[$i] = $line + '"'
        }
    }
    $fixedContent = $lines -join "`n"
    
    # Backup original and save fixed version
    Copy-Item -Path $FilePath -Destination "$FilePath.backup" -Force
    Set-Content -Path $FilePath -Value $fixedContent -Encoding UTF8
    
    Write-Host "✓ Syntax fixes applied to $FilePath" -ForegroundColor Green
    Write-Host "  Original backed up to $FilePath.backup" -ForegroundColor Gray
}
```

#### Automated Syntax Repair Workflow
```powershell
function Repair-AgentSyntax {
    param([string]$AgentDirectory)
    
    $agentFiles = Get-ChildItem -Path $AgentDirectory -Filter "*.ps1" -Recurse
    $repairResults = @()
    
    foreach ($file in $agentFiles) {
        Write-Host "Checking syntax for $($file.Name)..." -ForegroundColor Cyan
        
        $beforeValid = Test-PowerShellSyntax -FilePath $file.FullName
        
        if (-not $beforeValid) {
            Write-Host "Attempting to repair $($file.Name)..." -ForegroundColor Yellow
            Repair-FindSpecSyntax -FilePath $file.FullName
            
            $afterValid = Test-PowerShellSyntax -FilePath $file.FullName
            
            $repairResults += @{
                File = $file.Name
                BeforeRepair = $beforeValid
                AfterRepair = $afterValid
                Status = if ($afterValid) { "Fixed" } else { "Failed" }
            }
        } else {
            $repairResults += @{
                File = $file.Name
                BeforeRepair = $beforeValid
                AfterRepair = $beforeValid
                Status = "No repair needed"
            }
        }
    }
    
    # Display repair summary
    Write-Host "`nSyntax Repair Summary:" -ForegroundColor Green
    $repairResults | ForEach-Object {
        $status = $_["Status"]
        $color = switch ($status) {
            "Fixed" { "Green" }
            "Failed" { "Red" }
            "No repair needed" { "Gray" }
        }
        Write-Host "  $($_["File"]): $status" -ForegroundColor $color
    }
    
    return $repairResults
}
```

### Pre-Execution Syntax Validation

#### Module Loading with Syntax Check
```powershell
function Import-SmartAgentsModule {
    param(
        [string]$ModulePath,
        [switch]$AutoRepair
    )
    
    $moduleFile = Join-Path $ModulePath "SmartAgents.psd1"
    $agentsPath = Join-Path $ModulePath "Agents"
    
    # Validate module manifest
    try {
        Test-ModuleManifest -Path $moduleFile -ErrorAction Stop
        Write-Host "✓ Module manifest validation passed" -ForegroundColor Green
    } catch {
        Write-Error "Module manifest validation failed: $($_.Exception.Message)"
        return $false
    }
    
    # Validate agent scripts syntax
    $syntaxIssues = @()
    $agentFiles = Get-ChildItem -Path $agentsPath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $agentFiles) {
        if (-not (Test-PowerShellSyntax -FilePath $file.FullName)) {
            $syntaxIssues += $file.FullName
        }
    }
    
    if ($syntaxIssues.Count -gt 0) {
        Write-Host "Syntax issues found in agent files:" -ForegroundColor Red
        $syntaxIssues | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        
        if ($AutoRepair) {
            Write-Host "Attempting automatic repair..." -ForegroundColor Cyan
            $repairResults = Repair-AgentSyntax -AgentDirectory $agentsPath
            
            # Re-check after repair
            $remainingIssues = $repairResults | Where-Object { $_["Status"] -eq "Failed" }
            if ($remainingIssues.Count -gt 0) {
                Write-Error "Failed to repair all syntax issues. Manual intervention required."
                return $false
            }
        } else {
            Write-Host "Use -AutoRepair switch to attempt automatic fixes" -ForegroundColor Cyan
            return $false
        }
    }
    
    # Import module if syntax validation passed
    try {
        Import-Module $moduleFile -Force
        Write-Host "✓ SmartAgents module imported successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to import module: $($_.Exception.Message)"
        return $false
    }
}
```

#### Safe Module Import Command
```powershell
# Use this command instead of direct Import-Module
Import-SmartAgentsModule -ModulePath ".\" -AutoRepair
```

#### Quick Fix Commands for Current Errors

**Step 1: Fix Missing Closing Brace**
```powershell
# Navigate to the problematic file
$filePath = "C:\powershell\modules\SmartAgents-PowerShell-Framework\SmartAgents\Agents\Find-Spec.ps1"

# Read the current content
$content = Get-Content -Path $filePath -Raw

# Add missing closing brace if not present
if (-not $content.TrimEnd().EndsWith('}')) {
    $fixedContent = $content.TrimEnd() + "`n}"
    
    # Backup original
    Copy-Item -Path $filePath -Destination "$filePath.backup"
    
    # Save fixed version
    Set-Content -Path $filePath -Value $fixedContent -Encoding UTF8
    Write-Host "Fixed missing closing brace in Find-Spec.ps1" -ForegroundColor Green
}
```

**Step 2: Fix Unicode Character Issues**
```powershell
# Fix emoji characters that cause parsing issues
$content = Get-Content -Path $filePath -Raw
$fixedContent = $content -replace '👋', '(wave)' -replace '🔍', '[SEARCH]'

# Handle problematic unicode in string literals
$fixedContent = $fixedContent -replace '"👋"', '"(wave)"'
$fixedContent = $fixedContent -replace '"🔍"', '"[SEARCH]"'

# Save fixed version
Set-Content -Path $filePath -Value $fixedContent -Encoding UTF8
Write-Host "Fixed Unicode character issues" -ForegroundColor Green
```

**Step 3: Validate Syntax After Fixes**
```powershell
# Test the syntax using PowerShell parser
try {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $filePath, [ref]$tokens, [ref]$errors
    ) | Out-Null
    
    if ($errors.Count -eq 0) {
        Write-Host "✓ Syntax validation passed!" -ForegroundColor Green
    } else {
        Write-Host "Remaining syntax errors:" -ForegroundColor Red
        $errors | ForEach-Object {
            Write-Host "  Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Error "Failed to validate syntax: $($_.Exception.Message)"
}
```

**Step 4: Safe Module Import**
```powershell
# Remove any existing module instances
Remove-Module SmartAgents -ErrorAction SilentlyContinue

# Import with error handling
try {
    Import-Module ".\SmartAgents.psd1" -Force
    Write-Host "✓ Module imported successfully!" -ForegroundColor Green
    
    # Test agent function availability
    if (Get-Command Start-FindSpecAgent -ErrorAction SilentlyContinue) {
        Write-Host "✓ Start-FindSpecAgent function available" -ForegroundColor Green
    } else {
        Write-Warning "Start-FindSpecAgent function not found"
    }
} catch {
    Write-Error "Module import failed: $($_.Exception.Message)"
}
```

**Complete Fix Script**
```powershell
# Complete automated fix for Find-Spec.ps1 syntax errors
function Fix-FindSpecSyntaxErrors {
    $filePath = "C:\powershell\modules\SmartAgents-PowerShell-Framework\SmartAgents\Agents\Find-Spec.ps1"
    
    if (-not (Test-Path $filePath)) {
        Write-Error "Find-Spec.ps1 not found at $filePath"
        return
    }
    
    Write-Host "Backing up original file..." -ForegroundColor Cyan
    Copy-Item -Path $filePath -Destination "$filePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    Write-Host "Reading file content..." -ForegroundColor Cyan
    $content = Get-Content -Path $filePath -Raw
    
    Write-Host "Applying fixes..." -ForegroundColor Cyan
    
    # Fix 1: Add missing closing brace
    if (-not $content.TrimEnd().EndsWith('}')) {
        $content = $content.TrimEnd() + "`n}"
        Write-Host "  ✓ Added missing closing brace" -ForegroundColor Green
    }
    
    # Fix 2: Replace problematic Unicode characters
    $originalLength = $content.Length
    $content = $content -replace '👋', '(wave)'
    $content = $content -replace '🔍', '[SEARCH]'
    if ($content.Length -ne $originalLength) {
        Write-Host "  ✓ Fixed Unicode character issues" -ForegroundColor Green
    }
    
    # Fix 3: Check for unterminated strings
    $lines = $content -split '\r?\n'
    $lineNumber = 0
    $stringFixed = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $lineNumber = $i + 1
        
        # Simple check for unterminated strings (basic heuristic)
        if ($line -match '"[^"]*$' -and $line -notmatch '#.*"[^"]*$') {
            $lines[$i] = $line + '"'
            Write-Host "  ✓ Fixed unterminated string on line $lineNumber" -ForegroundColor Green
            $stringFixed = $true
        }
    }
    
    if ($stringFixed) {
        $content = $lines -join "`n"
    }
    
    Write-Host "Saving fixed content..." -ForegroundColor Cyan
    Set-Content -Path $filePath -Value $content -Encoding UTF8
    
    Write-Host "Validating syntax..." -ForegroundColor Cyan
    try {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $filePath, [ref]$tokens, [ref]$errors
        ) | Out-Null
        
        if ($errors.Count -eq 0) {
            Write-Host "✓ All syntax errors fixed successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Remaining syntax errors:" -ForegroundColor Red
            $errors | ForEach-Object {
                Write-Host "  Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Yellow
            }
            return $false
        }
    } catch {
        Write-Error "Syntax validation failed: $($_.Exception.Message)"
        return $false
    }
}

# Execute the fix
Fix-FindSpecSyntaxErrors
```

### Execution Troubleshooting

#### Common Execution Issues

**Issue 1: Execution Policy Restriction**
```powershell
# Check current execution policy
Get-ExecutionPolicy

# If Restricted, set to RemoteSigned for current session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```

**Issue 2: Module Not Found**
```powershell
# Add module path if needed
$env:PSModulePath += ";c:\powershell\modules\SmartAgents-PowerShell-Framework"

# Force reload module
Remove-Module SmartAgents -ErrorAction SilentlyContinue
Import-Module .\SmartAgents.psd1 -Force
```

**Issue 3: API Key Environment Variable**
```powershell
# Verify API key is set
if ([string]::IsNullOrEmpty($env:GEMINI_API_KEY)) {
    $env:GEMINI_API_KEY = "AIzaSyBUgSKa6hcsmxzRVv16L2zNJiOoFBDJNO8"
    Write-Host "API key set for current session" -ForegroundColor Green
}
```

### Step-by-Step Execution Guide

#### Terminal Session Workflow
```mermaid
flowchart TD
    A[Open PowerShell Terminal] --> B[Navigate to Project Directory]
    B --> C[Set Execution Policy if Needed]
    C --> D[Set API Key Environment Variable]
    D --> E[Choose Execution Method]
    E --> F{Method 1: Direct Script?}
    E --> G{Method 2: Module Import?}
    E --> H{Method 3: Installation Script?}
    F -->|Yes| I[Execute .\SmartAgents\Agents\Find-Spec.ps1]
    G -->|Yes| J[Import-Module, then Start-FindSpecAgent]
    H -->|Yes| K[Run install.ps1, then Start-FindSpecAgent]
    I --> L[Agent Starts Successfully]
    J --> L
    K --> L
    L --> M[Interactive Session Active]
    M --> N[Enter Queries or Commands]
    N --> O[Type 'exit' to Quit]
```

### Command-Line Parameters

#### Start-FindSpecAgent Parameters
```powershell
Start-FindSpecAgent [
    [-Model] <String> {gemini-2.5-pro | gemini-2.5-flash}
    [-ApiKey] <String>
    [-K] <String>     # Alias for ApiKey
]
```

**Examples:**
```powershell
# Default model with API key
Start-FindSpecAgent -ApiKey "YOUR_API_KEY"

# Specific model selection
Start-FindSpecAgent -Model "gemini-2.5-pro" -Key "YOUR_API_KEY"

# Using environment variable (no parameters needed)
$env:GEMINI_API_KEY = "YOUR_API_KEY"
Start-FindSpecAgent
```

### Debug Mode Execution

#### Enhanced Logging
```powershell
# Enable verbose output
$VerbosePreference = "Continue"
Start-FindSpecAgent -Verbose

# Enable debug output
$DebugPreference = "Continue"
Start-FindSpecAgent -Debug

# Combine with error action
Start-FindSpecAgent -ErrorAction Stop
```

#### Error Logging
```powershell
# Redirect errors to file
Start-FindSpecAgent 2>"error.log"

# Capture all output
Start-FindSpecAgent *>"full_output.log"

# Transcript logging
Start-Transcript -Path "find_spec_session.log"
Start-FindSpecAgent
Stop-Transcript
```

### Session Management

#### Interactive Commands Available
- `?` or `help` - Show agent help
- `history` - Display session history
- `clear` - Clear session history
- `key` - Show API key information
- `exit` or `quit` - Exit agent

#### Session Files Location
```
SmartAgents/Agents/FindSpec/.gemini/
├── .chat_history/          # Session history files
│   └── spec_session_*.jsonl
├── GEMINI.md              # System instructions
├── ShowHelp.md            # User help content
└── settings.json          # Configuration
```

### Performance Monitoring

#### Execution Metrics
```powershell
# Measure execution time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Start-FindSpecAgent
$stopwatch.Stop()
Write-Host "Execution time: $($stopwatch.Elapsed)"

# Monitor memory usage
$beforeMemory = [GC]::GetTotalMemory($false)
Start-FindSpecAgent
$afterMemory = [GC]::GetTotalMemory($true)
Write-Host "Memory used: $([math]::Round(($afterMemory - $beforeMemory) / 1MB, 2)) MB"
```

## Testing Strategy

### Unit Testing Approach
1. **API Key Validation Tests**
   - Valid key formats
   - Invalid key handling
   - Empty key scenarios

2. **Configuration Tests**
   - Directory creation
   - Path resolution
   - Permission validation

3. **Gemini Integration Tests**
   - API connectivity
   - Response parsing
   - Error handling

### Integration Testing
1. **End-to-End Agent Flow**
   - Complete session lifecycle
   - Command processing
   - History management

2. **Error Recovery Tests**
   - Network interruption handling
   - Invalid response processing
   - Session restoration

## Security Considerations

### API Key Management
- **Session-Only Storage**: Never persist API keys to permanent storage
- **Masked Display**: Show only partial key information in logs
- **Secure Transmission**: Use environment variables for CLI communication

### Input Validation
- **Command Sanitization**: Validate system commands before execution
- **JSON Parsing**: Safe JSON processing with error handling
- **Path Validation**: Secure file path handling for history and config

## Performance Optimization

### Response Time Optimization
- **Model Selection**: Use `gemini-2.5-flash` for faster responses
- **Caching Strategy**: Implement session-based response caching
- **Timeout Management**: Set appropriate timeouts for API calls

### Memory Management
- **History Limits**: Implement history file size limits
- **Session Cleanup**: Proper disposal of temporary resources
- **Streaming Responses**: Handle large API responses efficiently

## Configuration Management

### Agent Configuration Structure
```json
{
  "AgentRoot": "path/to/agent",
  "HistoryDir": "path/to/history", 
  "ConfigDir": "path/to/config",
  "SessionPrefix": "session_prefix",
  "AppName": "Agent Name",
  "Emoji": "🔍",
  "Color": {
    "Success": "Green",
    "Warning": "Yellow", 
    "Info": "Cyan",
    "Error": "Red",
    "Prompt": "Green",
    "Selection": "Magenta",
    "Processing": "Gray"
  }
}
```

### Session Management
- **History Format**: JSONL format for chat history
- **Session Naming**: Timestamp-based unique session identifiers
- **Cleanup Strategy**: Automatic cleanup of old sessions

## Deployment Considerations

### Installation Requirements
1. Run `install.ps1` with API key parameter
2. Import module: `Import-Module .\SmartAgents.psd1`
3. Verify prerequisites with system checks

### Runtime Environment
- **Execution Policy**: Ensure PowerShell execution policy allows script execution
- **Network Access**: Verify connectivity to Google Gemini API endpoints
- **File Permissions**: Ensure write access to history and config directories

### Monitoring & Logging
- **Session Logging**: Comprehensive logging of agent interactions
- **Error Tracking**: Detailed error information for troubleshooting
- **Performance Metrics**: Track API response times and success rates