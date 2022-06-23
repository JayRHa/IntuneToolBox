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
############################################ Functions ####################################################
###########################################################################################################
function Start-StartScreen{
    param (
        [Parameter(Mandatory = $true)]
        [String]$xamlPath
    )
    
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    Add-Type -AssemblyName PresentationFramework
    [xml]$xaml = Get-Content ("$PSScriptRoot\xaml\startScreen.xaml")
    $global:startScreen = ([Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml)))
    $global:textStartScreenTitle = $global:StartScreen.FindName("TextTitelStartScreen")
    $global:textStartScreen = $global:StartScreen.FindName("TextStartScreen")

    $global:textStartScreenTitle.Text = "Initializing Intune Tool Box"
    $global:textStartScreen.Text = "Starting initializing Intune Tool Box"
    $global:startScreen.Show() | Out-Null
    [System.Windows.Forms.Application]::DoEvents()
}

function Import-AllModules
{
    foreach($file in (Get-Item -path "$PSScriptRoot\modules\*.psm1"))
    {      
        $fileName = [IO.Path]::GetFileName($file) 
        if($skipModules -contains $fileName) { Write-Warning "Module $fileName excluded"; continue; }
    
        $module = Import-Module $file -PassThru -Force -Global -ErrorAction SilentlyContinue
        if($module)
        {
          $global:textStartScreen.Text = "Module $($module.Name) loaded successfully"
        }
        else
        {
          $global:textStartScreen.Text = "Failed to load module $file"
        }
    }
}

###########################################################################################################
############################################## Start ######################################################
###########################################################################################################
# Variables
[array]$script:GroupObservableCollection = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
[array]$script:GroupObjectsSearch = $null
$global:auth = $false
$global:SelectedGroupId = ""
# Create temp folder
if(-not (Test-Path "$PSScriptRoot\.tmp")) {
    New-Item "$PSScriptRoot\.tmp" -Itemtype Directory
}

# Start Start Screen
Start-StartScreen -xamlPath ("$PSScriptRoot\xaml\startScreen.xaml")

# Load custom modules
Import-AllModules

# Load main windows
$returnMainForm = New-XamlScreen -xamlPath ("$PSScriptRoot\xaml\ui.xaml")
$formMainForm = $returnMainForm[0]
$xamlMainForm = $returnMainForm[1]
$xamlMainForm.SelectNodes("//*[@Name]") | % {Set-Variable -Name "WPF$($_.Name)" -Value $formMainForm.FindName($_.Name)}
$formMainForm.add_Loaded({
    $global:StartScreen.Hide()
    $formMainForm.Activate()
})

# Remove
Get-FormVariables

# Init User interface
$global:textStartScreen.Text = "Load User Interface"
Set-UserInterface

# Load the click actions
$global:textStartScreen.Text = "Load Actions"
Set-UiAction

# Authentication
$global:textStartScreen.Text = "Login to Microsoft Graph"
Set-LoginOrLogout

# Start Main Windows
$formMainForm.ShowDialog() | out-null