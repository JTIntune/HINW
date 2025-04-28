<# 
.SYNOPSIS
Intune Windows Update Patching Remediation Scrip >

.DESCRIPTION
Intune Windows Update Patching Remediation Scrip >

.Demo
YouTube video link--> https://www.youtube.com/@ChanderManiPandey

.OUTPUTS
Script will install latest Security Update >

.Log Location 
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Intune_Patching_Compliance_Log_Current_Date

.NOTES
 Version:         1.1
 Author:          Chander Mani Pandey
 Creation Date:   18 April 2025
 Find the author on:  
 YouTube:    https://www.youtube.com/@chandermanipandey8763  
 Twitter:    https://twitter.com/Mani_CMPandey  
 LinkedIn:   https://www.linkedin.com/in/chandermanipandey  
 BlueSky:    https://bsky.app/profile/chandermanipandey.bsky.social
 GitHub:     https://github.com/ChanderManiPandey2022
#>

$error.clear() ## this is the clear error history 
clear
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' ﻿
$ErrorActionPreference = 'SilentlyContinue'


# Initialize Logging
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Intune_Patching_Compliance.log"         
Function Write-Log {
    Param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $LogPath  -Append
}
Write-Log "====================== Running Intune Patching Remediation Script $(Get-Date -Format 'yyyy/MM/dd') ==================="

$HostName = hostname
# Check if ESP is running
$ESP = Get-Process -ProcessName CloudExperienceHostBroker -ErrorAction SilentlyContinue
If ($ESP) {
    #Write-Host "Windows Autopilot ESP Running"
    Write-Log "Windows Autopilot ESP Running"
    Exit 1 
     }
Else {
    #Write-Host "Windows Autopilot ESP Not Running"
    Write-Log "Windows Autopilot ESP Not Running"
    
     }

Write-Log "Checking Machine :- $HostName OS Version"
$OSBuild = ([System.Environment]::OSVersion.Version).Build

IF (!($OSBuild)) {
    Write-Log 'Failed to Find Build Info'
    Exit 1
} else{
    Write-Log "Machine :- $HostName OS Version is $OSBuild"
}

$OSInfo = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion'
$DevicesInfos ="$($OSInfo.CurrentMajorVersionNumber).$($OSInfo.CurrentMinorVersionNumber).$($OSInfo.CurrentBuild).$($OSInfo.UBR)"
Write-Log "OS Build version $DevicesInfos"

# Get last reboot time
$LastReboot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Log "Machine Last Reboot Time: $LastReboot"

# Get total and free space on C: drive in GB
$Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$TotalSpaceGB = [math]::round($Disk.Size / 1GB, 2)
$FreeSpaceGB = [math]::round($Disk.FreeSpace / 1GB, 2)

Write-Log "Machine Total C: Drive Space: $TotalSpaceGB GB"
Write-Log "Machine Free  C: Drive Space: $FreeSpaceGB GB"

# Checking Windows Update
$ServiceName = 'wuauserv'
$ServiceType = (Get-Service -Name $ServiceName).StartType
Write-Log "Windows Update Service startup type is '$ServiceType'"
if ([string]$ServiceType -ne 'Manual') {
    Write-Log "Startup type for Windows Update is not Manual. Consider setting it to Manual." "WARNING"
    # Set-Service -Name $ServiceName -StartupType Manual
}

# Checking Microsoft Account Sign-in Assistant Service
$ServiceName = 'wlidsvc'
$ServiceType = (Get-Service -Name $ServiceName).StartType
Write-Log "Microsoft Account Sign-in Assistant Service startup type is '$ServiceType'"
if ([string]$ServiceType -ne 'Manual') {
    Write-Log "Startup type for Microsoft Account Sign-in Assistant is not Manual. Consider setting it to Manual." "WARNING"
    # Set-Service -Name $ServiceName -StartupType Manual
}

# Checking Update Orchestrator Service
$ServiceName = 'UsoSvc'
$ServiceType = (Get-Service -Name $ServiceName).StartType
if ($ServiceType) {
    Write-Log "Update Orchestrator Service startup type is '$ServiceType'"
    if ([string]$ServiceType -ne 'Automatic') {
        Write-Log "Startup type for Update Orchestrator Service is not Automatic. Consider setting it to Automatic." "WARNING"
        # Set-Service -Name $ServiceName -StartupType Automatic
    }
    }

