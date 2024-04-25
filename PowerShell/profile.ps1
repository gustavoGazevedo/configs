# To make ZLocation module work in every PowerShell instance.
Import-Module ZLocation

Import-Module PSReadLine
Enable-PowerType
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView

# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/kali.omp.json" | Invoke-Expression


# PSFzf has undocumented option to use fd executable for
# file and directory searching. This enables that option.
Set-PsFzfOption -EnableFd:$true
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -TabExpansion

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

  try {

    # Color output from fd to fzf if running in Windows Terminal
    $script:RunningInWindowsTerminal = [bool]($env:WT_Session)
    if ($script:RunningInWindowsTerminal) {
      $script:DefaultFileSystemFdCmd = "fd.exe --color always . {0}"    
    }
    else {
      $script:DefaultFileSystemFdCmd = "fd.exe . {0}"   
    }

    # Wrap $Directory in quotes if there is space (to be passed in fd)
    if ($Directory.Contains(' ')) {
      $strDir = """$Directory""" 
    }
    else {
      $strDir = $Directory
    }

    # Call fd to get directory list and pass to fzf
    Invoke-Expression (($script:DefaultFileSystemFdCmd -f '--type directory {0} --max-depth 1') -f $strDir) | Invoke-Fzf | ForEach-Object { $result = $_ }
  }
  catch {

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
      Description = 'ZLocation'

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

    }
    [pscustomobject]@{
      Command     = 'frg'
      Description = 'rg with fzf'

    }
  )

  Write-Output $tips | Format-Table
}

# Define aliases to call fuzzy methods from PSFzf
New-Alias -Scope Global -Name fcd -Value Invoke-FuzzySetLocation2 -ErrorAction Ignore
New-Alias -Scope Global -Name fe -Value Invoke-FuzzyEdit -ErrorAction Ignore
New-Alias -Scope Global -Name fh -Value Invoke-FuzzyHistory -ErrorAction Ignore
New-Alias -Scope Global -Name fkill -Value Invoke-FuzzyKillProcess -ErrorAction Ignore
New-Alias -Scope Global -Name fz -Value Invoke-FuzzyZLocation -ErrorAction Ignore
New-Alias -Scope Global -Name frg -Value Invoke-PsFzfRipgrep -ErrorAction Ignore
New-Alias -Scope Global -Name vim -Value nvim -ErrorAction Ignore
New-Alias -Scope Global -Name grep -Value findstr -ErrorAction Ignore

# Invoke-Expression (& { (zoxide init powershell | Out-String) })
