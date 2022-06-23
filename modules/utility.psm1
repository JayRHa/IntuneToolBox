<#
.SYNOPSIS
Core functions
.DESCRIPTION
Core functions
.NOTES
  Author: Jannik Reinhard
#>

##
function Get-ModuleVersion
{
    '1.0.0'
}

function Add-XamlEvent{
  param(
    [Parameter(Mandatory = $true)]  
    $object,
    [Parameter(Mandatory = $true)]
    $event,
    [Parameter(Mandatory = $true)]
    $scriptBlock
  )

  try {
      if($object)
      {
          $object."$event"($scriptBlock)
      }
      else 
      {
          $global:txtSplashText.Text = "Event  $($object.Name) loaded successfully"

      }
  }
  catch 
  {
      Write-Error "Failed load event $($object.Name). Error:" $_.Exception
  }
}

function Get-GraphAuthentication{
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

  try
  { 
      Import-Module -Name Microsoft.Graph.Intune -ErrorAction Stop
  } 
  catch
  {
      Write-Output "Module Microsoft.Graph.Intune was not found, try to installing in for the current user..."
      Install-Module -Name Microsoft.Graph.Intune -Scope CurrentUser -Force
      Import-Module Microsoft.Graph.Intune -Force
  }

  try {
    Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All","DeviceManagementApps.Read.All", "Device.Read.All"
  } catch {
    Write-Error "Failed to connect to MgGraph"
    return $false
  }
  
  try {
    Connect-MSGraph -AdminConsent -ErrorAction Stop
  } catch {
    Write-Error "Failed to connect to MSGraph"
    return $false
  }

  return $true
}

function Set-LoginOrLogout{
  if($global:auth){
    Disconnect-MgGraph

    Set-UserInterface
    $global:auth = $false
    [System.Windows.MessageBox]::Show('You are logged out')
    $WPFGridHomeFrame.Visibility = 'Hidden'
    $WPFGridGroupManagement.Visibility = 'Hidden'
    Return
  }


  $connectionStatus = Get-GraphAuthentication
  if(-not $connectionStatus) {
      [System.Windows.MessageBox]::Show('login Failed')
  }
  
  $global:auth = $true


  $user = Get-MgContext
  $org = Get-MgOrganization
  $upn  = $user.Account

  Write-Host "------------------------------------------------------"	
  Write-Host "Connection to graph success: $Success"
  Write-Host "Connected as: $($user.Account)"
  Write-Host "TenantId: $($user.TenantId)"
  Write-Host "Organizsation Name: $($org.DisplayName)"
  Write-Host "------------------------------------------------------"	
  
  Get-ProfilePicture -upn $upn

  #Set Login menue
  $WPFLableUPN.Content = $user.Account
  $WPFLableTenant.Content = $org.DisplayName

  # Enable tabs
  $WPFItemHome.IsEnabled = $true
  $WPFItemGroupManagement.IsEnabled = $true
  $WPFItemHome.IsSelected = $true

  #Load Image for groups
  Add-GroupImage
  return 
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

function Get-ProfilePicture {
  param (
      [Parameter(Mandatory = $true)]
      [String]$upn
  )
  $path = "$PSScriptRoot\.tmp\$upn.png"
  if (-Not (Test-Path $path)) {
      Get-MgUserPhotoContent -UserId $upn -OutFile $path
  }
  $iconButtonLogIn = [convert]::ToBase64String((get-content $path -encoding byte))
  $WPFImgButtonLogIn.source = DecodeBase64Image -ImageBase64 $iconButtonLogIn
  $WPFImgButtonLogIn.Width="40"
  $WPFImgButtonLogIn.Height="40"
}