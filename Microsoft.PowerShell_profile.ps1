# Check Internet and exit if it takes longer than 1 second
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1
$configPath = "$HOME\pwsh_custom_config.json"
$githubUser = "jorgeasaurus"
$name = "Jorge"
$OhMyPoshConfig = "/opt/homebrew/opt/oh-my-posh/themes/powerlevel10k_rainbow.omp.json"
$font = "CascadiaCode"
$font_url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip"
$font_folder = "CascadiaCode"
$fontFileName = "CaskaydiaCoveNerdFont-Regular.ttf"
$UserProfile = $HOME
Set-Variable -Name Onedrive -Value "$UserProfile\OneDrive" -Scope global

function Initialize-DevEnv {
    if (-not $global:canConnectToGitHub) {
        Write-Host "❌ Skipping dev-environment initialization due to GitHub.com not responding within 1 second." -ForegroundColor Red
        return
    }

    if ($ohmyposh_installed -ne "True") {
        Write-Host "⚡ Invoking Helper-Script" -ForegroundColor Yellow
        . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/unix-pwsh/main/pwsh_helper.ps1" -UseBasicParsing).Content
        Test-ohmyposh
    }
    $font_installed_var = "${font}_installed"
    if (((Get-Variable -Name $font_installed_var).Value) -ne "True") {
        Write-Host "⚡ Invoking Helper-Script" -ForegroundColor Yellow
        . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/unix-pwsh/main/pwsh_helper.ps1" -UseBasicParsing).Content
        Test-$font
    }

    Write-Host "✅ Successfully initialized Pwsh with all modules and applications`n" -ForegroundColor Green
}

# Function to create config file and install modules
function Install-Config {
    param (
        [string]$configPath = "$HOME\pwsh_custom_config.json",
        [switch]$Force
    )

    try {
        # Ensure config directory exists
        $configDir = Split-Path -Parent $configPath
        if (-not (Test-Path -Path $configDir)) {
            Write-Host "Creating config directory at $configDir" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path "$HOME/.pwsh" -Force | Out-Null
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }

        # Create or load config file
        if (-not (Test-Path -Path $configPath) -or $Force) {
            Write-Host "Creating config file at $configPath" -ForegroundColor Yellow
            New-Item -ItemType File -Path $configPath -Force | Out-Null
            Write-Host "Configuration file created at $configPath ❗" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Loading existing config file" -ForegroundColor Green
        }

        # Initialize config keys if needed
        Initialize-Keys

        # Define required modules with versions
        $modules = @(
            @{
                Name       = "Terminal-Icons"
                ConfigKey  = "Terminal-Icons_installed"
                MinVersion = "0.9.0"
            },
            @{
                Name       = "Get-ChildItemColor"
                ConfigKey  = "Get-ChildItemColor_installed"
                MinVersion = "1.2.0"
            }
        )

        $importedModuleCount = 0
        foreach ($module in $modules) {
            try {



                Write-Host "Installing $($module.Name) module..." -ForegroundColor Yellow
                Install-Module -Name $module.Name -Scope CurrentUser -MinimumVersion $module.MinVersion -Force


                # Import module and verify

                Import-Module $module.Name -MinimumVersion $module.MinVersion -ErrorAction Stop
                $importedModuleCount++

            } catch {
                Write-Warning "Failed to process module $($module.Name): $_"
            }
        }

        Write-Host "✅ Imported $importedModuleCount of $($modules.Count) modules successfully." -ForegroundColor Green

    } catch {
        Write-Error "Failed to configure PowerShell environment: $_"
        return $false
    }


    #return $true
}

# -------------
# Run section

Write-Host ""
Write-Host "Welcome $name ⚡" -ForegroundColor DarkCyan
Write-Host ""
#All Colors: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, Red, White, Yellow.


Install-Config

. Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/unix-pwsh/main/functions.ps1" -UseBasicParsing).Content

# ----------------------------------------------------------
# Deferred loading
# ----------------------------------------------------------

$Deferred = {
    # Create profile if not exists
    if (-not (Test-Path -Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE | Out-Null
        Add-Content -Path $PROFILE -Value "iex (iwr `https://raw.githubusercontent.com/$githubUser/unix-pwshs/main/Microsoft.PowerShell_profile.ps1`).Content"
        Write-Host "PowerShell profile created at $PROFILE." -ForegroundColor Yellow
    }

    # Update PowerShell in the background
    Start-Job -ScriptBlock {
        Write-Host "⚡ Invoking Helper-Script" -ForegroundColor Yellow
        . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/unix-pwsh/main/pwsh_helper.ps1" -UseBasicParsing).Content
        Update-PowerShell
    } > $null 2>&1
}

$Tab = '  '

# Set PowerShell Telemetry OptOut
$env:POWERSHELL_TELEMETRY_OPTOUT = $true

#region Setting Variables Based on Platform
if ($PSVersionTable.PSVersion.Major -lt 6) {
    $WindowsPowerShell = $true
}

switch ([System.Environment]::OSVersion.Platform) {
    "Win32NT" {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            Write-Host "✅ PowerShell on Windows - PSVersion $($PSVersionTable.PSVersion)" -ForegroundColor Green
        } else {
            Write-Host "✅ Windows PowerShell - PSVersion $($PSVersionTable.PSVersion)" -ForegroundColor Green
        }

        $global:IsAdmin = [bool](([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))

        # Try to import MS PowerToys WinGetCommandNotFound
        Import-Module -Name Microsoft.WinGet.CommandNotFound > $null 2>&1
        if (-not $?) { Write-Host "💭 Make sure to install WingetCommandNotFound by MS PowerToys" -ForegroundColor Yellow }

        $OhMyPoshCommand = (Get-Command -Name 'oh-my-posh.exe' -ea 0).Source
        if (($env:TERM_PROGRAM -ne 'vscode') -and $global:IsAdmin) {
            winget upgrade --all
        }

        Initialize-DevEnv

        $PSReadLineHistoryFile = [System.IO.Path]::Combine($Onedrive, 'PSReadLine', 'PSReadLineHistory.txt')

    }
    "Unix" {
        Write-Host "✅ PowerShell on Mac - PSVersion $($PSVersionTable.PSVersion)" -ForegroundColor Green
        $global:IsAdmin = $false
        $PSReadLineHistoryFile = "$Onedrive/PSReadLine/PSReadLineHistory.txt"
        $OhMyPoshCommand = "/opt/homebrew/bin/oh-my-posh"
        $BrewCommand = "/opt/homebrew/bin/brew"
        if (-not(Test-Path $BrewCommand)) {
            Write-Host "❌ Please install HomeBrew via a bash terminal" -ForegroundColor Red
            Write-Host "Use the following command:" -ForegroundColor Red
            Write-Host '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' -ForegroundColor Yellow
            Write-Host "ReOpen Pwsh afterwards" -ForegroundColor Yellow
            return
        } else {
            # add Homebrew
            $(/opt/homebrew/bin/brew shellenv) | Invoke-Expression
        }
        if (-not(Test-Path $OhMyPoshCommand)) {
            brew install jandedobbeleer/oh-my-posh/oh-my-posh
        }
        & $OhMyPoshCommand --init | Invoke-Expression
        Invoke-PsReadline
    }
    Default {}
}