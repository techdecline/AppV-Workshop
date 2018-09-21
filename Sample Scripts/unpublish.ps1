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

$startMenuPath = Join-Path -Path $(Resolve-UWMShellFolder -ShellFolderName StartMenu) -ChildPath "IBM Personal Communications"

Get-ChildItem $startMenuPath | ForEach-Object {Remove-Item -Confirm:$false -Path $_.FullName}