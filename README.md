# Intune Tool Box - Rebuild of Intune in PowerShell
[Blog Post](https://jannikreinhard.com/2022/07/07/intune-tool-box-rebuild-of-intune-in-powershell/)
<p align="left">
  <a href="https://twitter.com/jannik_reinhard">
    <img src="https://img.shields.io/twitter/follow/jannik_reinhard?style=social" target="_blank" />
  </a>
    <a href="https://github.com/JayRHa">
    <img src="https://img.shields.io/github/followers/JayRHa?style=social" target="_blank" />
  </a>
</p>


I think everyone who works with Intune on a daily basis knows the situation that they would like to have a simple feature that would simplify their daily work. In order not to have to do without exactly these small features that would make everyday life easier, I have created the Intune Tool Box. This is a WPF application that is written in PowerShell. The app has the same design as Intune but offers small helpers for the daily work. The good thing is that this app is built in such a way that it can be easily extended at any time. If you have any features in your mind that you are missing in Intune console let me know so I can add them to the app.<br/>
![Tool View](https://github.com/JayRHa/IntuneToolBox/blob/main/.images/groupView.png)


## How to execute the application
* Download and unzip the whole folder <br/>
![Download View](https://github.com/JayRHa/IntuneToolBox/blob/main/.images/downloadGitHub.png)
* Execute the Start-IntuneToolBox.ps1
* Have fun

## Features
### Overall Environment View:
On the start page you can get an overview of your complete environment and see how many clients are enrolled per OS.<br/>
![Enviroment View](https://github.com/JayRHa/IntuneToolBox/blob/main/.images/startPage.png)

### Group View:
In this view you get an overview from all groups in your environment with all the features know from the Portal.<br/>
![Groups View](https://github.com/JayRHa/IntuneToolBox/blob/main/.images/groupOverview.png)

### Sync all devices:
Sync all devices in a group with one simple click.<br/>
![Enviroment View](https://github.com/JayRHa/IntuneToolBox/blob/main/.images/syncAllDevices.png)

### Group Overview:
I think you have often been in a situation where you wanted to see what is assigned to a group. Now you can easily see this in the overview.<br/>
![Enviroment View](https://github.com/JayRHa/IntuneToolBox/blob/main/.images/groupView.png)

### Migrate Group:
With this function you can convert a user group into a device group or a device group into a user group. For this it is checked who is the owner of the device or which devices a certain user owns.<br/>
![Enviroment View](https://github.com/JayRHa/IntuneToolBox/blob/main/.images/migrateGroup.png)

### Duplicate Group:
Create a copy from a existing group. All member will be take over.<br/>
![Enviroment View](https://github.com/JayRHa/IntuneToolBox/blob/main/.images/copyGroup.png)

### Assign Items:
You can assign configuration profiles, compliance policies or apps direct in the group view.<br/>
![Enviroment View](https://github.com/JayRHa/IntuneToolBox/blob/main/.images/addConfiguration.png)
