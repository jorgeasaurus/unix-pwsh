
# Functions to mimic some of the functionality of the Unix shell
# Does the the rough equivalent of dir /s /b. For example, dirs *.png is dir /s /b *.png
function dirs {
    if ($args.Count -gt 0) {
        Get-ChildItem -Recurse -Include "$args" | ForEach-Object FullName
    } else {
        Get-ChildItem -Recurse | ForEach-Object FullName
    }
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    Set-Item -Force -Path "env:$name" -Value $value;
}

function pgrep($name) {
    Get-Process $name
}

function grep {
    param (
        [string]$regex,
        [string]$dir
    )
    process {
        if ($dir) {
            Get-ChildItem -Path $dir -Recurse -File | Select-String -Pattern $regex
        } else {
            # Use if piped input is provided
            $input | Select-String -Pattern $regex
        }
    }
}

function pkill {
    param (
        [string]$name
    )
    process {
        if ($name) {
            Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
        } else {
            $input | ForEach-Object { Get-Process $_ -ErrorAction SilentlyContinue | Stop-Process }
        }
    }
}

function head {
    param (
        [string]$Path,
        [int]$n = 10
    )
    process {
        if ($Path) {
            Get-Content $Path -Head $n
        } else {
            $input | Select-Object -First $n
        }
    }
}

function tail {
    param (
        [string]$Path,
        [int]$n = 10
    )
    process {
        if ($Path) {
            Get-Content $Path -Tail $n
        } else {
            $input | Select-Object -Last $n
        }
    }
}

# Unzip function
function unzip {
    param (
        [string]$file
    )
    process {
        $fullPath = Join-Path -Path $pwd -ChildPath $file
        if (Test-Path $fullPath) {
            Write-Output "Extracting $file to $pwd"
            Expand-Archive -Path $fullPath -DestinationPath $pwd
        } else {
            Write-Output "File $file does not exist in the current directory"
        }
    }
}

# Short ulities

Set-Alias ll Get-ChildItemColor -Option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope
function df { Get-Volume }

# Aliases for reboot and poweroff
function Reboot-System { Restart-Computer -Force }
Set-Alias reboot Reboot-System
function Poweroff-System { Stop-Computer -Force }
Set-Alias poweroff Poweroff-System

# Useful file-management functions
function cd... { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }

# Function to run a command or shell as admin.
function admin {
    if ($args.Count -gt 0) {
        $argList = "& '" + $args + "'"
        Start-Process "wt.exe" -Verb runAs -ArgumentList $argList
    } else {
        Start-Process "wt.exe" -Verb runAs
    }
}

# Display system uptime
function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        $lastBootUpTime = Get-WmiObject win32_operatingsystem | Select-Object @{Name = 'LastBootUpTime'; Expression = { $_.ConverttoDateTime($_.lastbootuptime) } }
        $uptime = (Get-Date) - $lastBootUpTime.LastBootUpTime
    } else {
        $since = net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
        $lastBootUpTime = [DateTime]::ParseExact($since, "M/d/yyyy h:mm:ss AM/PM", [Globalization.CultureInfo]::InvariantCulture)
        $uptime = (Get-Date) - $lastBootUpTime
    }
    return "Online since $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
}

