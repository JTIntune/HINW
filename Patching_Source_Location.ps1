
$MUSM = New-Object -ComObject "Microsoft.Update.ServiceManager"

$Output = $MUSM.Services | Where-Object { $_.IsDefaultAUService -eq $true }

$Patching_Source_Location = if ($Output.Name -eq "Windows Server Update Service" ) {"SCCM"} ElseIf ($Output.Name -eq "Windows Update" ) {"Windows Update"} ElseIf ($Output.Name -eq "Microsoft Update" ) {"Intune/GPO"} Else {$Output.Name }

$Patching_Source_Location