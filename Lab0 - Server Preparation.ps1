configuration AppVInfrastructure
{
    param (
        [Parameter(Mandatory=$false)]
        [PSCredential]$SetupCredential,

        [Parameter(Mandatory=$true)]
        [PSCredential]$SqlServiceAccount
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Name xSQLServerSetup -ModuleVersion 8.1.0.0 -ModuleName xSQLServer
    Import-DscResource -Name xSqlServerFirewall -ModuleVersion 8.1.0.0 -ModuleName xSQLServer
    Import-DscResource -Name xFirewall -ModuleVersion 5.1.0.0 -ModuleName xNetworking
    Import-DscResource -Name xSmbShare -ModuleVersion 2.0.0.0 -ModuleName xSmbShare

    node $AllNodes.Where{$_.Role -eq "Mgmt"}.NodeName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature DotNet3
        {
            Name = "NET-Framework-Core"
            Ensure = "Present"
            Source = (join-path $Node.SourcePath -ChildPath "sxs")
            DependsOn = "[File]SQLTempDir"
        }

        xSqlServerSetup ($Node.NodeName + $Node.InstanceName)
        {
            DependsOn = "[WindowsFeature]DotNet3"
            SourcePath = (join-path $Node.SourcePath -ChildPath "SQLServer2016")
            InstanceName = $Node.InstanceName
            Features = "SQLENGINE,RS"
            UpdateEnabled = "0"
            InstallSharedDir = "C:\Program Files\Microsoft SQL Server"
            InstallSharedWOWDir = "C:\Program Files (x86)\Microsoft SQL Server"
            InstanceDir = "C:\Program Files\Microsoft SQL Server"
            SQLSvcAccount = $SqlServiceAccount
            SQLSysAdminAccounts = $SetupCredential.UserName
            SQLTempDBDir = "C:\SQLTMP"
        }


        xSqlServerFirewall ($Node.NodeName + $Node.InstanceName)
        {
            DependsOn = ("[xSqlServerSetup]" + $Node.NodeName + $Node.InstanceName)
            SourcePath = (join-path $Node.SourcePath -ChildPath "SQLServer2016")
            InstanceName = $Node.InstanceName
            Features = "SQLENGINE,RS"
        }
        
        xFirewall ($Node.NodeName + "_AppV_8080")
        {
            Name                  = "AppV_8080"
            Ensure                = "Present"
            Enabled               = "True"
            Action = "Allow"
            Profile = "Domain"
            Direction = 'Inbound'
            LocalPort = "8080"
            Protocol = "TCP"
        }

        Registry SqlNoDynPort
        {
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL13.$($Node.InstanceName)\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
            ValueName = "TcpDynamicPorts"
            ValueData = ""
            ValueType = "STRING"
            Force = $true
            DependsOn = ("[xSqlServerSetup]" + $Node.NodeName + $Node.InstanceName)
        }

        Registry SqlStaticPort
        {
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL13.$($Node.InstanceName)\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
            ValueName = "TcpPort"
            ValueData = "1433"
            ValueType = "STRING"
            DependsOn = ("[xSqlServerSetup]" + $Node.NodeName + $Node.InstanceName)
        }

        Package MgmtStudio
        {
            Ensure = "Present"
            Path  = (join-path $Node.SourcePath -ChildPath "SQL Management Studio\SSMS-Setup-ENU.exe")
            Name = "SQL Server 2016 Management Studio"
            #Credential=$SetupCredential
            ProductId = "{510DB6E6-7CF0-4B25-A51E-3AED7E25D507}"
            Arguments = "/install /silent /norestart /log $env:Temp\SSMS.log"
        }

        File SqlTempDir
        {
            DestinationPath = "C:\SQLTMP"
            Ensure = "Present"
            Type = 'Directory'
        }
    }

    node $AllNodes.Where{$_.Role -eq "WebServer"}.NodeName
    {
        WindowsFeature ($Node.NodeName + "_Web-Server")
        {
            Ensure = "Present"
            Name = "Web-Server"
        }

        WindowsFeature ($Node.NodeName + "_Web-Mgmt-Tools")
        {
            Ensure = "Present"
            Name = "Web-Mgmt-Tools"
        }

        WindowsFeature ($Node.NodeName + "_Web-Asp-Net")
        {
            Ensure = "Present"
            Name = "Web-Asp-Net"
        }

        WindowsFeature ($Node.NodeName + "_Web-Asp-Net45")
        {
            Ensure = "Present"
            Name = "Web-Asp-Net45"
        }

        WindowsFeature ($Node.NodeName + "_Web-Net-Ext")
        {
            Ensure = "Present"
            Name = "Web-Net-Ext"
        }

        WindowsFeature ($Node.NodeName + "_Web-Net-Ext45")
        {
            Ensure = "Present"
            Name = "Web-Net-Ext45"
        }

        WindowsFeature ($Node.NodeName + "_Web-Windows-Auth")
        {
            Ensure = "Present"
            Name = "Web-Windows-Auth"
        }

        WindowsFeature ($Node.NodeName + "_Web-Filtering")
        {
            Ensure = "Present"
            Name = "Web-Filtering"
        }

        xFirewall ($Node.NodeName + "_ICMP")
        {
            Name                  = "FPS-ICMP4-ERQ-In"
            Ensure                = "Present"
            Enabled               = "True"
        }

        xFirewall ($Node.NodeName + "_SMB")
        {
            Name                  = "FPS-SMB-In-TCP"
            Ensure                = "Present"
            Enabled               = "True"
        }
    }

    node $AllNodes.Where{$_.Role -eq "Publ"}.NodeName {
        Group AddMgmtServerToLocalAdminGroup
        {
            GroupName='Administrators'
            Ensure= 'Present'
            #MembersToInclude= "training\appv-server1$"
            #MembersToInclude = $AllNodes.Where{$_.Role -eq "Mgmt"}.NodeName
            MembersToInclude = [string]$Allnodes.DomainName[0] + '\' + $($AllNodes.Where{$_.Role -eq "Mgmt"}.NodeName.split('.')[0]) + '$'
            #$AllNodes.Where{$_.Role -eq "ConfigMgr"}.NodeName
            Credential=$SetupCredential
        }

        File PackageStore
        {
            DestinationPath = "C:\PackageStore"
            Ensure = "Present"
            Type = 'Directory'
        }

        xSmbShare PackageStoreShare
        {
            DependsOn = "[File]PackageStore"
            Name = "PackageStore"
            FullAccess = "Administrators"
            Path = "C:\PackageStore"
        }

        xFirewall ($Node.NodeName + "_AppV_8081")
        {
            Name                  = "AppV_8081"
            Ensure                = "Present"
            Enabled               = "True"
            Action = "Allow"
            Profile = "Domain"
            Direction = "Inbound"
            LocalPort = "8081"
            Protocol = "TCP"
        }
    }
}

$setupCred = get-credential
$LocalSystemCred = New-Object System.Management.Automation.PSCredential "SYSTEM",(ConvertTo-SecureString -AsPlainText "blabla" -Force)
AppVInfrastructure -OutputPath 'C:\Code\AppV\MOF' `
    -ConfigurationData "C:\Code\AppVInfrastructure.psd1" -SetupCredential $setupCred -SqlServiceAccount $LocalSystemCred