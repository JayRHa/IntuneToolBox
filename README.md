# Intune Tool Box - Rebuild of Intune in PowerShell
* [Blog Post]("")
I think everyone who works with Intune on a daily basis knows the situation that they would like to have a simple feature that would simplify their daily work. In order not to have to do without exactly these small features that would make everyday life easier, I have created the Intune Tool Box. This is a WPF application that is written in PowerShell. The app has the same design as Intune but offers small helpers for the daily work. The good thing is that this app is built in such a way that it can be easily extended at any time. If you have any features in your mind that you are missing in Intune console let me know so I can add them to the app.
![Tool View](.images\groupView.png)


## How to execute the application
* Download and unzip the whole folder
![Download View](.images\downloadGitHub.png)
* Execute the Start-IntuneToolBox.ps1
* Have fun

## Features
### Overall Environment View:
On the start page you can get an overview of your complete environment and see how many clients are enrolled per OS.
![Enviroment View](.images\startPage.png)

### Group View:
In this view you get an overview from all groups in your environment with all the features know from the Portal.
![Groups View](.images\groupOverview.png)

### Sync all devices:
Sync all devices in a group with one simple click.
![Enviroment View](.images\syncAllDevices.png)


### Group Overview:
I think you have often been in a situation where you wanted to see what is assigned to a group. Now you can easily see this in the overview.

### Migrate Group:
With this function you can convert a user group into a device group or a device group into a user group. For this it is checked who is the owner of the device or which devices a certain user owns.

### Duplicate Group:
Create a copy from a existing group. All member will be take over.

### Assign Items:
You can assign configuration profiles, compliance policies or apps direct in the group view.