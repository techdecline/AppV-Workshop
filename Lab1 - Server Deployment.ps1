# Lab 1 - Serverdeployment
##########################

## Install AD PowerShell Feature
Get-WindowsFeature rsat-ad*power* | Install-WindowsFeature -Restart

## Prepare Active Directory Groups
Import-Module ActiveDirectory

New-ADGroup -Name App-V-Users -GroupCategory Security -GroupScope DomainLocal
New-ADGroup -Name App-V-Admins -GroupCategory Security -GroupScope DomainLocal

Add-ADGroupMember -Identity App-V-Admins -Members Administrator,AppV-Server1$

New-ADUser -Name Alice -DisplayName Alice -SamAccountName Alice -UserPrincipalName alice@training.lab -PassThru |Set-ADAccountPassword -NewPassword (ConvertTo-SecureString -AsPlainText -Force "Passw0rd") -PassThru | Enable-ADAccount
Add-ADGroupMember -Identity App-V-Users -Members Alice


# Reboot to update Group Memberships
Restart-Computer

# Install Management Server and Database
Start-Process -FilePath "\\appv-server1\Install\AppVServer\appv_server_setup.exe" -ArgumentList '/QUIET /MANAGEMENT_SERVER /MANAGEMENT_ADMINACCOUNT="training\App-V-Admins" /MANAGEMENT_WEBSITE_NAME="Microsoft AppV Management Service" /MANAGEMENT_WEBSITE_PORT="8080" /DB_PREDEPLOY_MANAGEMENT /MANAGEMENT_DB_CUSTOM_SQLINSTANCE="AppV" /MANAGEMENT_DB_NAME="AppVManagement" /ACCEPTEULA /INSTALLDIR="C:\Program Files\Microsoft Application Virtualization Server"'

Wait-Process appv_server_setup -Timeout 300

# Install Publishing Server on Appv-Server2
Copy-Item "\\appv-server1\Install\AppVServer\appv_server_setup.exe" -Destination \\appv-server2\c$\Windows\Temp
Invoke-Command -ComputerName appv-server2 -ScriptBlock {
    Start-Process -FilePath "C:\Windows\Temp\appv_server_setup.exe" -ArgumentList '/QUIET /ACCEPTEULA /PUBLISHING_SERVER /PUBLISHING_MGT_SERVER="http://Appv-Server1.training.lab:8080" /PUBLISHING_WEBSITE_NAME="Microsoft AppV Publishing Service" /PUBLISHING_WEBSITE_PORT="8081"'
    Wait-Process appv_server_setup -Timeout 300
}

# Open Management Console to add App-V Publishing Server
&  "C:\Program Files (x86)\Internet Explorer\iexplore.exe" http://localhost:8080/