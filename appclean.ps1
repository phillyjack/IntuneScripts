$osVersion = [System.Environment]::OSVersion.Version
if ($osVersion.Major -ne 10 -or $osVersion.Build -lt 22000) {
    Log "This script can only be run on Windows 11."
    exit 0
}


$xmldata = @"
<Config>
  <TimeZone></TimeZone>
  <RemoveApps>
    <App>Microsoft.BingNews</App>
    <App>Microsoft.MicrosoftTeams</App>
    <App>Microsoft.BingWeather</App>
    <App>Microsoft.GamingApp</App>
    <App>Microsoft.Getstarted</App>
    <App>Microsoft.Messaging</App>
    <App>Microsoft.Microsoft3DViewer</App>
    <App>Microsoft.MicrosoftOfficeHub</App>
    <App>Microsoft.MicrosoftSolitaireCollection</App>
    <App>Microsoft.MicrosoftStockyNotes</App>
    <App>Microsoft.MixedReality.Portal</App>
    <App>Microsoft.OneConnect</App>
    <App>Microsoft.People</App>
    <App>Microsoft.Print3D</App>
    <App>Microsoft.SkypeApp</App>
    <App>microsoft.windowscommunicationsapps</App>
    <App>Microsoft.WindowsFeedbackHub</App>
    <App>Microsoft.WindowsMaps</App>
    <App>Microsoft.XboxApp</App>
    <App>Microsoft.YourPhone</App>
    <App>Microsoft.ZuneMusic</App>
    <App>Microsoft.ZuneVideo</App>
    <App>Clipchamp.Clipchamp</App>
    <App>Microsoft.OutlookForWindows</App>
  </RemoveApps>
 </Config>
"@




function Log() {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$false)] [String] $message
	)

	$ts = get-date -f "yyyy/MM/dd hh:mm:ss tt"
	Write-Output "$ts $message"
}

# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64")
{
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe")
    {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
        Exit $lastexitcode
    }
}


# Start logging

$logFileName = "\\oigsrvgxa02\backup\logdump\AutopilotBranding_$($env:COMPUTERNAME).log"
Start-Transcript -Path $logFileName


# PREP: Load the Config XML Data

[Xml]$config = $xmldata


# STEP 3: Set time zone (if specified)
if ($config.Config.TimeZone) {
	Log "Setting time zone: $($config.Config.TimeZone)"
	Set-Timezone -Id $config.Config.TimeZone
}
else {
	# Enable location services so the time zone will be set automatically (even when skipping the privacy page in OOBE) when an administrator signs in
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type "String" -Value "Allow" -Force
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type "DWord" -Value 1 -Force
	Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
}

# STEP 4: Remove specified provisioned apps if they exist
Log "Removing specified in-box provisioned apps"
$apps = Get-AppxProvisionedPackage -online
$config.Config.RemoveApps.App | ForEach-Object {
	$current = $_
    Log "Preparing to remove $current"
	$apps | Where-Object {$_.DisplayName -eq $current} | % {
		try {
			Log "Removing provisioned app: $current"
			$_ | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction SilentlyContinue | Out-Null
		} catch { }
	}
}



Stop-Transcript
exit 0
