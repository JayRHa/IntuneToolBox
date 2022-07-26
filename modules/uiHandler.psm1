<#
.SYNOPSIS
Hadeling UI
.DESCRIPTION
Handling of the WPF UI
.NOTES
  Author: Jannik Reinhard
#>

########################################################################################
###################################### UI Actions ######################################
########################################################################################
function Set-UiActionButton{
    #Home
    Add-XamlEvent -object $WPFButtonHome -event "Add_Click" -scriptBlock {
            Hide-All
            $WPFListViewMenu.SelectedIndex = 0
            $WPFGridHomeFrame.Visibility = 'Visible'
    }

    # Start Page 
    Add-XamlEvent -object $WPFButtonLogIn -event "Add_Click" -scriptBlock {Set-LoginOrLogout}

    # Header
    Add-XamlEvent -object $WPFButtonAbout -event "Add_Click" -scriptBlock {
        if($WPFGridAbout.Visibility -eq "Visible"){
            Hide-All
            $WPFListViewMenu.SelectedIndex = 0
            $WPFGridHomeFrame.Visibility = 'Visible'
            Get-MainFrame
        }else{
            Hide-All
            $WPFListViewMenu.SelectedIndex = -1
            $WPFGridAbout.Visibility="Visible"
        }
    }

    # About
    Add-XamlEvent -object $WPFButtonAboutWordpress -event "Add_Click" -scriptBlock {Start-Process "https://www.jannikreinhard.com"}
    Add-XamlEvent -object $WPFButtonAboutTwitter -event "Add_Click" -scriptBlock {Start-Process "https://twitter.com/jannik_reinhard"}
    Add-XamlEvent -object $WPFButtonAboutLinkedIn -event "Add_Click" -scriptBlock {Start-Process "https://www.linkedin.com/in/jannik-r/"}

    # Side menue
    Add-XamlEvent -object $WPFButtonOpenSideMenu -event "Add_Click" -scriptBlock {
        $WPFButtonCloseSideMenu.Visibility = "Visible"
        $WPFButtonOpenSideMenu.Visibility = "Collapsed"
        $WPFGridContentFrame.ColumnDefinitions[0].Width = 150
    }

    Add-XamlEvent -object $WPFButtonCloseSideMenu -event "Add_Click" -scriptBlock {
        $WPFButtonCloseSideMenu.Visibility = "Collapsed"
        $WPFButtonOpenSideMenu.Visibility = "Visible"
        $WPFGridContentFrame.ColumnDefinitions[0].Width = 60
    }

    ## Groups
    Add-XamlEvent -object $WPFCbGroupSyncAllDevices -event "Add_Click" -scriptBlock {
        $global:SelectedGroupId = $WPFListViewAllGroups.SelectedItem
        Sync-AllDevicesInGroup -groupId $($global:SelectedGroupId).GroupObjectId
    }

    Add-XamlEvent -object $WPFCbGroupOpen -event "Add_Click" -scriptBlock {
        $global:SelectedGroupId = $WPFListViewAllGroups.SelectedItem
        Open-GroupView -groupId $global:SelectedGroupId.GroupObjectId | Out-Null
    }

    Add-XamlEvent -object $WPFButtonRefreshGroupOverview -event "Add_Click" -scriptBlock {
        $WPFTextboxSearchBoxGroup.Text = ""
        Add-InitGroupsGrid
    }

    Add-XamlEvent -object $WPFButtonNavigationGroupsBack -event "Add_Click" -scriptBlock {
        Hide-All
        $WPFGridGroupManagement.Visibility = 'Visible'
        $WPFTextboxSearchBoxGroup.Text = ""
        Add-InitGroupsGrid
    }

    Add-XamlEvent -object $WPFButtonNavigationGroupsBack2 -event "Add_Click" -scriptBlock {
        Hide-All
        $WPFGridGroupManagement.Visibility = 'Visible'
        $WPFTextboxSearchBoxGroup.Text = ""
        Add-InitGroupsGrid
    }

    # Group Creation
    Add-XamlEvent -object $WPFButtonCreateNewGroup -event "Add_Click" -scriptBlock {
        $WPFLabelGroupCreationAction.Content = "New Group"
        $global:GroupCreationMode = "new"
        Get-GroupCreationView  -groupCreationType $global:GroupCreationMode
    }

    Add-XamlEvent -object $WPFButtonMigrateGroup -event "Add_Click" -scriptBlock {
        $WPFLabelGroupCreationAction.Content = "Migrate Group"
        $global:GroupCreationMode = "migrate"
        Get-GroupCreationView  -groupCreationType $global:GroupCreationMode
    }

    Add-XamlEvent -object $WPFButtonCopyGroup -event "Add_Click" -scriptBlock {
        $WPFLabelGroupCreationAction.Content = "Copy Group"  
        $global:GroupCreationMode = "copy"
        Get-GroupCreationView  -groupCreationType $global:GroupCreationMode
    }

    Add-XamlEvent -object $WPFButtonGroupCreate -event "Add_Click" -scriptBlock {
        switch ($global:GroupCreationMode) {
            new {
                Add-MgtGroup -groupName $WPFTextboxGroupName.Text -groupDescription $WPFTextboxGroupDescription.Text 
            }
            copy {
                Add-MgtGroup -groupName $WPFTextboxGroupName.Text -groupDescription $WPFTextboxGroupDescription.Text -groupMember $global:AllGroupMember
            }
            migrate {
                $groupMember = Get-MigrateGroupMember -groupMember $global:AllGroupMember -migrationType $WPFComboboxMigrationType.SelectedIndex -windows $WPFCbWindows.IsChecked -ios $WPFCbIOS.IsChecked -macos $WPFCbMacOs.IsChecked -android $WPFCbAndroid.IsChecked                
                Add-MgtGroup -groupName $WPFTextboxGroupName.Text -groupDescription $WPFTextboxGroupDescription.Text -groupMember $groupMember
            }
        }
        Hide-All
        $WPFGridGroupManagement.Visibility = 'Visible'
        $WPFTextboxSearchBoxGroup.Text = ""
        Add-InitGroupsGrid
    }

    # Group Overview
    Add-XamlEvent -object $WPFButtonDeleteGroup -event "Add_Click" -scriptBlock {
        Show-MessageBoxInWindow -text "Are you shure that you want to delete the group?" -button1text "Yes" -button2text "No"
        $global:message.Add_ButtonClicked({
             $buttonArgs  = [SimpleDialogs.Controls.DialogButtonClickedEventArgs]$args[1]	
             $buttonValues = $buttonArgs.Button
             If($buttonValues -eq "FirstButton")
                 {
                     Hide-All
                     $WPFGridGroupManagement.Visibility = 'Visible'
                     Remove-MgGroup -GroupId $($global:SelectedGroupId).GroupObjectId
                     $WPFTextboxSearchBoxGroup.Text = ""
                     Add-InitGroupsGrid
                 }				
         })
     }

    # Group Member Overview
    Add-XamlEvent -object $WPFButtonSyncAllDevices -event "Add_Click" -scriptBlock {
        Sync-AllDevicesInGroup -groupId $($global:SelectedGroupId).GroupObjectId
    }

    # Group Object
    Add-XamlEvent -object $WPFButtonRemoveGroupMember -event "Add_Click" -scriptBlock {
        Show-MessageBoxInWindow -text "Are you shure that you want to delete the group assignment?" -button1text "Yes" -button2text "No"
        $global:message.Add_ButtonClicked({
            Remove-ObjectFromGroup
        })
    }

    Add-XamlEvent -object $WPFButtonAddGroupMember -event "Add_Click" -scriptBlock {
        Add-InitGroupItemAddGrid
        $WPFBorderAddItem.Visibility="Visible"
        $WPFListViewGroupsViewAdd.SelectedIndex = -1
    }

    Add-XamlEvent -object $WPFButtonAddToGroup -event "Add_Click" -scriptBlock {
        Add-ObjectToGroup
    }

    Add-XamlEvent -object $WPFButtonRefreshGroupMember -event "Add_Click" -scriptBlock {
        Get-GroupViewRefreshed
    }

    Add-XamlEvent -object $WPFButtonAddToGroupClose -event "Add_Click" -scriptBlock {
        $WPFBorderAddItem.Visibility="Collapsed"
    }
}
function Set-UiAction{
    
    Add-XamlEvent -object $WPFListViewMenu -event "Add_SelectionChanged" -scriptBlock {
        if(-not $global:auth) {return}
        if($WPFListViewMenu.SelectedIndex -eq -1) {return}
        Get-NavigationMainPageChange -selectedItem $WPFListViewMenu.SelectedItem.Name
    }
    
    Add-XamlEvent -object $WPFTextboxSearchBoxGroup -event "Add_TextChanged" -scriptBlock {
        Search-Group -searchString $($WPFTextboxSearchBoxGroup.Text)
    }

    Add-XamlEvent -object $WPFComboboxGridCount -event "Add_SelectionChanged" -scriptBlock {
        Add-InitGroupsGrid -clearGroupList $false
        $WPFTextboxSearchBoxGroup.Text = ""
    }

    Add-XamlEvent -object $WPFListViewAllGroups -event "Add_MouseDoubleClick" -scriptBlock {
        $global:SelectedGroupId = $WPFListViewAllGroups.SelectedItem
        Open-GroupView -groupId $global:SelectedGroupId.GroupObjectId | Out-Null
    }

    Add-XamlEvent -object $WPFTextboxGroupName -event "Add_TextChanged" -scriptBlock {
        if($WPFTextboxGroupName.Text -eq ""){$WPFButtonGroupCreate.IsEnabled = $false}else {$WPFButtonGroupCreate.IsEnabled = $true}
    }

    Add-XamlEvent -object $WPFListViewGroupMenu -event "Add_SelectionChanged" -scriptBlock {
        Get-NavigationGroupViewPageChange
    }

    Add-XamlEvent -object $WPFListViewGroupsViewSelection -event "Add_SelectionChanged" -scriptBlock {
        if($WPFListViewGroupsViewSelection.SelectedIndex -eq -1) {$WPFButtonRemoveGroupMember.IsEnabled = $false}
        else {$WPFButtonRemoveGroupMember.IsEnabled = $true}
    }

    Add-XamlEvent -object $WPFTextboxSearchGroupView -event "Add_TextChanged" -scriptBlock {
        if($WPFListViewGroupMenu.SelectedItem.Name -eq "ItemGroupsMember"){
            Search-InItemListItem -searchString $WPFTextboxSearchGroupView.Text
        }
    }

    Add-XamlEvent -object $WPFTextboxSearchAddToGroup -event "Add_TextChanged" -scriptBlock {
        Search-InItemAddList -searchString $WPFTextboxSearchAddToGroup.Text
    }

    Add-XamlEvent -object $WPFComboboxMigrationType -event "Add_SelectionChanged" -scriptBlock {
        if($WPFComboboxMigrationType.SelectedIndex -eq 0){
            ($WPFStackPanelOsFilter.Visibility = "Collapsed")
        }
        elseif($WPFComboboxMigrationType.SelectedIndex -eq 1){
            $WPFCbWindows.IsChecked = $false
            $WPFCbIOS.IsChecked = $false
            $WPFCbMacOs.IsChecked = $false
            $WPFCbAndroid.IsChecked = $false
            ($WPFStackPanelOsFilter.Visibility = "Visible")
        }
    }

    Add-XamlEvent -object $WPFListViewGroupsViewAdd -event "Add_SelectionChanged" -scriptBlock {
        if($WPFListViewGroupsViewAdd.SelectedIndex -eq -1) {$WPFButtonAddToGroup.IsEnabled = $false}
        else {$WPFButtonAddToGroup.IsEnabled = $true}
    }

    Add-XamlEvent -object $WPFListViewGroupsViewSelection -event "Add_MouseDoubleClick" -scriptBlock {
        if($WPFListViewGroupsViewSelection.SelectedItem.ItemType -eq 'Group' -and $WPFListViewGroupMenu.SelectedItem.Name -eq 'ItemGroupsMember'){
            $global:SelectedGroupId = ($global:AllGroupsCollection  | Where-Object {$_.GroupObjectId -eq $WPFListViewGroupsViewSelection.SelectedItem.Id})[0]
            Open-GroupView -groupId $global:SelectedGroupId.GroupObjectId | Out-Null
        }
    }

    Add-XamlEvent -object $WPFListViewGroupsViewAdd -event "Add_MouseDoubleClick" -scriptBlock {
        Add-InitGroupItemAddGrid
        $WPFBorderAddItem.Visibility="Visible"
        $WPFListViewGroupsViewAdd.SelectedIndex = -1
    }


}

