<#
.SYNOPSIS
Helper for Group management Module
.DESCRIPTION
Helper for Group management Module
.NOTES
  Author: Jannik Reinhard
#>

########################################################################################
###################################### Functions #######################################
########################################################################################
function Search-Group{
    param(  
        [String]$searchString
      )
    if($searchString.Length -lt 2) {
        Add-InitGroupsGrid -clearDevicesList $false
        return
    }
    if($searchString -eq '') { 
        Add-InitGroupsGrid -clearDevicesList $false
        return
    }

    $script:GroupObjectsSearch = @()          
    $script:GroupObjectsSearch = $script:GroupObservableCollection | Where `
        { ($_.GroupName -like "*$searchString*") -or `
        ($_.GroupObjectId -like "*$searchString*") -or `
        ($_.GroupEmail -like "*$searchString*") }

    Add-GroupsToGrid -groups $script:GroupObjectsSearch
}
function Get-ManagedGroups{
    $allGroups = Get-MgGroup -All
    $script:GroupObjects = $allGroups
    return $allGroups
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
    if($group.GroupTypes[0] -eq "DynamicMembership") {$groupType = "Dynamic"}


    # Set ui info
    $colornumber= Get-Random -Maximum 9
    $WPFGridGroupPicture.Background = $global:GroupColorSelection[$colornumber]
    $WPFTextGroupnameShort.Text = (($group.DisplayName).Substring(0,2)).ToUpper()
    $WPFLableGroupOverviewName.Content = $group.DisplayName
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
        "securityEnabled": true,
        "members@odata.bind":[]
    }
'@ | ConvertFrom-Json

    $bodyJson.displayName = $groupName

    if($groupDescription){
        $bodyJson | Add-Member -NotePropertyName description -NotePropertyValue $groupDescription
    } 
    
    $groupMmemberArray = @()
    $groupMember | Foreach-Object {
        $groupMmemberArray += "https://graph.microsoft.com/v1.0/directoryObjects/" + $_.Id
    }

    $bodyJson.'members@odata.bind' = $groupMmemberArray
    $bodyJson = $bodyJson | ConvertTo-Json
    New-MgGroup -BodyParameter $bodyJson
}

function Set-MigrateAadGroup{
    param (
        [Parameter(Mandatory = $true)]
        [String]$groupName,
        [String]$groupDescription = $null,
        [String]$migrationType,
        [array]$groupMember = $null
    )

    $user = @()
    $device = @()
    $newGroupMember = @()
    $groupMember | Foreach-Object {
        if($_.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.user"){$user += $_}
        elseif($_.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.device") {$user += $_}
    }

    if($migrationType -eq 0){
        $device  | Foreach-Object {
                        
        }
    }elseif($migrationType -eq 1){
        # $newGroupMember += $device.id
        # $user  | Foreach-Object {
        #     $Get-MgUserOwnedDevice -UserId $_.Id ###Check

        # }
    }
}

########################################################################################
################################### User Interface #####################################
########################################################################################
function Open-GroupView{
    param (
        [Parameter(Mandatory = $true)]
        [String]$groupId
    )   
    Hide-All
    Get-GroupOverview -groupId $($global:SelectedGroupId).GroupObjectId
    $WPFGridGroupView.Visibility = 'Visible'
    $global:AllGroupMember = Get-MgGroupMember -GroupId $groupId
    return $global:AllGroupMember
}

function Add-InitGroupsGrid{
    param (
        [boolean]$clearDevicesList = $true
    )
    
    if(-not $global:auth) {return}
    if(($script:GroupObservableCollection).Count -eq 0 -or $clearDevicesList) {
        $script:GroupObservableCollection = @()

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
    
            $script:GroupObservableCollection += $param
        }

    }
    Add-GroupsToGrid -groups $script:GroupObservableCollection 
}

function Add-GroupsToGrid{
    param (
        $groups
    )
    $items = @()
    #if(-not $groups){return}
    $items += $groups | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
	$WPFListViewAllGroups.ItemsSource = $items
	$WPFLabelCountGroups.Content = "$($items.count) Groups"
}