If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
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

Copy-Item $PSScriptRoot\PS_Profile.ps1 $PROFILE.CurrentUserAllHosts -Force

$FontList = Get-ChildItem -Path $PSScriptRoot -Include ('*.fon', '*.otf', '*.ttc', '*.ttf') -Recurse

foreach ($Font in $FontList) {

    Write-Host 'Installing font -' $Font.BaseName

    Copy-Item $Font "C:\Windows\Fonts"

    #register font for all users

    New-ItemProperty -Name $Font.BaseName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $Font.name -ErrorAction 0

}

if (Test-Path "$HOME\OneDrive") {
    Copy-Item "$PSScriptRoot\MS.png" "$HOME\OneDrive\Documents\PowerShell\MS.png" -Force
} else {
    Copy-Item "$PSScriptRoot\MS.png" "C:\Code\PowerShell\MS.png" -Force
}

$terminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe"
if (Test-Path $terminalDir) {
    Copy-Item "$PSScriptRoot\settings.json" "$terminalDir\LocalState\settings.json" -Force
}

Install-Module PowerShellGet -Force
Update-Module PowerShellGet -Force
Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck

Install-Module WindowsConsoleFonts -Force
Set-ConsoleFont -Name "Cascadia Code NF"

. $PROFILE.CurrentUserAllHosts