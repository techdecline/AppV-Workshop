function Resolve-UWMShellFolder {
    [CmdletBinding()]
    param (
        # Shell Folder Name
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]
        $ShellFolderName
    )
    process {
        $shellFolderArr = [Environment+SpecialFolder]::GetNames([Environment+SpecialFolder])
        if ($shellFolderArr -contains $ShellFolderName ) {
            $shellFolderPath = [System.Environment]::GetFolderPath("$ShellFolderName")
            return $shellFolderPath
        }
        elseif (([System.Environment]::GetEnvironmentVariables().getenumerator() | Select-Object -ExpandProperty Name) -contains $ShellFolderName) {
            $shellFolderPath = [System.Environment]::GetEnvironmentVariable($ShellFolderName)
            return $shellFolderPath
        }
        else {
            return $null
        }
    }
}


# Get WS Files
$wsFileArr = Get-ChildItem "$env:appdata\IBM\Personal Communications" -Filter "*.ws"
$startMenuPath = Join-Path -Path $(Resolve-UWMShellFolder -ShellFolderName StartMenu) -ChildPath "IBM Personal Communications"

if (-not (Test-Path $startMenuPath)) {
    New-Item $startMenuPath -ItemType Directory
}

foreach ($wsFileObj in $wsFileArr) {
    $wshShell = New-Object -ComObject WScript.Shell
    $name = $wsFileObj.Name -replace "`.ws",""
    $shortcut = $wshShell.CreateShortCut($(Join-Path -Path $startMenuPath -ChildPath "$name.lnk"))
    $shortcut.TargetPath = $wsFileObj.FullName
    $shortcut.save()
}