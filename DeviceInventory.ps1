<#ReportName (Export Parameter) line number = 50

DeviceCompliance
DeviceNonCompliance
Devices
DetectedAppsAggregate
FeatureUpdatePolicyFailuresAggregate
DeviceFailuresByFeatureUpdatePolicy
DetectedAppsRawData
FeatureUpdateDeviceState
UnhealthyDefenderAgents
DefenderAgents
ActiveMalware
Malware
AllAppsList
AppInstallStatusAggregate
DeviceInstallStatusByApp
UserInstallStatusAggregateByApp
ComanagedDeviceWorkloads
ComanagementEligibilityTenantAttachedDevices
DeviceRunStatesByProactiveRemediation
DevicesWithInventory
FirewallStatus
GPAnalyticsSettingMigrationReadiness
QualityUpdateDeviceErrorsByPolicy
QualityUpdateDeviceStatusByPolicy
MAMAppProtectionStatus
MAMAppConfigurationStatus

#>


CLS
$startTime = Get-Date
Write-Host "===============================Phase-1 (Exporting DevicesWithInventory Report) ======================================================(Started)" -ForegroundColor Green

# Set execution policy for the process
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' 

#====================== User Input ==================================
# Tenant and app details
$tenant = “d914085e-e994-4c53-b111-0f20b7f866bf”
$authority = “https://login.windows.net/$tenant”
$clientId = “d546c729-2aa7-4665-b246-e32af60743ea”
$clientSecret = “oQX8Q~ryqtoFl_C6A9eJ4DqZoGADoSxQ25bysa~s”

# Multiple Policy IDs
$PolicyIDs = @(    "e7a1a387-ea60-4ee0-ad94-af9747ef5078" )

$reportName = "DevicesWithInventory"
#===================================================================
# Initialize variables
$DetectApp = "Microsoft Intune Management Extension"
$error.clear() # Clear error history
$Pathfinalreport = "C:\DeviceStatusesByConfiguration_Report.csv"
$WorkingFolder = "C:\TEMP\Intune_DeviceStatusesByConfigurationProfile_Report"
$Path = "$WorkingFolder\PD_Dump\"
$MGIModule = Get-Module -Name "Microsoft.Graph.Intune" -ListAvailable

# Check if Microsoft.Graph.Intune module is installed
Write-Host "Checking Microsoft.Graph.Intune is Installed or Not"
if ($MGIModule -eq $null) {
    Write-Host "Microsoft.Graph.Intune module is not Installed"
    Write-Host "Installing Microsoft.Graph.Intune module"
    Install-Module -Name Microsoft.Graph.Intune -Force
    Write-Host "Importing Microsoft.Graph.Intune module"
    Import-Module Microsoft.Graph.Intune -Force
} else {
    Write-Host "Microsoft.Graph.Intune is Installed"
    Write-Host "Importing Microsoft.Graph.Intune module"
    Import-Module Microsoft.Graph.Intune -Force
}

# Connect to Microsoft Graph API
Update-MSGraphEnvironment -AppId $clientId -Quiet
Update-MSGraphEnvironment -AuthUrl $authority -Quiet
Connect-MSGraph -ClientSecret $ClientSecret -Quiet
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet

$PD_DumpPath = "$WorkingFolder\PD_Dump"

# Check if the folder exists and delete it
if (Test-Path -Path $PD_DumpPath) {
    Remove-Item -Path $PD_DumpPath -Recurse -Force
    Write-Host "Folder '$PD_DumpPath' has been deleted."
} else {
    Write-Host "Folder '$PD_DumpPath' does not exist."
}

# Ensure directories exist
if (-Not (Test-Path -Path $WorkingFolder)) {
    Write-Host "Working folder $WorkingFolder does not exist. Creating it now..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $WorkingFolder -Force
}

if (-Not (Test-Path -Path $Path)) {
    Write-Host "Path $Path does not exist. Creating it now..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

# Loop through each Policy ID
foreach ($PolicyID in $PolicyIDs) {
    Write-Host "Processing Policy ID: $PolicyID" -ForegroundColor Cyan

    # Create request body for report export
    $postBody = @{
        'reportName' = $reportName
       # 'filter' = "(PolicyId eq '$PolicyID')"
    }

    # Make the export request
    $exportJob = Invoke-MSGraphRequest -HttpMethod POST -Url "DeviceManagement/reports/exportJobs" -Content $postBody
   # Write-Host "Export Job initiated for Policy ID: $PolicyID"

    # Check report status
    do {
        $exportJob = Invoke-MSGraphRequest -HttpMethod Get -Url "DeviceManagement/reports/exportJobs('$($exportJob.id)')" -InformationAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host -NoNewline '...........'
    } while ($exportJob.status -eq 'inprogress')

    if ($exportJob.status -eq 'completed') {
        #Write-Host "Report is ready for Policy ID: $PolicyID" -ForegroundColor Yellow
        $fileName = (Split-Path -Path $exportJob.url -Leaf).split('?')[0]
        Invoke-WebRequest -Uri $exportJob.url -Method Get -OutFile "$Path$fileName"

        # Extract CSV data
        Expand-Archive -Path "$Path$fileName" -DestinationPath $Path
        $FileName = Get-ChildItem -Path "$Path*" -Include *.csv | Where {!$_.PSIsContainer}
        $DevicesInfos = Import-Csv -Path $FileName.FullName
        Invoke-Item -Path $FileName.FullName
        
    } else {
      
    }
}

Write-Host "===============================Phase-1 (Exported $reportName Reports) ====================================================(Completed)" -ForegroundColor Green
