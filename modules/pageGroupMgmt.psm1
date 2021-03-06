<#
.SYNOPSIS
Helper for Group management Module
.DESCRIPTION
Helper for Group management Module
.NOTES
  Author: Jannik Reinhard
#>

########################################################################################
################################### Search  Engine #####################################
########################################################################################
function Search-Group{
    param(  
        [String]$searchString
      )
    if($searchString.Length -lt 2) {
        Add-InitGroupsGrid -clearGroupList $false
        return
    }
    if($searchString -eq '') { 
        Add-InitGroupsGrid -clearGroupList $false
        return
    }

    $global:AllGroupsObservableCollection = @()          
    $global:AllGroupsObservableCollection = $global:AllGroupsCollection | Where `
        { ($_.GroupName -like "*$searchString*") -or `
        ($_.GroupObjectId -like "*$searchString*") -or `
        ($_.GroupEmail -like "*$searchString*") }

    Add-GroupsToGrid -groups $global:AllGroupsObservableCollection
}

function Search-InItemListItem{
    param(  
        [String]$searchString
      )

    if($searchString.Length -lt 2) {
        Add-InitGroupItemGrid
        return
    }
    if($searchString -eq '') { 
        Add-InitGroupItemGrid
        return
    }

    $global:AllGroupsItemObservableCollection = @()          
    $global:AllGroupsItemObservableCollection = $global:AllGroupMember | Where `
        { ($_.ItemName -like "*$searchString*") -or `
        ($_.ItemType -like "*$searchString*") -or `
        ($_.ItemId -like "*$searchString*") -or `
        ($_.ItemDetails -like "*$searchString*") }

    $items += $global:AllGroupsItemObservableCollection | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
	$WPFListViewGroupsViewSelection.ItemsSource = @($items)
}

function Search-InItemAddList{
    param(  
        [String]$searchString
      )

    if($searchString.Length -lt 2) {
        Add-InitGroupItemAddGrid
        return
    }
    if($searchString -eq '') { 
        Add-InitGroupItemAddGrid
        return
    }

    $global:AllGroupsItemAddObservableCollection = @()          
    $global:AllGroupsItemAddObservableCollection = $global:AllGroupsItemAddCollection | Where `
        { ($_.ItemName -like "*$searchString*") -or `
        ($_.ItemInfo -like "*$searchString*") }

    $items += $global:AllGroupsItemAddObservableCollection | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
	$WPFListViewGroupsViewAdd.ItemsSource = @($items)
}

########################################################################################
##################################### All Groups #######################################
########################################################################################

function Add-InitGroupsGrid{
    param (
        [boolean]$clearGroupList = $true
    )
    
    if(-not $global:auth) {return}
    if(($global:AllGroupsCollection ).Count -eq 0 -or $clearGroupList) {
        $global:AllGroupsCollection  = @()

        $allGroups = Get-ManagedGroups
        $allGroups = $allGroups | Sort-Object -Property DisplayName
        
        foreach ($group in $allGroups) {
            $groupType = "Assigned"
            if($group.groupTypes[0] -eq "DynamicMembership") {$groupType = "Dynamic"}
            $colornumber= Get-Random -Maximum 9
            # Create object
            $param = [PSCustomObject]@{
                GroupColor                  = $global:GroupColorSelection[$colornumber]
                GroupNameShort              = ($($group.displayName).Substring(0,2)).ToUpper()
                GroupName                   = $group.displayName
                GroupObjectId               = $group.id
                GroupMembershipType         = $groupType
                GroupEmail                  = $group.mail
                GroupSource                 = "Cloud"
            }
    
            $global:AllGroupsCollection  += $param
        }

    }
    Add-GroupsToGrid -groups $global:AllGroupsCollection 
}

function Add-GroupsToGrid{
    param (
        $groups
    )
    $items = @()
    $items += $groups | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
	$WPFListViewAllGroups.ItemsSource = $items
	$WPFLabelCountGroups.Content = "$($items.count) Groups"
}
########################################################################################
################################### Group Creation #####################################
########################################################################################
function Add-MgtGroup{
    param (
        [Parameter(Mandatory = $true)]
        [String]$groupName,
        [String]$groupDescription = $null,
        [array]$groupMember = $null
    )
    $bodyJson = @'
    {
        "displayName": "",
        "groupTypes": [],
        "mailEnabled": false,
        "mailNickname": "NotSet",
        "securityEnabled": true
    }
'@ | ConvertFrom-Json

    $bodyJson.displayName = $groupName

    if($groupDescription){
        $bodyJson | Add-Member -NotePropertyName description -NotePropertyValue $groupDescription
    } 
    
    if($groupMember.Length -gt 0){
        $bodyJson | Add-Member -NotePropertyName 'members@odata.bind' -NotePropertyValue @($groupMember.uri)
    }

    $bodyJson = $bodyJson | ConvertTo-Json
    New-MgGroup -BodyParameter $bodyJson
}

function Get-MigrateGroupMember{
    param (
        [String]$migrationType,
        [array]$groupMember = $null,
        $windows = $true,
        $ios = $true,
        $macos = $true,
        $android = $true
    )

    $os = @()
    if($windows){$os += 'Windows'}
    if($macos){$os += 'MacMDM'}
    if($android){$os += 'Android'}
    if($ios){$os += 'IOS'}
    
    $newGroupMember = @()

    if($migrationType -eq 0){
        $groupMember | Where-Object {$_.ItemType -eq 'Device'} | Foreach-Object {
            $userId = (Get-MgDeviceRegisteredOwner -DeviceId $_.Id).Id
            if($userId){
                $newGroupMember += [PSCustomObject]@{
                    Uri = "https://graph.microsoft.com/v1.0/directoryObjects/" + $userId 
                }  
            }
        }
        $groupMember  | Where-Object {$_.ItemType -eq 'User'} | Foreach-Object {
            $newGroupMember += [PSCustomObject]@{
                Uri             = $_.Uri
            }
        }
    }elseif($migrationType -eq 1){
        $groupMember  | Where-Object {$_.ItemType -eq 'User'} | Foreach-Object {
            (Get-MgUserOwnedDevice -UserId $_.Id) | ForEach-Object {
                $newGroupMember += [PSCustomObject]@{
                    Uri             = "https://graph.microsoft.com/v1.0/directoryObjects/" + $_.Id
                    OperatinSystem  = $_.AdditionalProperties.operatingSystem
                }
            }                        
        }
        $groupMember  | Where-Object {$_.ItemType -eq 'Device'} | Foreach-Object {
            $newGroupMember += [PSCustomObject]@{
                Uri             = $_.Uri
                OperatinSystem  = $_.OperatinSystem
            }
        }
        $newGroupMember = $newGroupMember | Where-Object {$_.OperatinSystem -in $os}
    }
    $newGroupMember = $newGroupMember | Sort-Object -Property uri -Uniqu 
    return ,$newGroupMember
}
########################################################################################
################################### Group Overview #####################################
########################################################################################
function Get-ManagedGroups{
    $allGroups = Get-MgGroup -All
    $global:GroupObjects = $allGroups
    return $allGroups
}

function Open-GroupView{
    param (
        [Parameter(Mandatory = $true)]
        [String]$groupId
    )   
    Hide-All
    Hide-GroupViewAll
    Get-GroupOverview -groupId $($global:SelectedGroupId).GroupObjectId
    Get-NavigationGroupViewPageChange -selectedItem "ItemGroupsOverview"
    $WPFListViewGroupMenu.SelectedIndex = 0
    $WPFGridGroupViewOverview.Visibility="Visible"
    $WPFGridGroupView.Visibility = 'Visible'
    Get-AllGroupMember -GroupId $groupId
}

function Get-GroupOverview{
    param (
        [Parameter(Mandatory = $true)]
        [String]$groupId
    )

    $group = Get-MgGroup -GroupId $groupId
    $countDevices = 0
    $countUser = 0
    $countGroup = 0
    $groupType = "Microsoft 365"
    $groupTypeMemberShip = "Assigned"
    if($group.SecurityEnabled -and $group.MailEnabled -eq $false){$groupType = "Security"}
    if($group.GroupTypes[0] -eq "DynamicMembership") {$groupTypeMemberShip = "Dynamic"}

    # Set ui info
    $colornumber= Get-Random -Maximum 9
    $WPFGridGroupPicture.Background = $global:GroupColorSelection[$colornumber]
    $WPFGridGroupPicture1.Background = $global:GroupColorSelection[$colornumber]
    $WPFTextGroupnameShort.Text = (($group.DisplayName).Substring(0,2)).ToUpper()
    $WPFTextGroupnameShort1.Text = (($group.DisplayName).Substring(0,2)).ToUpper()
    $WPFLableGroupOverviewName.Content = $group.DisplayName
    $WPFLableGroupName.Content = $group.DisplayName
    $WPFLabelSourceValue.Content = "Cloud"
    $WPFLabelMemberShipTypeValue.Content = $groupTypeMemberShip
    $WPFLabelTypeValue.Content = $groupType
    $WPFLabelObjectIdValue.Content = $group.Id
    $WPFLabelCreatedAtValue.Content = $group.CreatedDateTime
    $groupMember = Get-MgGroupMember -GroupId $groupId -All | Foreach-Object {
            if ($_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.device") {$countDevices++}
            if ($_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.user") {$countUser++}
            $countGroup++
    }

    $WPFLabelTotalGroupMembers.Content = "$countGroup Total"
    $WPFLabelGroupMembersUser.Content = "$countUser User(s)"
    $WPFLabelGroupMembersDevices.Content = "$countDevices Device(s)"   
}

########################################################################################
#################################### Group Member ######################################
########################################################################################
function Get-AllGroupMember {
    param(
      [Parameter(Mandatory = $true)]  
      $groupId
    )
  
    $global:AllGroupMember = @()
    $groupMembers = Get-MgGroupMember -GroupId $groupId
    $groupMembers = $groupMembers | Sort-Object -Property AdditionalProperties.displayName
    $items = @()
  
    $groupMembers | ForEach-Object {
        if($_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user'){
            $param = [PSCustomObject]@{
                ItemImg                         = ("$global:Path\.tmp\memberImg.png")
                ImgVisible                      = "Visible"
                GridColor                       = $null
                GroupNameShort                  = $null
                GridVisible                     = "Collapsed"
                ItemName                        = $_.AdditionalProperties.displayName
                ItemType                        = "User"
                ItemDetails                     = $_.AdditionalProperties.mail
                ItemId                          = $_.Id
                Id                              = $_.Id
                Uri                             = "https://graph.microsoft.com/v1.0/directoryObjects/" + $_.Id
                OperatinSystem                  = $null
            }
            $items += $param
        } elseif ($_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.device') {
            $param = [PSCustomObject]@{
                ItemImg                         = ("$global:Path\.tmp\deviceImg.png")
                ImgVisible                      = "Visible"
                GridColor                       = $null
                GroupNameShort                  = $null
                GridVisible                     = "Collapsed"
                ItemName                        = $_.AdditionalProperties.displayName 
                ItemType                        = "Device"
                ItemId                          = $_.Id
                ItemDetails                     = $_.AdditionalProperties.profileType
                Id                              = $_.Id
                Uri                             = "https://graph.microsoft.com/v1.0/directoryObjects/" + $_.Id
                OperatinSystem                  = $_.AdditionalProperties.operatingSystem
            }
            $items += $param
        } elseif ($_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.group') {
            $colornumber= Get-Random -Maximum 9
            $param = [PSCustomObject]@{
                ItemImg                         = $null
                ImgVisible                      = "Collapsed"
                GridColor                       = $global:GroupColorSelection[$colornumber]
                GroupNameShort                  = ($($_.AdditionalProperties.displayName).Substring(0,2)).ToUpper()
                GridVisible                     = "Visible"
                ItemName                        =  $_.AdditionalProperties.displayName
                ItemType                        = "Group"
                ItemId                          = $_.Id
                ItemDetails                     = $_.AdditionalProperties.securityIdentifier
                Id                              = $_.Id
                Uri                             = "https://graph.microsoft.com/v1.0/directoryObjects/" + $_.Id
                OperatinSystem                  = $null
            }
            $items += $param
        }
      }
    $global:AllGroupMember = @($items)
}
function Sync-AllDevicesInGroup{
    param (
        [Parameter(Mandatory = $true)]
        [String]$groupId
    )

    $groupMember = Get-MgGroupMember -GroupId $groupId -All | Foreach-Object {
        if ($_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.device"){
            $device = (Get-MgDevice -Filter "Id eq '$($_.Id)'")
            try {
                $intuneDeviceId = (Get-IntunemanagedDevice -Filter "azureADDeviceId eq '$($device.DeviceId)'").id
                if($intuneDeviceId) {
                    Invoke-IntuneManagedDeviceSyncDevice -managedDeviceId $intuneDeviceId | Out-Null
                }
            }
            catch {
                Write-Error "Sync of devices $($device.DeviceId) did not work."
            }
        }
    }
}

function Add-InitGroupItemGridMember{
    param (
        [boolean]$loadNew = $true
    )

    if(($global:AllGroupMember).Count -eq 0 -or $loadNew) {
        Get-AllGroupMember -groupId $global:SelectedGroupId.GroupObjectId 
    }
    
    $allGroupMembers = @()
    $allGroupMembers = $global:AllGroupMember

    $items += $allGroupMembers | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
	$WPFListViewGroupsViewSelection.ItemsSource = @($items)
}

############## Add ##############
function Add-InitGroupItemAddGrid{
    $itemsToAdd = $null

    switch($WPFListViewGroupMenu.SelectedItem.Name){
        ItemGroupsMember {
            $itemsToAdd = $global:AllManagedItems | Where-Object `
            { -not ($_.Id -in $global:AllGroupMember.id) -and `
            -not ($_.Id -like $global:SelectedGroupId.GroupObjectId) -and `
            -not ($_.GroupTypes -eq 'Dynamic')}
        }
        ItemGroupsPolicies {
            $itemsToAdd = $global:AllPolicies | Where-Object `
            { -not ($_.Id -in $global:AllGroupPolicies.id)}
        }
        ItemGroupsCompliancePolicies {
            $itemsToAdd = $global:AllCompliancePolicies | Where-Object `
            { -not ($_.Id -in $global:AllGroupCompliancePolicies.id)}
        }
        ItemGroupsApps {
            $itemsToAdd = $global:AllApps | Where-Object `
            { -not ($_.Id -in $global:AllGroupApps.id)}
        }
    }

    $itemsToAdd = $itemsToAdd | Sort-Object -Property ItemName
    $global:AllGroupsItemAddCollection = $itemsToAdd
    $items += $itemsToAdd | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
    $WPFListViewGroupsViewAdd.ItemsSource = @($items)
}
function Add-DirectoryItemToGroup {
    param(
        [Parameter(Mandatory = $true)]  
        $groupId,
        [Parameter(Mandatory = $true)]  
        $item
      )

      $params = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$item"
    }
    New-MgGroupMemberByRef -GroupId $groupId -BodyParameter $params
}

function Remove-DirectoryItemFromGroup{
    param(
        [Parameter(Mandatory = $true)]  
        $groupId,
        [Parameter(Mandatory = $true)]  
        $item
      )
    Invoke-MgGraphRequest -Method DELETE -Uri ("https://graph.microsoft.com/v1.0/groups/$groupId/members/$item/"+'$ref')
}

########################################################################################
##################################### Policies #########################################
########################################################################################
function Get-AllPolicies{
    $items = @()
    Get-MgDeviceManagementDeviceConfiguration -All | ForEach-Object{

        $param = [PSCustomObject]@{
            ItemImg                         = ("$global:Path\.tmp\policyImg.png")
            ImgVisible                      = "Visible"
            GridColor                       = $null
            GroupNameShort                  = $null
            GridVisible                     = "Collapsed"
            ItemName                        = $_.DisplayName
            ItemType                        = ($_.AdditionalProperties.'@odata.type').replace("#microsoft.graph.","")
            ItemId                          = $_.Id
            ItemDetails                     = $null
            ItemInfo                        = ($_.AdditionalProperties.'@odata.type').replace("#microsoft.graph.","")
            Id                              = $_.Id
            Uri                             = $null
            OperatinSystem                  = $null
            AssignmentId                    = $null
        }
        $items += $param
    }

    $global:AllPolicies = @($items)
}
function Get-AllGroupPolicies{
    param(
        [Parameter(Mandatory = $true)]  
        $groupId
      )
    $global:AllGroupPolicies = @()

    Get-IntuneDeviceConfigurationPolicy -Expand assignments| Where-Object {$_.assignments -match $groupId} | ForEach-Object {
        $id = $_.id
        $assignment = $null
        $policyAssignment = $null

        $_.assignments | ForEach-Object {
            if($_.target.groupId -eq $groupId){
                if($_.target.'@odata.type' -eq "#microsoft.graph.exclusionGroupAssignmentTarget"){
                    $assignment = "Exclude"
                }
                elseif ($_.target.'@odata.type' -eq "#microsoft.graph.groupAssignmentTarget"){
                    $assignment = "Include"
                }
                $policyAssignment = ($global:AllPolicies | Where-Object {$_.Id -eq $id}) | ConvertTo-Json | ConvertFrom-Json
                $policyAssignment.ItemDetails = $assignment
                $policyAssignment.AssignmentId = $_.id
                $global:AllGroupPolicies += $policyAssignment 
            }
        }
    }
}
function Add-InitGroupItemGridPolicies{
    param (
        [boolean]$loadNew = $true,
        [boolean]$init = $false,
        $groupId
    )

    if(($global:AllPolicies).Count -eq 0 -or $init) {
        Get-AllPolicies
    }

    if(($global:AllGroupPolicies).Count -eq 0 -or $loadNew) {
        Get-AllGroupPolicies -groupId $groupId
    }
    
    $groupPolicies = @()
    $groupPolicies = $global:AllGroupPolicies

    $items += $groupPolicies | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
	$WPFListViewGroupsViewSelection.ItemsSource = @($items)
}

function Add-PolicyToGroup {
    param(
        [Parameter(Mandatory = $true)]  
        $groupId,
        [Parameter(Mandatory = $true)]  
        $policyId,
        [parameter(Mandatory=$true)]
        [string]$assignment
      )

      $policyObject = $null
      $policyObject = New-Object PSObject
      if($assignment -eq "Include"){$policyObject | Add-Member NoteProperty '@odata.type' '#microsoft.graph.groupAssignmentTarget'}
      else{$policyObject | Add-Member NoteProperty '@odata.type' '#microsoft.graph.exclusionGroupAssignmentTarget'}
      $policyObject | Add-Member NoteProperty 'groupId' $groupId

      # Check if all deovices or user assigned
      New-DeviceManagement_DeviceConfigurations_Assignments -deviceConfigurationId $policyId -target $policyObject
}


function Remove-PolicyFromGroup{
    param(
        [Parameter(Mandatory = $true)]  
        $groupId,
        [Parameter(Mandatory = $true)]  
        $policyId
    )

    Get-DeviceManagement_DeviceConfigurations_Assignments -deviceConfigurationId $policyId | Foreach-Object {
        if($_.target.groupId -eq $groupId) {Remove-DeviceManagement_DeviceConfigurations_Assignments -deviceConfigurationAssignmentId $_.id -deviceConfigurationId $policyId}
    }
}


########################################################################################
############################### Compliance Policies ####################################
########################################################################################
function Get-AllCompliancePolicies{
    $items = @()
    Get-MgDeviceManagementDeviceCompliancePolicy -All | ForEach-Object{ 

        $param = [PSCustomObject]@{
            ItemImg                         = ("$global:Path\.tmp\compPolicyImg.png")
            ImgVisible                      = "Visible"
            GridColor                       = $null
            GroupNameShort                  = $null
            GridVisible                     = "Collapsed"
            ItemName                        = $_.DisplayName
            ItemType                        = ($_.AdditionalProperties.'@odata.type').replace("#microsoft.graph.","")
            ItemId                          = $_.Id
            ItemDetails                     = $null
            ItemInfo                        = ($_.AdditionalProperties.'@odata.type').replace("#microsoft.graph.","")
            Id                              = $_.Id
            Uri                             = $null
            OperatinSystem                  = $null
            AssignmentId                    = $null
        }
        $items += $param
    }

    $global:AllCompliancePolicies = @($items)
}
function Get-AllGroupCompliancePolicies{
    param(
        [Parameter(Mandatory = $true)]  
        $groupId
      )
    $global:AllGroupCompliancePolicies = @()

    Get-IntuneDeviceCompliancePolicy -Expand assignments| Where-Object {$_.assignments -match $groupId} | ForEach-Object {
        $id = $_.id
        $assignment = $null
        $compPolicyAssignment = $null

        $_.assignments | ForEach-Object {
            if($_.target.groupId -eq $groupId){
                if($_.target.'@odata.type' -eq "#microsoft.graph.exclusionGroupAssignmentTarget"){
                    $assignment = "Exclude"
                }
                elseif ($_.target.'@odata.type' -eq "#microsoft.graph.groupAssignmentTarget"){
                    $assignment = "Include"
                }
                $compPolicyAssignment = ($global:AllCompliancePolicies | Where-Object {$_.Id -eq $id}) | ConvertTo-Json | ConvertFrom-Json
                $compPolicyAssignment.ItemDetails = $assignment
                $compPolicyAssignment.AssignmentId = $_.id
                $global:AllGroupCompliancePolicies += $compPolicyAssignment 
            }
        }
    }
}
function Add-InitGroupItemGridCompliancePolicies{
    param (
        [boolean]$loadNew = $true,
        [boolean]$init = $false,
        $groupId
    )

    if(($global:AllCompliancePolicies).Count -eq 0 -or $init) {
        Get-AllCompliancePolicies
    }

    if(($global:AllGroupCompliancePolicies).Count -eq 0 -or $loadNew) {
        Get-AllGroupCompliancePolicies -groupId $groupId
    }
    
    $groupCompPolicies = @()
    $groupCompPolicies = $global:AllGroupCompliancePolicies

    $items += $groupCompPolicies | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
	$WPFListViewGroupsViewSelection.ItemsSource = @($items)
}

function Add-CompliancePolicyToGroup {
    param(
        [Parameter(Mandatory = $true)]  
        $groupId,
        [Parameter(Mandatory = $true)]  
        $policyId,
        [parameter(Mandatory=$true)]
        [string]$assignment
      )

      $compPolicyObject = $null
      $compPolicyObject = New-Object PSObject
      if($assignment -eq "Include"){$compPolicyObject | Add-Member NoteProperty '@odata.type' '#microsoft.graph.groupAssignmentTarget'}
      else{$compPolicyObject | Add-Member NoteProperty '@odata.type' '#microsoft.graph.exclusionGroupAssignmentTarget'}
      $compPolicyObject | Add-Member NoteProperty 'groupId' $groupId

      # Check if all deovices or user assigned
      New-DeviceManagement_DeviceCompliancePolicies_Assignments -deviceCompliancePolicyId $policyId -target $compPolicyObject
}


function Remove-CompliancePolicyFromGroup{
    param(
        [Parameter(Mandatory = $true)]  
        $groupId,
        [Parameter(Mandatory = $true)]  
        $policyId
    )

    Get-DeviceManagement_DeviceCompliancePolicies_Assignments -deviceCompliancePolicyId $policyId | Foreach-Object {
        if($_.target.groupId -eq $groupId) {Remove-DeviceManagement_DeviceCompliancePolicies_Assignments -deviceCompliancePolicyAssignmentId  $_.id -deviceCompliancePolicyId $policyId}
    }
}

########################################################################################
####################################### Apps ###########################################
########################################################################################
function Get-AllApps{
    $exclude = "#microsoft.graph.managedAndroidStoreApp", "#microsoft.graph.managedIOSStoreApp"
    $items = @()
    Get-MgDeviceAppMgtMobileApp -All | Where-Object {-not ($_.AdditionalProperties.'@odata.type' -in $exclude)} | ForEach-Object{  
        $param = [PSCustomObject]@{
            ItemImg                         = ("$global:Path\.tmp\appImg.png")
            ImgVisible                      = "Visible"
            GridColor                       = $null
            GroupNameShort                  = $null
            GridVisible                     = "Collapsed"
            ItemName                        = $_.DisplayName
            ItemType                        = ($_.AdditionalProperties.'@odata.type').replace("#microsoft.graph.","")
            ItemId                          = $_.Id
            ItemDetails                     = $null
            ItemInfo                        = ($_.AdditionalProperties.'@odata.type').replace("#microsoft.graph.","")
            Id                              = $_.Id
            Uri                             = $null
            OperatinSystem                  = $null
            AssignmentId                    = $null
        }
        $items += $param
    }
    $global:AllApps = @($items)
}

function Add-InitGroupItemGridApps{
    param (
        [boolean]$loadNew = $true,
        [boolean]$init = $false,
        $groupId
    )

    if(($global:AllApps).Count -eq 0 -or $init) {
        Get-AllApps
    }

    if(($global:AllGroupApps).Count -eq 0 -or $loadNew) {
        Get-AllGroupApps -groupId $groupId
    }
    
    $groupApps = @()
    $groupApps = $global:AllGroupApps
    $items += $groupApps | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
	$WPFListViewGroupsViewSelection.ItemsSource = @($items)
}

function Get-AllGroupApps{
    param(
        [Parameter(Mandatory = $true)]  
        $groupId
      )
    $global:AllGroupApps = @()
    Get-IntuneMobileApp -Expand assignments | Where-Object {$_.assignments -match $groupId} | ForEach-Object {
        $id = $_.id
        $assignment = $null
        $appAssignment = $null
        $_.assignments | ForEach-Object {
            if($_.target.groupId -eq $groupId){
                if($_.intent -eq "required" -and $_.target.'@odata.type' -eq "#microsoft.graph.exclusionGroupAssignmentTarget"){
                    $assignment = "Exclude (required)"
                }
                elseif ($_.intent -eq "available" -and $_.target.'@odata.type' -eq "#microsoft.graph.exclusionGroupAssignmentTarget"){
                    $assignment = "Exclude (available)"
                }
                elseif ($_.intent -eq "uninstall" -and $_.target.'@odata.type' -eq "#microsoft.graph.exclusionGroupAssignmentTarget" ){
                    $assignment = "Exclude (uninstall)"
                }
                elseif ($_.intent -eq "required" -and $_.target.'@odata.type' -eq "#microsoft.graph.groupAssignmentTarget"){
                    $assignment = "Include (required)"
                }
                elseif ($_.intent -eq "available" -and $_.target.'@odata.type' -eq "#microsoft.graph.groupAssignmentTarget"){
                    $assignment = "Include (available)"
                }
                elseif ($_.intent -eq "uninstall" -and $_.target.'@odata.type' -eq "#microsoft.graph.groupAssignmentTarget" ){
                    $assignment = "Include (uninstall)"
                }
    
    
                $appAssignment = ($global:AllApps | Where-Object {$_.Id -eq $id}) | ConvertTo-Json | ConvertFrom-Json
                $appAssignment.ItemDetails = $assignment
                $appAssignment.AssignmentId = $_.id
                $global:AllGroupApps += $appAssignment  
            }
        }
    }
}
function Add-AppToGroup {
    param(
        [Parameter(Mandatory = $true)]  
        $groupId,
        [Parameter(Mandatory = $true)]  
        $appId,
        [parameter(Mandatory=$true)]
        [string]$assignment,
        [parameter(Mandatory=$true)]
        [string]$intent
      )

      $appObject = $null
      $appObject = New-Object PSObject
      if($assignment -eq "Include"){$appObject | Add-Member NoteProperty '@odata.type' '#microsoft.graph.groupAssignmentTarget'}
      else{$appObject | Add-Member NoteProperty '@odata.type' '#microsoft.graph.exclusionGroupAssignmentTarget'}
      $appObject | Add-Member NoteProperty 'groupId' $groupId

      # Check if all deovices or user assigned

      New-IntuneMobileAppAssignment -mobileAppId $appId -intent $intent -target $appObject
}

function Remove-AppFromGroup{
    param(
        [Parameter(Mandatory = $true)]  
        $assignmentId,
        [Parameter(Mandatory = $true)]  
        $appId
    )

    Remove-IntuneMobileAppAssignment -mobileAppAssignmentId $assignmentId -mobileAppId $appId
}