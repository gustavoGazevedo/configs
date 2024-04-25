# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as an administrator."
    exit 1
}

# Check if Winget is installed, if not, install it
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Output "Winget is not installed. Installing Winget..."
    Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
    Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
    Write-Output "Winget installed successfully."
}

# List of packages to install with Winget
$wingetPackages = @(
    'neovim',
    'powertoys',
    'sharkdp.fd',
    'winget-store',
    'RevoUninstaller',
    'junegunn.fzf',
    'JesseDuffield.lazygit',
    'JesseDuffield.lazydocker',
    'BurntSushi.ripgrep.MSVC',
    'tldr-pages.tlrc',
    'sharkdp.bat',
    'JanDeDobbeleer.OhMyPosh',
    'antonmedv.walk',
    'nepnep.neofetch-win',
    'Microsoft.PowerToys'
)

# Install each package using Winget
foreach ($pkg in $wingetPackages) {
    if (-not (Get-Package -Name $pkg -ErrorAction SilentlyContinue)) {
        Write-Output "Installing $pkg..."
        winget install $pkg -e
    } else {
        Write-Output "$pkg is already installed."
    }
}

# Check if Windows version is 10 and install additional package with Winget
$winver = [System.Environment]::OSVersion.Version
if ($winver.Major -eq 10) {
    Write-Output "Windows 10 detected. Installing additional package..."
    winget install gerardog.gsudo -e
}

# Install required PowerShell modules
$requiredModules = @(
    'PSFzf',
    'ZLocation',
    'PSReadLine',
    'PowerType'
)

foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module -ListAvailable -ErrorAction SilentlyContinue)) {
        Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber
    } else {
        Write-Output "$module is already installed."
    }
}


# Check if Chocolatey is installed, if not, install it
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
	Write-Output "Chocolatey is not installed. Installing Chocolatey..."
		Set-ExecutionPolicy Bypass -Scope Process -Force
		iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
		Write-Output "Chocolatey installed successfully."

} 

# Check if Mingw and Make are installed, if not, install with Chocolatey
if (-not (Get-Package -Name mingw -ErrorAction SilentlyContinue) -or -not (Get-Package -Name make -ErrorAction SilentlyContinue)) {
	Write-Output "Mingw and/or Make are not installed. Installing Mingw and Make with Chocolatey..."
		choco install mingw make -y
		Write-Output "Mingw and Make installed successfully."
} else {
	Write-Output "Mingw and Make are already installed. Skipping installation."
}

Write-Output "All packages and tools installed successfully."

