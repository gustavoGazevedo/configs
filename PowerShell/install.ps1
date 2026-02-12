if (-not (Get-Module -ListAvailable -Name z)) {
    try {
        Install-Module z -Scope CurrentUser -Force -AllowClobber
    } catch {
        Write-Warning "Could not install z module: $_"
    }
}
