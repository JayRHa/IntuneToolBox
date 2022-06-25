<#
.SYNOPSIS
Helper for main page
.DESCRIPTION
Helper for main page
.NOTES
  Author: Jannik Reinhard
#>

########################################################################################
###################################### Functions #######################################
########################################################################################


########################################################################################
################################### User Interface #####################################
########################################################################################
function Get-MainFrame{
    $deviceManagementOverview = Get-MgDeviceManagementManagedDeviceOverview
    $complianceOverview = Get-MgDeviceManagementDeviceCompliancePolicyDeviceStateSummary

    # State
    $WPFLabelTotalDevicesState.Content = "$($deviceManagementOverview.EnrolledDeviceCount) Devices in your tenant"
    $WPFLabelIntuneOnlyState.Content = "$($deviceManagementOverview.MdmEnrolledCount) Mdm only managed devices"
    $WPFLabelHybrideDevicesState.Content = "$($deviceManagementOverview.DualEnrolledDeviceCount) Co-Managed devices"
    $WPFLabelComplianteState.Content = "$($complianceOverview.CompliantDeviceCount) Compliant devices"
    $WPFLabelUncomplianteState.Content = "$($complianceOverview.NonCompliantDeviceCount) Uncompliante devices"

    # OS
    $WPFLabelTotalWindowsDevicesState.Content = "$($deviceManagementOverview.deviceOperatingSystemSummary.windowsCount) devices"
    $WPFLabelTotalIosDevicesState.Content = "$($deviceManagementOverview.deviceOperatingSystemSummary.iosCount) devices"
    $WPFLabelTotalAndroidDevicesState.Content = "$($deviceManagementOverview.deviceOperatingSystemSummary.androidCount) devices"
    $WPFLabelTotalMacOSDevicesState.Content = "$($deviceManagementOverview.deviceOperatingSystemSummary.macOSCount) devices"
    $WPFLabelTotalUnknowDevicesState.Content = "$($deviceManagementOverview.deviceOperatingSystemSummary.unknownCount) devices"
    $WPFGridHomeFrame.Visibility = 'Visible'
}