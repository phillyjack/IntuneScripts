# Define the key name and the search root
$keyName = "*\f898e88e-a238-4811-8bf8-5ce6f77ca560"
$appId = "f898e88e-a238-4811-8bf8-5ce6f77ca560"
$searchRoot = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\win32Apps"


$app= "msiexec.exe"
$Arguments = "/i{A707D2B3-E2D3-48F5-84FC-ED04BF5A9FC3} /qn"


Try {
    Start-Process $app -ArgumentList $Arguments -Wait -NoNewWindow
    Write-Output "Complete"
    } 
Catch {
    Write-Warning "Error"
    write-warning %errorlevel%

}


Function gethash { 
$intuneLogList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs" -Filter "IntuneManagementExtension*.log" -File | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName
 
if (!$intuneLogList) {
Write-Error "Unable to find any Intune log files. Redeploy will probably not work as expected."
return
}
 
foreach ($intuneLog in $intuneLogList) {
$appMatch = Select-String -Path $intuneLog -Pattern "\[Win32App\]\[GRSManager\] App with id: $appId" -Context 0, 1

if ($appMatch) {
foreach ($match in $appMatch) {
$Hash = ""
$LineNumber = 0
$LineNumber = $match.LineNumber
$Hash = Get-Content $intuneLog | Select-Object -Skip $LineNumber -First 1
if ($hash) {
$hash = $hash.Replace('+','\+')
$Hash
return
}
}
}
}
}


# Get all the subkeys under the search root
$subKeys = Get-ChildItem -Path $searchRoot -Recurse


# Loop through each subkey and check if it contains the key name


foreach ($subKey in $subKeys) {
#write-host $subkey.Name
 
    if ($subKey.Name -like "$keyName*") {

        #Delete the subkey that matches the key name    
        write-host $subkey.name
        Remove-Item -Path $subKey.PSPath -Recurse -Force
        # Write a message to indicate the deletion        
        Write-Host "Deleted $($subKey.Name)"
    }
}

$hash = getHash $appId
$hash2 = $hash.Trim("Hash = ")

$subKeys2 = Get-ChildItem -Path $searchRoot -Recurse -Depth 4
foreach ($subKey in $subKeys2) {
#write-host $subkey.Name
 
    if ($subKey.Name -like "*$hash2*") {

        #Delete the subkey that matches the key name    
        write-host $subkey.name
        Remove-Item -Path $subKey.PSPath -Recurse -Force
        # Write a message to indicate the deletion        
        Write-Host "Deleted $($subKey.Name)"
    }
}





Restart-Service IntuneManagementExtension -Force