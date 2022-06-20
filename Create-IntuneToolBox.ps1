<#
Version: 1.0
Author: Jannik Reinhard (jannikreinhard.com)
Script: Create-IntuneToolBox
Description:
Tool box with different intune helper
Release notes:
Version 1.0: Init
#> 
###########################################################################################################
############################################# Load UI #####################################################
###########################################################################################################
$inputXML = Get-Content ("$PSScriptRoot\ui.xaml")
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$xaml = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $form = [Windows.Markup.XamlReader]::Load( $reader )
    $xaml.SelectNodes("//*[@Name]") | % {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
}
catch {
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}
$xaml.SelectNodes("//*[@Name]") | % {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
###########################################################################################################
############################################ Functions ####################################################
###########################################################################################################
Function Get-FormVariables {
    if ($global:ReadmeDisplay -ne $true) {Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true}
    Write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    get-variable WPF*
}
function DecodeBase64Image {
    param (
        [Parameter(Mandatory = $true)]
        [String]$imageBase64
    )
    # Parameter help description
    $objBitmapImage = New-Object System.Windows.Media.Imaging.BitmapImage
    $objBitmapImage.BeginInit()
    $objBitmapImage.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($imageBase64)
    $objBitmapImage.EndInit()
    $objBitmapImage.Freeze()
    return $objBitmapImage
}

function Set-UserInterface {
    #Load images for UI
    $iconButtonOpenMenu = @'
    iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAACwElEQVRIie2TXW8UZRiGr+ft7FCLiXgi8i0KMbSmm+7OduqGEJa2iqQhRI85JnDgL/An+BM8kHMTUUiwAbotkLrZmZ1hCzXKkhBFPvRAsym0bndmHg7cElN2t1uPuQ+fzFzXe79vHniVDSLrB0EQ7FTVr+I4PjM6Ovpgbe553gjwhYicdhxnuVeBWT9IkuRLVf3EGDMbBME+AFU1InJeRD4FLvm+P/C/BcBZoAS8myTJdd/33xORpK+v7zPgIVAAflhcXHy9F8FLVwTg+/4bqnpZRD4EHojIsWw2ey8Mw4NxHM8CO1X1um3bJ9Lp9LPNNsBxnLpt25PALLBHVYuVSuXAyMhILY7jAvBIRI40m81v5+fnX9u0ACCdTj9LpVJTQBHYrao3giAYdF337poEmLRt+7tuko6CNQkwparXgLeTJJkpl8tDruveVdVj/5Fc6CTpKgBwHGdZRE6KyFVguzFmxvO8D3K53C8tyWPgI9u2LxSLxf71/7d95Hap1Wpb6vX6N8AU8Ccw4TjObc/z3heRIrADmF5aWjpVKBT+6bnBWur1eh+w5cXJRATAsqyk24F7auD7/oCqfi8i48AfqjqRy+XuVCqVA6o6C+wSkauNRuNkPp9f2ZSgWq1ubTabF/l3wZ4YY8YzmcxPvu/vBeaAd4CbqVTqeLud6CrotHDlcnmPMWYO2C8i8/39/R8PDQ09bcfo+AZhGG4Dplvw34BCNpu9VyqVdhtjisB+Vf1xZWXleCd4xwZhGG6L43gaGAV+jeO44Lru/VKptN2yrCJwCAhs254YHh7+u9stvNRgYWHhzSiKrrTgtSiKDruue79arb5lWdZMC35rdXV1ciN4W0Gj0TgvIg7wszHm6NjY2O8AURR9DQy24OP5fP6vjeBtBZZlfS4il6MoOprJZB69+NCYc6p6EZjsFf4qPeU5CTIuzFdHs9MAAAAASUVORK5CYII=
'@
    $WPFImgButtonOpenMenue.source = DecodeBase64Image -ImageBase64 $iconButtonOpenMenu

    $iconButtonCloseMenu = @'
    iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAACpklEQVRIie2VTWtUSRSGn1M39IcDZjOgBEz8AD+mISHXm9vQZDTqxBlj3AyCf8CViL/CpX/AhYthlo4MxC8wmDFEm6RTuW0WPYSJoCJGo4wS1KT7kqpykXSQTjrdvfddnlvnOfWew6kL39VA0sphrfUO59yfwNW+vr5iNV4oFPZ4nnddRC76vr/wbY5qBQ7cEZHfReQP55wCiKKoSyn1yDl3xlp7rTavqQL5fD7tnBsBTgCLInJBRKzWutNaOwbsB2biOL5cm9uwRfl8Pp1MJkecc78Ai0qpk77v/xtFUZe19h9gn3NOJ5PJ093d3R9bcjA/P59MJBI3a+HFYnGvtfYRsA94Yow5tRUcwNsOvrS0dAs4C7yrwqempg4C40An8LhcLg/lcrlP9ThbtqhUKiVWVlZuAcPAO2vtyTAMS9PT04dEZAzoACbS6fRQJpP5vF0XNhWoB9daHwYeAh0iMp5KpYYbwaFmBqVSKbG8vPxXFe6cOxWGYWlmZuYIUL35g0qlcqYZ+KYCACKy4crzPLvF92R7e3vd2W06XxtYb9HfwBCwCAwEQTD3bYuAiXK5fLa/v7/ucOs6yGQycRzH51lryS5gVGt9IAiCOWPMCeA18HMqlbo/OTm5s2UHVa0/DXeBAeCVMeZ4Npt9XiwW9xpjxmiwYA0LAMzOzv4Qx/E9ETkGvPQ8b6C3t/fF+hZvPBHGmF+z2ez/WzG23eSenp4vxphzwBTQZYwZjaKow/f9l6y9S8+Ao57njWqtf2zZQVVa63YRGXXO9QH/sTb4N4VCYbdS6iHwEzCrlBr0ff990w6qCoJgqVKp/AY8BQ6KyA2AMAzfKqUGgTmgxxhzoza36f9BLpf7AAw6524rpS5V477vL6yurg6IyP22trYrzfK+a0NfAepxLvgo3BlmAAAAAElFTkSuQmCC
'@
    $WPFImgButtonCloseMenue.source = DecodeBase64Image -ImageBase64 $iconButtonCloseMenu

    $iconButtonLogIn = @'
    iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAAA1klEQVRIie2TsQrCMBCGc126dhcXX6Iv5OjkY1R9DPUFHHwQQdzV0lnBST+XBGs90xIpVPGHQHL5Lj+5S4z5q3MCYmAGHO2YAnEopxlMeVUWymkGuZKYh3KR5qHErqGcZjBXYosPuGfZ5k2Agx2Zp8m13A8JSIAhsAZ2wBm42NeyBCIPdwK2NjYGkurhKVAoz85p1JBzKoC0bLCpSRjUcCugp1VGbOLNzd8oEhE8XF9E9j4D7dM8IBEvV913a2P0j9ZduYaUY766Nz7Ut//9JWr9Bq0b3AFSVbeeEsxapQAAAABJRU5ErkJggg==
'@
    $WPFImgButtonLogIn.source = DecodeBase64Image -ImageBase64 $iconButtonLogIn

    $iconIntuneHome = @'
    iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAABPElEQVRIiWNgGFHAYerzYoepz4tJ0cNIlKr//xmdpr5o/8/wvxwqMsn+jWRhQwPjP4otCG24yvZGRHA+AwNDFJrU2v/cP2MOJCr+INsCt+4X3L85/61hYGDwwK7i/z6OfxyB2/OEP5FsgfOEl+L/WP5uZWBgMCbgwsvM//947M6Ve0a0BXaTXyiyMP3b+f8/gyo+w5HAfSaGfx57c2RuoUswoQs4TntmzMz47zgJhjMwMDAo/mNgOuYw6YUFXgucJr9wYvjHsI+BgUGcBMNhQJiR6d8ep8nPPbFa4DD1WfR/xn/bGRgY+MgwHAa4/zP+3+Q45WkSigUOk5/lM/5nWMTAwMBGgeEwwMLAwDjHYcrTcgYGLJHsOOXZf0pM358jhWImRiRTG9DcAhZiFaJ7ndigHPpBNGrBKKAcAAB1CWAtKzJosQAAAABJRU5ErkJggg==
'@
    $WPFImgItemHome.source = DecodeBase64Image -ImageBase64 $iconIntuneHome

    $iconGroupManagement = @'
    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
'@
    $WPFImgItemGroupManagement.source = DecodeBase64Image -ImageBase64 $iconGroupManagement

    $WPFItemHome.IsSelected = $false
    $WPFItemGroupManagement.IsSelected = $false
    $WPFItemHome.IsEnabled = $false
    $WPFItemGroupManagement.IsEnabled = $false

    $WPFLableUPN.Content = ""
    $WPFLableTenant.Content = ""
    $WPFImgButtonLogIn.Width="25"
    $WPFImgButtonLogIn.Height="25"
}

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
    

    $WPFGridFrame.Visibility = 'Visible'
}

