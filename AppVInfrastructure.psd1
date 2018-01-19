@{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowDomainUser = $true
            SourcePath = "\\AppV-Server1\INSTALL"
            DomainName = "training.lab"
            PSDSCAllowPlainTextPassword = $true
        }
        @{
            NodeName = "AppV-Server1.training.lab"
            Role = "WebServer","Mgmt"
            InstanceName = "AppV"
            }
        @{
            NodeName = "AppV-Server2.training.lab"
            Role = "WebServer","Publ"
        }
    )
}
# Save ConfigurationData in a file with .psd1 file extension