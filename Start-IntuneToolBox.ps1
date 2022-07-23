<#
Version: 1.0
Author: Jannik Reinhard (jannikreinhard.com)
Script: Create-IntuneToolBox
Description:
Tool box with different intune helper
Release notes:
Version 1.0: Init
Version 1.1:
- Bugfix for dll loading error
- UI optiomization
- IMprove stability

#> 
###########################################################################################################
############################################ Functions ####################################################
###########################################################################################################
function Get-MessageScreen{
    param (
        [Parameter(Mandatory = $true)]
        [String]$xamlPath
    )
    
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    Add-Type -AssemblyName PresentationFramework
    [xml]$xaml = Get-Content $xamlPath
    $global:messageScreen = ([Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml)))
    $global:messageScreenTitle = $global:messageScreen.FindName("TextMessageHeader")
    $global:messageScreenText = $global:messageScreen.FindName("TextMessageBody")
    $global:button1 = $global:messageScreen.FindName("ButtonMessage1")
    $global:button2 = $global:messageScreen.FindName("ButtonMessage2")

    $global:messageScreenTitle.Text = "Initializing Intune Tool Box"
    $global:messageScreenText.Text = "Starting initializing Intune Tool Box"
    $global:messageScreen.Show() | Out-Null
    [System.Windows.Forms.Application]::DoEvents()
}

function Import-AllModules
{

    foreach($file in (Get-Item -path "$global:Path\modules\*.psm1"))
    {      
        $fileName = [IO.Path]::GetFileName($file) 
        if($skipModules -contains $fileName) { Write-Warning "Module $fileName excluded"; continue; }
    
        $module = Import-Module $file -PassThru -Force -Global -ErrorAction SilentlyContinue
        if($module)
        {
            $global:messageScreenText.Text = "Module $($module.Name) loaded successfully"
        }
        else
        {
            $global:messageScreenText.Text = "Failed to load module $file"
        }
    }
}

###########################################################################################################
############################################## Start ######################################################
###########################################################################################################
# Variables
[array]$global:AllGroupsObservableCollection  = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
[array]$global:AllGroupsCollection = $null
[array]$global:AllGroupsItemObservableCollection  = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
[array]$global:AllGroupsItemAddObservableCollection  = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
[array]$global:AllGroupsItemAddCollection = $null
[array]$global:AllGroupMember = $null
[array]$global:AllGroupPolicies = $null
[array]$global:AllPolicies = $null
[array]$global:AllGroupCompliancePolicies = $null
[array]$global:AllCompliancePolicies = $null
[array]$global:AllGroupApps = $null
[array]$global:AllApps = $null

$global:Auth = $false
$global:SelectedGroupId = ""
$global:AllManagedItems = $null
$global:GroupCreationMode = ""
$global:Path = $PSScriptRoot
$global:SelectedIndex = -1
$global:GroupColorSelection = ("#00AAA8", "#1E7045", "#20874D", "#20874D", "#FE0096","#D9532C","#2D88EE","#D30BC4","#ED1111","#00AAA8")
# Start Start Screen
Get-MessageScreen -xamlPath ("$global:Path\xaml\message.xaml")
$global:messageScreenTitle.Text = "Initializing Intune Tool Box"
$global:messageScreenText.Text = "Starting initializing Intune Tool Box"

# Load custom modules
Import-AllModules

#Init 
if (-not (Start-Init)){
    Write-Error "Error while loading the dlls. Exit the script"
    Write-Warning "Unblock all dlls and restart the powershell seassion"
    $global:messageScreen.Hide()
    Exit
}

# Load main windows
$returnMainForm = New-XamlScreen -xamlPath ("$global:Path\xaml\ui.xaml")
$global:formMainForm = $returnMainForm[0]
$xamlMainForm = $returnMainForm[1]
$xamlMainForm.SelectNodes("//*[@Name]") | % {Set-Variable -Name "WPF$($_.Name)" -Value $formMainForm.FindName($_.Name)}
$global:formMainForm.add_Loaded({
    $global:messageScreen.Hide()
    $global:formMainForm.Activate()
})

# Init User interface
$global:messageScreenText.Text = "Load User Interface"
Set-UserInterface

# Load the click actions
$global:messageScreenText.Text = "Load Actions"
Set-UiAction
Set-UiActionButton

# Authentication
$global:messageScreenText.Text = "Login to Microsoft Graph (Auth Windows could be in the backround)"
Set-LoginOrLogout

$global:messageScreenText.Text = "Get all managed Items"
Get-AllManagedItems | out-null
$global:messageScreenText.Text = "Get all Configuration Profiles"
Get-AllPolicies | out-null
$global:messageScreenText.Text = "Get all Compliance Policies"
Get-AllCompliancePolicies | out-null
$global:messageScreenText.Text = "Get all Apps"
Get-AllApps | out-null


# Start Main Windows
$global:formMainForm.ShowDialog() | out-null