###########################################################################################################
############################################# Buttons #####################################################
###########################################################################################################
$WPFButtonLogIn.Add_Click({

    if($global:auth){
        Disconnect-MgGraph
        Set-UserInterface
        $global:auth = $false
        Remove-item ("$PSScriptRoot\.tmp\profile.png")
        [System.Windows.MessageBox]::Show('You are logged out')
        Return
    }

    $GraphPowershellModulePath = "$PSScriptRoot/Microsoft.Graph.psd1"
    if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph')) {

        if (-Not (Test-Path $GraphPowershellModulePath)) {
            Write-Error "Microsoft.Graph.Intune.psd1 is not installed on the system check: https://docs.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0"
            Return
        }
        else {
            Import-Module "$GraphPowershellModulePath"
            $Success = $?

            if (-not ($Success)) {
                Write-Error "Microsoft.Graph.Intune.psd1 is not installed on the system check: https://docs.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0"
                Return
            }
        }
    }

    $return = Connect-MgGraph
    $Success = $?

    if(-not $Success) {
        Write-Error "FAILED connection to Microsoft Graph!"
        return
    }

    $user = Get-MgContext
    $org = Get-MgOrganization
    $upn  = $user.Account
    Get-MgUserPhotoContent -UserId $upn -OutFile ("$PSScriptRoot\.tmp\profile.png")
    $iconButtonLogIn = [convert]::ToBase64String((get-content  ("$PSScriptRoot\.tmp\profile.png") -encoding byte))


    Write-Host "------------------------------------------------------"	
    Write-Host "Connection to graph success: $Success"
    Write-Host "Connected as: $($user.Account)"
    Write-Host "TenantId: $($user.TenantId)"
    Write-Host "Organizsation Name: $($org.DisplayName)"
    Write-Host "------------------------------------------------------"	

    $global:auth = $true
    
    #Set Login menue
    $WPFLableUPN.Content = $user.Account
    $WPFLableTenant.Content = $org.DisplayName
    $WPFImgButtonLogIn.source = DecodeBase64Image -ImageBase64 $iconButtonLogIn
    $WPFImgButtonLogIn.Width="40"
    $WPFImgButtonLogIn.Height="40"

    # Enable tabs
    $WPFItemHome.IsSelected = $true
    $WPFItemGroupManagement.IsSelected = $true
    $WPFItemHome.IsEnabled = $true
    $WPFItemGroupManagement.IsEnabled = $true4

    #LoadFrameValues
    Get-MainFrame
})

$WPFButtonOpenMenu.Add_Click( {
    $WPFButtonCloseMenu.Visibility = "Visible"
    $WPFButtonOpenMenu.Visibility = "Collapsed"
    $WPFGridContentFrame.ColumnDefinitions[0].Width = 150
})

$WPFButtonCloseMenu.Add_Click( {
    $WPFButtonCloseMenu.Visibility = "Collapsed"
    $WPFButtonOpenMenu.Visibility = "Visible"
    $WPFGridContentFrame.ColumnDefinitions[0].Width = 60
})

###########################################################################################################
############################################## Start ######################################################
###########################################################################################################

#Remove
Get-FormVariables


$global:auth = $false
Set-UserInterface
# Create temp folder
if(-not (Test-Path "$PSScriptRoot\.tmp")) {
    New-Item "$PSScriptRoot\.tmp" -Itemtype Directory
}

$form.ShowDialog() | out-null