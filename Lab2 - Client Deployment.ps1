# Lab 2 - Client Deployment
###########################

# Install Group Policy Management Console
Get-WindowsFeature *gpmc* | Install-WindowsFeature

# Setup Workstation Organizational Unit
$ou = New-ADOrganizationalUnit -Name Workstations -PassThru

# Move Clients into newly created OU
Get-ADComputer Appv-Client1 | Move-ADObject -TargetPath $ou
Get-ADComputer Appv-Client2 | Move-ADObject -TargetPath $ou

# Create Group Policy Object to enabe AppV-Client
New-GPO -Name "AppV"
New-GPLink -Name "AppV" -Target $ou

# Open Group Policy Management to confgure GPO Settings
# * Enable AppV
# * Publishing Server
gpmc.msc

# Refresh Policy on Clients
Invoke-Command -ComputerName Appv-Client1,Appv-Client2 -ScriptBlock {gpupdate}

# Restart Clients
Invoke-Command -ComputerName Appv-Client1,Appv-Client2 -ScriptBlock {Restart-Computer -Force}