########################################################################################
###################################### Navigation ######################################
########################################################################################
function Get-NavigationMainPageChange{
    param(
        [Parameter(Mandatory = $true)]  
        $selectedItem
    )
    Hide-GroupViewAll
    switch($selectedItem){
        ItemHome {
            Hide-All
            $WPFGridHomeFrame.Visibility = 'Visible'
            Get-MainFrame
        }
        ItemGroupManagement {
            Hide-All
            $WPFGridGroupManagement.Visibility = 'Visible'
            Add-InitGroupsGrid
        }
    }
}

function Get-NavigationGroupViewPageChange{
    Hide-GroupViewAll
    switch($WPFListViewGroupMenu.SelectedItem.Name){
        ItemGroupsOverview {
            $WPFGridGroupViewOverview.Visibility="Visible"
        }
        ItemGroupsMember {
            Add-InitGroupItemGridMember -loadNew $false
            $WPFGridGroupListView.Visibility="Visible"
            $WPFStackSyncAllDevices.Visibility="Visible"
            if($global:SelectedGroupId.GroupMembershipType -eq 'Dynamic'){
                $WPFButtonRemoveGroupMember.IsEnabled=$false
                $WPFButtonAddGroupMember.IsEnabled=$false
            }
            else{
                $WPFButtonRemoveGroupMember.IsEnabled=$true
                $WPFButtonAddGroupMember.IsEnabled=$true
            }
            $WPFComboboxAssignmentTypeApp.Visibility="Collapsed"
        }
        ItemGroupsPolicies {
            Add-InitGroupItemGridPolicies -init $false -loadNew $true -groupId $global:SelectedGroupId.GroupObjectId
            $WPFGridGroupListView.Visibility="Visible"
            $WPFStackSyncAllDevices.Visibility="Collapsed"
            $WPFButtonRemoveGroupMember.IsEnabled=$true
            $WPFButtonAddGroupMember.IsEnabled=$true
            $WPFComboboxAssignmentType.Visibility="Visible"
            $WPFComboboxAssignmentType.SelectedIndex = 0
            $WPFComboboxAssignmentTypeApp.Visibility="Collapsed"
        }
        ItemGroupsCompliancePolicies {
            Add-InitGroupItemGridCompliancePolicies -init $false -loadNew $true -groupId $global:SelectedGroupId.GroupObjectId
            $WPFGridGroupListView.Visibility="Visible"
            $WPFStackSyncAllDevices.Visibility="Collapsed"
            $WPFButtonRemoveGroupMember.IsEnabled=$true
            $WPFButtonAddGroupMember.IsEnabled=$true
            $WPFComboboxAssignmentType.Visibility="Visible"
            $WPFComboboxAssignmentType.SelectedIndex = 0
            $WPFComboboxAssignmentTypeApp.Visibility="Collapsed"
        }
        ItemGroupsApps {
            Add-InitGroupItemGridApps -loadNew $true -init $false -groupId $global:SelectedGroupId.GroupObjectId
            $WPFGridGroupListView.Visibility="Visible"
            $WPFStackSyncAllDevices.Visibility="Collapsed"
            $WPFButtonRemoveGroupMember.IsEnabled=$true
            $WPFButtonAddGroupMember.IsEnabled=$true
            $WPFComboboxAssignmentType.Visibility="Visible"
            $WPFComboboxAssignmentType.SelectedIndex = 0
            $WPFComboboxAssignmentTypeApp.Visibility="Visible"
            $WPFComboboxAssignmentTypeApp.SelectedIndex = 0
        }
    }
}


########################################################################################
###################################### UI Actions ######################################
########################################################################################
function Hide-All{
    $WPFGridHomeFrame.Visibility = 'Hidden'
    $WPFGridGroupManagement.Visibility = 'Hidden'
    $WPFGridGroupView.Visibility = 'Hidden'
    $WPFGridGroupCreation.Visibility = 'Hidden'
    $WPFGridGroupViewOverview.Visibility="Hidden"
    $WPFGridAbout.Visibility="Hidden"
}

function Hide-GroupViewAll{
    $WPFGridGroupViewOverview.Visibility="Hidden"
    $WPFGridGroupListView.Visibility="Hidden"
    $WPFBorderAddItem.Visibility="Collapsed"
    $WPFTextboxSearchGroupView.Text = ""
    $WPFTextboxSearchAddToGroup.Text = ""
    $WPFComboboxAssignmentType.Visibility="Collapsed"
}

function Get-GroupViewRefreshed {
    $WPFTextboxSearchAddToGroup.Text = ""
    $WPFListViewGroupsViewSelection.SelectedIndex = -1
    switch($WPFListViewGroupMenu.SelectedItem.Name){
        ItemGroupsMember {
            Get-AllManagedItems
            Add-InitGroupItemGridMember -loadNew $true 
        }
        ItemGroupsPolicies {
            Add-InitGroupItemGridPolicies -loadNew $true -init $true -groupId $global:SelectedGroupId.GroupObjectId
        }
        ItemGroupsCompliancePolicies {
            Add-InitGroupItemGridCompliancePolicies -loadNew $true -init $true -groupId $global:SelectedGroupId.GroupObjectId
        }
        ItemGroupsApps {
            Add-InitGroupItemGridApps -loadNew $true -init $true -groupId $global:SelectedGroupId.GroupObjectId
        }
    }
}