function sys {
    Start-Process -FilePath cmd.exe -Verb Runas -ArgumentList '/k C:\Windows\System32\PsExec.exe -i -accepteula -s powershell.exe'
}
function Search-RegistryUninstallKey {
    param($SearchFor, [switch]$Wow6432Node)
    $results = @()
    $keys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ea 0 |
    ForEach-Object {
        class x64 {
            [string]$GUID
            [string]$Publisher
            [string]$DisplayName
            [string]$DisplayVersion
            [string]$InstallLocation
            [string]$InstallDate
            [string]$UninstallString
            [string]$Wow6432Node
        }
        $x64 = [x64]::new()
        $x64.GUID = $_.pschildname
        $x64.Publisher = $_.GetValue('Publisher')
        $x64.DisplayName = $_.GetValue('DisplayName')
        $x64.DisplayVersion = $_.GetValue('DisplayVersion')
        $x64.InstallLocation = $_.GetValue('InstallLocation')
        $x64.InstallDate = $_.GetValue('InstallDate')
        $x64.UninstallString = $_.GetValue('UninstallString')
        if ($Wow6432Node) {
            $x64.Wow6432Node = 'No'
        }
        $results += $x64
    }
    if ($Wow6432Node) {
        $keys = Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
        ForEach-Object {
            class x86 {
                [string]$GUID
                [string]$Publisher
                [string]$DisplayName
                [string]$DisplayVersion
                [string]$InstallLocation
                [string]$InstallDate
                [string]$UninstallString
                [string]$Wow6432Node
            }
            $x86 = [x86]::new()
            $x86.GUID = $_.pschildname
            $x86.Publisher = $_.GetValue('Publisher')
            $x86.DisplayName = $_.GetValue('DisplayName')
            $x86.DisplayVersion = $_.GetValue('DisplayVersion')
            $x86.InstallLocation = $_.GetValue('InstallLocation')
            $x86.InstallDate = $_.GetValue('InstallDate')
            $x86.UninstallString = $_.GetValue('UninstallString')
            $x86.Wow6432Node = 'Yes'
            $results += $x86
        }
    }
    $results | Sort-Object DisplayName | Where-Object { $_.DisplayName -match $SearchFor }
}
function reload-profile {
    & $profile.CurrentUserAllHosts
}
function Invoke-ModuleCleanup {
    Update-Module -Force
    Get-InstalledModule | ForEach-Object {
        $CurrentVersion = $PSItem.Version
        Get-InstalledModule -Name $PSItem.Name -AllVersions | Where-Object -Property Version -LT -Value $CurrentVersion
    } | Uninstall-Module -Verbose
}

