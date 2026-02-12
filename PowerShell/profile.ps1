# Remove commented out lines that are not being used
# Removing:
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/kali.omp.json" | Invoke-Expression

if (Get-Module -ListAvailable -Name z) {
    Import-Module z
    $script:zJumpCmd = (Get-Module z).ExportedCommands['z']
    if ($script:zJumpCmd) {
        function zz { & $script:zJumpCmd @args }
    }
}

# ZLocation as z (loads on first use)
function z {
    param($location)
    
    Remove-Item -Path Alias:\z -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\z -ErrorAction SilentlyContinue
    
    Import-Module ZLocation
    
    if ($location) {
        Invoke-Expression "z $location"
    } else {
        Write-Output "ZLocation loaded. Use 'z <location>' to jump to frequently used directories."
    }
}

# zoxide as zx
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd zx | Out-String) })
}

# Provide on-demand activation for PowerType (Alt+P)
if (Get-Module -ListAvailable -Name PowerType) {
    if (Get-Command -Name Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
        Set-PSReadLineKeyHandler -Chord 'Alt+p' -BriefDescription 'Enable PowerType' -LongDescription 'Enable PowerType predictions' -ScriptBlock {
            if (-not (Get-Module -Name PowerType)) {
                Enable-PowerType
            }
        }
    }
}

# Proxy handler for Ctrl+R that initializes PSFzf on first use
if (Get-Command -Name Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -BriefDescription 'Fuzzy reverse history' -LongDescription 'Search command history with fzf' -ScriptBlock {
        if (-not (Get-Module -Name PSFzf)) {
            Initialize-FzfFunctions
        }
        
        if (Get-Command -Name Invoke-Fzf -ErrorAction SilentlyContinue) {
            $historyPath = (Get-PSReadLineOption).HistorySavePath
            if (Test-Path $historyPath) {
                $history = Get-Content $historyPath -ErrorAction SilentlyContinue | Where-Object { $_ -and $_.Trim().Length -gt 0 } | Select-Object -Last 1000 -Unique
                if ($history) {
                    $selected = $history | Invoke-Fzf
                    if ($selected -and $selected.Trim().Length -gt 0) {
                        $line = ''
                        $cursor = $null
                        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
                        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $selected.Trim())
                    }
                }
            }
        }
    }
}

function Initialize-PSReadLineOptions {
    # Remove the proxy function
    Remove-Item -Path Function:\Set-PSReadLineOptionsInitial -ErrorAction SilentlyContinue
    
    # Set actual options
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
    Set-PSReadLineOption -MaximumHistoryCount 1000
}

# Defer lightweight initialization until shell becomes idle (run once)
$global:__profileOnIdleSub = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -Action {
    try { Initialize-PSReadLineOptions } catch { }

    # Late imports that are nice-to-have but not needed at prompt time
    try {
        if (-not (Get-Module -Name Microsoft.WinGet.CommandNotFound)) {
            Import-Module Microsoft.WinGet.CommandNotFound -ErrorAction SilentlyContinue
        }
    } catch { }

    try {
        $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
        if (Test-Path($ChocolateyProfile)) {
            Import-Module $ChocolateyProfile -ErrorAction SilentlyContinue
        }
    } catch { }

    try {
        $sub = Get-Variable -Name __profileOnIdleSub -Scope Global -ErrorAction SilentlyContinue
        if ($null -ne $sub) {
            Unregister-Event -SubscriptionId $sub.Value.SubscriptionId -ErrorAction SilentlyContinue
            Remove-Variable -Name __profileOnIdleSub -Scope Global -ErrorAction SilentlyContinue
        }
    } catch { }
} 

# PSFzf has undocumented option to use fd executable for
# file and directory searching. This enables that option.
# Initialize PSFzf options on first use
function Initialize-PsFzfOptions {
    # Remove the proxy function
    Remove-Item -Path Function:\Set-PsFzfOptionsInitial -ErrorAction SilentlyContinue
    
    # Set actual PSFzf options
    Set-PsFzfOption -EnableFd:$true
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PsFzfOption -TabExpansion
}

# Create proxy function definition; actual initialization happens on first PSFzf use
function Set-PsFzfOptionsInitial { Initialize-PsFzfOptions }


