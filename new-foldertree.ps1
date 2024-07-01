<# 
.SYNOPSIS
Create a folder tree in vCenter using PowerCLI.

.DESCRIPTION
From a reference JSON file, a folder tree is created on a target vCenter appliance.

.NOTES
Author: Lucas McGlamery
Version:
1.0 2023-07-01  Initial release

.PARAMETER FolderTreePath
Full path of the source folder tree JSON file.

.PARAMETER Depth
Depth of JSON file. Default is 10. Increase this if your folder tree is heavily nested.

.PARAMETER RootFolderString
Root folder name for tree to start in. Default is the builtin vm folder, ID Folder-group-v4.

.EXAMPLE
New-FolderTree

.EXAMPLE
New-FolderTree -RootFolderString 'management'
#>
function New-FolderTree() {
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = 'Full path of the source folder tree file.')]
        [String]
        $FolderTreePath = "$PSScriptRoot\folder-tree.json",
        [Parameter(HelpMessage = 'Depth of JSON file. Default is 10.')]
        [Int32]
        $Depth = 10,
        [Parameter(HelpMessage = 'Root folder name for tree to start in. Default is the builtin vm folder.')]
        [String]
        $RootFolderString
    )

    if (!$Global:DefaultVIServer) {
        echo "Not connected to a vCenter Server system. Please connect and try again."
        break
    }

    if (!$RootFolderString) {
        $ParentFolder = $(Get-Folder -Id 'Folder-group-v4')
    } else {
        if (!$(Get-Folder $RootFolderString)) {
            echo "Folder is not valid. Please correct the name and try again."
            break
        } else {
            $ParentFolder = $(Get-Folder -Name $RootFolderString)
        }
    }

    $FolderTree = Get-Content $FolderTreePath | ConvertFrom-Json -Depth $Depth

    function New-Folders($FolderTree, $Parent) {
        foreach ($Name in $($FolderTree.PSObject.Properties.Name)) {
            New-Folder -Name $Name -Location $Parent
            if ($($FolderTree.$Name | Get-Member).MemberType -contains 'NoteProperty') {
                $NewParent = Get-Folder -Name $Name -Location $Parent
                New-Folders $FolderTree.$Name $NewParent
            }
        }
    }
    New-Folders $FolderTree $ParentFolder
}