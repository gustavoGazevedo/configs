# Remove commented out lines that are not being used
# Removing:
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/kali.omp.json" | Invoke-Expression
# Invoke-Expression (& { (zoxide init powershell | Out-String) })

# To make ZLocation module work in every PowerShell instance.
# Replace direct ZLocation import with lazy-loading function
function z {
    param($location)
    
    # Remove the proxy function and load the real module
    Remove-Item -Path Alias:\z -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\z -ErrorAction SilentlyContinue
    
    # Import ZLocation
    Import-Module ZLocation
    
    # Call ZLocation with the provided argument
    if ($location) {
        Invoke-Expression "z $location"
    } else {
        Write-Output "ZLocation loaded. Use 'z <location>' to jump to frequently used directories."
    }
}

# Defer PowerType/PSReadLine configuration to idle so startup is not blocked
# (see one-time OnIdle hook at end of file)

function Initialize-PSReadLineOptions {
    # Remove the proxy function
    Remove-Item -Path Function:\Set-PSReadLineOptionsInitial -ErrorAction SilentlyContinue
    
    # Set actual options
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
    Set-PSReadLineOption -MaximumHistoryCount 1000
}

# Create proxy function (kept for compatibility, but do not call at startup)
function Set-PSReadLineOptionsInitial { Initialize-PSReadLineOptions }

# PSFzf has undocumented option to use fd executable for
# file and directory searching. This enables that option.
# Initialize PSFzf options on first use (configured inside Initialize-FzfFunctions)


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

# Lazy load PSFzf functions
function Initialize-FzfFunctions {
    # Remove proxy functions
    Remove-Item -Path Function:\fcd -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\fe -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\fh -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\fkill -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\fz -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\frg -ErrorAction SilentlyContinue

    # Configure PSFzf and keybindings now (first actual use of any fzf function)
    try { Import-Module PSReadLine -ErrorAction SilentlyContinue } catch {}
    Set-PsFzfOption -EnableFd:$true
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PsFzfOption -TabExpansion


    # Define real aliases
    New-Alias -Scope Global -Name fcd -Value Invoke-FuzzySetLocation2 -ErrorAction Ignore
    New-Alias -Scope Global -Name fe -Value Invoke-FuzzyEdit -ErrorAction Ignore
    New-Alias -Scope Global -Name fh -Value Invoke-FuzzyHistory -ErrorAction Ignore
    New-Alias -Scope Global -Name fkill -Value Invoke-FuzzyKillProcess -ErrorAction Ignore
    New-Alias -Scope Global -Name fz -Value Invoke-FuzzyZLocation -ErrorAction Ignore
    New-Alias -Scope Global -Name frg -Value Invoke-PsFzfRipgrep -ErrorAction Ignore
}

New-Alias -Scope Global -Name grep -Value Select-String

# Create proxy functions that will initialize PSFzf on first use
function fcd { Initialize-FzfFunctions; fcd @args }
function fe { Initialize-FzfFunctions; fe @args }
function fh { Initialize-FzfFunctions; fh @args }
function fkill { Initialize-FzfFunctions; fkill @args }
function fz { Initialize-FzfFunctions; fz @args }
function frg { Initialize-FzfFunctions; frg @args }

# One-time idle initializer to finish background configuration without delaying startup
if (-not $global:__ProfileIdleInitRegistered) {
    $global:__ProfileIdleInitRegistered = $true
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -Action {
        try {
            if (-not $global:__PSReadLineConfigured) {
                try {
                    Import-Module PSReadLine -ErrorAction SilentlyContinue
                } catch {}
                Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView -ErrorAction SilentlyContinue
                Set-PSReadLineOption -MaximumHistoryCount 1000 -ErrorAction SilentlyContinue
                $global:__PSReadLineConfigured = $true
            }

            if (-not $global:__PowerTypeEnabled) {
                if (Get-Command Enable-PowerType -ErrorAction SilentlyContinue) {
                    try { Enable-PowerType | Out-Null } catch {}
                }
                $global:__PowerTypeEnabled = $true
            }
        } catch {}
        Unregister-Event -SourceIdentifier PowerShell.OnIdle -ErrorAction SilentlyContinue
    } | Out-Null
}