# Custom function to SetLocation, because PSFzf uses
# Get-ChildItem which doesn't use fd and doesn't use
# ignore files. Invoke-FuzzySetLocation is defined here
# https://github.com/kelleyma49/PSFzf/blob/b97263a30addd9a2c84a8603382c92e4e6de0eeb/PSFzf.Functions.ps1#L142
# 
# This implementation is for setting FileSystem location
# and implementation uses parts of
# https://github.com/kelleyma49/PSFzf/blob/b97263a30addd9a2c84a8603382c92e4e6de0eeb/PSFzf.Base.ps1#L20
# https://github.com/kelleyma49/PSFzf/blob/b97263a30addd9a2c84a8603382c92e4e6de0eeb/PSFzf.Base.ps1#L35
function Invoke-FuzzySetLocation2() {
    param($Directory = $null)
    
    if ($null -eq $Directory) {
        $Directory = $PWD.Path 
    }

    $result = $null
    $RunningInWindowsTerminal = [bool]($env:WT_Session)
    $DefaultFileSystemFdCmd = if ($RunningInWindowsTerminal) {
        "fd.exe --color always . {0}"    
    } else {
        "fd.exe . {0}"   
    }

    try {
        if ($Directory.Contains(' ')) {
            $strDir = """$Directory""" 
        }
        else {
            $strDir = $Directory
        }

        Invoke-Expression (($DefaultFileSystemFdCmd -f '--type directory {0} --max-depth 1') -f $strDir) | Invoke-Fzf | ForEach-Object { $result = $_ }
    }
    catch {
        Write-Error "Error occurred while searching directories: $_"
        return
    }

    if ($null -ne $result) {
        Set-Location $result
    } 
}

# Show tips about newly added commands
function Get-Tips {

  $tips = @(
    [pscustomobject]@{
      Command     = 'fcd'
      Description = 'navigate to subdirectory'

    },
    [pscustomobject]@{
      Command     = 'ALT+C'
      Description = 'navigate to deep subdirectory'

    },
    [pscustomobject]@{
      Command     = 'z'
      Description = 'ZLocation (loads on first use)'

    },
    [pscustomobject]@{
      Command     = 'zx'
      Description = 'zoxide - jump to frecent dirs'

    },
    [pscustomobject]@{
      Command     = 'zz'
      Description = 'badmotorfinger/z - jump to frecent dirs'

    },
    [pscustomobject]@{
      Command     = 'tldr'
      Description = 'Official tldr client written in Rust'

    },
    [pscustomobject]@{
      Command     = 'bat'
      Description = 'A cat(1) clone with syntax highlighting and Git integration'

    },
    [pscustomobject]@{
      Command     = 'lazygit'
      Description = 'Simple terminal UI for git commands'

    },
    [pscustomobject]@{
      Command     = 'lazydocker'
      Description = 'Terminal UI for both docker and docker-compose'

    },
    [pscustomobject]@{
      Command     = 'neofetch'
      Description = 'Simple, ultra-lightweight neofetch clone for Windows 10+'

    },
    [pscustomobject]@{
      Command     = 'walk'
      Description = 'a terminal navigator https://github.com/antonmedv/walk'

    },
    [pscustomobject]@{
      Command     = 'fz'
      Description = 'ZLocation through fzf'

    },
    [pscustomobject]@{
      Command     = 'fe'
      Description = 'fuzzy edit file'

    },
    [pscustomobject]@{
      Command     = 'fh'
      Description = 'fuzzy invoke command from history'

    },
    [pscustomobject]@{
      Command     = 'fkill'
      Description = 'fuzzy stop process'

    },
    [pscustomobject]@{
      Command     = 'fd'
      Description = 'find https://github.com/sharkdp/fd#how-to-use'

    },
    [pscustomobject]@{
      Command     = 'rg'
      Description = 'find in files https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md'

    },
    [pscustomobject]@{
      Command     = 'frg'
      Description = 'rg with fzf'

    }
  )

  Write-Output $tips | Format-Table
}

New-Alias -Scope Global -Name tips -Value Get-Tips

# Lazy load PSFzf functions
function Initialize-FzfFunctions {
    # Remove proxy functions
    Remove-Item -Path Function:\fcd -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\fe -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\fh -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\fkill -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\fz -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\frg -ErrorAction SilentlyContinue

    # Import PSFzf module on-demand and apply its options
    if (-not (Get-Module -Name PSFzf)) {
        Import-Module PSFzf -ErrorAction SilentlyContinue
    }
    if (Get-Command -Name Set-PsFzfOption -ErrorAction SilentlyContinue) {
        Initialize-PsFzfOptions
    }


    # Define real aliases
    New-Alias -Scope Global -Name fcd -Value Invoke-FuzzySetLocation2 -ErrorAction Ignore
    New-Alias -Scope Global -Name fe -Value Invoke-FuzzyEdit -ErrorAction Ignore
    New-Alias -Scope Global -Name fh -Value Invoke-FuzzyHistory -ErrorAction Ignore
    New-Alias -Scope Global -Name fkill -Value Invoke-FuzzyKillProcess -ErrorAction Ignore
    New-Alias -Scope Global -Name fz -Value Invoke-FuzzyZLocation -ErrorAction Ignore
    New-Alias -Scope Global -Name frg -Value Invoke-PsFzfRipgrep -ErrorAction Ignore
}

New-Alias -Scope Global -Name grep -Value Select-String

