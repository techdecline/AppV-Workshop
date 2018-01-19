# Start Virtual Bubble
$appv = Get-AppvClientPackage
Start-AppvVirtualProcess -FilePath powershell -AppvClientObject $appv

# Repair App-V Package

## Recreate Extensions
Get-AppvClientPackage | Repair-AppvClientPackage -Extensions

## Reset Virtual Bubble
Get-AppvClientPackage | Repair-AppvClientPackage -UserState