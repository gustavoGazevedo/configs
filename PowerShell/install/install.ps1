#Requires -RunAsAdministrator
param(
    [switch]$Winget,
    [switch]$Choco,
    [switch]$Npm,
    [switch]$Pip,
    [switch]$Pipx,
    [switch]$Misc,
    [switch]$All
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$miscDir = Split-Path -Parent $scriptDir

function Install-Winget {
    $packages = @(
        "7zip.7zip",
        "Git.Git",
        "Microsoft.PowerShell",
        "Microsoft.WindowsTerminal",
        "Microsoft.VisualStudioCode",
        "BurntSushi.ripgrep.MSVC",
        "sharkdp.bat",
        "sharkdp.fd",
        "junegunn.fzf",
        "ajeetdsouza.zoxide",
        "gerardog.gsudo",
        "GitHub.cli",
        "Python.Python.3.10",
        "Microsoft.DotNet.SDK.8",
        "Docker.DockerDesktop",
        "Microsoft.WSL",
        "voidtools.Everything",
        "Obsidian.Obsidian",
        "Notepad++.Notepad++",
        "VideoLAN.VLC",
        "qBittorrent.qBittorrent"
    )
    foreach ($id in $packages) {
        winget install --id $id --accept-package-agreements --accept-source-agreements
    }
}

function Install-Choco {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1"))
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
    $packages = @(
        "autohotkey",
        "eartrumpet",
        "gallery-dl",
        "lazygit",
        "make",
        "mingw",
        "nmap",
        "speedtest-by-ookla",
        "volume2"
    )
    foreach ($pkg in $packages) {
        choco install $pkg -y
    }
}

function Install-Npm {
    $packages = @("@google/clasp", "corepack")
    foreach ($pkg in $packages) {
        npm install -g $pkg
    }
}

function Install-Pip {
    $reqPath = Join-Path $scriptDir "requirements.txt"
    if (Test-Path $reqPath) {
        pip install -r $reqPath
    }
}

function Install-Pipx {
    pipx install argcomplete
    pipx install internetarchive
}

function Install-Misc {
    $pkgPath = Join-Path $miscDir "package.json"
    if (-not (Test-Path $pkgPath)) {
        @{
            name = "miscellaneous"
            private = $true
            dependencies = @{
                puppeteer = "^23.0.0"
                clipboardy = "^4.0.0"
            }
        } | ConvertTo-Json -Depth 5 | Set-Content $pkgPath -Encoding utf8
    }
    Push-Location $miscDir
    try {
        npm install
    } finally {
        Pop-Location
    }
}

if ($All -or (-not ($Winget -or $Choco -or $Npm -or $Pip -or $Pipx -or $Misc))) {
    $Winget = $Choco = $Npm = $Pip = $Pipx = $Misc = $true
}

if ($Winget) { Install-Winget }
if ($Choco) { Install-Choco }
if ($Npm) { Install-Npm }
if ($Pip) { Install-Pip }
if ($Pipx) { Install-Pipx }
if ($Misc) { Install-Misc }