function Add-ObjectToGroup{
    switch($WPFListViewGroupMenu.SelectedItem.Name){
        ItemGroupsMember {
            Add-DirectoryItemToGroup -groupId $global:SelectedGroupId.GroupObjectId -item $($WPFListViewGroupsViewAdd.SelectedItem.Id)
        }
        ItemGroupsPolicies {
            Add-PolicyToGroup -policyId $($WPFListViewGroupsViewAdd.SelectedItem.Id) -groupId $global:SelectedGroupId.GroupObjectId -assignment $WPFComboboxAssignmentType.Text
        }
        ItemGroupsCompliancePolicies {
            Add-CompliancePolicyToGroup -policyId $($WPFListViewGroupsViewAdd.SelectedItem.Id) -groupId $global:SelectedGroupId.GroupObjectId -assignment $WPFComboboxAssignmentType.Text
        }
        ItemGroupsApps {
            Add-AppToGroup -appId $WPFListViewGroupsViewAdd.SelectedItem.Id -groupId $global:SelectedGroupId.GroupObjectId -assignment $WPFComboboxAssignmentType.Text -intent $WPFComboboxAssignmentTypeApp.SelectedItem
        }
    }
    $WPFBorderAddItem.Visibility="Collapsed"
    Get-GroupViewRefreshed
}
function Remove-ObjectFromGroup{
    switch($WPFListViewGroupMenu.SelectedItem.Name){
        ItemGroupsMember {
            Remove-DirectoryItemFromGroup -groupId $($global:SelectedGroupId.GroupObjectId) -item  $($WPFListViewGroupsViewSelection.SelectedItem.Id)
        }
        ItemGroupsPolicies {
            Remove-PolicyFromGroup -groupId $($global:SelectedGroupId.GroupObjectId) -policyId $($WPFListViewGroupsViewSelection.SelectedItem.Id)
        }
        ItemGroupsCompliancePolicies {
            Remove-CompliancePolicyFromGroup -groupId $($global:SelectedGroupId.GroupObjectId) -policyId $($WPFListViewGroupsViewSelection.SelectedItem.Id)
        }
        ItemGroupsApps {
            Remove-AppFromGroup -assignmentId $($WPFListViewGroupsViewSelection.SelectedItem.AssignmentId) -appId $($WPFListViewGroupsViewSelection.SelectedItem.Id)
        }
    }
    Get-GroupViewRefreshed
}



function Get-GroupCreationView{
    param(
        [Parameter(Mandatory = $true)]  
        $groupCreationType
    )
    Hide-All
    $WPFGridGroupCreation.Visibility = 'Visible'
    $WPFStackPanelGroupType.Visibility = 'Visible'
    $WPFStackPanelGroupName.Visibility = 'Visible'
    $WPFStackPanelGroupDescription.Visibility = 'Visible'
    $WPFStackPanelOsFilter.Visibility = 'Collapsed'
    
    
    $WPFCbWindows.IsChecked= $false
    $WPFCbMacOs.IsChecked= $false
    $WPFCbAndroid.IsChecked= $false
    $WPFCbIOS.IsChecked= $false

    $WPFComboboxMigrationType.SelectedIndex = 0
    $WPFComboboxGroupType.SelectedIndex = 0
    $WPFTextboxGroupName.Text = ""
    $WPFTextboxGroupDescription.Text = ""
    $WPFLabelGroupCreationGroupName.Content = ""
    if($groupCreationType -eq 'migrate'){
        $WPFStackPanelGroupMigrationType.Visibility = 'Visible'
        $WPFLabelGroupCreationGroupName.Content = $global:SelectedGroupId.GroupName
    }else{
        $WPFStackPanelGroupMigrationType.Visibility = 'Collapsed'
    }
    if($groupCreationType -eq 'migrate' -or $groupCreationType -eq 'copy'){
        $WPFLabelGroupCreationGroupName.Content = $global:SelectedGroupId.GroupName
    }
}