# Helper function to find and add executables to PATH
function Add-ToPathIfFound {
    param([string]$ExeName, [string[]]$SearchPaths)
    
    foreach ($path in $SearchPaths) {
        if (Test-Path $path) {
            $exe = Get-ChildItem $path -Recurse -Filter "$ExeName.exe" -ErrorAction SilentlyContinue -Depth 3 | Select-Object -First 1
            if ($exe) {
                $exeDir = $exe.DirectoryName
                if ($env:PATH -notlike "*$exeDir*") {
                    $env:PATH = "$exeDir;$env:PATH"
                }
                return $true
            }
        }
    }
    return $false
}

# Try to find and add external tools to PATH
$searchPaths = @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
    "$env:USERPROFILE\scoop\shims",
    "$env:ProgramFiles",
    "$env:ProgramFiles(x86)"
)

Add-ToPathIfFound -ExeName "fd" -SearchPaths $searchPaths | Out-Null
Add-ToPathIfFound -ExeName "rg" -SearchPaths $searchPaths | Out-Null
Add-ToPathIfFound -ExeName "bat" -SearchPaths $searchPaths | Out-Null
Add-ToPathIfFound -ExeName "walk" -SearchPaths $searchPaths | Out-Null

# Wrapper functions for external tools (fallback if not in PATH)
function Find-Executable {
    param([string]$Name)
    $exe = Get-Command $Name -ErrorAction SilentlyContinue
    if ($exe) { return $exe.Source }
    
    $searchPaths = @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
        "$env:USERPROFILE\scoop\shims",
        "$env:ProgramFiles",
        "$env:ProgramFiles(x86)"
    )
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $found = Get-ChildItem $path -Recurse -Filter "$Name.exe" -ErrorAction SilentlyContinue -Depth 4 | Select-Object -First 1
            if ($found) { return $found.FullName }
        }
    }
    return $null
}

# Create wrapper functions for external tools if they exist
$fdPath = Find-Executable "fd"
if ($fdPath -and -not (Get-Command fd -ErrorAction SilentlyContinue)) {
    function fd { & $fdPath $args }
}

$rgPath = Find-Executable "rg"
if ($rgPath -and -not (Get-Command rg -ErrorAction SilentlyContinue)) {
    function rg { & $rgPath $args }
}

$batPath = Find-Executable "bat"
if ($batPath -and -not (Get-Command bat -ErrorAction SilentlyContinue)) {
    function bat { & $batPath $args }
}

$walkPath = Find-Executable "walk"
if ($walkPath -and -not (Get-Command walk -ErrorAction SilentlyContinue)) {
    function walk { & $walkPath $args }
}

# Handle rd alias conflict - PowerShell has rd as alias for Remove-Item
# If you have a custom rd command, uncomment the lines below:
# $rdPath = Find-Executable "rd"
# if ($rdPath) {
#     Remove-Alias rd -ErrorAction SilentlyContinue -Force
#     function rd { & $rdPath $args }
# }

# Create proxy functions that will initialize PSFzf on first use
function fcd { 
    if (-not (Get-Module -Name PSFzf)) { Initialize-FzfFunctions }
    if (Get-Command -Name Invoke-FuzzySetLocation2 -ErrorAction SilentlyContinue) {
        Invoke-FuzzySetLocation2 @args
    }
}
function fe { 
    if (-not (Get-Module -Name PSFzf)) { Initialize-FzfFunctions }
    if (Get-Command -Name Invoke-FuzzyEdit -ErrorAction SilentlyContinue) {
        Invoke-FuzzyEdit @args
    }
}
function fh { 
    if (-not (Get-Module -Name PSFzf)) { Initialize-FzfFunctions }
    if (Get-Command -Name Invoke-FuzzyHistory -ErrorAction SilentlyContinue) {
        Invoke-FuzzyHistory @args
    }
}
function fkill { 
    if (-not (Get-Module -Name PSFzf)) { Initialize-FzfFunctions }
    if (Get-Command -Name Invoke-FuzzyKillProcess -ErrorAction SilentlyContinue) {
        Invoke-FuzzyKillProcess @args
    }
}
function fz { 
    if (-not (Get-Module -Name PSFzf)) { Initialize-FzfFunctions }
    if (Get-Command -Name Invoke-FuzzyZLocation -ErrorAction SilentlyContinue) {
        Invoke-FuzzyZLocation @args
    }
}
function frg { 
    if (-not (Get-Module -Name PSFzf)) { Initialize-FzfFunctions }
    if (Get-Command -Name Invoke-PsFzfRipgrep -ErrorAction SilentlyContinue) {
        if ($args.Count -eq 0) {
            $searchString = Read-Host "Enter search string"
            if ($searchString) {
                Invoke-PsFzfRipgrep -SearchString $searchString
            }
        } else {
            Invoke-PsFzfRipgrep -SearchString ($args -join ' ')
        }
    }
}
