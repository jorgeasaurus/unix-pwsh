# Check Internet and exit if it takes longer than 1 second
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1
$configPath = "$HOME\pwsh_custom_config.yml"
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
        [string]$configPath = "$HOME/.pwsh/config.yaml",
        [switch]$Force
    )
    
    try {
        # Ensure config directory exists
        $configDir = Split-Path -Parent $configPath
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path "$HOME/.pwsh" -Force | Out-Null
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }

        # Create or load config file
        if (-not (Test-Path -Path $configPath) -or $Force) {
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
                Name       = "Powershell-Yaml"
                ConfigKey  = "Powershell-Yaml_installed"
                MinVersion = "0.4.2"
            },
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
                $isInstalled = Get-ConfigValue -Key $module.ConfigKey
                if ($isInstalled -ne "True") {
                    Write-Host "Installing $($module.Name) module..." -ForegroundColor Yellow
                    Install-Module -Name $module.Name -Scope CurrentUser -MinimumVersion $module.MinVersion -Force
                    Set-ConfigValue -Key $module.ConfigKey -Value "True"
                }
                
                # Import module and verify
                Import-Module $module.Name -MinimumVersion $module.MinVersion -ErrorAction Stop
                $importedModuleCount++
                
            } catch {
                Write-Warning "Failed to process module $($module.Name): $_"
                Set-ConfigValue -Key $module.ConfigKey -Value "False"
            }
        }

        Write-Host "✅ Imported $importedModuleCount of $($modules.Count) modules successfully." -ForegroundColor Green

    } catch {
        Write-Error "Failed to configure PowerShell environment: $_"
        return $false
    }
    
    #return $true
}

# Function to set a value in the config file
function Set-ConfigValue {
    param (
        [string]$Key,
        [string]$Value
    )
    $config = @{}
    # Try to load the existing config file content
    if (Test-Path -Path $configPath) {
        $content = Get-Content $configPath -Raw
        if (-not [string]::IsNullOrEmpty($content)) {
            $config = $content | ConvertFrom-Yaml
        }
    }
    # Ensure $config is a hashtable
    if (-not $config) {
        $config = @{}
    }
    $config[$Key] = $Value
    $config | ConvertTo-Yaml | Set-Content $configPath
    # Write-Host "Set '$Key' to '$Value' in configuration file." -ForegroundColor Green
    Initialize-Keys
}

# Function to get a value from the config file
function Get-ConfigValue {
    param (
        [string]$Key
    )
    $config = @{}
    # Try to load the existing config file content
    if (Test-Path -Path $configPath) {
        $content = Get-Content $configPath -Raw
        if (-not [string]::IsNullOrEmpty($content)) {
            $config = $content | ConvertFrom-Yaml
        }
    }
    # Ensure $config is a hashtable
    if (-not $config) {
        $config = @{}
    }
    return $config[$Key]
}

function Initialize-Module {
    param (
        [string]$moduleName
    )
    if ($global:canConnectToGitHub) {
        try {
            Install-Module -Name $moduleName -Scope CurrentUser -SkipPublisherCheck
            Set-ConfigValue -Key "${moduleName}_installed" -Value "True"
        } catch {
            Write-Error "❌ Failed to install module ${moduleName}: $_"
        }
    } else {
        Write-Host "❌ Skipping Module initialization check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
    }
}

function Initialize-Keys {
    $keys = "Terminal-Icons_installed", "Powershell-Yaml_installed", "PoshFunctions_installed", "Get-ChildItemColor_installed", "${font}_installed", "ohmyposh_installed"
    foreach ($key in $keys) {
        $value = Get-ConfigValue -Key $key
        Set-Variable -Name $key -Value $value -Scope Global
    }
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
    }
    Default {}
}

#region PSReadLine
''
'PSReadLine:'

$PSReadLineHistoryPath = Split-Path -Path $PSReadLineHistoryFile -Parent -ErrorAction SilentlyContinue
if (-Not ($PSReadLineHistoryPath)) {
    '{0}Creating PSReadLine history path: {1}' -f $Tab, $PSReadLineHistoryPath
    try {
        New-Item -Path $PSReadLineHistoryPath -ItemType Directory -Force
    } catch {
        '{0}Failed to create PSReadLine history path. Error: {1}' -f $Tab, $_
    }
}

Set-PSReadLineKeyHandler -Key Escape -Function RevertLine
Set-PSReadLineKeyHandler -Function MenuComplete -Chord 'Ctrl+@'
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -ShowToolTips -BellStyle Visual
Set-PSReadLineOption -Colors @{
    Comment  = [consolecolor]::DarkBlue
    Operator = [consolecolor]::DarkBlue
    String   = [consolecolor]::DarkMagenta
}
$PSReadLineOptions = @{
    HistoryNoDuplicates = $true
    HistorySaveStyle    = 'SaveIncrementally'
    HistorySavePath     = $PSReadLineHistoryFile
}
try {
    if ($PSVersionTable.PSEdition -eq 'Core') {
        $PSReadLineOptions.Add('PredictionSource', 'History')
        $PSReadLineOptions.Add('PredictionViewStyle', 'ListView')
        $PSReadLineOptions.Add('EditMode', 'Windows')

    }
    Set-PSReadLineOption @PSReadLineOptions
    '{0}Set PSReadLine options.' -f $Tab
} catch {
    'Failed to set PSReadLine options. Error: {0}' -f $_
}

function reload-profile {
    & $profile
}
function Invoke-ModuleCleanup {
    $Modules = Get-InstalledModule | Sort-Object Name | Get-PSModuleUpdates -OutdatedOnly
    if ($Modules) {
        Write-Output "Modules need updating."
        Write-Output "Running 'Invoke-ModuleCleanup'"
        $Modules | Format-Table
        Update-Module -Force
        Get-InstalledModule | ForEach-Object {
            $CurrentVersion = $PSItem.Version
            Get-InstalledModule -Name $PSItem.Name -AllVersions | Where-Object -Property Version -LT -Value $CurrentVersion
        } | Uninstall-Module -Verbose
    }
}

# Inject OhMyPosh
if (Test-Path $OhMyPoshCommand) {
    $OhMyPoshVersion = (&"$OhMyPoshCommand" version)
    '{0}Oh My Posh version {1} is installed. Loading custom theme.' -f $Tab, $OhMyPoshVersion
        (@(&"$OhMyPoshCommand" init pwsh --config="$OhMyPoshConfig" --print) -join [System.Environment]::NewLine) | Invoke-Expression
} else {
    '{0}Oh My Posh configuration file ({1}) not found. Not loading Oh My Posh.' -f $Tab, $OhMyPoshConfig | Write-Warning
}





#endregion