Function Get-LatestWindowsUpdateInfo {
    # Get the current build number
    $currentBuild = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
    $osBuildMajor = $currentBuild.Substring(0, 1)

    # Decide which update history URL to use based on the device OS Win10 or Win11
    $updateUrl = if ($osBuildMajor -eq "2") {
        "https://aka.ms/Windows11UpdateHistory"
    } else {
        "https://support.microsoft.com/en-us/help/4043454"
    }

    # Get the page content
    $response = if ($PSVersionTable.PSVersion.Major -ge 6) {
        Invoke-WebRequest -Uri $updateUrl -ErrorAction Stop
    } else {
        Invoke-WebRequest -Uri $updateUrl -UseBasicParsing -ErrorAction Stop
    }

    # Filter all KB links
    $updateLinks = $response.Links | Where-Object {
        $_.outerHTML -match "supLeftNavLink" -and
        $_.outerHTML -match "KB" -and
        $_.outerHTML -notmatch "Preview" -and
        $_.outerHTML -notmatch "Out-of-band"
    }

    # Get the latest relevant update
    $latest = $updateLinks | Where-Object {
        $_.outerHTML -match $currentBuild
    } | Select-Object -First 1

    if ($latest) {
        $title = $latest.outerHTML.Split('>')[1].Replace('</a','').Replace('&#x2014;', ' - ')
        $kbId  = "KB" + $latest.href.Split('/')[-1]

        [PSCustomObject]@{
            LatestUpdate_Title = $title
            LatestUpdate_KB    = $kbId
        }
    } else {
        Write-Warning "No update found for current build."
        exit -1
    }
}

#If you want to restart service remove # from these commands

#Restart-Service -Name wlidsvc -Force
#Restart-Service -Name uhssvc -Force
#Restart-Service -Name wuauserv -Force

# Run and show the result
$latestUpdateInfo = Get-LatestWindowsUpdateInfo

$LastHotFix = $latestUpdateInfo.LatestUpdate_KB
$LastPatchDate = $hotfix.InstalledOn
$KB = $LastHotFix-replace "^KB", ""
$InfoURL = "https://support.microsoft.com/en-us/help/$KB"
Write-Log "Latest Patch Tuesday Security Update KB Number:- $($latestUpdateInfo.LatestUpdate_KB)"
Write-Log "Latest Security Update KB Info URL :- $InfoURL"
Write-Log "Latest Security Update KB Title and Date:- $($latestUpdateInfo.LatestUpdate_Title)"


# Get the latest Windows cumulative Security Update information
$latestUpdateInfo = Get-LatestWindowsUpdateInfo
$MGIModule = Get-module -Name "PSWindowsUpdate" -ListAvailable -InformationAction SilentlyContinue
    If ($MGIModule -eq $null) {
        Write-Log "PSWindowsUpdate module not found. Installing..."
        Install-Module -Name PSWindowsUpdate -Force
        Write-Log "PSWindowsUpdate module is now Installed..."
        Write-Log "Importing PSWindowsUpdate module."
        Import-Module PSWindowsUpdate -Force

        
    } ELSE {
        Write-Log "PSWindowsUpdate module already installed."
        Write-Log "Importing PSWindowsUpdate module."
        Import-Module PSWindowsUpdate -Force
     }
    
# Check if Latest Security Update KB is already installed
Write-Log "Checking if the Latest $($latestUpdateInfo.LatestUpdate_KB) update is already installed"
$kbInstalled = Get-HotFix | Where-Object { $_.HotFixID -eq $latestUpdateInfo.LatestUpdate_KB }

if ($kbInstalled) {
    
    #Write-Host "$($latestUpdateInfo.LatestUpdate_KB) is already installed.No action needed..Exiting script."
    Write-Log "$($latestUpdateInfo.LatestUpdate_KB) is already installed."
    $rebootRequiredKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    
    if (Test-Path $rebootRequiredKey) {
    $rebootGuid = Get-ItemProperty -Path $rebootRequiredKey 
    $guidOnly = ($rebootGuid | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }) | Where-Object { $_ -match '^[a-f0-9\-]{36}$' }
    if ($rebootGuid) {Write-Log "Windows Update Reboot pending against.GUID: $guidOnly"} else {Write-Log "No Windows Update Patching Reboot Required."}}
    
    else {Write-Log "No Windows Update Patching Reboot Required."}
    
    Write-Log "No action needed..Exiting script....."
   
    exit 0
} 
else {
    #Write-Host "$($latestUpdateInfo.LatestUpdate_KB) is not installed.Action needed..Installing now..."
    Write-Log "$($latestUpdateInfo.LatestUpdate_KB) is not installed.Action needed..Installing now..."
    
    Get-WindowsUpdate -Install -KBArticleID $latestUpdateInfo.LatestUpdate_KB -IgnoreReboot -MicrosoftUpdate -InformationAction SilentlyContinue -acceptall
    Write-Log "$($latestUpdateInfo.LatestUpdate_KB) is noW installed."
    
    $rebootRequiredKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    if (Test-Path $rebootRequiredKey) {
    $rebootGuid = Get-ItemProperty -Path $rebootRequiredKey 
    $guidOnly = ($rebootGuid | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }) | Where-Object { $_ -match '^[a-f0-9\-]{36}$' }
    if ($rebootGuid)
    
     { Write-Log "Windows Update Reboot pending against.GUID: $guidOnly"
       Write-Log "Manually Reboot the System"
     } 
     else { Write-Log "No Windows Update Patching Reboot Required."}}
     else { Write-Log "No Windows Update Patching Reboot Required."}
}

#===================================================================Script End ====================================================