function Set-UserInterface {
    #Load images for UI
    $iconButtonOpenMenu = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAACwElEQVRIie2TXW8UZRiGr+ft7FCLiXgi8i0KMbSmm+7OduqGEJa2iqQhRI85JnDgL/An+BM8kHMTUUiwAbotkLrZmZ1hCzXKkhBFPvRAsym0bndmHg7cElN2t1uPuQ+fzFzXe79vHniVDSLrB0EQ7FTVr+I4PjM6Ovpgbe553gjwhYicdhxnuVeBWT9IkuRLVf3EGDMbBME+AFU1InJeRD4FLvm+P/C/BcBZoAS8myTJdd/33xORpK+v7zPgIVAAflhcXHy9F8FLVwTg+/4bqnpZRD4EHojIsWw2ey8Mw4NxHM8CO1X1um3bJ9Lp9LPNNsBxnLpt25PALLBHVYuVSuXAyMhILY7jAvBIRI40m81v5+fnX9u0ACCdTj9LpVJTQBHYrao3giAYdF337poEmLRt+7tuko6CNQkwparXgLeTJJkpl8tDruveVdVj/5Fc6CTpKgBwHGdZRE6KyFVguzFmxvO8D3K53C8tyWPgI9u2LxSLxf71/7d95Hap1Wpb6vX6N8AU8Ccw4TjObc/z3heRIrADmF5aWjpVKBT+6bnBWur1eh+w5cXJRATAsqyk24F7auD7/oCqfi8i48AfqjqRy+XuVCqVA6o6C+wSkauNRuNkPp9f2ZSgWq1ubTabF/l3wZ4YY8YzmcxPvu/vBeaAd4CbqVTqeLud6CrotHDlcnmPMWYO2C8i8/39/R8PDQ09bcfo+AZhGG4Dplvw34BCNpu9VyqVdhtjisB+Vf1xZWXleCd4xwZhGG6L43gaGAV+jeO44Lru/VKptN2yrCJwCAhs254YHh7+u9stvNRgYWHhzSiKrrTgtSiKDruue79arb5lWdZMC35rdXV1ciN4W0Gj0TgvIg7wszHm6NjY2O8AURR9DQy24OP5fP6vjeBtBZZlfS4il6MoOprJZB69+NCYc6p6EZjsFf4qPeU5CTIuzFdHs9MAAAAASUVORK5CYII="
    $iconButtonCloseMenu = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAACpklEQVRIie2VTWtUSRSGn1M39IcDZjOgBEz8AD+mISHXm9vQZDTqxBlj3AyCf8CViL/CpX/AhYthlo4MxC8wmDFEm6RTuW0WPYSJoCJGo4wS1KT7kqpykXSQTjrdvfddnlvnOfWew6kL39VA0sphrfUO59yfwNW+vr5iNV4oFPZ4nnddRC76vr/wbY5qBQ7cEZHfReQP55wCiKKoSyn1yDl3xlp7rTavqQL5fD7tnBsBTgCLInJBRKzWutNaOwbsB2biOL5cm9uwRfl8Pp1MJkecc78Ai0qpk77v/xtFUZe19h9gn3NOJ5PJ093d3R9bcjA/P59MJBI3a+HFYnGvtfYRsA94Yow5tRUcwNsOvrS0dAs4C7yrwqempg4C40An8LhcLg/lcrlP9ThbtqhUKiVWVlZuAcPAO2vtyTAMS9PT04dEZAzoACbS6fRQJpP5vF0XNhWoB9daHwYeAh0iMp5KpYYbwaFmBqVSKbG8vPxXFe6cOxWGYWlmZuYIUL35g0qlcqYZ+KYCACKy4crzPLvF92R7e3vd2W06XxtYb9HfwBCwCAwEQTD3bYuAiXK5fLa/v7/ucOs6yGQycRzH51lryS5gVGt9IAiCOWPMCeA18HMqlbo/OTm5s2UHVa0/DXeBAeCVMeZ4Npt9XiwW9xpjxmiwYA0LAMzOzv4Qx/E9ETkGvPQ8b6C3t/fF+hZvPBHGmF+z2ez/WzG23eSenp4vxphzwBTQZYwZjaKow/f9l6y9S8+Ao57njWqtf2zZQVVa63YRGXXO9QH/sTb4N4VCYbdS6iHwEzCrlBr0ff990w6qCoJgqVKp/AY8BQ6KyA2AMAzfKqUGgTmgxxhzoza36f9BLpf7AAw6524rpS5V477vL6yurg6IyP22trYrzfK+a0NfAepxLvgo3BlmAAAAAElFTkSuQmCC"
    $iconButtonLogIn = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAAA1klEQVRIie2TsQrCMBCGc126dhcXX6Iv5OjkY1R9DPUFHHwQQdzV0lnBST+XBGs90xIpVPGHQHL5Lj+5S4z5q3MCYmAGHO2YAnEopxlMeVUWymkGuZKYh3KR5qHErqGcZjBXYosPuGfZ5k2Agx2Zp8m13A8JSIAhsAZ2wBm42NeyBCIPdwK2NjYGkurhKVAoz85p1JBzKoC0bLCpSRjUcCugp1VGbOLNzd8oEhE8XF9E9j4D7dM8IBEvV913a2P0j9ZduYaUY766Nz7Ut//9JWr9Bq0b3AFSVbeeEsxapQAAAABJRU5ErkJggg=="
    $iconIntuneHome = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAABPElEQVRIiWNgGFHAYerzYoepz4tJ0cNIlKr//xmdpr5o/8/wvxwqMsn+jWRhQwPjP4otCG24yvZGRHA+AwNDFJrU2v/cP2MOJCr+INsCt+4X3L85/61hYGDwwK7i/z6OfxyB2/OEP5FsgfOEl+L/WP5uZWBgMCbgwsvM//947M6Ve0a0BXaTXyiyMP3b+f8/gyo+w5HAfSaGfx57c2RuoUswoQs4TntmzMz47zgJhjMwMDAo/mNgOuYw6YUFXgucJr9wYvjHsI+BgUGcBMNhQJiR6d8ep8nPPbFa4DD1WfR/xn/bGRgY+MgwHAa4/zP+3+Q45WkSigUOk5/lM/5nWMTAwMBGgeEwwMLAwDjHYcrTcgYGLJHsOOXZf0pM358jhWImRiRTG9DcAhZiFaJ7ndigHPpBNGrBKKAcAAB1CWAtKzJosQAAAABJRU5ErkJggg=="
    $iconGroupManagement = "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"
    $iconSearch = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAgVBMVEUAAAAknvMnmfUomfUomfUnmfUpmvUjl/MomPYomfUomfYnmPYpmvYomfUpmvUol/Muov8omvcnmfUomfUmmfIomfUpmPQnmfQomPUomfUnmfMomfUnnesrlf8omfUkku0nm/MomfUomPUnmfUomvQpmfUomfUnmvYomfUomfX///+Vwm5wAAAAKXRSTlMAFYLO9M+DFlLx8lRR/bBACz+v/hTwd3WBskHQDQzzDkKAs+95fc2IfxLEHQcAAAABYktHRCpTvtSeAAAAB3RJTUUH5gYUDicDFaCpggAAAJ5JREFUKM+tkNkOgjAQRVs2obILtaDsgt7//0GJpHFq9Enm6eTc5GZmGPtnuGU7jusdPr0f4DXiaPowQpykaZbjZCRFCbnRGYK2KVQac3gksFFrzHAhgcBVY4PWCLp3IIyqXmMClwQDRo0xLHr2hNtGEgGnh8zA2DdNXSHyjSbM0/aSMjQ9GFeL0y6qIP6+evnl33t59vjh15UGtsc8AfKLD4mzmPrPAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIyLTA2LTIwVDE0OjM5OjAzKzAwOjAwYoXoEAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMi0wNi0yMFQxNDozOTowMyswMDowMBPYUKwAAAAASUVORK5CYII="   
    $iconGroup = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAABjklEQVRIie2UzStEURiHn/eORjOXMhsWLNgNNnbWvlbKhuwkxR32kmyEklK23CKZpViwseEfsLIgkxLlo1BYMMPEeS1mxozPubaaZ3X79T7nd+qec6DAv0e8DNWvqv/lLjElaA+gIFFfKDB+0C3JfG6Rl4KX+8SkoCPZREdfb+MKjP2poNZ9bFdwATWCc+TYWwCi2vPFFHozBT95AFauo7AAVAJVorh5NqdePOuz9T0S/SZc8WJ+KDCCA5wrnKHqZHJfKDAOMgNcAhfAtC8UnMjn/Q8EoGpOA6V2fFihU6BEjdUaGwqcNizflT0n/V2qdCFaA1KZ0vQClRMR1or9ybW9vtB9eD5RLZbZVngQWE/4g7OnffIkAOGF+A6izenGgcOIvVjnxhsNugmU59nklTHScTQU3A27jw68n6LtWMRuS/1k0abMdNKYTQCDLnlYHKDCsnQJoMjSjZy8BbKn6P3JOB4suUl/1nlYPEM9wH6/fZ2TCaRvcixiZ9+kyMcBj6RmRTT2yfN40QoU+IU3oc2O2Vns69UAAAAASUVORK5CYII="
    $iconGroupRefresh = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAACVUlEQVRIid2VQWsTQRTHf283qUkTtXhrUSlSSNLc2i8gqBVPBg89etBKlIpQaAW9NLfWVi8epFv04EkICI1Xix9A7K2lKUUQlfaitEqS1TTZ52G3sk3SJS160P9peDPz/82+nXkP/nVJ0GQ6rx21bTsjOBnUGAA9CSjIZ5QlhYW4RAtLWdnx70ta5VwxG8sFApJzlSuIzgJngs+o66oysXYzVvDMJ4FcMRuT1oCcGqlue1rRCS+yrCJPTeqLoUj8A0DtR6lX1byg6AiQBhRlGuEnkAPYF5CyKjOeeVWEsdWNzjly4rQ8fF7NxJY9KuhDIOyfagnw0vISqKrhXFq7cfRNcHq8ffPl5yhXWwGM3UA6rx1ezhFhrG1zqzzZaO7Xb0Bt287g/tDl1a5Oq21zL+dtLC69SFplTViVO21taFOGbzwAENL64l8CSA8A9fjHPwkINQZqkS+BrztIfY+/HgsdiXwDvhezseOw5wt0AyC0Ezl1WEA43HHaHcnmbswHMN4BOGIOHRaghlwEUHjbBFCh4E7qCHk1D+yeVxPkmmvGqyZAqCu6IPAeSCe37FsH9U9s27eBftD1uEQLTYCVYaki4hU4fdQ/VzrXrnlqvnReVGcBVZFxf/luujEJq/JA0LtAFZXx4onoE4al3sr4bE5Dmz32qGceBpkuZjvv+de0LNeJbnvKgwCsCPIMp/7acNxy7RilXhVzCNHrblpQFZlZ24jeb6y8+975lFXOKMwCffutcbW34TQq8FENWhouqX1ZIIMw6LVMBD6BLDlKoVXL/L/0C7qI6rgG7zcJAAAAAElFTkSuQmCC"
    $iconGroupPaging = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAAB3UlEQVRIidWVMWtTYRSGn/MlanJvM7fYChXE3jgouLk5OTTaQcHVQUxT/AN1sVpE9BfopX9BESXVwdWtOLjYNIsZQm0Hl9qbREzOcWiE9N5EmljBvtPh/V7OA985Hx8cdUncyIdRwSAEJofsVVehWC3673pNF08ZPB+hOcCUGGHcTACAqRGaAyBw6iCAQ9U/Bxx9JdY0CCP7m4aVeX9fz/96yAq8wZhrkzrT/uFlBE7GQ+kRm9dVuF4t+msx/+thAGqptl2q3B3bCp41p3F6D5gFxoFtYBV1TyoL2RoMP+SO4i5X57MfgnD3CrgXYLlkTL6L6Y310tj7BOAgmllpnha1T2A5jLI6ljMZ73Or1TjnjCWgAOxIyp0faQaiugjkMMqVkn+t52gNuBqEURkooLqYAPzpiizN5MZtf5O9O8fgYb+cqiw7ZwUzZoda007kfeuW4wAnPG+9X06OR7/9iaEAx7zWRLfcBvjZbMwEYfQgAVDvbLfc6geoDwKo6oVu+RrA4CWwtC9kJij3AUR4mwCoUBwEEeMWQKptj4AWMN17ng+ji/mVxitgDtixjnuaGHL3T038TL3qpKUEZOK+wUf2VmQXsZuVhWxtpHcwSEEYbRqs4tzjjTvZLwC/AJiinuCuqDEqAAAAAElFTkSuQmCC"  
    $iconGroupCount = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAAAN0lEQVRIiWNgGAUDDRjhrIor/xkYGBgYOnQwxcgBUHOYyDZgxIDROBgFlIPRVDTwYDQORgHlAADHmRgNDUab0wAAAABJRU5ErkJggg=="
    $iconDeleteGroupt = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAABBElEQVRIid2TvUpDQRCFv1kJGK+tZTB5qbyDIljedKa9rT6bhRjhoqiNVnpDhCRjEZCQ2WV/SBNPucycb3bPDhy6JKVo2HRT4GantWnrk0kWYNh0mjFcUG1d/fm6fRj+b5mQz5vuTuCqzE5v2/r0evvEZCCqL2XmIIrp9YTsnksB6lwcsHZ2imSAYIYzgN6RLUpVb53wRE+D/pvCMtdcYTkb9d+jAMayEjCFMQm8MpZVHLBRdg4a6AkANDsHEfH2eAGK/W5ReXYgCHBS8ESBBfXfoGCbHf7v7Qd4FiYmdRk3ONb5I/CT4b+o5tUsGfBQn32pcAl8xpwVPhC9uJ/Kd8ZAB6RfZMRSJsaTTHMAAAAASUVORK5CYII="
    $iconMigrateGroup = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAADDUlEQVRIid2VT2hcVRTGf+dOmua9mUAJXRgpyUxpXXRw02xc6aIEF4KO3XdVJRQMVWk6obT1UUEzBlHBhaFkY3YFwbhxYS24caOFUkwXVplJC+oqCM17byZ13ufizaTTeZMpXeqBC4/z5/vO+e5998J/3WxYsBxoNBqLK7KkAu446FCjmi88DcHIXoHpWnQyJFoGDqd9aGBesRYOCOjTRrXwzmCCQG7ai5cMLXQ8t8FWk1z7ekuFzSf3/Ah8IEEPeAtxttH0rxJY8mRgAH7sBYe+PZiuRScNfQW0MPdy47z3A6R7Efrx+0inAIGt5WPv8kZgOz0SJYBJvLK5mP+2i+m6H+VAo4aW0yk52wUHCL34CtJ5YBJ4FlQNvfhKryxm9jZgZvqMa8plCKKxuAIcBm43mv7VxyfXqawaXV+qeX3B+xxxB+xoqR6/niFIjyKArT6F5uxqbiZz9gVAAq9mCIAZgCTXvp6FsbWsy77sd7WT9g0AI3mh6+s5RW4ShNdu3u8vzMfe5dCLeSSLreUj773+vPFmYTP0IoRNZgiEzICR+GDmx9kIbAdY7Kw9rTWx5YjHMLEr8a5Ehv4AeFDYnhoGMszUGk1rzf7MTIC5n5Gec0luFrjTdU8tPSgbbs7ghIwpABP3BN+LZOXe4vhGN7et3GyqBT9lJ0hYT9vQaQI5gFItvGTmbpkxj3HMoGBQwDhmxryZu1X6KLwIwDXlkE4DOHWwegn8pvc18DvwfHEsmiOQE5RsyIVoMKKEEoFcqR6fAcqguxMHvCzBRmA7crbQqfykuH/7xUbsv2HYPLA1AH9L4q1G039z2tt+SehjQIaduzlnD3uaeNyKtWgJVAVagnc3S/7Kkb8YediMThh2FECJft3n+zd+e4Z/SvX4TAd8FPiwUc1f6JuyzwK5ohd/0CFB8Ithq4na34030+u6md8utpWb7WheTtNYasT+xf5bYM8XrVgLK4JlgyN75aSmu4adq1fz3wyKDn0yZ1a0b+vv+DWgImNG0qFO0X2Z3XRifeKAt96r+f/P/gWEqEKE0SihaAAAAABJRU5ErkJggg=="
    $iconSyncAllDevice = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAACL0lEQVRIie2UTUhUYRSGn/ON4nVuKpO6suD6Uy3ctI+kjRBUZBBCWxcSUVvHIvC28Ge2CRFE0C6QWbiIaBEG/UDLWgSFaGPixhghde6M6P1OCzWcaWbuGC19l4fzvc933vudC0eKkEQ1dKY2+y0yKMh50BMgFtVlFT6Afb6UbHrzT4CuicJpG9t5AtJXzUCV1zETu7U44swDeKmcn0m6flVA51S+T8XOAglgVYRpRV/kxZ1valiLbeecbgzXBG4C7cCasVy0hkvAWCbpSkXA7s3Dj0BCIe0QDH1Ltm+Uu0jHxHprfV3sKcpVYAtoADgIqCs9tBdLQiG9NBIfRFytFM/KveYsvl73GoNPQG+5HlMUTWqzfy/zVYdgCJGK5vvyGoP7lcz/AlhkEECE6UqxFJmncj4wVq2n6Bt4qeAr6BlRPft99NjnKEAtKppA0Q6AeMFd+B/mUMOi1aqeh9nmnbzzC2U9M+q27NdNtUOH0XbB6QFAWDlYL3qmXipX7tX4maT7IAogypU9wNuD9agJajLvmlprUbgNoKGdqRXwJZOPj0eZ46ux0vBMoA2RuaW7TXO1ALaAXi8epDsm1lur3dxzgjQwAGRDzHBpT8ke5BTwjeWlNbwCjgM/FR4jzMbs1kK9hLYg8VMCl1W5I9AGZI2agcXRxvdRgD+/2u7JQk9owkdAf6UJdh1kLsQML484ZXcncg+8yY0LGHMDOIdyUgUjyg8M7zS0M6WZH+nQ+g3+T8fG5ZGFPgAAAABJRU5ErkJggg=="
    $iconTotalGroupMember = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAACUklEQVRIid2Vy08TYRTFf3eQR4vySsQoiZ0CCYnFpe58LEhcsQASjP8GKS1xxc4ZCpiYqPE/IBF3JhI2Ji51LTGgtCQGH4kV7czAotPrgraZdobqFs9q5n7nnnPv94T/GqlF7UBVAIYt56ppux8TtrszkiuNA6AqqUXtaKVhnDSQWPJmnJj3GBEdtoq9FZENYERg1PeNjdFHP3oQUS/mPUnY3vS/G6iKaTsPRXXdEH0O4NOZBi7VOcJQ+bBrDkBF1wV9YVrOaq3bIEKBpO2sKDIHFAvJ+CCAmfe+AOebqN8KyfgQW4gZ874D/SqyvJeJz5/YQdJyJ6vigG4yK34i79yMEAe4YH5ybrAoZdBNAFFNt5qu04n6Gpi2swZyt/Zv+G1ju/e7tk3LfY9wJTJb2SosdKeS9u8xpe1DYGCtkD17DxrWQK415Gr5V7WEvhbl9QNQNg6aBq7XCw1ELwYpbee6a0kDJxpwbBDghrSCBhpklIvhLRwBBTgqh85TJcrga5Ah7W5v9bPYwuAAoP3Q7WmK17UCBvqugXKmUpv7ny0MigAqlf7GsL5tkXPK0LCQpuXcQeTVcfx4L5sPSrcxjNeRyWrcyi/E3gTPkCFM7ma6X0YaACSWvJyopmm87PaBwSZq6LJDZKmQiWeDpNB1vTcfywiyAgyYu+4Es+IrPIto4Cmz4ptxdwLoUyRXmI8tNJPC74GI5rPxNDClIjMA7bGjZWC/RlH43Im3CqAq0yhTe9l4BhEN6bVC8MkcyZXGE7a7Y9rO9mWrlKKq/rcn8/TjD3da3rnEW+IhAAAAAElFTkSuQmCC"
    $iconGroupMemberUser = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAABUElEQVRIie2TP0tCYRSHn+O9FhoIRVsKkdAQga2NSeQ36Bu0tBooTY0N/pmaoj6AfYIC98aGFsEytNpEcLiZeu9pqMhM7xWVJp/x/M45D+/L+8IMD2SUpmjWijgdzavI3mdFi4KdrqRCpYkF0awVsbt6Byz1RQ3DlNhDMlhzm/d5CZyO5gcsB1i0u5r1mvcU/FzLoJDExAJXBJ2CQIsu2fXEAsFOA40BUd3El5xYUEmFSoYpMeAKpYnSBC2YyFY5FXz2mp/hyfCfXFBj7bG17ficeKdrn70ch+q98Xqmudx2jEMHKVZXA7fsiz2SIJzTgNl5OwA9AiIACmVE0uJ/LwJIe35X0VMg+jVWFZGMWoHzpxNpDRWEc9aK2dYbhA3vw/9F4d6BRC218Ppd+/VMzbZejrscQGDTgIvemq+vY2fc5T3EhwvAPwXBnJtgxv/zAQJ3aVeO+h5sAAAAAElFTkSuQmCC"
    $iconGroupMemberDevices = "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAABmJLR0QA/wD/AP+gvaeTAAABMUlEQVQ4ja2UsUoDQRRFz2QnUSNZ1EKNTdIIFvoBgr2VnR8hWNrkF2wEv8De0loEK3sj2ghaiASLKOrGTXbmjUVcCKybHUJuMwx35rz73sDAlKRo3T3Xw3JDl7LmWi2gsaC57QyIEpfxv/rCR8+ecLx5pCuBalwdNidKcf0YcXD+2gTQKLAyEQc3ElIDWFGFly7bfZ7eDAD1mqJagfsO7K+v7M6ddR80gGTbz+gzEt6/hwfTFWCmFMyLY+MvUTHI4LAuv6I3yArTAjlMEUg8hm3cEJYPcmA9hm0EknEgB3QjS1AQKjaWRPJnoGi1b0AtFyXaWgpXF2d1NR/kqe3Tlwsce3m+9gX1Exlb1hsUiyUlKaAcKAYjr/TP55GTyLif2AqxFeqhYqepSfexlZ4vp1C/cTCFm76WjAIAAAAASUVORK5CYII="
    $iconGroupNavigationPolicies = "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAABmJLR0QA/wD/AP+gvaeTAAACJ0lEQVQ4jYWST0hUURTGf/e+J07+w5oIF0ZFQdIigv6sIjIXRi6CWRQEUbQcEFq2K1pEi2ohDu5atCwGNxK1KyUKJwsiMSIjsj+QDjJDU43v3XNavDfqqG+8cDb3O+e73/edawAu3i/1q9FDbHKstaMPLnV83AjzAcS4q02eOe170eXetKG92fC9rMz/VgCWQsWpC4G7iUQIXO7dwp7tXqKap++rPJ+uJuJ+zIMqiCbbMmqQZDgicqo4VcIGnU4V1wCPFKkgYhA1DYggbKApUsTm1kShkbeISBSnEVmiIlHCZBgbyVZEogySShRSUmrJ5XIZ1fUZWIBQhJAoh43qx+cPyN8i+93bk6qaHxkZOTM0NHQgl8vtq7MWCjgHskEGqsrc9BtSlTIpOAUgImPWWlT1MTCwSpEiqoiwrlQNrdt2ANDc2l7p6el57XleEL/zst6aarx+6ioMAmYmxih+mwXg3PkLQV9f35FMJvMqnr82PDx8a9laoBJ/yjWbUjB+U2QR8DzjAfi+b+MWUdWlZUXVIPrVa0PGa2L3sX7a0l0Y4NHDvCsUCuP5fP5gTHRncHDwRp2iwtc/zC3WrK8c46p0FH8hxqNSmu+cnJw/sQoeAG6ubE2FJzPlZXRXp8f13jaujJYA2Okd5qfbytmWqYluu3DcWnsUCFS1qzbjA/wLuQf6rHb5ZTG0t8crbVWnZYBPLg3A7FL6RXdqoTubzU7Fre9qM/8BE/86JRnVtJMAAAAASUVORK5CYII="
    $iconGroupNavigationCompPolicies = "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAABmJLR0QA/wD/AP+gvaeTAAABv0lEQVQ4jYWSwUtVQRTGfzP3mqYPM3XRqjIICikjaClYBLVxWyurTas2rfoPIgiT2oeL1kGLIooiaiOEq8IIM0gKiQh7+LiK1zdzTou578XLO/cNnM35hh/f980YgJn5jQtq9BRdjrX2yaOrg1/KtBRAjL/Zk5iLaRKWR4YNg32GtYbyO1MAdpzi1TvgXhSEwLWzexkbTaJuXi7lvPuUR/W04KAKovFYRg0SlwPIq+JVcRU3vSq+Qg+OVBAxiJoKELgKT8ER3aOJQlW2ABLFa4BFHYni4vK/jkSqOxAF3y2aE8EReogd1+UxChB4DxK5+OrrDOtuiYmjzE68PjHbqZpnd89/nLYBpIgqIpSP+l3wxKScO3wdW5ixLdvh+Smd/xNbY7k0fhtQpFAtQFOl+JSUDsDpA9OkthdrLJfH7/ArW+HN6sPOjvJmKDJWtgI9SS9XTt4ndxk/s+UOSBvUVGHx+xY/6s1SUCbC+7XHjPQfpC+p7YK0QU6FF58b7eWhoYRbkzVuPN0AYOq4Y/8APF+ZK7fcAm075kDftpardWcfLGzWcq8NgPXNY2e2d4ZG9w18W+7f86feEduYDwB/AYjz/zbCqyVFAAAAAElFTkSuQmCC"
    $iconGroupNavigationOverview = "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"
    $iconGroupNavigationApplications = "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAABmJLR0QA/wD/AP+gvaeTAAABNklEQVQ4ja2TMU7DQBBF32xyAkQOEKhScxJ6GprkTLihoecQqVObyhdIRA0hO5/CjuRZbxQJMeWz/fx3vhb+aQzg6fWzA5YjuMNoJF7Cy8YGsRY8jHD39nxzPwfI0pIwhgmEIpUNJPA7gLOo8AghTBawzDGs8PQzBzh58efzh2WiKh2Jjq5dcYRW8j3JAse1N0utbKrqRVnNGCbpcCJ/JM0Cd+WPOby7sa2KfrKHdjB2QJN9wjcZX+OhNYCmF7lPovYbKXmNjRJ95+KhGSCYtDnUUPKLIkAG5U5rLIiOJ98EmuyQoZ25As/JtjM44LqtJxLrMXT3FpLShLMHf0yyVeFphqPlsgUkX5jFdiQWZqxg0trlHQ3rvsqC6Ku2bNTfqyusEOXOhlt8/rVRb1/EWILuQsi/zS9LeaMYZFIZsAAAAABJRU5ErkJggg=="
    $iconCopyGroup = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAAAuklEQVRIidWUyxGCMBRFz2PcUYI60o99pAUsQTqQSmwHB1pg/Vw4aCZDhATEyVll8rn3fZJA6ohvoah6jRFU6FDM45LfAbLYyHwIHESo19Z9U1S92tmvnoHLbhicrv1ZoEbYhwi4NXf5ZCDcQsVfx77XPLM3hopbHCcNfsUsg6bMpSlz75tZbLCE7a6py1hJ7Lm5X8n/MrAjHCKP+QDTb3Jw03z43sl2JVLoFui0kwYoJtKkRdTERJUGT1tnMuEQslpmAAAAAElFTkSuQmCC"
    $iconAdd = "iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAABmJLR0QA/wD/AP+gvaeTAAAAbUlEQVRoge3Xuw3AIAwAUSdtlmDLzMCWWYKabJBPYXSy7tVI9okGIiRJUr7Wx2x9zOw5e/aAVQyhMYTGEBpDaAyhMYSmTMj25dCKZ/iT6zxe9yxzI+n8WP1kCI0hNIbQGEJjCI0hNGVCJElSRNy7aQ6wukLO8wAAAABJRU5ErkJggg=="
    $iconDelete = "iVBORw0KGgoAAAANSUhEUgAAAPAAAADwCAYAAAA+VemSAAAABmJLR0QA/wD/AP+gvaeTAAAIEklEQVR4nO3dO24cRxRG4b8JBdRwBc5GSpx6NYYA2zTITciZx5m1CFkQAQFckUJ7Qi/AGjGwWQ6EIilyHt099bi36nwZmdwip850JY2SAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAX0IYai8BzjnfQ24Xv3zzaSWFb9efz37Savi39nrg0CqcLJ9v/pCGv9evF7/UXs4cLgP+Eq9+/fJTuCZiTHYXr37+8ovhjceI3QX8dbwREWOCJ/FG/iJ2FfD2eCMixgg74418Rewm4P3xRkSMPQ7GG/mJ2EXA4+KNiBhbjI438hGx+YCnxRsRMR6YHG9kP2LTAc+LNyJi6Ih4I9sRmw34uHgjIu7a0fFGdiM2GXCaeCMi7lKyeCObEZsLOG28ERF3JXm8kb2ITQWcJ96IiLuQLd7IVsRmAs4bb0TETcseb2QnYhMBl4k3IuImFYs3shHxSe0FKIRBQS/KDRxeLU83b7UK9f92pLEKJ8vTzTsVi1dSCN9YeBWx/iYehrC+WVxIel9ups6Xzz990Co8KzYTecQn76DzckPD9frl4lLDEMrN3K76N8id4kcgieO0c7X2zIuzH/X98F+5mbvZCVgiYoxHvJKsBSwRMQ4j3jv2ApaIGLsR71dsBiwRMZ4i3ifsBiwRMe4R71a2A5aIGMS7h/2AJSLuGfHu5SNgiYh7RLwH+QlYIuKeEO8ovgKWiLgHxDuav4AlIm4Z8U7iM2CJiFtEvJP5DVgi4pYQ7yy+A5aIuAXEO5v/gCUi9ox4j9JGwBIRe0S8R2snYImIPSHeJNoKWCJiD4g3mfYClojYMuJNqs2AJSK2iHiTazdgiYgtId4s2g5YImILiDeb9gOWiLgm4s2qj4AlIq6BeLPrJ2CJiEsi3iL6Clgi4hKIt5j+ApaIOCfiLarPgCUizoF4i+s3YImIUyLeKvoOWCLiFIi3GgKWiPgYxFsVAUdEPB3xVkfADxHxeMRrAgE/RsSHEa8ZBLwNEe9GvKYQ8C5E/BTxmkPA+xDxPeI1iYAPIWLiNYyAx+g5YuI1jYDH6jFi4jWPgKfoKWLidYGAp+ohYuJ1g4DnaDli4nWFgOdqMWLidYeAj9FSxMTrEgEfq4WIidctAk7Bc8TE6xoBp+IxYuJ1j4BT8hQx8TaBgFPzEDHxNoOAc7AcMfE2hYBzsRgx8TaHgHOyFDHxNomAc7MQMfE2i4BLqBmxdEu87SLgUlbhZHm6eadB58VmBl1JUumZ65vFhVbDbbGZHSPgkqo8iUviyVsaAZfWbMTEWwMB19BcxMRbCwHX0kzExFsTAdfkPmLirY2Aa3MbMfFaQMAWuIuYeK0gYCvcREy8lhCwJeYjJl5rCNgasxETr0UEbJG5iInXKgK2ykzExGsZAVtWPWLitY6ArasWMfF6cFJ7ATDsI1/w1vEBWWbhCG3hknHsRMBWVY83ImLLCNgiM/FGRGwVAVtjLt6IiC0iYEvMxhsRsTUEbIX5eCMitoSALXATb0TEVhBwbe7ijYjYAgKuyW28ERHXRsC1uI83IuKaCLiGZuKNiLgWAi6tuXgjIq6BgEtqNt6IiEvjbaRS4uVmJeMNurq74KyI4dXydPNWq8C+KoR/dAnxyVvylkCF6/XLxeX6ZnEh6X2xsYPOl88/fdAqPCs2s2McoXOzcLm2hUvGkQUB52Qh3tprIeKsCDgXS/HWXhMRZ0PAOViMNyLiphBwapbjjYi4GQSckod4IyJuAgGn4ineiIjdI+AUPMYbEbFrBHwsz/FGROwWAR+jhXgjInaJgOdqKd6IiN0h4DlajDciYlcIeKqW442I2A0CnqKHeCMidoGAx+op3oiIzSPgMXqMNyJi0wj4kJ7jjYjYLALeh3jvEbFJBLwL8T5FxOYQ8DbEuxsRm0LAjxHvYURsBgE/RLzjEbEJBBwR73REXB0BS8R7DCKuioCJ93hEXE3fARNvOkRcRb8BE296RFxcnwETbz5EXFR/ARNvfkRcTF8BE285RFxEPwETb3lEnF0fARNvPUScVfsBE299RJxN2wETrx1EnEW7AROvPUScXJsBE69dRJxUewETr31EnExbAROvH0ScRDsBE68/RHy0NgImXr+I+Cj+AyZe/4h4Nt8BE287iHgWvwETb3uIeDKfARNvu4h4En8BE2/7iHg0XwETbz+IeBQ/ARNvf4j4IB8BE2+/iHgv+wETL4h4J9sBEy8iIt7KbsDEi8eI+AmbARMvdiHir9gLmHhxCBHfsRUw8WIsIpZkKWDixVREbCRg4sVcnUd8UnsBCmFYnm7eqeQHEHS1/nz2A/E2YDXcrj8vLhV0VW7o8Gp5unmrEKo/AOsHPAxBQ/hYbmC4Xr9cXGo13JabiaxWw+36ZnEh6X2xmYP+1DCEYvN2LsOI5Zt/XkvD73mncGxuWrnj9Gr9+uy3zDNGMROwlDti4u1C/ojNxCsZC1jKFTHxdiVfxKbilQwGLKWOmHi7lD5ic/FKRgOWUkVMvF1LF7HJeCXDAUvHRky8UIqIzcYrGQ9Ymhsx8eKB+RGbjldyELA0NWLixRbTIzYfr+QkYGlsxMSLPcZH7CJeyVHA0qGIiRcjHI7YTbySs4ClXRETLybYHbGreCWHAUuPIyZezPA0YnfxSk4DlmLE+o54Mdt9xH95jNc/A69zwTn2EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA3fkfTzAn4xpMcy0AAAAASUVORK5CYII="
    $iconAbout = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAABZklEQVRIidWVPU7DQBCFn4OSAhEkqCkRByA0cAMoiKMoSsEZOAcEcQQOkdQcgZ86/KTB9EiRaCDio/CEWM6uvQlVnrSytfP2Pc/s7lhadURFQaAmqSWpKWlf0o6F3iU9SupL6kdR9LWwM9AGRpTjFWgtIrwGXAcI53EFVEIMXOJvllHdRgwMHbxeSFlc4tsO7pbF8oh94jXcNW9b/ARIbBzbXMfBfyE9HHMGXQcZoG7xJJuVzW161nSmutlNaXoqNwbQ7IhmseFZ86eVNWh4yHlMJJ3be9fDOZibAcaedPM4M/4h8OnhjJc1uDHuLvBRwHMaPAUY7Bn3toQ3nOpm9+A+oP4jex6V8O5cBoMAgwmApPUS3rwWUCW9JP/FCNdFM5NW0coMz4cf4LQwN9KuuKzBRUnpJKAC9Ioy8Xz5JSHtOmMUE7Ynz4CvzZT+MquSYqW9paFZP0okPSg9LYMoir6Dv3zl8AsKfI8ggolmqwAAAABJRU5ErkJggg=="
    $iconLinkedIn = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAABJ0lEQVRIie2Sr07DUBSHv9N1YmuxGCAMFG5BIJBYeAhCSOpm2wUMju0FyOawPMEegQSFJYHQsTkUCd34k/UgCKQ0KdDugoHP3T/n9+Wee+CfL5DkYrEVbQl0EeaKhCkMUbx+0+m97VkpXado+Gs58yJ0k3tW+kLR8AQLmYIUV4juCBxNY8sUiGon9N3j63G1ATwXFdhZB2pZu0ut0Y1KtA5SNi5AdUWFk9Sg5SazRSrsh4EjYeC8G+xJPBsGjqiySRxvMK5WEF0Fucgt+Ix+0+k9Pbpn4YE8hL57LqhvVLB8GK2VK6O7Wvt+G6A0iU+NCrREXcBGqQNc7s3cGhUQf//niwly8OOCD0+ttSM1EZoc7d9tkcLQQOYgU4DiTSkZIOpNUf8XeQFjeFM4aqoyewAAAABJRU5ErkJggg=="
    $iconTwitter = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAACA0lEQVRIie2SP2gTcRTHP+9y1+Qutf4dxCEJHXTUooOtWLqJILqIgrMgAXFqbMUlXUzqqCCosyIu4uBSFBHxz6A4ZQnFFrVasQ62uYsxXp5L06bJ5Uy66NDv+H3vfb7v9/jBhv61pNuBXVl1LNsbFzgDJICPCnd8y8ltXsR3Y95RhH2zY/GJloBk3r1mOU5m+oJU2sF7bO8JcDCg/B7YDiyYyMj0mPMJwFgpqwpC+nfZu79n8tumoADL9sbbwAH6gajC06rqibq5GiCiAovA8QrOu8RV71AzYfksYYqBRHdsdW41zKwqOeleFzjfYL0CvR2pmc8r0eicWfWWgEhIgM5edCKIaN0wG6u9ZeeSa7t7QQ4vW4Mgg77hY1a9vywPIKVGODSeCHBjXqYGE8DLDmgBqn1pdtYEqCH9BvIYGFpfAG9DA3o9Oy3wYp1wFB6FBhSyUpopO8MKZ4HXXfLnq+X4g2bTbDZStncPOADs7IYuIlc+Z6XlJxjNRtX300ARsDumK1MzKftGYHC7mWTOHRBDToNmghZpUKEn4o8UR/sWgoprTrT/plrz35f6TMvcbfh6TNFzoXBlyqByqji67Ue7lpUXpPKlI4jkgIGQbev6IKqXZ37G75KVWlhjy4mSeW9IqJ0UQ4ZVSQBbFL6KMicGb1B96JTjzwpZ+dXBIhv6D/QH8mKgEDaLDDsAAAAASUVORK5CYII="
    $iconWordpress = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAAD8ElEQVRIid2VX4iUVRjGf+/5Znfn+2azxT/4J9dZKQpUSDKKErUugoLIyXDcQiMCk4T+XLRuRhcDEbVtGHQRtOJVRbUG6yaBN1uURX/MyEgrMXe2VSMoKXd3vtnd+c7Txcza6mxSl3Uun/Oe53nf5z3nPfBfX3apzeUFNZbScU7mc+CuAy2uHTsF/iuT2xeVw31HCzbxrwWyXaUNhrqBH83oRcnBkrvsFEA4OdJqLljjIW/GUjnrGOqI+v6ZQEEuG8bPG369KdiapCq/usS2gt0CtAENiCHBQCrwPYlSc1CyG3N9xVK4k4L56XSuLvMq+Y0Y62TJ3S5x34I9DqwEWoAMxjIzHkm8O2LyeVVsHfI3tUXxcxfzXSBQtcWvD5w2gnujRnypPjlJw5OT0R+VhiQnaUNb11huRouWF9Q4FpaOmdyDiSUNzuweZOdA90ocx9nXJs3CSGr4JiCbCqPwxKM2Xk1w5FZwPXNbomWHt9nkBRWU0nEOOBmV05/91Nk8UNyR2Y40D5hvxgqkuNiZ2VbckdkuNAeYD1hSHlt3PlufGnTY0Nnf4/V1Fsl8zozeUljqvOplNQGYYxBoAhaYeGzxLoW16O+BEECyFygoVWXzD2HqBXJ1AsAqlByUaJ8sx3dWeZK908yclarEdwF47E0gqe1cm02XblteUDNwhyrJR4LrZxBwCxsZP4NZq0n3Awx2zvoB+OZ8iDQOMNyZOYMYOI8Hlo7T5ZVAW1MwfhpYNFMFUywp4ParXzw3F0DQWythhDg6MGWTodemTjR4DsmUq+e6QMD/PEHTIsyGgMbJJNUOECTB3ppF+2kqLwgm4ocBSkGmTzCKOHZiR3haaCNQLJNeDJypFzD3JQrWmvR+NXNtATj5VPo4cARpLy7ZZFbFf+mwMbA+zPYv6Y5vBpYYNmBya2UcqhMwT7+HPFIP4IEblnaduwbAzPYQRwfA2oGVV3aPrABw5l/3xn4nnwe8J9mDs7wT/XUCUTncVx1cQQvQU0WDLQCDbeErFo5kqY4LEh9sruKZgXmXh1+AbZTZLjwLkW+d3RLWCxwt2IScdaBkdwLPgH0g2ExBjrwlImj/q1+6bwr/7ezoauCIl14y53oMe2LqFV/UZBjqiPow1xegtxK02eC9pVF5ddVDmyZAazYcrb5gF5StogccvA30DnZm3p3OWXdNi6VwJ+Y+dfChx78TldKfZ58dW4gwIAZKwHdOdgWAfBIpZZ+Y2cfFOHr6Yr6/nZRtXWM5QbfDhjD1evmDzXHzMMBI8+gSV3FrcJZHvhVZR/HJTP9MPJf8Mle9qoba4MrJWCVVv0yDYZkddqJ/dkvYP93z/9/6E+aHsqs7a3d1AAAAAElFTkSuQmCC"
    $iconBlog = "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"

    # Add image to UI
    $WPFImgHome.source = Get-DecodeBase64Image -ImageBase64 $iconIntuneHome
    $WPFImgButtonCloseMenue.source = Get-DecodeBase64Image -ImageBase64 $iconButtonCloseMenu
    $WPFImgButtonOpenMenue.source = Get-DecodeBase64Image -ImageBase64 $iconButtonOpenMenu
    $WPFImgButtonLogIn.source = Get-DecodeBase64Image -ImageBase64 $iconButtonLogIn
    $WPFImgItemHome.source = Get-DecodeBase64Image -ImageBase64 $iconIntuneHome
    $WPFImgItemGroupManagement.source = Get-DecodeBase64Image -ImageBase64 $iconGroupManagement
    $WPFImgSearchBoxGroup.source = Get-DecodeBase64Image -ImageBase64 $iconSearch
    $WPFImgNewGroup.source = Get-DecodeBase64Image -ImageBase64 $iconGroup
    $WPFImgRefresh.source = Get-DecodeBase64Image -ImageBase64 $iconGroupRefresh
    $WPFImgMaxGroups.source = Get-DecodeBase64Image -ImageBase64 $iconGroupPaging
    $WPFImgGroupCount.source = Get-DecodeBase64Image -ImageBase64 $iconGroupCount
    $WPFImgButtonAbout.source = Get-DecodeBase64Image -ImageBase64 $iconAbout

    
    
    # Group Overview
    $WPFImgDeleteGroup.source = Get-DecodeBase64Image -ImageBase64 $iconDeleteGroupt
    $WPFImgMigrateGroup.source = Get-DecodeBase64Image -ImageBase64 $iconMigrateGroup
    $WPFImgCopyGroup.source = Get-DecodeBase64Image -ImageBase64 $iconCopyGroup
    $WPFImgTotalGroupMembers.source = Get-DecodeBase64Image -ImageBase64 $iconTotalGroupMember
    $WPFImgTotalGroupMembersUser.source = Get-DecodeBase64Image -ImageBase64 $iconGroupMemberUser
    $WPFImgTotalGroupMembersDevices.source = Get-DecodeBase64Image -ImageBase64 $iconGroupMemberDevices
    $WPFImgGroupNavigationPolicies.source = Get-DecodeBase64Image -ImageBase64 $iconGroupNavigationPolicies
    $WPFImgGroupNavigationCompliancePolicies.source = Get-DecodeBase64Image -ImageBase64 $iconGroupNavigationCompPolicies
    $WPFImgGroupNavigationMember.source = Get-DecodeBase64Image -ImageBase64 $iconGroup
    $WPFImgGroupNavigationOverview.source = Get-DecodeBase64Image -ImageBase64 $iconGroupNavigationOverview
    $WPFImgGroupNavigationApplications.source = Get-DecodeBase64Image -ImageBase64 $iconGroupNavigationApplications
    $WPFImgGroupGreation.source = Get-DecodeBase64Image -ImageBase64 $iconGroupNavigationOverview

    #Group Grid view
    $WPFImgGroupGreation.source = Get-DecodeBase64Image -ImageBase64 $iconGroupNavigationOverview
    $WPFImgSyncAllDevice.source = Get-DecodeBase64Image -ImageBase64 $iconSyncAllDevice
    $WPFImgSearchGroupView.source = Get-DecodeBase64Image -ImageBase64 $iconSearch
    $WPFImgRefreshGroupMember.source = Get-DecodeBase64Image -ImageBase64 $iconGroupRefresh
    $WPFImgAddGroupMember.source = Get-DecodeBase64Image -ImageBase64 $iconAdd
    $WPFImgRemoveGroupMember.source = Get-DecodeBase64Image -ImageBase64 $iconDelete
    $WPFImgSearchSearchAddToGroup.source = Get-DecodeBase64Image -ImageBase64 $iconSearch

    #About
    Add-XamlEvent -object $WPFBlogPost -event "Add_Click" -scriptBlock {Start-Process "https://jannikreinhard.com/2022/07/07/intune-tool-box-rebuild-of-intune-in-powershell/"} 
    Add-XamlEvent -object $WPFReadme -event "Add_Click" -scriptBlock {Start-Process "https://github.com/JayRHa/IntuneToolBox"} 

    $WPFImgTwitter.source = Get-DecodeBase64Image -ImageBase64 $iconTwitter
    $WPFImgWordpress.source = Get-DecodeBase64Image -ImageBase64 $iconWordpress
    $WPFImgLinkedIn.source = Get-DecodeBase64Image -ImageBase64 $iconLinkedIn
    $WPFImgBlog.source = Get-DecodeBase64Image -ImageBase64 $iconBlog

    $iconJannik
    
    # Fill combo box    
    $valueGroupCount = "10", "100", "500", "1000", "5000", "10000", "All"
    foreach ($value in $valueGroupCount) { $WPFComboboxGridCount.items.Add($value) | Out-Null }
    $WPFComboboxGridCount.SelectedIndex = 2

    $valueGroupMigrationType = "Migrate to User group", "Migrate to Device group"
    foreach ($value in $valueGroupMigrationType) { $WPFComboboxMigrationType.items.Add($value) | Out-Null }
    $WPFComboboxMigrationType.SelectedIndex = 0

    $valueGroupType = "Security" # Add M365
    foreach ($value in $valueGroupType) { $WPFComboboxGroupType.items.Add($value) | Out-Null }
    $WPFComboboxGroupType.SelectedIndex = 0

    $valueAssignmentType = "Include", "Exclude"
    foreach ($value in $valueAssignmentType) { $WPFComboboxAssignmentType.items.Add($value) | Out-Null }
    $WPFComboboxAssignmentType.SelectedIndex = 0

    $valueAssignmentTypeApp = "required", "available", "uninstall"
    foreach ($value in $valueAssignmentTypeApp) { $WPFComboboxAssignmentTypeApp.items.Add($value) | Out-Null }
    $WPFComboboxAssignmentTypeApp.SelectedIndex = 0


    
    

    # Enable icons
    $WPFItemHome.IsEnabled = $false
    $WPFItemGroupManagement.IsEnabled = $false
    $WPFItemHome.IsSelected = $false
    $WPFItemGroupManagement.IsSelected = $false

    # Reset lables
    $WPFLableUPN.Content = ""
    $WPFLableTenant.Content = ""
    $WPFImgButtonLogIn.Width="25"
    $WPFImgButtonLogIn.Height="25"

    if(-not(Test-Path ("$global:Path\.tmp\deviceImg.png"))) {
    $imagePath = ("$global:Path\.tmp\deviceImg.png")
    [byte[]]$Bytes = [convert]::FromBase64String($iconGroupMemberDevices)
    [System.IO.File]::WriteAllBytes($imagePath,$Bytes)
    }

    if(-not(Test-Path ("$global:Path\.tmp\memberImg.png"))) {
        $imagePath = ("$global:Path\.tmp\memberImg.png")
        [byte[]]$Bytes = [convert]::FromBase64String($iconGroupMemberUser)
        [System.IO.File]::WriteAllBytes($imagePath,$Bytes)
    }

    if(-not(Test-Path ("$global:Path\.tmp\policyImg.png"))) {
        $imagePath = ("$global:Path\.tmp\policyImg.png")
        [byte[]]$Bytes = [convert]::FromBase64String($iconGroupNavigationPolicies)
        [System.IO.File]::WriteAllBytes($imagePath,$Bytes)
    }

    if(-not(Test-Path ("$global:Path\.tmp\compPolicyImg.png"))) {
        $imagePath = ("$global:Path\.tmp\compPolicyImg.png")
        [byte[]]$Bytes = [convert]::FromBase64String( $iconGroupNavigationCompPolicies)
        [System.IO.File]::WriteAllBytes($imagePath,$Bytes)
    }

    if(-not(Test-Path ("$global:Path\.tmp\appImg.png"))) {
        $imagePath = ("$global:Path\.tmp\appImg.png")
        [byte[]]$Bytes = [convert]::FromBase64String($iconGroupNavigationApplications)
        [System.IO.File]::WriteAllBytes($imagePath,$Bytes)
    }
}