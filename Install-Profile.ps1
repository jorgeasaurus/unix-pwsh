switch ([System.Environment]::OSVersion.Platform) {
    "Win32NT" { 
        if ($PSVersionTable.PSEdition -eq 'Core') {
            'PowerShell on Windows - PSVersion {0}' -f $PSVersionTable.PSVersion
        } else {
            'Windows PowerShell - PSVersion {0}' -f $PSVersionTable.PSVersion
        }
    
        $global:IsAdmin = [bool](([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
        If (!$IsAdmin) {
            Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
            Start-Sleep 1
            Write-Host "                                               3"
            Start-Sleep 1
            Write-Host "                                               2"
            Start-Sleep 1
            Write-Host "                                               1"
            Start-Sleep 1
            Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -WhitelistApps {1}" -f $PSCommandPath, ($WhitelistApps -join ',')) -Verb RunAs
            Exit
        }

    
    }
    "Unix" {
        'PowerShell on Mac - PSVersion {0}' -f $PSVersionTable.PSVersion
        $global:IsAdmin = $false
        $PSReadLineHistoryFile = "$Onedrive/PSReadLine/PSReadLineHistory.txt"
        $OhMyPoshCommand = "/opt/homebrew/bin/oh-my-posh"
        if (-not(Get-Command brew)) {
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


#no errors throughout
$ErrorActionPreference = 'silentlycontinue'

$profile.AllUsersAllHosts,
$profile.AllUsersCurrentHost,
$profile.CurrentUserAllHosts,
$profile.CurrentUserCurrentHost | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item $_ -ItemType File -Force
    }
}

Copy-Item $PSScriptRoot\Microsoft.PowerShell_profile.ps1 $PROFILE.CurrentUserAllHosts -Force

$FontList = Get-ChildItem -Path $PSScriptRoot -Include ('*.fon', '*.otf', '*.ttc', '*.ttf') -Recurse

foreach ($Font in $FontList) {

    Write-Host 'Installing font -' $Font.BaseName

    Copy-Item $Font "C:\Windows\Fonts"

    #register font for all users

    New-ItemProperty -Name $Font.BaseName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $Font.name -ErrorAction 0

}


$terminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe"
if (Test-Path $terminalDir) {
    Copy-Item "$PSScriptRoot\settings.json" "$terminalDir\LocalState\settings.json" -Force
}

Install-Module PowerShellGet -Force
Update-Module PowerShellGet -Force -ErrorAction 0
Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck

Install-Module WindowsConsoleFonts -Force
Set-ConsoleFont -Name "Cascadia Code NF"

. $PROFILE.CurrentUserAllHosts