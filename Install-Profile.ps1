# install-profile.ps1
# Simplified platform detection and font installation
switch ([System.Environment]::OSVersion.Platform) {
    "Win32NT" { 
        # Elevation check
        $global:IsAdmin = [bool](([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
        
        if (!$IsAdmin) {
            Write-Host "⚠️ Elevating permissions..." -ForegroundColor Yellow
            Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
            Exit
        }

        # Single font installation function
        function Install-Font {
            param($FontPath)
            try {
                $destination = Join-Path $env:windir "Fonts"
                $fontName = [System.IO.Path]::GetFileName($FontPath)
                Copy-Item $FontPath $destination
                New-ItemProperty -Name $fontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $fontName -ErrorAction Stop
                Write-Host "✅ Installed font: $fontName" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to install font: $fontName" -ForegroundColor Red
                Write-Error $_
            }
        }

        # Install fonts
        Get-ChildItem -Path $PSScriptRoot -Include ('*.fon', '*.otf', '*.ttc', '*.ttf') -Recurse | ForEach-Object {
            Install-Font $_.FullName
        }

        # Windows Terminal settings
        $terminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
        if (Test-Path "$terminalDir") {
            Copy-Item "$PSScriptRoot\settings.json" "$terminalDir\settings.json" -Force
        }
    }
    "Unix" {
        # Mac specific setup
        $global:IsAdmin = $false
        if (-not(Get-Command brew -ErrorAction SilentlyContinue)) {
            Write-Host "❌ Homebrew required. Install with:" -ForegroundColor Red
            Write-Host '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' -ForegroundColor Yellow
            return
        }
        
        # Initialize Homebrew
        $(/opt/homebrew/bin/brew shellenv) | Invoke-Expression
        
        # Install oh-my-posh if missing
        if (-not(Test-Path "/opt/homebrew/bin/oh-my-posh")) {
            brew install jandedobbeleer/oh-my-posh/oh-my-posh
        }
    }
}

# Profile setup
$ErrorActionPreference = 'Stop'

# Create profile files if missing
@($profile.CurrentUserAllHosts, $profile.CurrentUserCurrentHost) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item $_ -ItemType File -Force
    }
}

# Install required modules
$modules = @(
    @{Name = "PowerShellGet"; AllowPrerelease = $false },
    @{Name = "PSReadLine"; AllowPrerelease = $true },
    @{Name = "WindowsConsoleFonts"; AllowPrerelease = $false }
)

foreach ($module in $modules) {
    try {
        Install-Module @module -Scope CurrentUser -Force -SkipPublisherCheck
    } catch {
        Write-Warning "Failed to install $($module.Name): $_"
    }
}

# Copy profile and reload
Copy-Item $PSScriptRoot\Microsoft.PowerShell_profile.ps1 $PROFILE.CurrentUserAllHosts -Force
. $PROFILE.CurrentUserAllHosts