function Invoke-Spongebob {
    [cmdletbinding()]
    param(
        [Parameter(HelpMessage = "provide string" , Mandatory = $true)]
        [string]$Message
    )
    $charArray = $Message.ToCharArray()

    foreach ($char in $charArray) {
        $Var = $(Get-Random) % 2
        if ($var -eq 0) {
            $string = $char.ToString()
            $Upper = $string.ToUpper()
            $output = $output + $Upper
        } else {
            $lower = $char.ToString()
            $output = $output + $lower
        }
    }
    $output
    $output = $null
}
function youtube {

    Begin {
        $query = 'https://www.youtube.com/results?search_query='
    }
    Process {
        Write-Host $args.Count, "Arguments detected"
        "Parsing out Arguments: $args"
        for ($i = 0; $i -le $args.Count; $i++) {
            $args | ForEach-Object { "Arg $i `t $_ `t Length `t" + $_.Length, " characters"; $i++ }
        }

        $args | ForEach-Object { $query = $query + "$_+" }
        $url = "$query"
    }
    End {
        $url.Substring(0, $url.Length - 1)
        "Final Search will be $url"
        "Invoking..."
        Start-Process "$url"
    }
}
function Google {

    Begin {
        $query = 'https://www.google.com/search?q='
    }
    Process {
        Write-Host $args.Count, "Arguments detected"
        "Parsing out Arguments: $args"
        for ($i = 0; $i -le $args.Count; $i++) {
            $args | ForEach-Object { "Arg $i `t $_ `t Length `t" + $_.Length, " characters"; $i++ }
        }

        $args | ForEach-Object { $query = $query + "$_+" }
        $url = "$query"
    }
    End {
        $url.Substring(0, $url.Length - 1)
        "Final Search will be $url"
        "Invoking..."
        Start-Process "$url"
    }
}
function Get-PSModuleUpdates {
    param
    (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [version]$Version,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Repository = 'PSGallery',

        [switch]$OutdatedOnly
    )

    process {
        try {
            $latestVersion = [version](Find-Module -Name $Name -Repository $Repository -ErrorAction Stop).Version
            $needsUpdate = $latestVersion -gt $Version
        } catch {
            Write-Warning "Error finding module $Name in repository $($Repository): $_"
            return
        }

        if ($needsUpdate -or -not $OutdatedOnly) {
            [PSCustomObject]@{
                ModuleName     = $Name
                CurrentVersion = $Version
                LatestVersion  = $latestVersion
                NeedsUpdate    = $needsUpdate
                Repository     = $Repository
            }
        }
    }
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

function Invoke-PsReadline {
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
    #endregion
}

function Update-Modules {
    param (
        [switch]$AllowPrerelease,
        [string]$Name = '*',
        [switch]$WhatIf,
        [int]$ThrottleLimit = 5
    )

    # Get all installed modules
    Write-Host ("Retrieving all installed modules ...") -ForegroundColor Green
    [array]$CurrentModules = Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue |
    Select-Object Name, Version, Repository |
    Sort-Object Name

    if (-not $CurrentModules) {
        Write-Host ("No modules found.") -ForegroundColor Gray
        return
    }

    Write-Host ("{0} modules found." -f $CurrentModules.Count) -ForegroundColor Gray
    Write-Host ("Updating installed modules to the latest {0} version ..." -f $(if ($AllowPrerelease) { "PreRelease" } else { "Production" })) -ForegroundColor Green

    # Create hashtable to store original versions
    $script:OldVersions = @{}
    foreach ($Module in $CurrentModules) {
        $script:OldVersions[$Module.Name] = $Module.Version
    }

    # Use parallel processing for updating modules
    $CurrentModules | ForEach-Object -Parallel {
        $Module = $_
        $AllowPrerelease = $using:AllowPrerelease
        $WhatIf = $using:WhatIf

        try {
            # Check the latest version online
            $findParams = @{
                Name            = $Module.Name
                AllowPrerelease = $AllowPrerelease
                ErrorAction     = 'Stop'
            }

            $latest = Find-Module @findParams | Select-Object -First 1

            if ($latest.Version -and $Module.Version -and ([version]$latest.Version -gt [version]$Module.Version)) {
                $updateParams = @{
                    Name            = $Module.Name
                    AllowPrerelease = $AllowPrerelease
                    AcceptLicense   = $true
                    Force           = $true
                    WhatIf          = $WhatIf
                    ErrorAction     = 'Stop'
                }

                Update-Module @updateParams
                Write-Host ("Updated {0} from version {1} to {2}" -f $Module.Name, $Module.Version, $latest.Version) -ForegroundColor Yellow

                # Cleanup old versions
                if (-not $WhatIf) {
                    $AllVersions = Get-InstalledModule -Name $Module.Name -AllVersions | Sort-Object PublishedDate -Descending
                    foreach ($Version in $AllVersions | Select-Object -Skip 1) {
                        try {
                            Uninstall-Module -Name $Module.Name -RequiredVersion $Version.Version -Force -ErrorAction Stop
                            Write-Host ("Uninstalled older version {0} of {1}" -f $Version.Version, $Module.Name) -ForegroundColor Gray
                        } catch {
                            Write-Warning ("Failed to uninstall version {0} of {1}: {2}" -f $Version.Version, $Module.Name, $_.Exception.Message)
                        }
                    }
                }
            } else {
                Write-Host ("{0} is up to date (version {1})" -f $Module.Name, $Module.Version) -ForegroundColor Cyan
            }
        } catch {
            Write-Warning ("{0}: {1}" -f $Module.Name, $_.Exception.Message)
        }
    } -ThrottleLimit $ThrottleLimit

    # Summary of updates
    if (-not $WhatIf) {
        $NewModules = Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue |
        Select-Object Name, Version |
        Sort-Object Name

        $UpdatedModules = $NewModules | Where-Object {
            $script:OldVersions[$_.Name] -ne $_.Version
        }

        if ($UpdatedModules) {
            Write-Host "`nUpdated modules:" -ForegroundColor Green
            foreach ($Module in $UpdatedModules) {
                Write-Host ("- {0}: {1} -> {2}" -f $Module.Name, $script:OldVersions[$Module.Name], $Module.Version) -ForegroundColor Green
            }
        } else {
            Write-Host "`nNo modules were updated." -ForegroundColor Gray
        }
    }
}