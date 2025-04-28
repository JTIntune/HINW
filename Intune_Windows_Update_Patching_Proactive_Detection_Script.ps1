<# 
.SYNOPSIS
Intune Windows Update Patching Detection Script >

.DESCRIPTION
Intune Windows Update Patching Detection Script >

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

#===========================   User Input===========================================

$IsPatchedWithInDays = '45'   # Days since not patched

#===================================================================================

# Initialize Logging
$IntLog = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
if (!(Test-Path -Path $IntLog)) {new-Item -ItemType Directory -Path $IntLog -Force | Out-Null}
$LogPath = "$IntLog\Intune_Patching_Compliance.log"         
Function Write-Log {
    Param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $LogPath  -Append
}
Write-Log "====================== Running Intune Patching Detection Script $(Get-Date -Format 'yyyy/MM/dd') ===================="

 # Check if ESP is running
$ESP = Get-Process -ProcessName CloudExperienceHostBroker -ErrorAction SilentlyContinue
If ($ESP) {
    #Write-Host "Windows Autopilot ESP Running"
    Write-Log "Windows Autopilot ESP Running"
    Write-Log "Exiting Intune Patching Detection Script"
    Exit 1 
     }
Else {
    #Write-Host "Windows Autopilot ESP Not Running"
    Write-Log "Windows Autopilot ESP Not Running"
    
     }
$HostName = hostname
Write-Log "Checking if Machine Name:- $HostName was patched within the last $IsPatchedWithInDays days"    
     

# Date minus $IsPatchedWithInDays days 
$Date = (get-date).AddDays(-$IsPatchedWithInDays)

# Get last patch install date
$hotfix = get-wmiobject -class win32_quickfixengineering | Where-Object {$_. Description  -eq  "Security Update" } |  Sort-Object InstalledOn -Descending | Select-Object -First 1

$LastHotFix = $hotfix.HotFixID
$LastPatchDate = $hotfix.InstalledOn
$KB = $LastHotFix-replace "^KB", ""
$InfoURL = "https://support.microsoft.com/en-us/help/$KB"



# Check $LastPatchDate is date and not a string
If ($lastPatchDate.GetType().Name -ne 'DateTime') {

    # Convert string to datetime
    $LastPatchDate = [DateTime]$LastPatchDate
}

# Compare dates to determine last patch date
If ($date -lt $LastPatchDate) {
    Write-Log "Machine Name:-$HostName was patched within the last $IsPatchedWithInDays days."
    Write-Log "Last Security Update Installed Patch:- $LastHotFix"
    Write-Log "Security Update $LastHotFix installed on $($hotfix.InstalledOn)"
    Write-Log "Security Update $LastHotFix installed by $($hotfix.InstalledBy)"
    Write-Log "Installed Security Update Info URL :- $InfoURL"
    Write-Log "No action needed..Exiting Intune Patching Detection Script."
    Exit 0
}
Else {
    write-Log "Machine Name:-$HostName has not been patched in the last $IsPatchedWithInDays days."
    write-Log "Last Security Update Installed Patch:- $LastHotFix"
    Write-Log "Patching Remediation Required.."
    write-Log "Trigrring Intune Patching Remediation Script.. "
    Exit 1
}

#==================================Script End========================================================================================