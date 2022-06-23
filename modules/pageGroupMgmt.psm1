<#
.SYNOPSIS
Helper for Group management Module
.DESCRIPTION
Helper for Group management Module
.NOTES
  Author: Jannik Reinhard
#>

function Get-ModuleVersion
{
    '1.0.0'
}
function Search-Group{
    param(  
        [String]$searchString
      )
      Write-Host "$searchString"
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

function Add-GroupsToGrid{
    param (
        $groups
    )

    #if(-not $groups){return}
    $items = $groups | Select-Object -First $([int]$($WPFComboboxGridCount.SelectedItem))
	$WPFListViewAllGroups.ItemsSource = $items
	$WPFLabelCountGroups.Content = "$($items.count) Groups"
}

function Get-ManagedGroups{
    $allGroups = Get-MgGroup -All
    $script:GroupObjects = $allGroups
    return $allGroups
}

function Add-GroupImage{
    if((Test-Path ("$PSScriptRoot\.tmp\groupImg.png"))) {return}
    $imageGroup = "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAvCAIAAAATh2/FAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAASdEVYdFNvZnR3YXJlAEdyZWVuc2hvdF5VCAUAAALsSURBVFhH7ZfLaxNBHMeDVhvyaGxrXpvE7sYk3aQhJG2sWs3DkjakD62tgidvhaKIAQ961auexApehKCi1xQRQ0EPKj5AqAo+/hu/m1nGZpJNp6C7K2T4HHZnZnc+M7+ZX7KWgOA3CaZXmZACaxnpbj66UZa3lsZ+rSR1gFWJhIRqNtyoxJl+OtCiUoqF1gtRpodu/FHJRYK16RjTrCeqSkoMGLgeBFUF+4Np0B9FBeelXpaZBv1RVFbTIlNrCIoK8gdTawiKyuacAVmkHUs0JOiWT7ujrApTZRQ9lU70VDrx36q8nZevp3yTbrulWRIHrBcjwy9m1Qz5cjYqu6ykCcXet6ckDNTy0o/llpdowavycyV57/ghydmPMQK2fVMeB8AFbm8fCZI+RMW1f+8xt/2k15E9aIcNuDMZxOP0VVrwqjzKSxgYKg9OjHxfVlMiLp4UpIc59SeMqOS8jo+LSvrG8JCASt7r+LCwc0LnUkFcyBpAiGnaDqMC3szLR912VKKJdtOCS+X+1AgCcTnuoevRkXaV15XR8WEbbOBEu2nBpXI14YEKDYQWjAp2682MwDMHwi5UnhbVf3pflhIXwkOoIQXXqEE9UaHbNj1kQ+s5cfD9Atf/sl2oPC6oG+Xr0tgl2U3PCKPS1FNLdcz77Szvzz6XClnnGykfcybJ2IwKCdDn04krcWUC15JenugALpXnM9HDzn5swFeVlq+TLiq4/bQYrwRdbmsfshx9pAtcKpgWJocpzggDjXKMrk29FBnVVgHYXkgBRZ/z3d86QWDrTGJNdivxb+Z7uitRuqhgDuQpbJodw8SrAnA4nxXD58VBku9xUk75nbfGBTpwuwpATBFZPEIPoBa7UPnX9FQ60VNpA99iZlHZKMtmUcF3u1lU1jKSKVQalfiEFDCFSjUbhobxKuuFaCQkGK9Sm46VYiE4GKyC9chFgsTDMJV6Wcb+SIkB6qGrCvLp5lwc+WM1LeK8bJdQEPy/AQHJ/VSRm5sfAAAAAElFTkSuQmCC"
    $imagePath = ("$PSScriptRoot\.tmp\groupImg.png")
    [byte[]]$Bytes = [convert]::FromBase64String($imageGroup)
    [System.IO.File]::WriteAllBytes($imagePath,$Bytes)
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
    
            # Create object
            $param = [PSCustomObject]@{
                GroupImage                  = ("$PSScriptRoot\.tmp\groupImg.png")
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
function Sync-AllDevicesInGroup{
    param (
        [Parameter(Mandatory = $true)]
        [String]$groupId
    )

    $groupMember = Get-MgGroupMember -GroupId $groupId -All | Foreach-Object {
        if ($_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.device"){
            $device = (Get-MgDevice -Filter "Id eq '$($_.Id)'")
            try {
                Write-Host "Azure AD Device id: $($device.DeviceId)"
                $intuneDeviceId = (Get-IntunemanagedDevice -Filter "azureADDeviceId eq '$($device.DeviceId)'").id
                Write-Host "Intune Device id: $intuneDeviceId"
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

function Get-GroupOverView{
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

function Get-GroupMigrated{
    # Pop up

    # As if user or device group

    # Create group

    # Get primary contact
    
    # Add User
}