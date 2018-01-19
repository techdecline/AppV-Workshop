# Lab 3B - Add Server Package
#############################

# Import Package on Server
Import-AppvServerPackage -PackagePath '\\appv-server2\PackageStore\Google Chrome\Google Chrome.appv'

# Restrict Access to App-V-Users group
Get-AppvServerPackage *chrome* | Grant-AppvServerPackage -Groups "training\app-v-users" -Verbose

# Publish Package
Get-AppvServerPackage *chrome* | Publish-AppvServerPackage