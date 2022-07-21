<#
.SYNOPSIS
Core functions
.DESCRIPTION
Core functions
.NOTES
  Author: Jannik Reinhard
#>

##
function Start-Init {
  #Load dll
  try {
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  				| out-null
    [System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 				| out-null
    [System.Reflection.Assembly]::LoadFrom("$global:Path\libaries\MahApps.Metro.dll")       				| out-null
    [System.Reflection.Assembly]::LoadFrom("$global:Path\libaries\ControlzEx.dll")                 | out-null  
    [System.Reflection.Assembly]::LoadFrom("$global:Path\libaries\SimpleDialogs.dll")              | out-null
  }catch{
    Write-Error "Loading from dll's was not sucessfull:"
    return $false
  }

  # Create temp folder
  if(-not (Test-Path "$global:Path\.tmp")) {
    New-Item "$global:Path\.tmp" -Itemtype Directory
  }
  return $true
}

function Get-AllManagedItems {
    $managedItems = @()
    $devices = Get-MgDevice -All
    $user = Get-MgUser -All
    $groups = Get-MgGroup -All

    $devices | ForEach-Object {
        $param = [PSCustomObject]@{
            ItemImg                         =  ("$global:Path\.tmp\deviceImg.png")
            ImgVisible                      = "Visible"
            GridColor                       = $null
            GroupNameShort                  = $null
            GridVisible                     = "Collapsed"
            ItemName                        = $_.DisplayName
            ItemInfo                        = $_.DeviceId
            Id                              = $_.Id
            Type                            = "Device"
            GroupTypes                      = $null
        }
        $managedItems += $param
    }

    $user | ForEach-Object {
        $param = [PSCustomObject]@{
            ItemImg                         = ("$global:Path\.tmp\memberImg.png")
            ImgVisible                      = "Visible"
            GridColor                       = $null
            GroupNameShort                  = $null
            GridVisible                     = "Collapsed"
            ItemName                        = $_.DisplayName
            ItemInfo                        = $_.UserPrincipalName
            Id                              = $_.Id
            Type                            = "User"
            GroupTypes                      = $null
        }
        $managedItems += $param
    }

    $groups | ForEach-Object {
        $colornumber= Get-Random -Maximum 9
        if($_.GroupTypes[0] -eq "DynamicMembership") {$groupTypeMemberShip = "Dynamic"}else{$groupTypeMemberShip = "Assigned"}
        $param = [PSCustomObject]@{
            ItemImg                         = $null
            ImgVisible                      = "Collapsed"
            GridColor                       = $global:GroupColorSelection[$colornumber]
            GroupNameShort                  = ($($_.DisplayName).Substring(0,2)).ToUpper()
            GridVisible                     = "Visible"
            ItemName                        = $_.DisplayName
            ItemInfo                        = $_.Id
            Id                              = $_.Id
            Type                            = "Group"
            GroupTypes                      = $groupTypeMemberShip
        }
        $managedItems += $param
    }
  
  $global:AllManagedItems = $managedItems
  return $global:AllManagedItems
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
  $GraphPowershellModulePath = "$global:Path/Microsoft.Graph.psd1"
  if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph')) {

      if (-Not (Test-Path $GraphPowershelModulePath)) {
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
    Connect-MgGraph -Scopes "User.Read.All","User.Read", "Group.ReadWrite.All", "Device.Read.All", "DeviceManagementApps.ReadWrite.All", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All"
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
  Select-MgProfile -Name "beta"
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
  return 
}

function Get-DecodeBase64Image {
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
  $path = "$global:Path\.tmp\$upn.png"
  if (-Not (Test-Path $path)) {
      Get-MgUserPhotoContent -UserId $upn -OutFile $path
  }

  if (Test-Path $path) {
    try{
      $iconButtonLogIn = [convert]::ToBase64String((get-content $path -encoding byte))
      $WPFImgButtonLogIn.source = Get-DecodeBase64Image -ImageBase64 $iconButtonLogIn
      $WPFImgButtonLogIn.Width="35"
      $WPFImgButtonLogIn.Height="35"
    }catch{}
  }
}
########################################################################################
########################################### UI  ########################################
########################################################################################
function New-XamlScreen{
  param (
      [Parameter(Mandatory = $true)]
      [String]$xamlPath
  )
  $inputXML = Get-Content $xamlPath
  [xml]$xaml = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
  $reader = (New-Object System.Xml.XmlNodeReader $xaml)

  try {
      $form = [Windows.Markup.XamlReader]::Load( $reader )
  }
  catch {
      Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
  }
  return @($form, $xaml)
}

Function Get-FormVariables {
  if ($global:ReadmeDisplay -ne $true) {Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true}
  Write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
  get-variable WPF*
}

function Show-MessageBoxWindow{
  param (
      [String]$titel="Intune Tool Box",
      [Parameter(Mandatory = $true)]
      [String]$text,
      [String]$button1text="",
      [String]$button2text=""

  )

  if($button1text -eq ""){$global:button1.Visibility = "Hidden"}else{$global:button1.Visibility = "Visible"}
  if($button2text -eq ""){$global:button2.Visibility = "Hidden"}else{$global:button2.Visibility = "Visible"}

  $global:messageScreenTitle.Text = $titel
  $global:messageScreenText = $text
  $global:button1.Content = "Yes"
  $global:button2.Content = "No"
  $global:messageScreen.Show() | Out-Null
}

function Show-MessageBoxInWindow{
  param (
      [String]$titel="Intune Tool Box",
      [Parameter(Mandatory = $true)]
      [String]$text,
      [String]$button1text="",
      [String]$button2text="",
      [String]$messageSeverity="Information"

  )

  $global:message = [SimpleDialogs.Controls.MessageDialog]::new()		    
  $global:message.MessageSeverity = $messageSeverity
  $global:message.Title = $titel
  if($button1text -eq ""){$global:message.ShowFirstButton = $false}else{$global:message.ShowSecondButton = $true}
  if($button2text -eq ""){$message.ShowSecondButton = $false}else{$global:message.ShowSecondButton = $true}
  $global:message.FirstButtonContent = $button1text
  $global:message.SecondButtonContent = $button2text

  $global:message.TitleForeground = "White"
  $global:message.Background = "#FF1B1A19"
  $global:message.Message = $text	
  [SimpleDialogs.DialogManager]::ShowDialogAsync($($global:formMainForm), $global:message)

  $global:message.Add_ButtonClicked({
    $buttonArgs  = [SimpleDialogs.Controls.DialogButtonClickedEventArgs]$args[1]	
    $buttonValues = $buttonArgs.Button
    If($buttonValues -eq "FirstButton")
      {
        return $null
      }
    ElseIf($buttonValues -eq "SecondButton")
      {
                return $null
      }				
  })
  return $null
}
